public with sharing class OpportunityProductTriggerHandler extends BaseTriggerHandler {
    
    public override void afterInsert() {
        handleProductFamilyMatch();
    }
    
    public override void afterUpdate() {
        handleProductFamilyMatch();
    }

    public override void beforeInsert() {}
    public override void beforeUpdate() {}
    public override void beforeDelete() {}
    public override void afterDelete() {}
    public override void afterUndelete() {}

    /**
     * Логика копирования Product_Family_Formula__c в Product_Family_Match__c 
     * (Flow: Week3_1_Flow). Срабатывает After Save.
     */
    private void handleProductFamilyMatch() {
        List<OpportunityLineItem> olisToUpdate = new List<OpportunityLineItem>();
        
        // Предполагаем, что Product_Family_Formula__c - это формульное поле, 
        // которое должно быть доступно после сохранения (After Save)
        
        for (SObject sObj : this.newList) {
            OpportunityLineItem newOli = (OpportunityLineItem) sObj;
            
            // ПРОВЕРКА: Пропускаем, если поля не существуют или формула пуста
            if (newOli.get('Product_Family_Formula__c') != null) {
                String formulaValue = (String) newOli.get('Product_Family_Formula__c');
                
                // Проверяем, что значение изменилось или не было установлено
                if (formulaValue != (String) newOli.get('Product_Family_Match__c')) {
                    
                    // Обновляем поле Match
                    newOli.put('Product_Family_Match__c', formulaValue);
                    olisToUpdate.add(newOli);
                }
            }
        }
        
        if (!olisToUpdate.isEmpty()) {
            update olisToUpdate; 
        }
    }
}