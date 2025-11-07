public with sharing class RollupService {

    /**
     * Вычисляет и обновляет RLSF #1 и #2 на Opportunity.
     * @param opportunityIdsToUpdate ID Opportunity, для которых нужно пересчитать свертки.
     */
    public static void recalculateOpportunityProductRollups(Set<Id> opportunityIdsToUpdate) {
        
        if (opportunityIdsToUpdate.isEmpty()) return;

        // 1. Свертка (Aggregation)
        // Группируем OLI по OpportunityId и фильтруем по Product Family Match
        Map<Id, Double> arduinoCounts = new Map<Id, Double>();
        Map<Id, Double> otherCounts = new Map<Id, Double>();

        // Запрос для RLSF #1 (Count Of Arduino Products) и RLSF #2 (Not Arduino Board)
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

            // RLSF #1: Count Of Arduino Products (Product Family Match equals Arduino Board)
            if (family == 'Arduino Board') { 
                arduinoCounts.put(oppId, count);
            }
            // RLSF #2: Not Arduino Board (Product Family Match not equal to Arduino Board)
            else { 
                // Суммируем все остальные, которые не 'Arduino Board'
                Double currentOther = otherCounts.containsKey(oppId) ? otherCounts.get(oppId) : 0;
                otherCounts.put(oppId, currentOther + count);
            }
        }

        // 2. Обновление (DML Update)
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

        for (Id oppId : opportunityIdsToUpdate) {
            Opportunity opp = new Opportunity(Id = oppId);
            
            // Opp_Summ__c (Count Of Arduino Products)
            opp.put('Opp_Summ__c', arduinoCounts.get(oppId)); 
            
            // not_Arduino_Board__c (Not Arduino Board)
            opp.put('not_Arduino_Board__c', otherCounts.get(oppId));

            opportunitiesToUpdate.add(opp);
        }

        if (!opportunitiesToUpdate.isEmpty()) {
            // Внимание: DML (update) здесь может вызвать UNABLE_TO_LOCK_ROW
            update opportunitiesToUpdate; 
        }
    }
}