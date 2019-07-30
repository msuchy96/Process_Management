@isTest
private class ProcessCreatorControllerTest {

    @TestSetup
    static void dataSetup() {
        TestHelper.createJobs(null, 10, true);
        TestHelper.createClients(null, 10, true);
        TestHelper.createClient(null, true);
        TestHelper.createEntity(null, true);
    }

    @isTest
    static void deleteSelectedJobSuccess() {
        Job__c jobToDelete = [SELECT Id FROM Job__c LIMIT 1];
        Test.startTest();
        FrontResponseWrapper result = ProcessCreatorController.deleteSelectedJob(jobToDelete.Id);
        Test.stopTest();
        System.assert(result.isSuccess);
    }

    @isTest
    static void deleteSelectedJobError() {
        Job__c jobToDelete = [SELECT Id FROM Job__c LIMIT 1];
        Id deletedJobId = jobToDelete.Id;
        delete jobToDelete;
        Test.startTest();
        FrontResponseWrapper result = ProcessCreatorController.deleteSelectedJob(deletedJobId);
        Test.stopTest();
        System.assert(!result.isSuccess);
    } 

    @isTest
    static void createConnectionBetweenJobsSuccess() {
        List<Job__c> jobsToConnect = [SELECT Id FROM Job__c LIMIT 3];
        Test.startTest();
        FrontResponseWrapper result = ProcessCreatorController.createConnectionBetweenJobs(jobsToConnect[0].Id, jobsToConnect[1].Id);
        FrontResponseWrapper result2 = ProcessCreatorController.createConnectionBetweenJobs(jobsToConnect[0].Id, jobsToConnect[2].Id);
        Test.stopTest();
        Job__c connectedJob = [SELECT Id, Next_Job__c, Second_Next_Job__c FROM Job__c WHERE Id =: jobsToConnect[0].Id];
        System.assert(result.isSuccess);
        System.assert(result2.isSuccess);
        System.assertEquals(jobsToConnect[1].Id, connectedJob.Next_Job__c);
        System.assertEquals(jobsToConnect[2].Id, connectedJob.Second_Next_Job__c);
    }

    @isTest
    static void createConnectionBetweenJobsError() {
        List<Job__c> jobsToConnect = [SELECT Id FROM Job__c LIMIT 2];
        Id deletedJobId = jobsToConnect[0].Id;
        delete jobsToConnect[0];
        Test.startTest();
        FrontResponseWrapper result = ProcessCreatorController.createConnectionBetweenJobs(deletedJobId, jobsToConnect[1].Id);
        Test.stopTest();
        System.assert(!result.isSuccess);
    }

    @isTest
    static void saveStreamAsTemplateSuccess() {
        Stream__c stream = [SELECT Id, Client__c, Name FROM Stream__C LIMIT 1];
        Client__c client = [SELECT Id FROM Client__c LIMIT 1];
        stream.Client__c = client.Id;
        update stream;
        Test.startTest();
        FrontResponseWrapper result = ProcessCreatorController.saveStreamAsTemplate(stream.Name, client.Id);
        Test.stopTest();
        System.assertEquals(1, [SELECT Id FROM Stream__c WHERE RecordTypeId =: CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_STREAM, CommonUtility.STREAM_TYPE_STANDARD_TEMPLATE)].size());
        System.assert(result.isSuccess);
    }

    @isTest
    static void saveStreamAsTemplateError() {
        Stream__c stream = [SELECT Id, Client__c, Name FROM Stream__C LIMIT 1];
        Client__c client = [SELECT Id FROM Client__c LIMIT 1];
        stream.Client__c = client.Id;
        update stream;
        delete client;
        Test.startTest();
        FrontResponseWrapper result = ProcessCreatorController.saveStreamAsTemplate(stream.Name, client.Id);
        Test.stopTest();
        System.assertEquals(0, [SELECT Id FROM Stream__c WHERE RecordTypeId =: CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_STREAM, CommonUtility.STREAM_TYPE_STANDARD_TEMPLATE)].size());
        System.assert(!result.isSuccess);
    } 

    @isTest
    static void updateStreamJSONDescriptionSuccess() {
        Stream__c stream = [SELECT Id, Client__c, JSON_Description__c FROM Stream__C LIMIT 1];
        String testJson = JSON.serialize(stream);
        Test.startTest();
        FrontResponseWrapper result = ProcessCreatorController.updateStreamJSONDescription(testJson, stream.Id);
        Test.stopTest();
        System.assertEquals(testJson, [SELECT Id, JSON_Description__c FROM Stream__c WHERE Id =: stream.Id].JSON_Description__c);
        System.assert(result.isSuccess);
    }

    @isTest
    static void updateStreamJSONDescriptionError() {
        Stream__c stream = [SELECT Id, Client__c, JSON_Description__c FROM Stream__C LIMIT 1];
        String testJson = JSON.serialize(stream);
        delete stream;
        Test.startTest();
        FrontResponseWrapper result = ProcessCreatorController.updateStreamJSONDescription(testJson, stream.Id);
        Test.stopTest();
        System.assert(!result.isSuccess);
    }

    @isTest
    static void retrieveJSONStreamDescription() {
        Stream__c stream = [SELECT Id, Client__c, JSON_Description__c FROM Stream__C LIMIT 1];
        String testJson = JSON.serialize(stream);
        stream.JSON_Description__c = testJson;
        update stream;
        Test.startTest();
        FrontResponseWrapper result = ProcessCreatorController.retrieveJSONStreamDescription(stream.Id);
        Test.stopTest();
        System.assert(result.isSuccess);
        System.assertEquals(testJson, result.dataJSON);
    }
}