public without sharing class DueDateIsComingBatch implements Schedulable, Database.Batchable<SObject> {
    /* 
		DueDateIsComingBatch m = new DueDateIsComingBatch();
		System.schedule('Due Date Notification Processing', '0 0 * * * ?', m);
		System.schedule('Due Date Notification Processing', '0 15 * * * ?', m);
		System.schedule('Due Date Notification Processing', '0 30 * * * ?', m);
		System.schedule('Due Date Notification Processing', '0 45 * * * ?', m);

	*/
    public String query = '';
    public EmailTemplate emailTemplate = null;

    public DueDateIsComingBatch() {
        query = 'SELECT Id, Time_Planned__c, Time_Spent__c, Assigned_To__c ' +
                'FROM Job__c ' +
                'WHERE Reminder_Sent__c = false' +
                ' AND Due_Date__c != null' +
                ' AND Time_Planned__c > 0' +
                ' AND Time_Spent__c != null' +
                ' AND Assigned_To__r.Allow_Email_Notification__c = true' +
                ' AND Assigned_To__r.Email != null' +
                ' AND Time_Planned__c > Time_Spent__c';

        emailTemplate = [SELECT Id FROM EmailTemplate WHERE Name =: CommonUtility.EMAIL_NOTIFICATION_DUE_DATE_DEADLINE_TEMPLATE]; 
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Job__c> scope) {
        List<Job__c> jobToUpdate = new List<Job__c>();
        List<Messaging.SingleEmailMessage> emailToSent = new List<Messaging.SingleEmailMessage>();
        for(Job__c job: scope) {
            
            String [] hoursAndMinutesRemain = String.valueOf(job.Time_Planned__c - job.Time_Spent__c).split('\\.');
            Integer hoursRemain = Integer.valueOf(hoursAndMinutesRemain[0]);
            Integer minutesRemain = Integer.valueOf(hoursAndMinutesRemain[1]);

            if(DateTime.now().addHours(hoursRemain).addMinutes(minutesRemain) > job.Due_Date__c) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
                mail.setTargetObjectId(job.Assigned_To__c); 
                mail.setSenderDisplayName(CommonUtility.EMAIL_NOTIFICATION_SALESFORCE_SENDER); 
                mail.setSaveAsActivity(true); 
                mail.setWhatId(job.Id);
                mail.setTemplateId(emailTemplate.id); 
                emailToSent.add(mail);
                job.Reminder_Sent__c = true;
                jobToUpdate.add(job);
            } 
        }

        Messaging.SendEmailResult [] r = Messaging.sendEmail(emailToSent);
        update jobToUpdate;
    }


    public void finish(Database.BatchableContext BC) {}

    public void execute(SchedulableContext sc) {
		Database.executeBatch(new DueDateIsComingBatch());
    }
}
