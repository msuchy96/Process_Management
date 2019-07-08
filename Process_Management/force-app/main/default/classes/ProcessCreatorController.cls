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

    @AuraEnabled
    public static FrontResponseWrapper saveStreamAsTemplate(String streamNameSelection, String streamClientId){
        try {
            Stream__c streamToInsert =  new Stream__c(Name = streamNameSelection,
                                                        Client__c = streamClientId,
                                                        RecordTypeId = CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_STREAM, CommonUtility.STREAM_TYPE_STANDARD_TEMPLATE));
            insert streamToInsert;
            return new FrontResponseWrapper(true, 'Stream saved!', JSON.serialize(streamToInsert.Id)); 
        } catch (Exception e) {
            System.debug('@@MacSuc1: ' + e.getMessage());
            return new FrontResponseWrapper(false, e.getMessage());
        }
    }
}