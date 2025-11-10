@isTest
private class LeadTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        insert new Account(Name = 'Test Account for Triggers');

        List<Lead_Scoring_Setting__mdt> rules = [
            SELECT DeveloperName, Attribute_API_Name__c, Condition_Operator__c, 
                   Comparison_Value__c, Score_Change__c
            FROM Lead_Scoring_Setting__mdt
            WHERE DeveloperName IN ('STUDENT_RULE_1', 'STUDENT_RULE_2')
        ];

        System.assertEquals(2, rules.size(), 
            'ОШИБКА: Должны быть 2 записи CMDT: STUDENT_RULE_1 и STUDENT_RULE_2\n' +
            'Проверь: Setup → Custom Metadata → Lead Scoring Setting → Manage Records'
        );

        // Дополнительная проверка значений
        for (Lead_Scoring_Setting__mdt r : rules) {
            if (r.DeveloperName == 'STUDENT_RULE_1') {
                System.assertEquals('Number_of_Students__c', r.Attribute_API_Name__c);
                System.assertEquals('More_Than', r.Condition_Operator__c);
                System.assertEquals('25', r.Comparison_Value__c);
                System.assertEquals(10, r.Score_Change__c);
            } else if (r.DeveloperName == 'STUDENT_RULE_2') {
                System.assertEquals('Number_of_Students__c', r.Attribute_API_Name__c);
                System.assertEquals('More_Than', r.Condition_Operator__c);
                System.assertEquals('40', r.Comparison_Value__c);
                System.assertEquals(5, r.Score_Change__c);
            }
        }
    }

    @isTest
    static void testLeadScoring_ScoreCalculationOnInsert() {
        Lead testLead = new Lead(
            LastName = 'HighScore',
            Company = 'TestCo',
            Number_of_Students__c = 30  
        );

        Test.startTest();
        insert testLead;
        Test.stopTest();

        Lead result = [SELECT Lead_Score__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(10.0, result.Lead_Score__c, '30 > 25 → должно быть 10 очков');
    }

    @isTest
    static void testLeadScoring_ScoreCalculationOnUpdate() {
        Lead testLead = new Lead(
            LastName = 'LowScore',
            Company = 'TestCo',
            Number_of_Students__c = 30  
        );
        insert testLead;

        testLead.Number_of_Students__c = 50;  

        Test.startTest();
        update testLead;
        Test.stopTest();

        Lead result = [SELECT Lead_Score__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(15.0, result.Lead_Score__c, '50 > 25 и 50 > 40 → 10 + 5 = 15');
    }

    @isTest
    static void testLeadScoring_NegativeScenario() {
        Lead testLead = new Lead(
            LastName = 'ZeroScore',
            Company = 'TestCo',
            Number_of_Students__c = 1  
        );

        Test.startTest();
        insert testLead;
        Test.stopTest();

        Lead result = [SELECT Lead_Score__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(0.0, result.Lead_Score__c, '1 < 25 → должно быть 0');
    }
}