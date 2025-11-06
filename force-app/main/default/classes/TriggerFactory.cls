public with sharing class TriggerFactory {
    public createHandle(String objectName){
        if(objectName == 'Lead'){
            return new LeadTriggerHandler;
        }
        if(objectName == 'Opportunity'){
            return new OpportunityTriggerHandler;
        }
        if(objectName == 'OpportunityProduct'){
            return new OpportunityProductTriggerHandler;
        }
        if(objectName == 'Product2'){
            return new ProductTriggerHandler;
        }

    }


}