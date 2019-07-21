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
            Account entity = entityTemplate != null ? entityTemplate.clone(false, false) : new Account();
            if(entity.Name == null) entity.Name = TEST_CONST + CommonUtility.SOBJECT_NAME_ENTITY + randomNumber;
            result.add(entity);
        } 
        if(isInsert) insert result;
        return result;
    }

    public static User createUser(User userTemplate, Boolean isInsert){
        return createUsers(userTemplate, 1, isInsert)[0];
    }
    global static List<User> createUsers(User userTemplate, Integer count, Boolean isInsert){
        List<User> result = new List<User>();

        for(Integer i = 0; i < count; i++) {
            String randomNumber = String.valueOf(createRandomNumber());
            User u = userTemplate != null ? userTemplate.clone(false, false) : new User();
            if(u.FirstName == null) u.FirstName = TEST_CONST + randomNumber;
            if(u.Lastname == null) u.Lastname = TEST_CONST + randomNumber;
            if(u.Email == null) u.Email = 'email-' + TEST_CONST + randomNumber + '@example.com';
            if(u.Alias == null) { 
                u.Alias = 'U-'+ randomNumber;
            }
            if(u.Username == null) u.Username = TEST_CONST + randomNumber + '@example.com';
            if(u.LocaleSidKey == null) u.LocaleSidKey = 'en_US';
            if(u.TimeZoneSidKey == null) u.TimeZoneSidKey = 'GMT';
            if(u.ProfileID == null) u.ProfileID = CommonUtility.getAdminProfileId();
            if(u.LanguageLocaleKey == null) u.LanguageLocaleKey = 'en_US';
            if(u.EmailEncodingKey == null) u.EmailEncodingKey = 'UTF-8';
            result.add(u);
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
            Stream__c stream = streamTemplate != null ? streamTemplate.clone(false, false) : new Stream__c();
            if(stream.Name == null) stream.Name = TEST_CONST + CommonUtility.SOBJECT_NAME_STREAM + randomNumber;
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
            Job__c job = jobTemplate != null ? jobTemplate.clone(false, false) : new Job__c();
            if(job.Name == null) job.Name = TEST_CONST + CommonUtility.SOBJECT_NAME_JOB + randomNumber;
            if(job.Assigned_To__c == null) job.Assigned_To__c = createUser(null, true).Id;
            if(job.Status__c == null) job.Status__c = CommonUtility.JOB_STATUS_TODO;
            if(job.Stream__c == null) job.Stream__c = createStream(null, true).Id;
            result.add(job);
        }
        if(isInsert) insert result;
        return result;
    }

}