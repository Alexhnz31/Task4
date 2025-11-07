public interface iTriggerHandler {
    void beforeInsert();
    void beforeUpdate();
    void beforeDelete();
    void afterInsert();
    void afterUpdate();
    void afterDelete();
    void run();
}