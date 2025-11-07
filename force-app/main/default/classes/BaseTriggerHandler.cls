public with sharing virtual class BaseTriggerHandler implements iTriggerHandler {
    protected List<SObject> newList;
    protected List<SObject> oldList;
    protected Map<Id, SObject> newMap;
    protected Map<Id, SObject> oldMap;
    protected Boolean isBefore;
    protected Boolean isAfter;
    protected Boolean isInsert;
    protected Boolean isUpdate;
    protected Boolean isDelete;
    protected Integer triggerSize;

    public BaseTriggerHandler() {
        this.newList = Trigger.isInsert || Trigger.isUpdate ? Trigger.new : null;
        this.oldList = Trigger.isUpdate || Trigger.isDelete ? Trigger.old : null;
        this.newMap = Trigger.isInsert || Trigger.isUpdate ? Trigger.newMap : null;
        this.oldMap = Trigger.isUpdate || Trigger.isDelete ? Trigger.oldMap : null;
        this.isBefore = Trigger.isBefore;
        this.isAfter = Trigger.isAfter;
        this.isInsert = Trigger.isInsert;
        this.isUpdate = Trigger.isUpdate;
        this.isDelete = Trigger.isDelete;
        this.triggerSize = Trigger.size;
    }

    public void run() {
        if (isBefore) {
            if (isInsert) {
                beforeInsert();
            } else if (isUpdate) {
                beforeUpdate();
            } else if (isDelete) {
                beforeDelete();
            }
        } else if (isAfter) {
            if (isInsert) {
                afterInsert();
            } else if (isUpdate) {
                afterUpdate();
            } else if (isDelete) {
                afterDelete();
            } else if (Trigger.isUndelete) {
                afterUndelete();
            }
        }
    }
 
    public virtual void beforeInsert() {}
    public virtual void beforeUpdate() {}
    public virtual void beforeDelete() {}
    public virtual void afterInsert() {}
    public virtual void afterUpdate() {}
    public virtual void afterDelete() {}
    public virtual void afterUndelete() {}
}