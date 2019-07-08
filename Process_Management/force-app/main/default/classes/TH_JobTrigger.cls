public without sharing class TH_JobTrigger extends TriggerHandler.DelegateBase {

    Map<Job__c, Decimal> jobsWithTimeReported;
    Map<Id, List<Job__c>> jobsToCheckTemplate;
    

    public override void prepareBefore() {
        jobsToCheckTemplate = new Map<Id, List<Job__c>>();
    }

    public override void prepareAfter() {
        jobsWithTimeReported = new Map<Job__c, Decimal>();
    }

    public override void beforeInsert(List<SObject> newObjectsMap) {
        List<Job__c> newJobsList = (List<Job__c>)newObjectsMap;
        collectJobsToCheckTemplate(newJobsList);
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

    public override void beforeDelete(Map<Id, SObject> oldObjectsMap) {
        JobManager.updateRelatedJobs(oldObjectsMap.keySet());
    }

    private void collectJobsToCheckTemplate(List<Job__c> jobsToCollectByStreamId) {
        for(Job__c jobToCheck : jobsToCollectByStreamId) {
            if(jobToCheck.Stream__c != null && jobToCheck.RecordTypeId != CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_JOB, CommonUtility.JOB_TYPE_STANDARD_TEMPLATE)) {
                if(jobsToCheckTemplate.containsKey(jobToCheck.Stream__c)) {
                    jobsToCheckTemplate.get(jobToCheck.Stream__c).add(jobToCheck);
                } else {
                    jobsToCheckTemplate.put(jobToCheck.Stream__c, new List<Job__c>{jobToCheck});
                }
            }
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
        if(jobsToCheckTemplate != null && !jobsToCheckTemplate.isEmpty()) {
            JobManager.checkJobToTemplateIfTemplateStream(jobsToCheckTemplate);
        }

        if(jobsWithTimeReported != null && !jobsWithTimeReported.isEmpty())
            TimeReportManager.createTimeReports(jobsWithTimeReported);
    }

}