public with sharing class TriggerFactory {
    
    // Вспомогательный метод для безопасного определения объекта
    private static Boolean isSObjectType(String expectedObjectName) {
        // ИСПРАВЛЕНИЕ: Использовать Trigger.SObjectType (с заглавной 'S')
        // Сравниваем строку с API Name объекта
      return Trigger.isExecuting && 
     String.valueOf(Trigger.new.getSObjectType()) == expectedObjectName;
    }

    public static void run(){
        BaseTriggerHandler handler;

        if(isSObjectType('Lead')){
            // handler = new LeadTriggerHandler(); // Предполагается, что этот класс существует
        }
        else if (isSObjectType('Opportunity')) {
            handler = new OpportunityTriggerHandler();
        }
        else if (isSObjectType('OpportunityLineItem')) { 
            // handler = new OpportunityProductTriggerHandler(); // Предполагается, что этот класс существует
        }
        else if (isSObjectType('Product2')) {
            handler = new ProductTriggerHandler();
        }
        
        if (handler != null) {  
            handler.run();
        }
    }
}