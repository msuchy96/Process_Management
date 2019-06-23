public with sharing class ProcessCreatorController {
    public ProcessCreatorController() {}

    @AuraEnabled
    public static FrontResponseWrapper deleteSelectedJob(Id jobId) {
        try{
            delete new Job__c(Id = jobId);
            return new FrontResponseWrapper(true, Label.TST_MSG_JobDeleted);
        } catch(Exception e) {
            return new FrontResponseWrapper(false, e.getMessage());
        }
    }

    @AuraEnabled
    public static FrontResponseWrapper createConnectionBetweenJobs(Id firstJobId, Id secondJobId) {
        try{
            Job__c firstJob = [SELECT Id, Next_Job__c, Second_Next_Job__c FROM Job__c WHERE Id =: firstJobId];
            if(firstJob.Next_Job__c != null) {
                firstJob.Second_Next_Job__c = secondJobId;
            } else {
                firstJob.Next_Job__c = secondJobId;
            }
            update firstJob;
            return new FrontResponseWrapper(true, Label.TST_MSG_EdgeCreated);
        } catch(Exception e) {
            return new FrontResponseWrapper(false, e.getMessage());
        }
    }
}
