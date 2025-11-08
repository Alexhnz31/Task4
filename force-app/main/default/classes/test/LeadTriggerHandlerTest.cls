@isTest
private class LeadTriggerHandlerTest {

    private static Id getStandardPricebookId() {
        return Test.getStandardPricebookId();
    }

    @TestSetup
    static void setupTestData() {
        Account testAcc = new Account(Name = 'Test Account for Triggers');
        insert testAcc;
        
        Product2 prodArduino = new Product2(Name = 'Arduino Uno R3', ProductCode = 'Arduino', Family = 'Default');
        Product2 prodSensor = new Product2(Name = 'Temp Sensor', ProductCode = 'SEN010', Family = 'Default');
        insert new List<Product2>{prodArduino, prodSensor};
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            List<Lead_Scoring_Setting__mdt> rules = [
                SELECT Id 
                FROM Lead_Scoring_Setting__mdt
                WHERE DeveloperName IN ('STUDENT_RULE_1', 'STUDENT_RULE_2')
            ];
            System.assert(rules.size() == 2, 'FAILURE: CMDT rules STUDENT_RULE_1 and STUDENT_RULE_2 must be created manually in Setup.');
        }
    }

    @isTest
    static void testLeadScoring_ScoreCalculationOnInsert() {
        
        Account testAcc = [SELECT Id FROM Account LIMIT 1]; 

        Lead testLead = new Lead(
            LastName = 'HighScore',
            Company = 'TestCo',
            Number_of_Students__c = 30 
        );

        Test.startTest(); 
        insert testLead; 
        Test.stopTest(); 

        Lead resultLead = [SELECT Lead_Score__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(10.0, resultLead.Lead_Score__c, 'Score should be 10 based on the CMDT rule.');
    }
    
    @isTest
    static void testLeadScoring_ScoreCalculationOnUpdate() {
        
        Account testAcc = [SELECT Id FROM Account LIMIT 1];
        
        Lead testLead = new Lead(
            LastName = 'LowScore',
            Company = 'TestCo',
            Number_of_Students__c = 30
        );
        insert testLead; 


        Test.startTest();
        update testLead;
        Test.stopTest();

        Lead resultLead = [SELECT Id, Lead_Score__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(15.0, resultLead.Lead_Score__c, 'Score should be 15 after update (10 + 5).');
    }
    
    @isTest
    static void testLeadScoring_NegativeScenario() {
        
        Account testAcc = [SELECT Id FROM Account LIMIT 1];

        Lead testLead = new Lead(
            LastName = 'ZeroScore',
            Company = 'TestCo',
            Number_of_Students__c = 1
        );

        Test.startTest();
        insert testLead;
        Test.stopTest();

        Lead resultLead = [SELECT Lead_Score__c FROM Lead WHERE Id = :testLead.Id];
        
        System.assertEquals(0.0, resultLead.Lead_Score__c, 'Score should be 0 if no rule is met.');
    }
}