global class TestHelper {

    public final static String TEST_CONST = 'Test-';
   

    public static Account createEntity(Account entityTemplate, Boolean isInsert) {
        return createEntity(entityTemplate, 1, isInsert)[0];
    }

    public static List<Account> createEntity(Account entityTemplate, Integer count, Boolean isInsert) {
        List<Account> result = new List<Account>();
        for(Integer i = 0; i < count; i++) {
            String randomNumber = String.valueOf(RandomUtility.createRandomNumber());
            Account entity = entityTemplate != null ? entityTemplate.clone(false, false) : new Account();
            if(entity.Name == null) entity.Name = TEST_CONST + CommonUtility.SOBJECT_NAME_ENTITY + '-' + randomNumber;
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
            String randomNumber = String.valueOf(RandomUtility.createRandomNumber());
            User u = userTemplate != null ? userTemplate.clone(false, false) : new User();
            if(u.FirstName == null) u.FirstName = TEST_CONST + randomNumber;
            if(u.Lastname == null) u.Lastname = TEST_CONST + randomNumber;
            if(u.Email == null) u.Email = 'email-' + TEST_CONST + randomNumber + '@example.com';
            if(u.Alias == null) { 
                u.Alias = 'U-'+ randomNumber;
            }
            if(u.Username == null) u.Username = TEST_CONST + randomNumber + String.valueOf(i) + '@example.com';
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
            String randomNumber = String.valueOf(RandomUtility.createRandomNumber());
            Stream__c stream = streamTemplate != null ? streamTemplate.clone(false, false) : new Stream__c();
            if(stream.Name == null) stream.Name = TEST_CONST + CommonUtility.SOBJECT_NAME_STREAM + '-' + randomNumber;
            result.add(stream);
        }
        if(isInsert) insert result;
        return result;
    }

    public static Job__c createJob(Job__c jobTemplate, Boolean isInsert, Boolean isTemplate) {
        return createJobs(jobTemplate, 1, isInsert, isTemplate)[0];
    }

    public static List<Job__c> createJobs(Job__c jobTemplate, Integer count, Boolean isInsert, Boolean isTemplate) {
        List<Job__c> result = new List<Job__c>();
        for(Integer i=0; i<count; i++) {
            String randomNumber = String.valueOf(RandomUtility.createRandomNumber());
            Job__c job = jobTemplate != null ? jobTemplate.clone(false, false) : new Job__c();
            if(job.Name == null) job.Name = TEST_CONST + CommonUtility.SOBJECT_NAME_JOB + '-' + randomNumber;
            if(job.Assigned_To__c == null && !isTemplate) job.Assigned_To__c = createUser(null, true).Id;
            if(job.Status__c == null) job.Status__c = CommonUtility.JOB_STATUS_TODO;
            if(job.Stream__c == null) job.Stream__c = createStream(null, true).Id;
            result.add(job);
        }
        if(isInsert) insert result;
        return result;
    }

    public static Client__c createClient(Client__c clientTemplate, Boolean isInsert) {
        return createClients(clientTemplate, 1, isInsert)[0];
    }

    public static List<Client__c> createClients(Client__c clientTemplate, Integer count, Boolean isInsert) {
        List<Client__c> result = new List<Client__c>();
        for(Integer i=0; i<count; i++) {
            String randomNumber = String.valueOf(RandomUtility.createRandomNumber());
            Client__c client = clientTemplate != null ? clientTemplate.clone(false, false) : new Client__c();
            if(client.Name == null) client.Name = TEST_CONST + CommonUtility.SOBJECT_NAME_CLIENT + '-' + randomNumber;
            result.add(client);
        }
        if(isInsert) insert result;
        return result;
    }

    public static Task createTask(Task taskTemplate, Boolean isInsert) {
        return createTasks(taskTemplate, 1, isInsert)[0];
    }

    public static List<Task> createTasks(Task taskTemplate, Integer count, Boolean isInsert) {
        List<Task> result = new List<Task>();
        List<String> subjects = new List<String>{'Call', 'Email', 'Other', 'Check if you can make it on time'};
        List<String> statuses = new List<String>{'Not Started', 'In Progress', 'Completed', 'Waiting on someone else', 'Deferred'};
        List<String> priorities = new List<String>{'High', 'Normal', 'Low'}; 
        for(Integer i=0; i<count; i++) {
            Integer subjectIndex = RandomUtility.generateRandomFromRange(0, 4);
            Integer statusIndex = RandomUtility.generateRandomFromRange(0, 5);
            Integer todayPropability = RandomUtility.generateRandomFromRange(0, 5);
            Integer priorityIndex = RandomUtility.generateRandomFromRange(0, 3);
            Task task = taskTemplate != null ? taskTemplate.clone(false, false) : new Task();
            if(task.Subject == null) task.Subject = subjects.get(subjectIndex);
            if(task.OwnerId == null) task.OwnerId = UserInfo.getUserId();
            if(task.Status == null) task.Status = statuses.get(statusIndex);
            if(task.Priority == null) task.Priority = priorities.get(priorityIndex);
            if(task.ActivityDate == null) {
                if(todayPropability > 3) {
                    task.ActivityDate = Date.today();
                } else {
                    DateTime dT = RandomUtility.prepareRandomDateTime(null, true);
                    task.ActivityDate = Date.newinstance(dT.year(), dT.month(), dT.day());
                } 
            }
            result.add(task);
        }
        if(isInsert) insert result;
        return result;
    }

    public static Event createEvent(Event eventTemplate, Boolean isInsert) {
        return createEvents(eventTemplate, 1, isInsert)[0];
    }

    public static List<Event> createEvents(Event eventTemplate, Integer count, Boolean isInsert) {
        List<Event> result = new List<Event>();
        List<String> subjects = new List<String>{'Call', 'Email', 'Other', 'Meeting', 'Send Offer'};
        for(Integer i=0; i<count; i++) {
            Integer subjectIndex = RandomUtility.generateRandomFromRange(0, 5);
            Integer todayPropability = RandomUtility.generateRandomFromRange(0, 6);
            Event event = eventTemplate != null ? eventTemplate.clone(false, false) : new Event();
            if(event.Subject == null) event.Subject = subjects.get(subjectIndex);
            if(event.OwnerId == null) event.OwnerId = UserInfo.getUserId();
            if(event.DurationInMinutes == null) event.DurationInMinutes = 60;
            if(event.StartDateTime == null) {
                if(todayPropability > 4) {
                    event.StartDateTime = DateTime.now().addHours(RandomUtility.generateRandomFromRange(0, 6)).addMinutes(RandomUtility.generateRandomFromRange(0, 60));
                } else {
                    event.StartDateTime = RandomUtility.prepareRandomDateTime(null, true);
                }
            }
            result.add(event);
        }
        if(isInsert) insert result;
        return result;
    }



    public static void generateGraphJSONDescription(Set<Id> streamIdSet) {
        List<Stream__c> streamList = [SELECT Id, JSON_Description__c, (SELECT Id, Name, Status__c, Next_Job__c, Second_Next_Job__c FROM Jobs__r) FROM Stream__c WHERE Id IN :streamIdSet];
        for(Stream__c stream : streamList) {
            Map<Id, Job__c> jobs = new Map<Id, Job__c>(stream.Jobs__r);
            Map<Id, NodeStructure> nodeStructureMap = new Map<Id, NodeStructure>();
            GraphStructure graphStruct = new GraphStructure(stream.Id);
            for(Job__c job: jobs.values()) {
                NodeStructure node = new NodeStructure(job);
                nodeStructureMap.put(node.jobId, node);
                graphStruct.nodes.add(node);
            }
            for(Job__c job: jobs.values()) {
                if(job.Next_Job__c != null) {
                    graphStruct.edges.add(new EdgeStructure(nodeStructureMap.get(job.Id), nodeStructureMap.get(job.Next_Job__c)));
                }
                if(job.Second_Next_Job__c != null) {
                    graphStruct.edges.add(new EdgeStructure(nodeStructureMap.get(job.Id), nodeStructureMap.get(job.Second_Next_Job__c)));
                }
            }
            stream.JSON_Description__c = JSON.serialize(graphStruct);
        }
        
        update streamList;
    }

    private class GraphStructure {
        List<NodeStructure> nodes;
        List<EdgeStructure> edges;
        NodeStructure startNodeForEdge = null;
        Boolean edgeMode = false;
        Id selectedJobId = null;
        Id streamId;
        Boolean template = false; 

        GraphStructure(Id graphId) {
            streamId = graphId;
            nodes = new List<NodeStructure>();
            edges = new List<EdgeStructure>();
        }
               
    }

    private class NodeStructure {
        Integer x_pos;
        Integer y_pos;
        Integer edgeCounter;
        Boolean selected = false;
        Id jobId;
        String Name;
        String status;

        NodeStructure(Job__c job) {
            jobId = job.Id;
            Name = job.Name;
            status = job.Status__c;
            edgeCounter = 0;
            if(job.Next_Job__c != null) edgeCounter++;
            if(job.Second_Next_Job__c != null) edgeCounter++;
            x_pos = RandomUtility.generateRandomFromRange(50, 1100);
            y_pos = RandomUtility.generateRandomFromRange(50, 400);
        }
    }

    private class EdgeStructure {
        NodeStructure nodeStart;
        NodeStructure nodeEnd;
        Boolean selected = false;

        EdgeStructure(NodeStructure nodeS, NodeStructure nodeE) {
           nodeStart = nodeS;
           nodeEnd = nodeE;
        }
    }

}