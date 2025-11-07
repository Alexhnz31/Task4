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

    /**
     * Устанавливает Product_Family_Match__c, запрашивая ProductCode и используя сервисную карту.
     * Это обходит проблемы с Formula Fields и гарантирует, что RollupService увидит правильное значение.
     */
    private void handleProductFamilyMatch_Before() {
        Set<Id> productIds = new Set<Id>();
        
        // 1. Collect product IDs
        for (SObject sObj : this.newList) {
            OpportunityLineItem newOli = (OpportunityLineItem) sObj;
            if (newOli.Product2Id != null) {
                productIds.add(newOli.Product2Id);
            }
        }

        if (productIds.isEmpty()) return;

        // 2. Get Product Code (and Family for map) for all products
        // ВАЖНО: Запрашиваем ProductCode, так как он используется для маппинга
        Map<Id, Product2> products = new Map<Id, Product2>([
            SELECT Id, ProductCode 
            FROM Product2 
            WHERE Id IN :productIds
        ]);
        
        // Получаем карту маппинга (Code -> Family)
        Map<String, String> familyMapping = ProductFamilyByCodeMappingService.getProductCodeMapping();

        // 3. Set Product_Family_Match__c directly on newOli
        for (SObject sObj : this.newList) {
            OpportunityLineItem newOli = (OpportunityLineItem) sObj;
            OpportunityLineItem oldOli = this.isUpdate ? (OpportunityLineItem) this.oldMap.get(newOli.Id) : null;
            
            if (newOli.Product2Id != null && products.containsKey(newOli.Product2Id)) {
                Product2 prod = products.get(newOli.Product2Id);
                String productCode = prod.ProductCode; 
                String derivedFamily = familyMapping.get(productCode); // Получаем Family из карты
                
                if (derivedFamily != null) {
                    // Устанавливаем значение только если оно отличается или это новая запись
                    if (this.isInsert || derivedFamily != (String) oldOli?.get('Product_Family_Match__c')) {
                        newOli.put('Product_Family_Match__c', derivedFamily);
                    }
                } else if (this.isUpdate && newOli.Product2Id == oldOli.Product2Id) {
                    // Если код продукта не найден, но он был ранее, оставляем как есть
                } else {
                    // Если код продукта не найден и это новая запись, сбрасываем или оставляем null
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