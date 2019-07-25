@isTest
private class TimeReportManagerTest {

    @TestSetup
    static void dataSetup() {
        TestHelper.createJobs(null, 10, true);
    }

    @isTest
    static void timeReportsCreation() {
        Map<Id, Job__c> jobMap = new Map<Id,Job__c>([SELECT Id, Time_Spent__c FROM Job__c]);
        for(Job__c job : jobMap.values()) {
            job.Time_Spent__c = Decimal.valueOf(RandomUtility.createRandomNumber());
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
            job.Time_Spent__c = Decimal.valueOf(RandomUtility.createRandomNumber());
            job.Status__c = CommonUtility.JOB_STATUS_INPROGRESS;
        }
        update jobMap.values();
        Map<Id, Time_Report__c> relatedTimeReports = new Map<Id, Time_Report__c>([SELECT Id, Time_Reported__c, Job__c FROM Time_Report__c]);

        Test.startTest();
        for(Job__c job : jobMap.values()) {
            job.Time_Spent__c = job.Time_Spent__c + Decimal.valueOf(RandomUtility.createRandomNumber());
        }
        update jobMap.values();
        Test.stopTest();
        List<Time_Report__c> updatedTimeReports = [SELECT Id, Time_Reported__c, Job__c FROM Time_Report__c];
        for(Time_Report__c tR : updatedTimeReports) {
            System.assertEquals(jobMap.get(tR.Job__c).Time_Spent__c, tr.Time_Reported__c);
        }
    }

    @isTest
    static void timeReportsDeletion() {
        Map<Id, Job__c> jobMap = new Map<Id,Job__c>([SELECT Id, Time_Spent__c FROM Job__c]);
        for(Job__c job : jobMap.values()) {
            job.Time_Spent__c = Decimal.valueOf(RandomUtility.createRandomNumber());
            job.Status__c = CommonUtility.JOB_STATUS_INPROGRESS;
        }
        update jobMap.values();
        Map<Id, Time_Report__c> relatedTimeReports = new Map<Id, Time_Report__c>([SELECT Id, Time_Reported__c, Job__c FROM Time_Report__c]);

        Test.startTest();
        for(Job__c job : jobMap.values()) {
            job.Time_Spent__c = 0;
        }
        update jobMap.values();
        Test.stopTest();
        List<Time_Report__c> updatedTimeReports = [SELECT Id, Time_Reported__c, Job__c FROM Time_Report__c];
        System.assertEquals(0, updatedTimeReports.size());
        
    }

    @isTest
    static void timeReportsCounter() {
        Map<Id, Job__c> jobMap = new Map<Id,Job__c>([SELECT Id, Time_Spent__c FROM Job__c]);
        User testUser = [SELECT Id FROM User LIMIT 1];
        Test.startTest();
        for(Job__c job : jobMap.values()) {
            job.Time_Spent__c = Decimal.valueOf(RandomUtility.createRandomNumber());
            job.Status__c = CommonUtility.JOB_STATUS_INPROGRESS;
            job.Assigned_To__c = testUser.Id;
        }
        System.runAs(testUser) {
            update jobMap.values();
        }
        Map<Id, Time_Report__c> relatedTimeReports = new Map<Id, Time_Report__c>([SELECT Id, Time_Reported__c, Job__c, Reporter__c FROM Time_Report__c]);
        System.runAs(testUser) {
            System.assertEquals(relatedTimeReports.values().size(), TimeReportManager.getUserTimeReportsCount());
            System.assertEquals(5, TimeReportManager.getUserTimeReports(1,5,5).size());
        }
        Test.stopTest();
    }

}