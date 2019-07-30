public with sharing class DataGenerator {
    @AuraEnabled
    public static FrontResponseWrapper generateRandomData() {
        return new FrontResponseWrapper(true, 'sukces tworzenia!');
    }

    @AuraEnabled
    public static FrontResponseWrapper deleteAllData(){
        try {
            delete [SELECT Id FROM Account];
            delete [SELECT Id FROM Time_Report__c];
            delete [SELECT Id FROM Client__c];
            delete [SELECT Id FROM Job__c];
            delete [SELECT Id FROM Stream__c];
        } catch (Exception e) {
            return new FrontResponseWrapper(false, e.getMessage());
        }
        return new FrontResponseWrapper(true, 'sukces usuwania!');
    }
}