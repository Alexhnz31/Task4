public with sharing class ProductTriggerHandler extends BaseTriggerHandler {
   @override
   public void beforeInsert(List<SObject> newRecords) {}
   @override
   public void beforeUpdate(List<SObject> oldRecords, List<SObject> newRecords){} 
   @override
   public void afterUpdate(List<Sobject> updatedRecords) {}
}