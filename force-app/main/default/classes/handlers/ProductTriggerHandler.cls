public with sharing class ProductTriggerHandler extends BaseTriggerHandler {

    // Статический флаг для предотвращения рекурсии
    public static Boolean skipOpportunityProductTrigger = false;
    
    public override void beforeInsert() {
        enforceProductCodeMappingAndFamilyUpdate();
    }
    
    public override void beforeUpdate() {
        enforceProductCodeMappingAndFamilyUpdate();
    }

    public override void afterUpdate() {
        cascadeProductFamilyUpdate();
    }

    public override void beforeDelete() {}
    public override void afterInsert() {}
    public override void afterDelete() {}
    public override void afterUndelete() {}


    private void enforceProductCodeMappingAndFamilyUpdate() {
        // Вызов сервисного класса
        Map<String, String> validMapping = ProductFamilyByCodeMappingService.getProductCodeMapping();
        
        for (SObject sObj : this.newList) {
            Product2 newProduct = (Product2) sObj;
            String productCode = newProduct.ProductCode;
            
            if (String.isBlank(productCode)) continue;

            String expectedFamily = validMapping.get(productCode);
            
            if (expectedFamily == null) {
                // ТРЕБОВАНИЕ: Блокировка
                newProduct.addError('Such product code is not allowed in the system. Please update the PFC mapping or contact administrator.');
            } else {
                // ТРЕБОВАНИЕ: Обновление Family
                newProduct.Family = expectedFamily;
            }
        }
    }
 
    private void cascadeProductFamilyUpdate() {
        if (ProductTriggerHandler.skipOpportunityProductTrigger) return;
        
        Set<Id> productIdsToUpdate = new Set<Id>();
        Map<Id, String> newFamilyMap = new Map<Id, String>();
        
        for (SObject sObj : this.newList) {
            Product2 newProd = (Product2) sObj;
            Product2 oldProd = (Product2) this.oldMap.get(newProd.Id);

            if (oldProd != null && newProd.Family != oldProd.Family) {
                productIdsToUpdate.add(newProd.Id);
                newFamilyMap.put(newProd.Id, newProd.Family);
            }
        }

        if (productIdsToUpdate.isEmpty()) return;

        List<OpportunityLineItem> olisToUpdate = [
            SELECT Id, Product2Id, Product_Family_Match__c 
            FROM OpportunityLineItem
            WHERE Product2Id IN :productIdsToUpdate
        ];
        
        for (OpportunityLineItem oli : olisToUpdate) {
            String newFamily = newFamilyMap.get(oli.Product2Id);

            if (newFamily != (String) oli.get('Product_Family_Match__c')) {
                oli.put('Product_Family_Match__c', newFamily);
            }
        }
        
        if (!olisToUpdate.isEmpty()) {
            ProductTriggerHandler.skipOpportunityProductTrigger = true; 
            update olisToUpdate;
            ProductTriggerHandler.skipOpportunityProductTrigger = false;
        }
    }
}