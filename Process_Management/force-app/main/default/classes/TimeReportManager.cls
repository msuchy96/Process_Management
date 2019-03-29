public without sharing class TimeReportManager {
    public static void createTimeReports(Map<Job__c, Decimal> jobsWithTimeReported) {
        Map<String, JobWrapper> wrappedJobMap = new Map<String, JobWrapper>();
        List<Time_Report__c> timeReportToUpsert = new List<Time_Report__c>();
        List<Time_Report__c> timeReportToDelete = new List<Time_Report__c>();

        for(Job__c job : jobsWithTimeReported.keySet()) {
            String externalId = String.valueOf(job.Id).substring(0, 15) + String.valueOf(job.Assigned_To__c).substring(0, 15) + String.valueOf(Date.today());
            JobWrapper wrappedJob = new JobWrapper(job, externalId);
            wrappedJobMap.put(wrappedJob.externalId, wrappedJob);
        }

        for(Time_Report__c timeReport : [SELECT Id, Reporter__c, Time_Reported__c, Job__c, Job_Reporter_Date_Id__c    //update existing TR
                                                    FROM Time_Report__c
                                                    WHERE Job_Reporter_Date_Id__c IN: wrappedJobMap.keySet()]
        ) { 
            if(timeReport.Time_Reported__c + jobsWithTimeReported.get(wrappedJobMap.get(timeReport.Job_Reporter_Date_Id__c).job) <= 0) {
                timeReportToDelete.add(new Time_Report__c(Id = timeReport.Id));
            } else {
                timeReportToUpsert.add(
                    new Time_Report__c(
                        Id = timeReport.Id,
                        Time_Reported__c = timeReport.Time_Reported__c + jobsWithTimeReported.get(wrappedJobMap.get(timeReport.Job_Reporter_Date_Id__c).job))
                );
            }
            wrappedJobMap.get(timeReport.Job_Reporter_Date_Id__c).updateTR = true; 
        }

        for(JobWrapper jobWrap : wrappedJobMap.values()) {                                                          // cretate new TR
            if(!jobWrap.updateTR && jobsWithTimeReported.get(jobWrap.job) > 0) {
                timeReportToUpsert.add(
                    new Time_Report__c(
                        Time_Reported__c = jobsWithTimeReported.get(jobWrap.job),
                        Reporter__c = jobWrap.job.Assigned_To__c,
                        Job__c = jobWrap.job.Id,
                        Date__c = Date.today())
                );
            }
        }
     
        delete timeReportToDelete;
        upsert timeReportToUpsert;
    }


    private class JobWrapper {
        public String externalId {get; set;}
        public Job__c job {get; set;}
        public Boolean updateTR {get; set;}

        public JobWrapper(Job__c job, String externalId) {
            this.externalId = externalId;
            this.job = job;
            updateTR = false;
		}
    }
}