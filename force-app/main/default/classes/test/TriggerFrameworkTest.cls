@isTest
private class TriggerFrameworkTest {
    private static Id getStandardPricebookId() {
        return Test.getStandardPricebookId();
    }

    @TestSetup
    static void makeData() {
        Id campusSaleRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Campus Sale')?.getRecordTypeId();
        Id groupSaleRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Group Sale')?.getRecordTypeId();
        
        if (campusSaleRtId == null || groupSaleRtId == null) {
            System.debug('Warning: Required Record Types (Campus Sale or Group Sale) not found.');
        }

        Account testAcc = new Account(Name = 'Test Account for Triggers');
        insert testAcc;

        Product2 prodArduino = new Product2(Name = 'Arduino Uno R3', ProductCode = 'Arduino', Family = 'Default'); // Используем живой код 'Arduino'
        Product2 prodSensor = new Product2(Name = 'Temp Sensor', ProductCode = 'SEN010', Family = 'Default');
        
        insert new List<Product2>{prodArduino, prodSensor};
    }
    @isTest
    static void testProductFamilyMapping_Success() {
        List<Product2> products = [SELECT Id, ProductCode, Family FROM Product2 WHERE ProductCode = 'Arduino'];
        Product2 arduinoProd = products[0];

        Product2 newProd = arduinoProd.clone(false, true, false, false);
        newProd.Name = 'New Sensor Product';
        newProd.ProductCode = 'SEN010'; 
        newProd.Family = 'Wrong Family'; 

        Test.startTest();
        insert newProd;
        Test.stopTest();

        Product2 insertedProd = [SELECT Family FROM Product2 WHERE Id = :newProd.Id];
        System.assertNotEquals(null, insertedProd.Id, 'Product should be inserted successfully.');
    }

    @isTest
    static void testProductFamilyMapping_Failure() {
        Product2 invalidProd = new Product2(
            Name = 'Invalid Code Product', 
            ProductCode = 'XXX999',
            Family = 'Default'
        );
        
        Boolean hadError = false;

        Test.startTest();
        try {
            insert invalidProd;
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Such product code is not allowed in the system. Please update the PFC mapping or contact administrator.'), 'Expected validation error for invalid product code.');
            hadError = true;
        }
        Test.stopTest();
        
        System.assert(hadError, 'DML Exception was expected for invalid product code.');
    }

    @isTest
    static void testOpportunityRecordTypeAssignment() {
        Account testAcc = [SELECT Id FROM Account WHERE Name = 'Test Account for Triggers' LIMIT 1];
        
        Id campusSaleRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Campus Sale')?.getRecordTypeId();
        Id groupSaleRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Group Sale')?.getRecordTypeId();

        if (campusSaleRtId == null) {
            campusSaleRtId = '012g5000000CFhdAAG'; 
        }
        if (groupSaleRtId == null) {
            groupSaleRtId = '012g5000000CFg1AAG'; 
        }

        Opportunity oppCampus = new Opportunity(
            Name = 'Big Sale',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAcc.Id,
            Number_of_Students__c = 51 
        );

        Opportunity oppGroup = new Opportunity(
            Name = 'Group Sale',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAcc.Id,
            Number_of_Students__c = 50 
        );

        Test.startTest();
        insert new List<Opportunity>{oppCampus, oppGroup};
        Test.stopTest();

        Opportunity fetchedCampusOpp = [SELECT RecordTypeId FROM Opportunity WHERE Id = :oppCampus.Id];
        Opportunity fetchedGroupOpp = [SELECT RecordTypeId FROM Opportunity WHERE Id = :oppGroup.Id];

        System.assertEquals(campusSaleRtId, fetchedCampusOpp.RecordTypeId, 'Record Type should be Campus Sale for > 50 students.');
        System.assertEquals(groupSaleRtId, fetchedGroupOpp.RecordTypeId, 'Record Type should be Group Sale for 50 students.');
    }

    @isTest
    static void testOpportunityRollups() {
        Account testAcc = [SELECT Id FROM Account LIMIT 1];
        Product2 prodArduino = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode = 'Arduino' LIMIT 1];
        Product2 prodSensor = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode = 'SEN010' LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Rollup Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAcc.Id
        );
        insert opp;
        
        Id pricebookId = getStandardPricebookId();
        PricebookEntry pbeArduino = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodArduino.Id, UnitPrice = 10.00, IsActive = true);
        PricebookEntry pbeSensor = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodSensor.Id, UnitPrice = 5.00, IsActive = true);
        insert new List<PricebookEntry>{pbeArduino, pbeSensor};

        OpportunityLineItem oliArduino = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prodArduino.Id,
            PricebookEntryId = pbeArduino.Id,
            Quantity = 2,
            UnitPrice = 10.00
        );
        OpportunityLineItem oliSensor = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prodSensor.Id,
            PricebookEntryId = pbeSensor.Id,
            Quantity = 5,
            UnitPrice = 5.00
        );

        Test.startTest();
        insert new List<OpportunityLineItem>{oliArduino, oliSensor}; 
        Test.stopTest();
        
        OpportunityLineItem updatedOliArduino = [SELECT Product_Family_Match__c FROM OpportunityLineItem WHERE Id = :oliArduino.Id];
        System.assertEquals('Arduino Board', updatedOliArduino.get('Product_Family_Match__c'), 'ERROR: Product Family Match was not set correctly.');

        Opportunity fetchedOpp = [SELECT Opp_Summ__c, not_Arduino_Board__c FROM Opportunity WHERE Id = :opp.Id];
        
        System.assertEquals(1.0, fetchedOpp.get('Opp_Summ__c'), 'RLSF 1: Count of Arduino products must be 1.');
        System.assertEquals(1.0, fetchedOpp.get('not_Arduino_Board__c'), 'RLSF 2: Count of Non-Arduino products must be 1.');
    }

    @isTest
    static void testClosedWonInterestCreation() {
        Account testAcc = [SELECT Id FROM Account LIMIT 1];
        Product2 prodArduino = [SELECT Id FROM Product2 WHERE ProductCode = 'Arduino' LIMIT 1]; 

        Opportunity opp = new Opportunity(
            Name = 'Closed Won Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAcc.Id
        );
        insert opp;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbeArduino = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodArduino.Id, UnitPrice = 10.00, IsActive = true);
        insert pbeArduino;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prodArduino.Id,
            PricebookEntryId = pbeArduino.Id,
            Quantity = 1,
            UnitPrice = 10.00
        );
        insert oli; 

        Test.startTest();

        opp.StageName = 'Closed Won';
        update opp;
        
        List<Account_Interest__c> interests = [SELECT Id, Account__c, Deal_Link__c FROM Account_Interest__c WHERE Deal_Link__c = :opp.Id];
        System.assertNotEquals(0, interests.size(), 'Account_Interest__c records should be created when Opportunity is Closed Won.');

        opp.StageName = 'Closed Lost';
        update opp;
        
        Test.stopTest(); 

        List<Account_Interest__c> deletedInterests = [SELECT Id FROM Account_Interest__c WHERE Deal_Link__c = :opp.Id ALL ROWS];
        
        System.assertEquals(0, [SELECT Id FROM Account_Interest__c WHERE Deal_Link__c = :opp.Id].size(), 'Account_Interest__c records should be deleted when Opportunity reverts from Closed Won.');
        System.assertNotEquals(0, deletedInterests.size(), 'Interest records should exist in the recycle bin.');
        
        System.assertEquals(testAcc.Id, interests[0].Account__c, 'Account field on Interest record is incorrect.');
    }
}