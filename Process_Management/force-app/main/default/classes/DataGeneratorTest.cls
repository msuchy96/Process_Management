@isTest
private class DataGeneratorTest {
    
    @isTest
    static void generateDataTest() {
        Test.startTest();
        FrontResponseWrapper result = DataGenerator.generateRandomData();
        Test.stopTest();
        System.assert(result.isSuccess);
        System.assert([SELECT Id FROM Task].size() > 0);
        System.assert([SELECT Id FROM Event].size() > 0);
        System.assert([SELECT Id FROM Account].size() > 0);
        System.assert([SELECT Id FROM Time_Report__c].size() > 0);
        System.assert([SELECT Id FROM Client__c].size() > 0);
        System.assert([SELECT Id FROM Job__c].size() > 0);
        System.assert([SELECT Id FROM Stream__c].size() > 0);
    }

    @isTest
    static void deleteAllDataTest() {
        FrontResponseWrapper generationResult = DataGenerator.generateRandomData();
        Test.startTest();
        FrontResponseWrapper deletionResult = DataGenerator.deleteAllData();
        Test.stopTest();
        System.assert(deletionResult.isSuccess);
        System.assert([SELECT Id FROM Task].isEmpty());
        System.assert([SELECT Id FROM Event].isEmpty());
        System.assert([SELECT Id FROM Account].isEmpty());
        System.assert([SELECT Id FROM Time_Report__c].isEmpty());
        System.assert([SELECT Id FROM Client__c].isEmpty());
        System.assert([SELECT Id FROM Job__c].isEmpty());
        System.assert([SELECT Id FROM Stream__c].isEmpty());
    }
}