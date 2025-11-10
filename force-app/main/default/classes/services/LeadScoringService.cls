public with sharing class LeadScoringService {

    public static void calculateScore(List<Lead> leads) {
    

    List<Lead_Scoring_Setting__mdt> rules = [
        SELECT DeveloperName, Attribute_API_Name__c, Condition_Operator__c, Comparison_Value__c, Score_Change__c
        FROM Lead_Scoring_Setting__mdt
    ];


    if (rules.isEmpty()) return;

    for (Lead ld : leads) {
        Decimal newScore = 0;

        for (Lead_Scoring_Setting__mdt rule : rules) {

            Object leadValueObj = ld.get(rule.Attribute_API_Name__c);
            if (leadValueObj == null) {
                continue;
            }

            Decimal leadValue, comparisonValue;
            try {
                leadValue = Decimal.valueOf(String.valueOf(leadValueObj));
                comparisonValue = Decimal.valueOf(rule.Comparison_Value__c);
            } catch (Exception e) {
                continue;
            }

            Boolean conditionMet = false;
            String op = rule.Condition_Operator__c;

            if (op == 'More_Than' && leadValue > comparisonValue) {
                conditionMet = true;
            } else if (op == 'Less_Than' && leadValue < comparisonValue) {
                conditionMet = true;
            } else if (op == 'Equals' && leadValue == comparisonValue) {
                conditionMet = true;
            } else if (op == 'Not_Equals' && leadValue != comparisonValue) {
                conditionMet = true;
            }


            if (conditionMet) {
                newScore += rule.Score_Change__c;
            }
        }

        ld.Lead_Score__c = newScore; 
    }
}
}