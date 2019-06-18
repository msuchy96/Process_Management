public with sharing class ProcessCreatorController {
    public ProcessCreatorController() {}

    @AuraEnabled
    public static FrontResponseWrapper deleteSelectedJob(Id jobId) {
        try{
            delete new Job__c(Id = jobId);
            return new FrontResponseWrapper(true, 'Job successfully deleted!');
        } catch(Exception e) {
            return new FrontResponseWrapper(false, e.getMessage());
        }
        
    }
}
