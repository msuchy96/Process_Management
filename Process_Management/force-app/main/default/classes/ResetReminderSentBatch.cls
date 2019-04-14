public without sharing class ResetReminderSentBatch implements Schedulable, Database.Batchable<SObject> {
    /*  Batch Scheduling: 
		Each Day 1AM
	*/
    public String query = '';

    public ResetReminderSentBatch() {
        query = 'SELECT Id, Reminder_Sent__c ' +
                'FROM Job__c ' +
                'WHERE Reminder_Sent__c = true' +
                ' AND ( Status__c = \'' + CommonUtility.JOB_STATUS_TODO + '\'' +
                    ' OR Status__c = \'' + CommonUtility.JOB_STATUS_INPROGRESS + '\')' +
                ' AND ( RecordTypeId = \'' + CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_JOB, CommonUtility.JOB_TYPE_STANDARD) + '\'' +
                    ' OR RecordTypeId = \'' + CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_JOB, CommonUtility.JOB_TYPE_FORK) + '\')';
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Job__c> scope) {
        List<Job__c> jobToUpdate = new List<Job__c>();
        for(Job__c job: scope) {
            if(!Approval.isLocked(job.Id)) {
                job.Reminder_Sent__c = false;
                jobToUpdate.add(job);
            }
        }
        update jobToUpdate;
    }


    public void finish(Database.BatchableContext BC) {}

    public void execute(SchedulableContext sc) {
		Database.executeBatch(new ResetReminderSentBatch(), 200);
    }
}

