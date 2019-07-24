public without sharing class DailyReminderBatch implements Schedulable, Database.Batchable<SObject> {
    /*  Batch Scheduling: 
		Each Day 2AM
	*/
    public String query = '';
    public Datetime tommorowDateTime = null;

    public DailyReminderBatch() {

        tommorowDateTime = DateTime.now().addDays(1);
        query = 'SELECT Id, Name, Stream__r.Name, Time_Spent__c, Time_Planned__c, Status__c, Assigned_To__c, Due_Date__c ' +
                'FROM Job__c ' +
                'WHERE Due_Date__c < :tommorowDateTime ' +
                ' AND Assigned_To__r.Allow_Email_Notification__c = true' +
                ' AND Assigned_To__r.Email != null' +
                ' AND ( Status__c = \'' + CommonUtility.JOB_STATUS_TODO + '\'' +
                    ' OR Status__c = \'' + CommonUtility.JOB_STATUS_INPROGRESS + '\')' +
                ' AND RecordTypeId = \'' + CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_JOB, CommonUtility.JOB_TYPE_STANDARD) + '\'';
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Job__c> scope) {
        Set<Id> userIdSet = new Set<Id>();
        Map<Id, Contact> tempContactMap = new Map<Id, Contact>();
        Map<Id, List<Job__c>> userWithRelatedJobs = new Map<Id, List<Job__c>>();
        List<Messaging.SingleEmailMessage> emailToSent = new List<Messaging.SingleEmailMessage>();
        
        for(Job__c job: scope) {
            userIdSet.add(job.Assigned_To__c);
        }
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Email, FirstName, LastName FROM User WHERE Id IN: userIdSet]);
        for(User user: userMap.values()) {
            Contact tempContact = new Contact(email = user.email, firstName = user.firstName, lastName = user.lastName);
            tempContactMap.put(user.Id, tempContact);
        }
        insert tempContactMap.values();
        for(Job__c job: scope) {
            if(!Approval.isLocked(job.Id)) {
                User user = userMap.get(job.Assigned_To__c);
                if(userWithRelatedJobs.containsKey(user.Id)) {
                    userWithRelatedJobs.get(user.Id).add(job);
                } else {
                    userWithRelatedJobs.put(user.Id, new List<Job__c>{job});
                }
            }
        }

        for(Id userId : userWithRelatedJobs.keySet()) {
            emailToSent.add(prepareEmail(userWithRelatedJobs.get(userId), tempContactMap.get(userId)));
        }

        Messaging.SendEmailResult [] r = Messaging.sendEmail(emailToSent);
        delete tempContactMap.values();
    }

    private Messaging.SingleEmailMessage prepareEmail(List<Job__c> jobList, Contact tempContact) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        mail.setTargetObjectId(tempContact.Id); 
        mail.setSenderDisplayName(CommonUtility.EMAIL_NOTIFICATION_SALESFORCE_SENDER); 
        mail.setSaveAsActivity(false); 
        mail.setSubject(CommonUtility.EMAIL_NOTIFICATION_SALESFORCE_SENDER);
        mail.setHtmlBody(prepareEmailBody(jobList));
        return mail;
    }

    private String prepareEmailBody(List<Job__c> jobList) {
        String result =
        'Hello!<br><br>' +
        'There are some jobs which require your attention today:<br><ul style="list-style-type:disc;">';
        for(Job__c job : jobList) {
            result += '<li><a href="' + CommonUtility.getBaseURL() + '/' + job.Id +'">' +
            job.Name + '</a>:' +
            '<dt>Stream: ' + job.Stream__r.Name + '</dt>' +
            '<dt>Status: ' + job.Status__c + '</dt>' +
            '<dt>Time Planned: ' + job.Time_Planned__c + 'h</dt>' +
            '<dt>Time Spent: ' + job.Time_Spent__c + 'h</dt>' +
            '<dt>Due Date: ' + String.valueOf(job.Due_Date__c).substring(0, 16) + '</dt>' + 
            '</li>';
        }
        result += '</ul><br><br>Best regards, <br>'+
        'Salesforce Platform';
        return result;
    }

    public void finish(Database.BatchableContext BC) {}

    public void execute(SchedulableContext sc) {
		Database.executeBatch(new DailyReminderBatch(), 90);
    }
}
