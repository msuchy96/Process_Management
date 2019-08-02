@IsTest
private class ResetReminderSentBatchTest {
    @TestSetup
    static void dataSetup() {
        TestHelper.createJobs(new Job__c(Reminder_Sent__c = true), 10, true, false);
    }

    @isTest
    static void testBatchExecution(){
        Test.startTest();
        ResetReminderSentBatch m = new ResetReminderSentBatch();
        System.schedule('ResetReminderSentBatch Processing 0', '0 0 * * * ?', m);
        Test.stopTest();
    }
}