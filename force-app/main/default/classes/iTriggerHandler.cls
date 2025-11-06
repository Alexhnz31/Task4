public with sharing global interface iTriggerHandler {
    public static beforeInsert(List<SOBJECT> ListOfRecords);
    public static beforeUpdate(List<SOBJECT> ListOfOldRecords, List<SOBJECT> ListOfNewRecords);
    public static beforeDelete(List<SOBJECT> ListOfRecords);
    public static afterInsert(List<SOBJECT> ListOfRecords);
    public static afterUpdate(List<SOBJECT> ListOfRecords);
    run();
}