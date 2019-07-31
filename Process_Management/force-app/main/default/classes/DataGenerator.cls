public with sharing class DataGenerator {
    @AuraEnabled
    public static FrontResponseWrapper generateRandomData() {
        try {
            List<User> userList = [SELECT Id, Name FROM User WHERE Name LIKE '%Employee%'];
            //create companies
            List<Account> companyList = TestHelper.createEntity(new Account(Type = CommonUtility.ENTITY_TYPE_COMPANY), 2, true);
            //create departments
            List<Account> departmentList = new List<Account>();
            for(Account comp : companyList) {
                departmentList.addAll(TestHelper.createEntity(new Account(ParentId = comp.Id, Type = CommonUtility.ENTITY_TYPE_DEPARTMENT), 5, false));
            }
            insert departmentList;

            List<Client__c> clientList = TestHelper.createClients(null, 10, true);

            for(Client__c client : clientList) {
                TestHelper.createStreams(new Stream__c(Client__c = client.Id), 10, true);
            }

        } catch (Exception e) {
            return new FrontResponseWrapper(false, e.getMessage());
        }
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
        return new FrontResponseWrapper(true, Label.TST_MSG_DataDeleted);
    }
}