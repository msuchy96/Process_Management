public without sharing class JobManager {
    public static void updateRelatedJobs(Set<Id> jobsIdForDeletion) {
        List<Job__c> jobsToUpdate = [SELECT Id, Next_Job__c, Second_Next_Job__c FROM Job__c WHERE Next_Job__c IN: jobsIdForDeletion AND Second_Next_Job__c != null];

        for(Job__c job : jobsToUpdate) {
            job.Next_Job__c = job.Second_Next_Job__c;
            job.Second_Next_Job__c = null;
        }
        update jobsToUpdate;
    }
}
