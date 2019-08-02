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
            Account company = TestHelper.createEntity(new Account(Type = CommonUtility.ENTITY_TYPE_COMPANY), true);
            //create departments
            departmentList.addAll(TestHelper.createEntity(new Account(ParentId = company.Id, Type = CommonUtility.ENTITY_TYPE_DEPARTMENT), 2, false));
            insert departmentList;
            //create clients and streams
            List<Client__c> clientList = TestHelper.createClients(null, 5, true);
            for(Client__c client : clientList) {
                streamList.addAll(TestHelper.createStreams(new Stream__c(Client__c = client.Id), RandomUtility.generateRandomFromRange(2, 6), true));
            }
            streamList.addAll(TestHelper.createStreams(new Stream__c(RecordTypeId = CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_STREAM, CommonUtility.STREAM_TYPE_STANDARD_TEMPLATE)), 3, true));
            //create job and collect in proper order to create hierarhy
            for(Integer i = 0; i < streamList.size() ; i++) {
                Integer numberOfJobs = RandomUtility.generateRandomFromRange(2, 6);
                for(Integer j = 0 ; j < numberOfJobs ; j++) {
                    jobList.add(prepareRandomJob(streamList.get(i), userList, streamToJobTODOList, streamToJobINPROGRESSList, streamToJobDONEList));
                }
            }
            insert jobList;
            //create time reports
            for(Job__c job : jobList) {
                if(job.Time_Spent__c > 0) {
                    timeReportList.add(prepareRandomTimeReport(job));
                }
            }
            insert timeReportList;
            //create job hierarchy in stream
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
            Map<Id, Stream__c> streamMap = new Map<Id, Stream__c>(streamList);
            //create stream graph
            TestHelper.generateGraphJSONDescription(streamMap.keySet());
            /* TODO 
            -users to department
            -create tasks
            -create events
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
        Job__c job; 
        if(stream.RecordTypeId == CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_STREAM, CommonUtility.STREAM_TYPE_STANDARD_TEMPLATE)) {
            job = TestHelper.createJob(new Job__c(Stream__c = stream.Id,
                                                Assigned_To__c = null,
                                                Time_Planned__c = RandomUtility.generateRandomFromRange(1, 16),
                                                Time_Spent__c = 0,
                                                Status__c = status,
                                                Due_Date__c = null), false, true);
        } else {
            job = TestHelper.createJob(new Job__c(Stream__c = stream.Id,
                                                Assigned_To__c = userList.get(RandomUtility.generateRandomFromRange(0, userList.size())).Id,
                                                Time_Planned__c = RandomUtility.generateRandomFromRange(1, 16),
                                                Time_Spent__c = timeSpent,
                                                Status__c = status,
                                                Due_Date__c = prepareRandomDateTime(status)), false, false);
        }
        
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
        Integer delayPropability = RandomUtility.generateRandomFromRange(0, 5);
        return delayPropability < 2 ? Datetime.now()
                                        .addMonths(status == CommonUtility.JOB_STATUS_DONE ? RandomUtility.generateRandomFromRange(0,7) : 0)
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
        if(job.Due_Date__c > System.now()) {
            dateReported = addTimeToBase(System.now(), 4, 24, 60, -1);
        } else if(delayPropability < 2) {
            dateReported = addTimeToBase(job.Due_Date__c, 4, 24, 60, 1);
                                
        } else {
            dateReported = addTimeToBase(job.Due_Date__c, 4, 24, 60, -1);
                                
        }
        String externalId = String.valueOf(job.Id).substring(0, 15) +
                            String.valueOf(job.Assigned_To__c).substring(0, 15) +
                            String.valueOf(dateReported);
        return new Time_Report__c(Job__c = job.Id,
                                    Time_Reported__c = job.Time_Spent__c,
                                    Date__c = Date.newinstance(dateReported.year(), dateReported.month(), dateReported.day()),
                                    Reporter__c = job.Assigned_To__c);
           
    }

    private static DateTime addTimeToBase(DateTime base, Integer days, Integer hours, Integer minutes, Integer past) {
        return base
                .addDays(past * RandomUtility.generateRandomFromRange(0, days))
                .addHours(past * RandomUtility.generateRandomFromRange(0, hours))
                .addMinutes(past * RandomUtility.generateRandomFromRange(0, minutes));
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