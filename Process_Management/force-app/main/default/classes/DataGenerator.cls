public with sharing class DataGenerator {
    @AuraEnabled
    public static FrontResponseWrapper generateRandomData() {
        List<Account> departmentList = new List<Account>();
        List<Stream__c> streamList = new List<Stream__c>();
        List<Job__c> jobList = new List<Job__c>(); 
        Integer numberOfFirstRange = RandomUtility.generateRandomFromRange(1, 5);
        Integer numberOfFSecondRange = RandomUtility.generateRandomFromRange(2, 6);
        Integer numberOfThirdRange = RandomUtility.generateRandomFromRange(3, 5);
        Integer numberOfFourthRange = RandomUtility.generateRandomFromRange(2, 8);
        Map<Id, List<Job__c>> streamToJobTODOList = new Map<Id, List<Job__c>>();
        Map<Id, List<Job__c>> streamToJobINPROGRESSList = new Map<Id, List<Job__c>>();
        Map<Id, List<Job__c>> streamToJobDONEList = new Map<Id, List<Job__c>>();
        List<Time_Report__c> timeReportList = new List<Time_Report__c>();
        try {
            List<User> userList = [SELECT Id, Name FROM User WHERE Name LIKE '%Employee%'];
            //create companies
            List<Account> companyList = TestHelper.createEntity(new Account(Type = CommonUtility.ENTITY_TYPE_COMPANY), 2, true);
            //create departments
            for(Account comp : companyList) {
                departmentList.addAll(TestHelper.createEntity(new Account(ParentId = comp.Id, Type = CommonUtility.ENTITY_TYPE_DEPARTMENT), 5, false));
            }
            insert departmentList;
            //create clients and streams
            List<Client__c> clientList = TestHelper.createClients(null, 10, true);
            for(Client__c client : clientList) {
                streamList.addAll(TestHelper.createStreams(new Stream__c(Client__c = client.Id), 10, true));
            }
            //create job and collect in proper order to create hierarhy
            for(Integer i = 0; i < streamList.size() ; i++) {
                if (i < streamList.size()/3) {
                    for(Integer j = 0 ; j < numberOfFirstRange ; j++) {
                        jobList.add(prepareRandomJob(streamList.get(i), userList, streamToJobTODOList, streamToJobINPROGRESSList, streamToJobDONEList));
                    }
                } else if(i < streamList.size()/2) {
                    for(Integer j = 0 ; j < numberOfFSecondRange ; j++) {
                        jobList.add(prepareRandomJob(streamList.get(i), userList, streamToJobTODOList, streamToJobINPROGRESSList, streamToJobDONEList));
                    }
                } else if(i < streamList.size()/1.5) {
                    for(Integer j = 0 ; j < numberOfThirdRange ; j++) {
                        jobList.add(prepareRandomJob(streamList.get(i), userList, streamToJobTODOList, streamToJobINPROGRESSList, streamToJobDONEList));
                    }
                } else {
                    for(Integer j = 0 ; j < numberOfFourthRange ; j++) {
                        jobList.add(prepareRandomJob(streamList.get(i), userList, streamToJobTODOList, streamToJobINPROGRESSList, streamToJobDONEList));
                    }
                }
            }
            insert jobList;
            for(Job__c job : jobList) {
                if(job.Time_Spent__c > 0) {
                    DateTime dT = prepareRandomDateTime(job.Status__c);
                    Date dateReported = Date.newInstance(dT.year(), dT.month(), dT.day());
                    String externalId = String.valueOf(job.Id).substring(0, 15) +
                                        String.valueOf(job.Assigned_To__c).substring(0, 15) +
                                        String.valueOf(dateReported);
                    timeReportList.add(new Time_Report__c(Job__c = job.Id,
                                                        Time_Reported__c = job.Time_Spent__c,
                                                        Date__c = dateReported,
                                                        Reporter__c = job.Assigned_To__c));
                }
            }
            insert timeReportList;
            /* TODO 
            -make job hierarhy (based on status)
            -update stream (generateGraphJSONDescription)
            -create tasks
            -create events
            -create stream templates
            */

        } catch (Exception e) {
            return new FrontResponseWrapper(false, e.getMessage());
        }
        return new FrontResponseWrapper(true, 'sukces tworzenia!');
    }

    private static Job__c prepareRandomJob(Stream__c stream, List<User> userList, Map<Id, List<Job__c>> streamToJobTODOList, Map<Id, List<Job__c>> streamToJobINPROGRESSList, Map<Id, List<Job__c>> streamToJobDONEList) {
        Integer statusOption = RandomUtility.generateRandomFromRange(1, 4);
        String status = (statusOption == 1 ? CommonUtility.JOB_STATUS_TODO : (statusOption == 2 ? CommonUtility.JOB_STATUS_INPROGRESS : CommonUtility.JOB_STATUS_DONE));
        Integer timeSpent = status == CommonUtility.JOB_STATUS_TODO ? 0 : RandomUtility.generateRandomFromRange(0, 9);
        
        Job__c job = TestHelper.createJob(new Job__c(Stream__c = stream.Id,
                                                Assigned_To__c = userList.get(RandomUtility.generateRandomFromRange(1, userList.size())).Id,
                                                Time_Planned__c = RandomUtility.generateRandomFromRange(1, 16),
                                                Time_Spent__c = timeSpent,
                                                Status__c = status,
                                                Due_Date__c = prepareRandomDateTime(status)), false);
        if(job.Status__c == CommonUtility.JOB_STATUS_TODO) {
            if(streamToJobTODOList.containsKey(job.Stream__c)) {
                streamToJobTODOList.get(job.Stream__c).add(job);
            } else {
                streamToJobTODOList.put(job.Stream__c, new List<Job__c>{job});
            }
        } else if(job.Status__c == CommonUtility.JOB_STATUS_INPROGRESS) {
            if(streamToJobINPROGRESSList.containsKey(job.Stream__c)) {
                streamToJobINPROGRESSList.get(job.Stream__c).add(job);
            } else {
                streamToJobINPROGRESSList.put(job.Stream__c, new List<Job__c>{job});
            }
        } else {
            if(streamToJobDONEList.containsKey(job.Stream__c)) {
                streamToJobDONEList.get(job.Stream__c).add(job);
            } else {
                streamToJobDONEList.put(job.Stream__c, new List<Job__c>{job});
            }
        }
        return job;
    }

    private static DateTime prepareRandomDateTime(String status) {
        return status == CommonUtility.JOB_STATUS_DONE ? Datetime.now()
                                                            .addMonths(-1)
                                                            .addDays(-RandomUtility.generateRandomFromRange(0, 31))
                                                            .addHours(-RandomUtility.generateRandomFromRange(0, 24))
                                                            .addMinutes(-RandomUtility.generateRandomFromRange(1, 60)) :
                                                        Datetime.now()
                                                            .addMonths(-1)
                                                            .addDays(RandomUtility.generateRandomFromRange(0, 31))
                                                            .addHours(RandomUtility.generateRandomFromRange(0, 24))
                                                            .addMinutes(RandomUtility.generateRandomFromRange(1, 60));
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