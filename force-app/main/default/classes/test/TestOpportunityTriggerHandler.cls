@IsTest
private class TestOpportunityTriggerHandler {

    private static Id pricebookId = Test.getStandardPricebookId();

    @TestSetup
    static void setupTestData() {
        // Создаем Аккаунт (будет использоваться во всех тестах)
        Account setupAcc = new Account(Name = 'Test Setup Account');
        insert setupAcc;

        // Создаем Продукты
        Product2 prod1 = new Product2(Name = 'Product A', IsActive = true);
        Product2 prod2 = new Product2(Name = 'Product B', IsActive = true);
        Product2 prod3 = new Product2(Name = 'Product C', IsActive = true);
        insert new List<Product2>{prod1, prod2, prod3};

        // PricebookEntry
        List<PricebookEntry> testPBEs = new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod1.Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod2.Id, UnitPrice = 200.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod3.Id, UnitPrice = 10.00, IsActive = true)
        };
        insert testPBEs;
    }


    @IsTest
    static void testAfterUpdate_CreationAndDeletionLogic() {
        // --- 1. НАСТРОЙКА ВСЕХ ДАННЫХ ВНУТРИ ТЕСТА ---
        
        // Получаем Аккаунт из TestSetup
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Setup Account' LIMIT 1];
        
        // Получаем PBE из TestSetup через Map для надежности
        Map<Decimal, Id> priceToPBEId = new Map<Decimal, Id>();
        for (PricebookEntry pbe : [SELECT Id, UnitPrice FROM PricebookEntry WHERE Pricebook2Id = :pricebookId]) {
            priceToPBEId.put(pbe.UnitPrice, pbe.Id);
        }

        // --- Создание Opportunity ---
        Opportunity oppToClose = new Opportunity(
            Name = 'Opp to Close',
            AccountId = acc.Id, 
            StageName = 'Prospecting', 
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = pricebookId
        );
        insert oppToClose; 

        // --- Создание OpportunityLineItem с гарантированными PBE ID ---
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        olis.add(new OpportunityLineItem(
            OpportunityId = oppToClose.Id, 
            Quantity = 5, 
            PricebookEntryId = priceToPBEId.get(100.00), 
            UnitPrice = 100.00
        ));
        olis.add(new OpportunityLineItem(
            OpportunityId = oppToClose.Id, 
            Quantity = 12, 
            PricebookEntryId = priceToPBEId.get(200.00), 
            UnitPrice = 200.00
        ));
        
        insert olis; 

        // --- 2. СЦЕНАРИЙ: ПЕРЕХОД В CLOSED WON (СОЗДАНИЕ) ---

        Test.startTest();
        
        // 1. Триггер срабатывает: Prospecting -> Closed Won 
        oppToClose.StageName = 'Closed Won';
        update oppToClose; 
        
        // --- ПРОВЕРКИ ПОСЛЕ СОЗДАНИЯ ---
        List<Account_Interest__c> interestsAfterCreation = [SELECT Quantity__c FROM Account_Interest__c WHERE Deal_Link__c = :oppToClose.Id];
        System.assertEquals(2, interestsAfterCreation.size(), 'Assert 1: Должно быть создано две записи Account_Interest__c после Closed Won.');
        
        // --- СЦЕНАРИЙ 2: РЕГРЕСС ИЗ CLOSED WON (УДАЛЕНИЕ) ---
        
        // 2. Триггер срабатывает: Closed Won -> Negotiation 
        oppToClose.StageName = 'Negotiation';
        update oppToClose; 

        Test.stopTest();
        
        // --- ПРОВЕРКИ ПОСЛЕ УДАЛЕНИЯ ---
        List<Account_Interest__c> interestsAfterDeletion = [SELECT Id FROM Account_Interest__c WHERE Deal_Link__c = :oppToClose.Id];
        System.assertEquals(0, interestsAfterDeletion.size(), 'Assert 2: Записи Account_Interest__c должны быть удалены после отката StageName.');
    }
    
    @IsTest
    static void testAfterUpdate_NoChangeInStageName() {
        // --- 1. НАСТРОЙКА ДАННЫХ ВНУТРИ ТЕСТА ---
        
        // Получаем PBE с ценой 10.00 (Устранена QueryException)
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE UnitPrice = 10.00 LIMIT 1];
        
        // Создаем Аккаунт здесь
        Account acc = new Account(Name = 'Test Opp No Change Account');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp No Change',
            AccountId = acc.Id,
            StageName = 'Closed Won', // Уже Closed Won
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = pricebookId
        );
        insert opp;
        
        // --- 2. ВЫПОЛНЕНИЕ ТРИГГЕРА ---
        Test.startTest();
        
        // Обновляем Opportunity, но не меняем StageName
        opp.StageName = 'Closed Won'; 
        opp.Description = 'Updated description';
        update opp;
        
        Test.stopTest();
        
        // --- 3. ПРОВЕРКА ---
        // Проверяем, что записи НЕ были созданы 
        Integer interestCount = [SELECT count() FROM Account_Interest__c];
        System.assertEquals(0, interestCount, 'Записи не должны быть созданы, если StageName не изменился.');
    }
}