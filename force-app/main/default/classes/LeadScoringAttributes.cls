public class LeadScoringAttributes {
    
    public enum Attribute {
        Number_of_Students_c 
    }

    public static Attribute getAttributeByApiName(String apiName) {
        try {
            // Удаляем суффикс '__c' для сопоставления с именем Enum
            String attributeName = apiName.endsWith('__c') ? apiName.substring(0, apiName.length() - 3) : apiName;
            
            return (Attribute) Attribute.valueOf(attributeName);
        } catch (Exception e) {
            return null;
        }
    }
}