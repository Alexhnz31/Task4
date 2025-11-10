public with sharing class OpportunityTriggerHandler extends BaseTriggerHandler {

    private static final Id CAMPUS_SALE_RT_ID = '012g5000000CFhdAAG'; 
    private static final Id GROUP_SALE_RT_ID  = '012g5000000CFg1AAG'; 

    public override void beforeInsert() {
        assignRecordType();
    }

    public override void beforeUpdate() {
        assignRecordType();
    }

    public override void afterUpdate() {
        handleAccountInterestCreationAndDeletion();
    }

    public override void beforeDelete() {}
    public override void afterInsert() {}
    public override void afterDelete() {}
    public override void afterUndelete() {}

    private void assignRecordType() {
        for (Opportunity opp : (List<Opportunity>) this.newList) {
            Decimal students = (Decimal) opp.get('Number_of_Students__c');
            if (students != null) {
                opp.RecordTypeId = students > 50 ? CAMPUS_SALE_RT_ID : GROUP_SALE_RT_ID;
            }
        }
    }

    private void handleAccountInterestCreationAndDeletion() {
        Set<Id> oppsToCreate = new Set<Id>();
        Set<Id> oppsToDelete = new Set<Id>();

        for (Id oppId : this.newMap.keySet()) {
            Opportunity newOpp = (Opportunity) this.newMap.get(oppId);
            Opportunity oldOpp = (Opportunity) this.oldMap.get(oppId);

            if (newOpp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
                oppsToCreate.add(oppId);
            } else if (oldOpp.StageName == 'Closed Won' && newOpp.StageName != 'Closed Won') {
                oppsToDelete.add(oppId);
            }
        }

        if (!oppsToCreate.isEmpty()) {
            createAccountInterests(oppsToCreate);
        }
        if (!oppsToDelete.isEmpty()) {
            deleteAccountInterests(oppsToDelete);
        }
    }

    private void createAccountInterests(Set<Id> oppIds) {
        Map<Id, Id> oppToAccountMap = new Map<Id, Id>();
        for (Opportunity opp : [SELECT Id, AccountId FROM Opportunity WHERE Id IN :oppIds AND AccountId != null]) {
            oppToAccountMap.put(opp.Id, opp.AccountId);
        }
        if (oppToAccountMap.isEmpty()) return;

        List<OpportunityLineItem> olis = [
            SELECT OpportunityId, Product2Id, Quantity
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppToAccountMap.keySet()
        ];

        List<Account_Interest__c> interests = new List<Account_Interest__c>();
        for (OpportunityLineItem oli : olis) {
            Account_Interest__c interest = new Account_Interest__c(
                Account__c = oppToAccountMap.get(oli.OpportunityId),
                Product__c = oli.Product2Id,
                Quantity__c = oli.Quantity,
                Deal_Link__c = oli.OpportunityId
            );
            interests.add(interest);
        }
        if (!interests.isEmpty()) insert interests;
    }

    private void deleteAccountInterests(Set<Id> oppIds) {
        List<Account_Interest__c> toDelete = [SELECT Id FROM Account_Interest__c WHERE Deal_Link__c IN :oppIds];
        if (!toDelete.isEmpty()) delete toDelete;
    }
}