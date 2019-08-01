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
            //create clients and streams
            List<Client__c> clientList = TestHelper.createClients(null, 10, true);
            List<Stream__c> streamList = new List<Stream__c>();
            for(Client__c client : clientList) {
                streamList.addAll(TestHelper.createStreams(new Stream__c(Client__c = client.Id), 10, true));
            }
            List<Job__c> jobList = new List<Job__c>(); 
            Integer numberOfFirstRange = RandomUtility.generateRandomFromRange(1, 5);
            Integer numberOfFSecondRange = RandomUtility.generateRandomFromRange(2, 6);
            Integer numberOfThirdRange = RandomUtility.generateRandomFromRange(3, 5);
            Integer numberOfFourthRange = RandomUtility.generateRandomFromRange(2, 8);
            for(Integer i = 0; i < streamList.size() ; i++) {
                if (i < streamList.size()/3) {
                    for(Integer j = 0 ; j < numberOfFirstRange ; j++) {
                        jobList.add(prepareRandomJob(streamList.get(i), userList));
                    }
                } else if(i < streamList.size()/2) {
                    for(Integer j = 0 ; j < numberOfFSecondRange ; j++) {
                        jobList.add(prepareRandomJob(streamList.get(i), userList));
                    }
                } else if(i < streamList.size()/1.5) {
                    for(Integer j = 0 ; j < numberOfThirdRange ; j++) {
                        jobList.add(prepareRandomJob(streamList.get(i), userList));
                    }
                } else {
                    for(Integer j = 0 ; j < numberOfFourthRange ; j++) {
                        jobList.add(prepareRandomJob(streamList.get(i), userList));
                    }
                }
            }
            insert jobList;
            Map<Id, Job__c> jobMap = new Map<Id, Job__c>(jobList);
            /* TODO 
            -change name pattern for TR
            -insert time reports date (renadomly before, after and in due date)
            -prepare job hierarhy (based on status)
            -update stream (generateGraphJSONDescription)
            -create tasks
            -create events
            */

        } catch (Exception e) {
            return new FrontResponseWrapper(false, e.getMessage());
        }
        return new FrontResponseWrapper(true, 'sukces tworzenia!');
    }

    private static Job__c prepareRandomJob(Stream__c stream, List<User> userList) {
        Integer statusOption = RandomUtility.generateRandomFromRange(1, 4);
        String status = (statusOption == 1 ? CommonUtility.JOB_STATUS_TODO : (statusOption == 2 ? CommonUtility.JOB_STATUS_INPROGRESS : CommonUtility.JOB_STATUS_DONE));
        Integer timeSpent = status == CommonUtility.JOB_STATUS_TODO ? 0 : RandomUtility.generateRandomFromRange(0, 9);
        DateTime dueDate = status == CommonUtility.JOB_STATUS_DONE ? Datetime.now()
                                                                .addDays(-RandomUtility.generateRandomFromRange(0, 31))
                                                                .addHours(-RandomUtility.generateRandomFromRange(0, 24))
                                                                .addMinutes(-RandomUtility.generateRandomFromRange(1, 59)) :
                                                                Datetime.now()
                                                                .addMonths(-1)
                                                                .addDays(RandomUtility.generateRandomFromRange(0, 31))
                                                                .addHours(RandomUtility.generateRandomFromRange(0, 24))
                                                                .addMinutes(RandomUtility.generateRandomFromRange(1, 59));
        return TestHelper.createJob(new Job__c(Stream__c = stream.Id,
                                                Assigned_To__c = userList.get(RandomUtility.generateRandomFromRange(1, userList.size())).Id,
                                                Time_Planned__c = RandomUtility.generateRandomFromRange(1, 16),
                                                Time_Spent__c = timeSpent,
                                                Status__c = status,
                                                Due_Date__c = dueDate), false);
    }

    @AuraEnabled
    public static FrontResponseWrapper deleteAllData() {
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