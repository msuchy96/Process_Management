public without sharing class JobManager {

    public static void checkJobToTemplateIfTemplateStream(Map<Id, List<Job__c>> jobsToCheckTemplate) {
        for(Stream__c templatSteam : [SELECT Id, RecordTypeId 
                                    FROM Stream__c 
                                    WHERE Id IN: jobsToCheckTemplate.keySet()
                                    AND RecordTypeId =: CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_STREAM, CommonUtility.STREAM_TYPE_STANDARD_TEMPLATE)]) {
            for(Job__c jobToChange : jobsToCheckTemplate.get(templatSteam.Id)) {
                jobToChange.RecordTypeId = CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_JOB, CommonUtility.JOB_TYPE_STANDARD_TEMPLATE);
            }
        }
    }

    public static void updateRelatedJobs(Set<Id> jobsIdForDeletion) {
        List<Job__c> jobsToUpdate = [SELECT Id, Next_Job__c, Second_Next_Job__c FROM Job__c WHERE Next_Job__c IN: jobsIdForDeletion AND Second_Next_Job__c != null];

        for(Job__c job : jobsToUpdate) {
            job.Next_Job__c = job.Second_Next_Job__c;
            job.Second_Next_Job__c = null;
        }
        update jobsToUpdate;
    }
}