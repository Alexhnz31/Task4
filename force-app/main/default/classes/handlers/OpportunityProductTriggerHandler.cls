public with sharing class OpportunityProductTriggerHandler extends BaseTriggerHandler {
    
    public override void afterInsert() {
        handleProductFamilyMatch();
        updateOpportunityRollups(); // Добавление RLSF логики
    }
    
    public override void afterUpdate() {
        handleProductFamilyMatch();
        updateOpportunityRollups(); // Добавление RLSF логики
    }

    public override void beforeInsert() {}
    public override void beforeUpdate() {}
    public override void beforeDelete() {}
    public override void afterDelete() {}
    public override void afterUndelete() {}

    /**
     * Логика копирования формульного поля (Миграция Flow).
     */
    private void handleProductFamilyMatch() {
        List<OpportunityLineItem> olisToUpdate = new List<OpportunityLineItem>();
        
        for (SObject sObj : this.newList) {
            OpportunityLineItem newOli = (OpportunityLineItem) sObj;
            
            if (newOli.get('Product_Family_Formula__c') != null) {
                String formulaValue = (String) newOli.get('Product_Family_Formula__c');
                
                if (formulaValue != (String) newOli.get('Product_Family_Match__c')) {
                    newOli.put('Product_Family_Match__c', formulaValue);
                    olisToUpdate.add(newOli);
                }
            }
        }
        
        if (!olisToUpdate.isEmpty()) {
            // Внимание: Здесь должен быть использован статический флаг рекурсии
            update olisToUpdate; 
        }
    }

    /**
     * Выполняет RLSF на Opportunity при изменении OLI.
     * RLSF #1: Count Of Arduino Products (Opp_Summ__c)
     * RLSF #2: Not Arduino Board (not_Arduino_Board__c)
     */
    private void updateOpportunityRollups() {
        // Получаем ID родительских Opportunity, которые нужно обновить.
        Set<Id> oppIdsToRecalculate = new Set<Id>();
        
        // 1. Собираем ID из новых записей (insert/update)
        for(SObject sObj : this.newList) {
            oppIdsToRecalculate.add(((OpportunityLineItem)sObj).OpportunityId);
        }
        // 2. Собираем ID из старых записей (для delete/update, если OpportunityId изменился)
        if(this.oldMap != null) {
            for(SObject oldSObj : this.oldMap.values()) {
                oppIdsToRecalculate.add(((OpportunityLineItem)oldSObj).OpportunityId);
            }
        }

        if (oppIdsToRecalculate.isEmpty()) return;

        // Вызов сервисного класса для выполнения свертки (RollupService)
        // ВАЖНО: Требуется класс RollupService.cls, который вы создадите.
        RollupService.recalculateOpportunityProductRollups(oppIdsToRecalculate);
    }
}