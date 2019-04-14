public without sharing class DueDateIsComingBatch implements Schedulable, Database.Batchable<SObject> {
    /*  Batch Scheduling: 
		DueDateIsComingBatch m = new DueDateIsComingBatch();
		System.schedule('Due Date Notification Processing 0', '0 0 * * * ?', m);
		System.schedule('Due Date Notification Processing 15', '0 15 * * * ?', m);
		System.schedule('Due Date Notification Processing 30', '0 30 * * * ?', m);
		System.schedule('Due Date Notification Processing 45', '0 45 * * * ?', m);
	*/
    public String query = '';
    public EmailTemplate emailTemplate = null;

    public DueDateIsComingBatch() {
        query = 'SELECT Id, Time_Planned__c, Time_Spent__c, Assigned_To__c, Due_Date__c ' +
                'FROM Job__c ' +
                'WHERE Reminder_Sent__c = false' +
                ' AND Due_Date__c != null' +
                ' AND Time_Planned__c > 0' +
                ' AND Time_Spent__c != null' +
                ' AND Assigned_To__r.Allow_Email_Notification__c = true' +
                ' AND Assigned_To__r.Email != null' +
                ' AND ( Status__c = \'' + CommonUtility.JOB_STATUS_TODO + '\'' +
                    ' OR Status__c = \'' + CommonUtility.JOB_STATUS_INPROGRESS + '\')' +
                ' AND ( RecordTypeId = \'' + CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_JOB, CommonUtility.JOB_TYPE_STANDARD) + '\'' +
                    ' OR RecordTypeId = \'' + CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_JOB, CommonUtility.JOB_TYPE_FORK) + '\')';

        emailTemplate = [SELECT Id FROM EmailTemplate WHERE Name =: CommonUtility.EMAIL_NOTIFICATION_DUE_DATE_DEADLINE_TEMPLATE]; 
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Job__c> scope) {
        List<Job__c> jobToUpdate = new List<Job__c>();
        List<Contact> contactToDelete = new List<Contact>();
        List<Task> taskToInsert = new List<Task>();
        List<Messaging.SingleEmailMessage> emailToSent = new List<Messaging.SingleEmailMessage>();

        for(Job__c job: scope) {
            if(job.Time_Planned__c > job.Time_Spent__c && !Approval.isLocked(job.Id)) {
                String [] hoursAndMinutesRemain = String.valueOf(job.Time_Planned__c - job.Time_Spent__c).split('\\.');
                Integer hoursRemain = Integer.valueOf(hoursAndMinutesRemain[0]);
                Integer minutesRemain = Integer.valueOf(hoursAndMinutesRemain[1]);

                if(DateTime.now().addHours(hoursRemain).addMinutes(minutesRemain) > job.Due_Date__c) {
                    User user = [SELECT email, firstName, lastName FROM User WHERE id =: job.Assigned_To__c];
                    Contact tempContact = new Contact(email = user.email, firstName = user.firstName, lastName = user.lastName);
                    insert tempContact;
                    contactToDelete.add(tempContact);

                    job.Reminder_Sent__c = true;
                    jobToUpdate.add(job);

                    emailToSent.add(prepareEmail(job, tempContact));
                    taskToInsert.add(prepareTask(job));
                } 
            }
        }

        Messaging.SendEmailResult [] r = Messaging.sendEmail(emailToSent);
        delete contactToDelete;
        update jobToUpdate;
        insert taskToInsert;
    }

    private Messaging.SingleEmailMessage prepareEmail(Job__c job, Contact tempContact) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        mail.setTargetObjectId(tempContact.Id); 
        mail.setSenderDisplayName(CommonUtility.EMAIL_NOTIFICATION_SALESFORCE_SENDER); 
        mail.setSaveAsActivity(false); 
        mail.setWhatId(job.Id);
        mail.setTemplateId(emailTemplate.id);
        return mail;
    }

    private Task prepareTask(Job__c job) {
        return new Task(
            Status = CommonUtility.TASK_STATUS_NOTSTARTED,
            Priority = CommonUtility.TASK_PRIORITY_HIGH,
            ActivityDate = System.today(),
            Subject = CommonUtility.TASK_SUBJECT_CHECKIFYOUCANMAKEIT,
            Description = Label.Task_JobDeadlineDesc,
            OwnerId = job.Assigned_To__c,
            WhatId = job.Id
        );
    }

    public void finish(Database.BatchableContext BC) {}

    public void execute(SchedulableContext sc) {
		Database.executeBatch(new DueDateIsComingBatch(), 90);
    }
}