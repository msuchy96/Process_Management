global without sharing class CommonUtility {

    // Class for creating custom exceptions
    global class MyException extends Exception {}

    @AuraEnabled(cacheable=true)
    public static CommonUtility getAllConstants() {
        return new CommonUtility();
    }

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
    
    // EMPLOYEE ROLE PICKLIST FIELD VALUES
    global static final String EMPLOYEE_ROLE_MANAGER = 'Manager';
    global static final String EMPLOYEE_ROLE_REGULAR = 'Regular employee';

    // JOB RECORD TYPES
    global static final String JOB_TYPE_STANDARD = 'Standard';
    global static final String JOB_TYPE_STANDARD_TEMPLATE = 'Standard_Template';

    // STREAM RECORD TYPES
    global static final String STREAM_TYPE_STANDARD_TEMPLATE = 'Standard_Template';

    // JOB STATUS PICKLIST FIELD VALUES
    global static final String JOB_STATUS_TODO = 'TO DO';
    global static final String JOB_STATUS_INPROGRESS = 'IN PROGRESS';
    global static final String JOB_STATUS_DONE = 'DONE';

    // TASK PRIORITY PICKLIST VALUES
    global static final String TASK_PRIORITY_HIGH = 'High';
    global static final String TASK_PRIORITY_NORMAL = 'Normal';
    global static final String TASK_PRIORITY_LOW = 'Low';

    // TASK STATUS PICKLIST VALUES
    global static final String TASK_STATUS_NOTSTARTED = 'Not Started';
    global static final String TASK_STATUS_INPROGRESS = 'In Progress';
    global static final String TASK_STATUS_COMPLETED = 'Completed';
    global static final String TASK_STATUS_WAITINGONSOMEONE = 'Waiting on someone else';
    global static final String TASK_STATUS_DEFERRED = 'Deferred';

    // TASK SUBJECT PICKLIST VALUES
    global static final String TASK_SUBJECT_CALL = 'Call';
    global static final String TASK_SUBJECT_EMAIL = 'Email';
    global static final String TASK_SUBJECT_CHECKIFYOUCANMAKEIT = 'Check if you can make it on time';
    global static final String TASK_SUBJECT_OTHER = 'Other';

    //PROFILE NAMES
    global static final String PROFILE_SYSTEM_ADMINISTRATOR = 'System Administrator';
    global static Profile adminProfile;
    global static Id getAdminProfileId() {
        return adminProfile != null ? adminProfile.Id : [SELECT Id FROM Profile WHERE Name = :PROFILE_SYSTEM_ADMINISTRATOR LIMIT 1].Id;
    }

    //APPROVAL PROCCESS
    global static final String APPROVAL_PROCESS_NAME_CHANGING_DUE_DATE = 'ChangingDueDate';

    //NOTIFICATION EMAIL
    global static final String EMAIL_NOTIFICATION_SALESFORCE_SENDER = 'Salesforce Notification';
    global static final String EMAIL_NOTIFICATION_DUE_DATE_DEADLINE_TEMPLATE = 'DueDateDeadline';
    
    //BUTTON VARIANTS
    @AuraEnabled
    public final String BUTTON_VARIANT_NEUTRAL = 'neutral';
    @AuraEnabled
    public final String BUTTON_VARIANT_SUCCESS = 'success';


    /* map, used to preserve different mechanisms from retrieving (quering) 
        the same record types ids for more than once */
    global final static String NO_SUCH_RT_FOUND = 'No such record type found!';
    global final static String OBJECTNAME_AND_RT_NEEDS_TO_BE_DELIVERED = 'ObjectName and RecType needs to be delivered!';

    global static Map<String, Id> mRecordTypeName2Id = new Map<String, Id>();

    global static Id getRecordTypeId(string objectName, string recTypeDevName) {
        if (string.isNotBlank(objectName) && string.isNotBlank(recTypeDevName)) {
            string key = createKeyForRtMap(objectName, recTypeDevName);
            if (mRecordTypeName2Id == null || mRecordTypeName2Id.isEmpty()) {
                RecordType[]rts = [Select SobjectType, Name, Id, DeveloperName From RecordType];
                for (RecordType r1 : rts) {
                    putRecordTypeId(r1.SobjectType, r1.DeveloperName, r1.Id);
                }
            }
            if (mRecordTypeName2Id.containsKey(key)) {
                return mRecordTypeName2Id.get(key);
            } else {
                throw new MyException(NO_SUCH_RT_FOUND + ' [OBJECT: ' + objectName + ' RECTYPE: ' + recTypeDevName + ']');
            }
        } else {
            throw new MyException(OBJECTNAME_AND_RT_NEEDS_TO_BE_DELIVERED);
        }
    }

    global static void putRecordTypeId(string objectName, string recTypeDevName, Id recTypeId) {
        if (string.isNotBlank(objectName) && string.isNotBlank(recTypeDevName) && recTypeId != null) {
            mRecordTypeName2Id.put(createKeyForRtMap(objectName, recTypeDevName), recTypeId);
        }
    }

    global static string createKeyForRtMap(string objectName, string recTypeDevName) {
        return objectName.toUpperCase() + '.' + recTypeDevName.toUpperCase();
    }
}