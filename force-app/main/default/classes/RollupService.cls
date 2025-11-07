public with sharing class RollupService {

  
    public static void recalculateOpportunityProductRollups(Set<Id> opportunityIdsToUpdate) {
        
        if (opportunityIdsToUpdate.isEmpty()) return;

        Map<Id, Double> arduinoCounts = new Map<Id, Double>();
        Map<Id, Double> otherCounts = new Map<Id, Double>();
        
        List<AggregateResult> results = [
            SELECT OpportunityId, 
                   COUNT(Id) totalCount, 
                   Product_Family_Match__c family
            FROM OpportunityLineItem
            WHERE OpportunityId IN :opportunityIdsToUpdate
            GROUP BY OpportunityId, Product_Family_Match__c
        ];

        for (AggregateResult ar : results) {
            Id oppId = (Id) ar.get('OpportunityId');
            Double count = (Double) ar.get('totalCount');
            String family = (String) ar.get('family');

            String normalizedFamily = (family != null) ? family.trim() : null;
            
            if (normalizedFamily != null) {
                if (normalizedFamily.equalsIgnoreCase('Arduino Board')) { 
                    Double currentCount = arduinoCounts.containsKey(oppId) ? arduinoCounts.get(oppId) : 0;
                    arduinoCounts.put(oppId, currentCount + count);
                }
                else { 
                    Double currentOther = otherCounts.containsKey(oppId) ? otherCounts.get(oppId) : 0;
                    otherCounts.put(oppId, currentOther + count);
                }
            }
        }

        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

        for (Id oppId : opportunityIdsToUpdate) {
            Opportunity opp = new Opportunity(Id = oppId);
            
            opp.put('Opp_Summ__c', arduinoCounts.get(oppId) != null ? arduinoCounts.get(oppId) : 0.0); 
            opp.put('not_Arduino_Board__c', otherCounts.get(oppId) != null ? otherCounts.get(oppId) : 0.0);

            opportunitiesToUpdate.add(opp);
        }

        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate; 
        }
    }
}