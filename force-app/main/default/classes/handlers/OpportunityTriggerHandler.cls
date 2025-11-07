public with sharing class OpportunityTriggerHandler extends BaseTriggerHandler {
    public override void beforeInsert() {
        handleRecordTypeAssignment();
    }
    public override void beforeUpdate() {
        handleRecordTypeAssignment();
    }
    public override void afterUpdate() {
        handleProductInterestCreationAndDelete();
    }
    public override void beforeDelete() {}
    public override void afterInsert() {}
    public override void afterDelete() {}
    public override void afterUndelete() {}
    
    private void handleRecordTypeAssignment() {
        final Id CAMPUS_SALE_RT_ID = '012g5000000CFhdAAG';
        final Id GROUP_SALE_RT_ID = '012g5000000CFg1AAG'; 
        List<Opportunity> opportunities = (List<Opportunity>) this.newList; 
        for (SObject sObj : opportunities) {
            Opportunity newOpp = (Opportunity) sObj;
            if (newOpp.get('Number_of_Students__c') != null) {
                Decimal numStudents = (Decimal) newOpp.get('Number_of_Students__c');
                
                if (numStudents > 50) {
                    newOpp.RecordTypeId = CAMPUS_SALE_RT_ID;
                } 
                else if (numStudents >= 50) {
                    newOpp.RecordTypeId = GROUP_SALE_RT_ID;
                }
            }
        }
    }
    private void handleProductInterestCreationAndDelete() {
        Set<Id> closedWonOppsToProcess = new Set<Id>();
        Set<Id> revertedOppsToProcess = new Set<Id>(); 
        for (Id oppId : this.newMap.keySet()) {
            Opportunity newOpp = (Opportunity)this.newMap.get(oppId);
            Opportunity oldOpp = (Opportunity)this.oldMap.get(oppId);
            if (newOpp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
                closedWonOppsToProcess.add(oppId); 
            } 
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
    
    private void createAccountInterests(Set<Id> oppIds) {
        Map<Id, Id> oppIdToAccountId = new Map<Id, Id>();
        for (Opportunity o : [SELECT AccountId FROM Opportunity WHERE Id IN :oppIds]) {
            if (o.AccountId != null) {
                oppIdToAccountId.put(o.Id, o.AccountId);
            }
        }
        
        if (oppIdToAccountId.isEmpty()) return;

        List<OpportunityLineItem> productsToProcess = [
            SELECT Product2Id, Quantity, OpportunityId
            FROM OpportunityLineItem 
            WHERE OpportunityId IN :oppIds
        ];
        
        List<Account_Interest__c> interestsToInsert = new List<Account_Interest__c>();
        
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
    
    private void deleteAccountInterests(Set<Id> oppIds) {
        List<Account_Interest__c> interestsToDelete = [
            SELECT Id FROM Account_Interest__c WHERE Deal_Link__c IN :oppIds
        ];
        
        if (!interestsToDelete.isEmpty()) {
            delete interestsToDelete;
        }
    }
}