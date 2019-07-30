public with sharing class ManageApprovalProcess {

    @AuraEnabled
	public static FrontResponseWrapper submitDueDateApproval(Id jobId, DateTime dueDateToChange) {
        if(!Approval.isLocked(jobId)) {
            try {
                Job__c jobToApprove = [SELECT Id, Assigned_To__c FROM Job__c WHERE Id =: jobId];
                jobToApprove.Due_Date_To_Change__c = dueDateToChange;
                update jobToApprove;
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
				req.setObjectId(jobId);
				req.setSubmitterId(jobToApprove.Assigned_To__c);
				req.setProcessDefinitionNameOrId(CommonUtility.APPROVAL_PROCESS_NAME_CHANGING_DUE_DATE);
				Approval.ProcessResult result = Approval.process(req);
                return new FrontResponseWrapper(true, Label.APP_ApprovalSentManager);
            } catch (Exception e) {
                return new FrontResponseWrapper(false, e.getMessage());
            }
        } else {
            return new FrontResponseWrapper(false, Label.APP_RecordPendingApp);
        }
	}
}