public with sharing class LeadScoringService {

    public static void calculateScore(List<Lead> leads) {
        
        List<Lead_Scoring_Setting__mdt> rules = [
            SELECT Attribute_API_Name__c, Condition_Operator__c, Comparison_Value__c, Score_Change__c 
            FROM Lead_Scoring_Setting__mdt
        ];

        if (rules.isEmpty()) return;

        for (Lead ld : leads) {
            Decimal newScore = 0;
            
            for (Lead_Scoring_Setting__mdt rule : rules) {
                
                LeadScoringAttributes.Attribute attribute = LeadScoringAttributes.getAttributeByApiName(rule.Attribute_API_Name__c);
                if (attribute == null) continue; 
                
                Object leadValueObj = ld.get(rule.Attribute_API_Name__c);
                if (leadValueObj == null || rule.Comparison_Value__c == null) continue;

                Decimal leadValue;
                Decimal comparisonValue;

                try {
                    leadValue = Decimal.valueOf(String.valueOf(leadValueObj));
                    comparisonValue = Decimal.valueOf(rule.Comparison_Value__c);
                } catch (Exception e) {
                    System.debug('Lead Scoring Error: Cannot convert values to Decimal for comparison. Rule: ' + rule.DeveloperName);
                    continue; 
                }
                
                Decimal scoreChange = rule.Score_Change__c;
                Boolean conditionMet = false;
                String operator = rule.Condition_Operator__c;

                if (operator == 'More_Than' && leadValue > comparisonValue) {
                    conditionMet = true;
                } else if (operator == 'Less_Than' && leadValue < comparisonValue) {
                    conditionMet = true;
                } else if (operator == 'Equals' && leadValue == comparisonValue) {
                    conditionMet = true;
                } else if (operator == 'Not_Equals' && leadValue != comparisonValue) {
                    conditionMet = true;
                }

                if (conditionMet) {
                    newScore += scoreChange;
                }
            }
            
            Decimal currentScore = (Decimal) ld.get('Lead_Score__c');
            if (currentScore == null || currentScore != newScore) {
                ld.put('Lead_Score__c', newScore);
            }
        }
    }
}