@isTest
private class ManageApprovalProcessTest {

    @TestSetup
    static void dataSetup() {
        User managerUser = [SELECT Id FROM User LIMIT 1];
        User testUser = TestHelper.createUser(new User(managerId = managerUser.Id), true);
        TestHelper.createJob(new Job__c(Assigned_To__c = testUser.Id), true);
        
    }

    @isTest
    static void submitDueDateApprovalSuccess() {
        Job__c jobToTest = [SELECT Id FROM Job__c LIMIT 1];
        DateTime newDueDate = Datetime.now().addDays(1);
        Test.startTest();
        FrontResponseWrapper response = ManageApprovalProcess.submitDueDateApproval(jobToTest.Id, newDueDate);
        Test.stopTest();
        System.assert(response.isSuccess);
    }

    @isTest
    static void submitDueDateApprovalManagerNotDefined() {
        User managerUser = [SELECT Id FROM User WHERE managerId = null LIMIT 1];
        Job__c jobToTest = [SELECT Id FROM Job__c LIMIT 1];
        jobToTest.Assigned_To__c = managerUser.Id;
        update jobToTest;
        DateTime newDueDate = Datetime.now().addDays(1);
        Test.startTest();
        FrontResponseWrapper response = ManageApprovalProcess.submitDueDateApproval(jobToTest.Id, newDueDate);
        Test.stopTest();
        System.assert(!response.isSuccess);
    }

    @isTest
    static void submitDueDateApprovalLocked() {
        Job__c jobToTest = [SELECT Id FROM Job__c LIMIT 1];
        DateTime newDueDate = Datetime.now().addDays(1);
        Test.startTest();
        FrontResponseWrapper response = ManageApprovalProcess.submitDueDateApproval(jobToTest.Id, newDueDate);
        FrontResponseWrapper response2 = ManageApprovalProcess.submitDueDateApproval(jobToTest.Id, newDueDate);
        Test.stopTest();
        System.assert(!response2.isSuccess);
    }
}