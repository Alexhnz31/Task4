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
            OpportunityLineItem newOli = (OpportunityLineItem) sObj;
            if (newOli.Product2Id != null) {
                productIds.add(newOli.Product2Id);
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
            
            if (newOli.Product2Id != null && products.containsKey(newOli.Product2Id)) {
                Product2 prod = products.get(newOli.Product2Id);
                String productCode = prod.ProductCode; 
                String derivedFamily = familyMapping.get(productCode); 
                
                if (derivedFamily != null) {
                    if (this.isInsert || derivedFamily != (String) oldOli?.get('Product_Family_Match__c')) {
                        newOli.put('Product_Family_Match__c', derivedFamily);
                    }
                } else if (this.isUpdate && newOli.Product2Id == oldOli.Product2Id) {
                } else {
                    newOli.put('Product_Family_Match__c', null); 
                }
            }
        }
    }

    private void updateOpportunityRollups() {
        Set<Id> oppIdsToRecalculate = new Set<Id>();
        
        for(SObject sObj : this.newList) {
            oppIdsToRecalculate.add(((OpportunityLineItem)sObj).OpportunityId);
        }

        if (oppIdsToRecalculate.isEmpty()) return;
        RollupService.recalculateOpportunityProductRollups(oppIdsToRecalculate);
    }
    
    private void updateOpportunityRollupsFromOldRecords() {
        Set<Id> oppIdsToRecalculate = new Set<Id>();
        
        for(SObject oldSObj : this.oldMap.values()) {
            oppIdsToRecalculate.add(((OpportunityLineItem)oldSObj).OpportunityId);
        }

        if (oppIdsToRecalculate.isEmpty()) return;
        RollupService.recalculateOpportunityProductRollups(oppIdsToRecalculate);
    }
}