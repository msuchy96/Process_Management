@IsTest
private class DueDateIsComingBatchTest {
    @TestSetup
    static void dataSetup() {
        User testUser = TestHelper.createUser(new User(Allow_Email_Notification__c = true), true);
        TestHelper.createJobs(new Job__c(Assigned_To__c = testUser.Id, 
                                            Status__c = CommonUtility.JOB_STATUS_INPROGRESS,
                                            Due_Date__c = Datetime.now(),
                                            Reminder_Sent__c = false,
                                            Time_Planned__c = 10,
                                            Time_Spent__c = 4), 10, true, false);
    }

    @isTest
    static void testBatchExecution(){
        Test.startTest();
        DueDateIsComingBatch m = new DueDateIsComingBatch();
        System.schedule('DueDateIsComingBatch Processing 0', '0 0 * * * ?', m);
        Test.stopTest();
    }
}