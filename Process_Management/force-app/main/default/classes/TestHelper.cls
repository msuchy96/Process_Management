global class TestHelper {

    public final static String TEST_CONST = 'Test-';
    public final static Integer STRING_LENGTH = 3;

    public static Integer createRandomNumber() {
        return Math.Round(Math.Random() * ((Math.pow(10,STRING_LENGTH) - 1)-Math.pow(10,STRING_LENGTH -1)) + Math.pow(10,STRING_LENGTH -1));
    }

    public static Account createEntity(Account entityTemplate, Boolean isInsert) {
        return createEntity(entityTemplate, 1, isInsert)[0];
    }

    public static List<Account> createEntity(Account entityTemplate, Integer count, Boolean isInsert) {
        List<Account> result = new List<Account>();
        for(Integer i = 0; i < count; i++) {
            String randomNumber = String.valueOf(createRandomNumber());
            Account entity = entityTemplate != null ? entityTemplate : new Account();
            entity.Name = entity.Name != null ? entity.Name : TEST_CONST + CommonUtility.SOBJECT_NAME_ENTITY + randomNumber;
            result.add(entity);
        } 
        if(isInsert) insert result;
        return result;
    }

    public static Contact createEmployee(Contact employeeTemplate, Boolean isInsert) {
        return createEmployees(employeeTemplate, 1, isInsert)[0];
    }

    public static List<Contact> createEmployees(Contact employeeTemplate, Integer count, Boolean isInsert) {
        List<Contact> result = new List<Contact>();
        for(Integer i = 0; i < count; i++) {
            String randomNumber = String.valueOf(createRandomNumber());
            Contact employee = employeeTemplate != null ? employeeTemplate : new Contact();
            employee.FirstName = employee.FirstName != null ? employee.FirstName : TEST_CONST + CommonUtility.SOBJECT_NAME_EMPLOYEE;
            employee.LastName = employee.LastName != null ? employee.LastName : randomNumber;
            employee.AccountId = employee.AccountId != null ? employee.AccountId : createEntity(null, true).Id;
            employee.Role__c = employee.Role__c != null ? employee.Role__c : CommonUtility.EMPLOYEE_ROLE_REGULAR;
            result.add(employee);
        }
        if(isInsert) insert result;
        return result;
    }

    public static Stream__c createStream(Stream__c streamTemplate, Boolean isInsert) {
        return createStreams(streamTemplate, 1, isInsert)[0];
    }

    public static List<Stream__c> createStreams(Stream__c streamTemplate, Integer count, Boolean isInsert) {
        List<Stream__c> result = new List<Stream__c>();
        for(Integer i=0; i<count; i++) {
            String randomNumber = String.valueOf(createRandomNumber());
            Stream__c stream = streamTemplate != null ? streamTemplate : new Stream__c();
            stream.Name = stream.Name != null ? stream.Name : TEST_CONST + CommonUtility.SOBJECT_NAME_STREAM + randomNumber;
            result.add(stream);
        }
        if(isInsert) insert result;
        return result;
    }

    public static Job__c createJob(Job__c jobTemplate, Boolean isInsert) {
        return createJobs(jobTemplate, 1, isInsert)[0];
    }

    public static List<Job__c> createJobs(Job__c jobTemplate, Integer count, Boolean isInsert) {
        List<Job__c> result = new List<Job__c>();
        for(Integer i=0; i<count; i++) {
            String randomNumber = String.valueOf(createRandomNumber());
            Job__c job = jobTemplate != null ? jobTemplate : new Job__c();
            job.Name = job.Name != null ? job.Name : TEST_CONST + CommonUtility.SOBJECT_NAME_JOB + randomNumber;
            job.Assigned_To__c = createEmployee(null, true).Id;
            job.Status__c = job.Status__c != null ? job.Status__c : CommonUtility.JOB_STATUS_TODO;
            job.Stream__c = job.Stream__c != null ? job.Stream__c : createStream(null, true).Id;
            result.add(job);
        }
        if(isInsert) insert result;
        return result;
    }

}
