public with sharing class OpportunityTriggerHandler extends BaseTriggerHandler {
    
    // --- BEFORE INSERT/UPDATE LOGIC (Migration of Setting_For_Creating_an_Opp) ---
    public override void beforeInsert() {
        handleRecordTypeAssignment();
    }

    public override void beforeUpdate() {
        handleRecordTypeAssignment();
    }
    
    // --- AFTER UPDATE LOGIC (Migration of Opportunity_Closed_Won_Create_Account_Interest) ---
    public override void afterUpdate() {
        handleProductInterestCreationAndDelete();
    }
    
    // --- PLACEHOLDERS ---
    public override void beforeDelete() {}
    public override void afterInsert() {}
    public override void afterDelete() {}
    public override void afterUndelete() {}
    
    // --- МЕТОДЫ РЕАЛИЗАЦИИ ---

    /**
     * Логика установки Record Type (Flow: Setting_For_Creating_an_Opp)
     * Срабатывает Before Insert/Update.
     */
    private void handleRecordTypeAssignment() {
        // IDs RecordType нужно получить в реальной среде или использовать Custom Metadata
        // ВАЖНО: замените эти ID на актуальные Record Type ID из вашего Flow/Process Builder
        final Id CAMPUS_SALE_RT_ID = '012g5000000CFhdAAG'; // myRule_1_A1
        final Id GROUP_SALE_RT_ID = '012g5000000CFg1AAG';  // myRule_3_A1

        List<Opportunity> opportunities = this.isInsert ? this.newList : this.newList;

        for (SObject sObj : opportunities) {
            Opportunity newOpp = (Opportunity) sObj;
            
            // Если поле Number_of_Students__c существует и не null
            if (newOpp.get('Number_of_Students__c') != null) {
                Decimal numStudents = (Decimal) newOpp.get('Number_of_Students__c');
                
                // myRule_1: Campus Sale Condition (Number_of_Students__c > 50)
                if (numStudents > 50) {
                    newOpp.RecordTypeId = CAMPUS_SALE_RT_ID;
                } 
                // myRule_3: Group Sale Condition (Number_of_Students__c >= 50). 
                // Так как myRule_1 уже поймало > 50, здесь достаточно проверять, что > 50 не сработало,
                // но в коде Process Builder логика идет по порядку, поэтому:
                else if (numStudents >= 50) {
                    // Эта ветка сработает только для случая, когда Number_of_Students__c == 50
                    newOpp.RecordTypeId = GROUP_SALE_RT_ID;
                }
            }
        }
    }


    /**
     * Логика создания/удаления Account Interest (Flow: Opportunity_Closed_Won_...)
     * Срабатывает After Update.
     */
    private void handleProductInterestCreationAndDelete() {
        Set<Id> closedWonOppsToProcess = new Set<Id>();
        Set<Id> revertedOppsToProcess = new Set<Id>(); 
        
        // Фильтрация Opportunity
        for (Id oppId : this.newMap.keySet()) {
            Opportunity newOpp = (Opportunity)this.newMap.get(oppId);
            Opportunity oldOpp = (Opportunity)this.oldMap.get(oppId);
            
            // СОЗДАНИЕ: Stage перешел в Closed Won
            if (newOpp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
                closedWonOppsToProcess.add(oppId); 
            } 
            
            // УДАЛЕНИЕ: Stage ушел из Closed Won
            if (oldOpp.StageName == 'Closed Won' && newOpp.StageName != 'Closed Won') {
                revertedOppsToProcess.add(oppId); 
            }
        }
        
        if (!closedWonOppsToProcess.isEmpty()) {
            createAccountInterests(closedWonOppsToProcess);
        }
        
        if (!revertedOppsToProcess.isEmpty()) {
            deleteAccountInterests(revertedOppsToProcess);
        }
    }
    
    // Вспомогательный метод для создания Account_Interest__c
    private void createAccountInterests(Set<Id> oppIds) {
        // 1. Получение AccountId (более надежно, чем через перекрестный запрос OLI)
        Map<Id, Id> oppIdToAccountId = new Map<Id, Id>();
        for (Opportunity o : [SELECT AccountId FROM Opportunity WHERE Id IN :oppIds]) {
            if (o.AccountId != null) {
                oppIdToAccountId.put(o.Id, o.AccountId);
            }
        }
        
        if (oppIdToAccountId.isEmpty()) return;

        // 2. Запрос OpportunityLineItem
        List<OpportunityLineItem> productsToProcess = [
            SELECT Product2Id, Quantity, OpportunityId
            FROM OpportunityLineItem 
            WHERE OpportunityId IN :oppIds
        ];
        
        List<Account_Interest__c> interestsToInsert = new List<Account_Interest__c>();
        
        // 3. Создание новых записей
        for (OpportunityLineItem oli : productsToProcess) {
            Account_Interest__c newInterest = new Account_Interest__c();
            newInterest.Product__c = oli.Product2Id; 
            newInterest.Account__c = oppIdToAccountId.get(oli.OpportunityId); 
            newInterest.Quantity__c = oli.Quantity;
            newInterest.Deal_Link__c = oli.OpportunityId;
            interestsToInsert.add(newInterest);
        }
        
        if (!interestsToInsert.isEmpty()) {
            insert interestsToInsert;
        }
    }
    
    // Вспомогательный метод для удаления Account_Interest__c
    private void deleteAccountInterests(Set<Id> oppIds) {
        List<Account_Interest__c> interestsToDelete = [
            SELECT Id FROM Account_Interest__c WHERE Deal_Link__c IN :oppIds
        ];
        
        if (!interestsToDelete.isEmpty()) {
            delete interestsToDelete;
        }
    }
}