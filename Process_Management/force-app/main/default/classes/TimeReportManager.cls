public without sharing class TimeReportManager {
    public static createTimeReports(Map<Job__c, Decimal> jobsWithTimeReported) {
        List<Time_Report__c> timeReportToInsert = new List<Time_Report__c>();
        for(Job__c job : jobsWithTimeReported.keySet()) {
            timeReportToInsert.add(
                new Time_Report__c(
                    Job__c = job.Id,
                    Reporter__c = job.Assigned_To__c,
                    Time_Reported__c = jobsWithTimeReported.get(job),
                    Date__c = Date.today()
            ));
        }
        insert timeReportToInsert;
    }
}
