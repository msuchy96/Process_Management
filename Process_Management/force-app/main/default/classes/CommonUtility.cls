global without sharing class CommonUtility {

    // SOBJECT API NAMES
    global static final String SOBJECT_APINAME_ACCOUNT = 'Account';
    global static final String SOBJECT_APINAME_USER = 'User';
    global static final String SOBJECT_APINAME_EVENT = 'Event';
    global static final String SOBJECT_APINAME_TASK = 'Task';
    global static final String SOBJECT_APINAME_JOB = 'Job__c';
    global static final String SOBJECT_APINAME_STREAM = 'Stream__c';

    // SOBJECT NAMES
    global static final String SOBJECT_NAME_ENTITY = 'Entity';
    global static final String SOBJECT_NAME_JOB = 'Job';
    global static final String SOBJECT_NAME_STREAM = 'Stream';

    // EMPLOYEE ROLE PICKLIST FIELD VALES
    global static final String EMPLOYEE_ROLE_MANAGER = 'Manager';
    global static final String EMPLOYEE_ROLE_REGULAR = 'Regular employee';

    // JOB STATUS PICKLIST FIELD VALES
    global static final String JOB_STATUS_TODO = 'TO DO';
    global static final String JOB_STATUS_INPROGRESS = 'IN PROGRESS';
    global static final String JOB_STATUS_DONE = 'DONE';

    //PROFILE NAMES
    global static final String PROFILE_SYSTEM_ADMINISTRATOR = 'System Administrator';

    //APPROVAL PROCCESS
    global static final String APPROVAL_PROCESS_NAME_CHANGING_DUE_DATE = 'ChangingDueDate';

    //NOTIFICATION EMAIK
    global static final String EMAIL_NOTIFICATION_SALESFORCE_SENDER = 'Salesforce Notification';

    global static Profile adminProfile;
    global static Id getAdminProfileId() {
        return adminProfile != null ? adminProfile.Id : [SELECT Id FROM Profile WHERE Name = :PROFILE_SYSTEM_ADMINISTRATOR LIMIT 1].Id;
    }

}