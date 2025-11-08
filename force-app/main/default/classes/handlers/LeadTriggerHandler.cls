public with sharing class LeadTriggerHandler extends BaseTriggerHandler {

    public override void beforeInsert() {
        LeadScoringService.calculateScore((List<Lead>) this.newList);
    }

    public override void beforeUpdate() {
        LeadScoringService.calculateScore((List<Lead>) this.newList);
    }
    
    public override void afterInsert() {}
    public override void afterUpdate() {}
    public override void beforeDelete() {}
    public override void afterDelete() {}
    public override void afterUndelete() {}
}