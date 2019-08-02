public with sharing class DataGenerator {
    @AuraEnabled
    public static FrontResponseWrapper generateRandomData() {
        List<Account> departmentList = new List<Account>();
        List<Stream__c> streamList = new List<Stream__c>();
        List<Job__c> jobList = new List<Job__c>();
        List<Job__c> jobListToUpdate = new List<Job__c>();       
        Map<Id, List<Job__c>> streamToJobTODOList = new Map<Id, List<Job__c>>();
        Map<Id, List<Job__c>> streamToJobINPROGRESSList = new Map<Id, List<Job__c>>();
        Map<Id, List<Job__c>> streamToJobDONEList = new Map<Id, List<Job__c>>();
        List<Time_Report__c> timeReportList = new List<Time_Report__c>();
        Map<Id, List<Job__c>> streamToJobListHierarchy = new Map<Id, List<Job__c>>();
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
                Integer numberOfJobs = RandomUtility.generateRandomFromRange(2, 8);
                for(Integer j = 0 ; j < numberOfJobs ; j++) {
                    jobList.add(prepareRandomJob(streamList.get(i), userList, streamToJobTODOList, streamToJobINPROGRESSList, streamToJobDONEList));
                }
            }
            insert jobList;
            for(Job__c job : jobList) {
                if(job.Time_Spent__c > 0) {
                    timeReportList.add(prepareRandomTimeReport(job));
                }
            }
            insert timeReportList;

            for(Id streamId : streamToJobTODOList.keySet()) {
                streamToJobListHierarchy.put(streamId, streamToJobTODOList.get(streamId));
            }
            for(Id streamId : streamToJobINPROGRESSList.keySet()) {
                if(streamToJobListHierarchy.containsKey(streamId)) {
                    streamToJobListHierarchy.get(streamId).addAll(streamToJobINPROGRESSList.get(streamId));
                } else {
                    streamToJobListHierarchy.put(streamId, streamToJobINPROGRESSList.get(streamId));
                } 
            }
            for(Id streamId : streamToJobDONEList.keySet()) {
                if(streamToJobListHierarchy.containsKey(streamId)) {
                    streamToJobListHierarchy.get(streamId).addAll(streamToJobDONEList.get(streamId));
                } else {
                    streamToJobListHierarchy.put(streamId, streamToJobDONEList.get(streamId));
                } 
            }

            for(Id streamId : streamToJobListHierarchy.keySet()) {
                if(streamToJobListHierarchy.get(streamId).size() > 2) {
                    for(Integer i = 0; i < streamToJobListHierarchy.get(streamId).size()-2 ; i++) {
                        streamToJobListHierarchy.get(streamId).get(i).Next_Job__c = streamToJobListHierarchy.get(streamId).get(i+1).Id;
                        streamToJobListHierarchy.get(streamId).get(i).Second_Next_Job__c = streamToJobListHierarchy.get(streamId).get(i+2).Id;
                    }
                } else {
                    streamToJobListHierarchy.get(streamId).get(0).Next_Job__c = streamToJobListHierarchy.get(streamId).get(1).Id;
                }
                jobListToUpdate.addAll(streamToJobListHierarchy.get(streamId));
            }
            update jobListToUpdate;

            /* TODO 
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
                                                Assigned_To__c = userList.get(RandomUtility.generateRandomFromRange(0, userList.size())).Id,
                                                Time_Planned__c = RandomUtility.generateRandomFromRange(1, 16),
                                                Time_Spent__c = timeSpent,
                                                Status__c = status,
                                                Due_Date__c = prepareRandomDateTime(2, status)), false);
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

    private static DateTime prepareRandomDateTime( Integer monthDelay, String status) {
        Integer delayPropability = RandomUtility.generateRandomFromRange(0, 5);
        return delayPropability < 2 ? Datetime.now()
                                        .addMonths(-RandomUtility.generateRandomFromRange(0, status == CommonUtility.JOB_STATUS_DONE ? monthDelay + 5 : monthDelay))
                                        .addDays(-RandomUtility.generateRandomFromRange(0, 31))
                                        .addHours(-RandomUtility.generateRandomFromRange(0, 24))
                                        .addMinutes(-RandomUtility.generateRandomFromRange(1, 60)) :
                                    Datetime.now()
                                        .addMonths(RandomUtility.generateRandomFromRange(0, 6))
                                        .addDays(RandomUtility.generateRandomFromRange(0, 31))
                                        .addHours(RandomUtility.generateRandomFromRange(0, 24))
                                        .addMinutes(RandomUtility.generateRandomFromRange(1, 60));
    }

    private static Time_Report__c prepareRandomTimeReport(Job__c job) {
        Integer delayPropability = RandomUtility.generateRandomFromRange(0, 5);
        DateTime dateReported;
        if(delayPropability < 2) {
            dateReported = job.Due_Date__c
                                .addDays(RandomUtility.generateRandomFromRange(0, 12))
                                .addHours(RandomUtility.generateRandomFromRange(0, 24))
                                .addMinutes(RandomUtility.generateRandomFromRange(1, 60));
        } else {
            dateReported = job.Due_Date__c
                                .addDays(-RandomUtility.generateRandomFromRange(0, 12))
                                .addHours(-RandomUtility.generateRandomFromRange(0, 24))
                                .addMinutes-(RandomUtility.generateRandomFromRange(1, 60));
        }
        String externalId = String.valueOf(job.Id).substring(0, 15) +
                            String.valueOf(job.Assigned_To__c).substring(0, 15) +
                            String.valueOf(dateReported);
        return new Time_Report__c(Job__c = job.Id,
                                    Time_Reported__c = job.Time_Spent__c,
                                    Date__c = Date.newinstance(dateReported.year(), dateReported.month(), dateReported.day()),
                                    Reporter__c = job.Assigned_To__c);
           
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