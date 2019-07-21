@isTest
private class JobManagerTest {

    @isTest
    static void changeJobToTemplateIfStreamIsTemplate() {
        Stream__c stream = TestHelper.createStream(new Stream__c(RecordTypeId = CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_STREAM, CommonUtility.STREAM_TYPE_STANDARD_TEMPLATE)), true);
        List<Job__c> jobList = TestHelper.createJobs(new Job__c(Stream__c = stream.Id), 10, false);
        Test.startTest();
        insert jobList;
        Test.stopTest();
        for(Job__c job : [SELECT Id, RecordTypeId FROM Job__c]) {
            System.assertEquals(CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_JOB, CommonUtility.JOB_TYPE_STANDARD_TEMPLATE), job.RecordTypeId);
        }
    }

    @isTest 
    static void updateLookupAfterRelatedJobDeletion() {
        Stream__c stream = TestHelper.createStream(new Stream__c(RecordTypeId = CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_STREAM, CommonUtility.STREAM_TYPE_STANDARD_TEMPLATE)), true);
        Job__c firstRelJob = TestHelper.createJob(new Job__c(Stream__c = stream.Id), true);
        Job__c secondRelJob = TestHelper.createJob(new Job__c(Stream__c = stream.Id), true);
        Job__c testJob = TestHelper.createJob(new Job__c(Stream__c = stream.Id, Next_Job__c = firstRelJob.Id, Second_Next_Job__c = secondRelJob.Id), true);
        Test.startTest();
        delete firstRelJob;
        Test.stopTest();

        Job__c testJobQueried = [SELECT Id, Next_Job__c, Second_Next_Job__c FROM Job__c WHERE Id =: testJob.Id];
        System.assertEquals(null, testJobQueried.Second_Next_Job__c);
        System.assertEquals(secondRelJob.Id, testJobQueried.Next_Job__c);
    }

    @isTest 
    static void cloneStreamWithJobs() {
        Stream__c stream = TestHelper.createStream(null , true);
        Job__c firstRelJob = TestHelper.createJob(new Job__c(Stream__c = stream.Id), true);
        Job__c secondRelJob = TestHelper.createJob(new Job__c(Stream__c = stream.Id), true);
        Job__c testJob = TestHelper.createJob(new Job__c(Stream__c = stream.Id, Next_Job__c = firstRelJob.Id, Second_Next_Job__c = secondRelJob.Id), true);
        stream.JSON_Description__c = 'JSON: ' + testJob.Id;
        update stream;
        Map<Id, Job__c> jobMap = new Map<Id, Job__c>();
        jobMap.put(firstRelJob.Id, firstRelJob);
        jobMap.put(secondRelJob.Id, secondRelJob);
        jobMap.put(testJob.Id, testJob);
        Test.startTest();
        FrontResponseWrapper repsonse = JobManager.cloneStreamWithJobs(stream.Id);
        Test.stopTest();
        System.assertEquals(true, repsonse.isSuccess);
        System.assertEquals(1, [SELECT Id FROM Stream__c WHERE Id <> :stream.Id].size());
        System.assertEquals(jobMap.keySet().size(), [SELECT Id FROM Job__c WHERE Id NOT IN :jobMap.keySet()].size());
    }

    @isTest
    static void userJobsCount() {
        User testUser = TestHelper.createUser(null, true);
        List<Job__c> jobList = TestHelper.createJobs(new Job__c(Assigned_To__c = testUser.Id, Status__c = CommonUtility.JOB_STATUS_TODO), 10, true);
        Test.startTest();
        System.runAs(testUser) {
            System.assertEquals(jobList.size(), JobManager.getUserJobsCount());
            System.assertEquals(5, JobManager.getUserJobs(1,5,5).size());
        }
        Test.stopTest();
    }
}