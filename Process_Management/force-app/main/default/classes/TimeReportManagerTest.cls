@isTest
private class TimeReportManagerTest {

    @TestSetup
    static void dataSetuo() {
        TestHelper.createJobs(null, 10, true);
    }

    @isTest
    static void timeReportsCreation() {
        Map<Id, Job__c> jobMap = new Map<Id,Job__c>([SELECT Id, Time_Spent__c FROM Job__c]);
        for(Job__c job : jobMap.values()) {
            job.Time_Spent__c = Decimal.valueOf(TestHelper.createRandomNumber());
            job.Status__c = CommonUtility.JOB_STATUS_INPROGRESS;
        }
        Test.startTest();
        update jobMap.values();
        Test.stopTest();
        List<Time_Report__c> result = [SELECT Id, Time_Reported__c, Job__c FROM Time_Report__c];
        System.assert(!result.isEmpty());
        for(Time_Report__c tR : result) {
            System.assertEquals(jobMap.get(tR.Job__c).Time_Spent__c, tr.Time_Reported__c);
        }
    }

    @isTest
    static void timeReportsModified() {
        Map<Id, Job__c> jobMap = new Map<Id,Job__c>([SELECT Id, Time_Spent__c FROM Job__c]);
        for(Job__c job : jobMap.values()) {
            job.Time_Spent__c = Decimal.valueOf(TestHelper.createRandomNumber());
            job.Status__c = CommonUtility.JOB_STATUS_INPROGRESS;
        }
        update jobMap.values();
        Map<Id, Time_Report__c> relatedTimeReports = new Map<Id, Time_Report__c>([SELECT Id, Time_Reported__c, Job__c FROM Time_Report__c]);

        Test.startTest();
        for(Job__c job : jobMap.values()) {
            job.Time_Spent__c = job.Time_Spent__c + Decimal.valueOf(TestHelper.createRandomNumber());
        }
        update jobMap.values();
        Test.stopTest();
        List<Time_Report__c> updatedTimeReports = [SELECT Id, Time_Reported__c, Job__c FROM Time_Report__c];
        for(Time_Report__c tR : updatedTimeReports) {
            System.assertEquals(jobMap.get(tR.Job__c).Time_Spent__c, tr.Time_Reported__c);
        }
    }

}