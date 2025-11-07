public with sharing class TriggerFactory {
    
    private static Boolean isSObjectType(String expectedObjectName) {

      return Trigger.isExecuting && 
     String.valueOf(Trigger.new.getSObjectType()) == expectedObjectName;
    }

    public static void run(){
        BaseTriggerHandler handler;

        if(isSObjectType('Lead')){
        }
        else if (isSObjectType('Opportunity')) {
            handler = new OpportunityTriggerHandler();
        }
        else if (isSObjectType('OpportunityLineItem')) { 
           handler = new OpportunityProductTriggerHandler(); 
        }
        else if (isSObjectType('Product2')) {
            handler = new ProductTriggerHandler();
        }
        
        if (handler != null) {  
            handler.run();
        }
    }
}