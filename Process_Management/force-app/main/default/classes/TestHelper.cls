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
            result.add(employee);
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
            job.Name = job.Name != null ? job.Name : TEST_CONST + randomNumber;
            job.Assigned_To__c = createEmployee(null, true).Id;
            job.Time_Planned__c = job.Time_Planned__c != null ? job.Time_Planned__c : Decimal.valueOf(randomNumber);
            job.Time_Spent__c = job.Time_Spent__c != null ? job.Time_Spent__c : Math.ceil(job.Time_Planned__c/2);
            result.add(job);
        }
        if(isInsert) insert result;
        return result;
    }

}
