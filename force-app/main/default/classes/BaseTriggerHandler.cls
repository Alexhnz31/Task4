public with sharing class BaseTriggerHandler implements iTriggerHandler {
    
 public void run() {
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            beforeInsert();
        }
        if(Trigger.isUpdate){
            beforeUpdate();
        }
        if(Trigger.isDelete){
            beforeDelete();
        }


    }
    else-if(Trigger.isAfter){

        if(Trigger.isInstert){
            afterInsert();
        }
        if(Trigger.isUpdate){
            afterUpdate();
        }
    }
    
    public static beforeInsert(List<SOBJECT> ListOfRecords) {
    }

    public static beforeUpdate(List<SOBJECT> ListOfOldRecords, List<SOBJECT> ListOfNewRecords) {
    }

    public static beforeDelete(List<SOBJECT> ListOfRecords) {
    }

    public static afterInsert(List<SOBJECT> ListOfRecords) {
    }

    public static afterUpdate(List<SOBJECT> ListOfRecords) {
    }

   
}