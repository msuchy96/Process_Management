public without sharing class TH_JobTrigger extends TriggerHandler.DelegateBase {

    Map<Job__c, Decimal> jobsWithTimeReported;

    public override void prepareAfter() {
        jobsWithTimeReported = new Map<Job__c, Decimal>();
    }

    public override void afterInsert(Map<Id, SObject> newObjectsMap) {
        Map<Id, Job__c> newJobsMap = (Map<Id, Job__c>)newObjectsMap;
        for (Id key : newJobsMap.keySet()) {
            Job__c newJob = newJobsMap.get(key);

            checkReportedTimeChanges(null, newJob);
        }
    }

    public override void afterUpdate(Map<Id, SObject> oldObjectsMap, Map<Id, SObject> newObjectsMap) {
        Map<Id, Job__c> newJobsMap = (Map<Id, Job__c>)newObjectsMap;
        Map<Id, Job__c> oldJobsMap = (Map<Id, Job__c>)oldObjectsMap;
        for (Id key : newJobsMap.keySet()) {
            Job__c newJob = newJobsMap.get(key);
            Job__c oldJob = oldJobsMap.get(key);

            checkReportedTimeChanges(oldJob, newJob);
        }
    }

    private void checkReportedTimeChanges(Job__c oldJob, Job__c newJob) {
        if(
            newJob.Assigned_To__c != null
            && ((oldJob != null && oldJob.Time_Spent__c != newJob.Time_Spent__c)                    //afterUpdate
                || (oldJob == null && newJob.Time_Spent__c != null && newJob.Time_Spent__c != 0)   //afterInsert
            )
        ) {
            jobsWithTimeReported.put(newJob, oldJob != null ? newJob.Time_Spent__c - oldJob.Time_Spent__c : newJob.Time_Spent__c);
        }
            
    }

    public override void finish() {
        if(jobsWithTimeReported != null && !jobsWithTimeReported.isEmpty())
            TimeReportManager.createTimeReports(jobsWithTimeReported);
    }

}