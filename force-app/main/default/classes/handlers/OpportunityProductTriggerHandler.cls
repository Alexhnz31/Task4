public with sharing class OpportunityProductTriggerHandler extends BaseTriggerHandler {

    public override void beforeInsert() {
        handleProductFamilyMatch_Before(); 
    }
    
    public override void beforeUpdate() {
        handleProductFamilyMatch_Before(); 
    }

    public override void afterInsert() {
        updateOpportunityRollups();
    }
    
    public override void afterUpdate() {
        updateOpportunityRollups();
    }
    
    public override void afterDelete() {
        updateOpportunityRollupsFromOldRecords();
    }

    public override void beforeDelete() {}
    public override void afterUndelete() {}

    private void handleProductFamilyMatch_Before() {
        Set<Id> productIds = new Set<Id>();
        for (SObject sObj : this.newList) {
            OpportunityLineItem oli = (OpportunityLineItem) sObj;
            if (oli.Product2Id != null) {
                productIds.add(oli.Product2Id);
            }
        }
        if (productIds.isEmpty()) return;

        Map<Id, Product2> products = new Map<Id, Product2>([
            SELECT Id, ProductCode 
            FROM Product2 
            WHERE Id IN :productIds
        ]);
        
        Map<String, String> familyMapping = ProductFamilyByCodeMappingService.getProductCodeMapping();

        for (SObject sObj : this.newList) {
            OpportunityLineItem newOli = (OpportunityLineItem) sObj;
            OpportunityLineItem oldOli = this.isUpdate ? (OpportunityLineItem) this.oldMap.get(newOli.Id) : null;
            
            if (newOli.Product2Id == null || !products.containsKey(newOli.Product2Id)) continue;

            Product2 prod = products.get(newOli.Product2Id);
            String productCode = prod.ProductCode; 
            String derivedFamily = familyMapping.get(productCode); 
            
            if (derivedFamily == null) {
                newOli.addError('Such product code is not allowed in the system. Please update the PFC mapping or contact administrator.');
                continue;
            }

            if (this.isInsert || derivedFamily != (String) oldOli?.get('Product_Family_Match__c')) {
                newOli.Product_Family_Match__c = derivedFamily;
            }
        }
    }

    private void updateOpportunityRollups() {
        Set<Id> oppIds = new Set<Id>();
        for (SObject sObj : this.newList) {
            oppIds.add(((OpportunityLineItem)sObj).OpportunityId);
        }
        if (!oppIds.isEmpty()) {
            RollupService.recalculateOpportunityProductRollups(oppIds);
        }
    }
    
    private void updateOpportunityRollupsFromOldRecords() {
        Set<Id> oppIds = new Set<Id>();
        for (SObject oldSObj : this.oldMap.values()) {
            oppIds.add(((OpportunityLineItem)oldSObj).OpportunityId);
        }
        if (!oppIds.isEmpty()) {
            RollupService.recalculateOpportunityProductRollups(oppIds);
        }
    }
}