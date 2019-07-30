@IsTest
private class DailyReminderBatchTest {

    @TestSetup
    static void dataSetup() {
        User testUser = TestHelper.createUser(new User(Allow_Email_Notification__c = true), true);
        TestHelper.createJobs(new Job__c(Assigned_To__c = testUser.Id, Due_Date__c = Datetime.now()), 10, true);
    }

    @isTest
    static void testBatchExecution(){
        Test.startTest();
        DailyReminderBatch m = new DailyReminderBatch();
        System.schedule('DailyReminderBatch Processing 0', '0 0 * * * ?', m);
        Test.stopTest();
    }
}