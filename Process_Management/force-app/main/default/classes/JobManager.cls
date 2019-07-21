public without sharing class JobManager {

    public static void checkJobToTemplateIfTemplateStream(Map<Id, List<Job__c>> jobsToCheckTemplate) {
        for(Stream__c templatSteam : [SELECT Id, RecordTypeId 
                                    FROM Stream__c 
                                    WHERE Id IN: jobsToCheckTemplate.keySet()
                                    AND RecordTypeId =: CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_STREAM, CommonUtility.STREAM_TYPE_STANDARD_TEMPLATE)]) {
            for(Job__c jobToChange : jobsToCheckTemplate.get(templatSteam.Id)) {
                jobToChange.RecordTypeId = CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_JOB, CommonUtility.JOB_TYPE_STANDARD_TEMPLATE);
            }
        }
    }

    public static void updateRelatedJobs(Set<Id> jobsIdForDeletion) {
        List<Job__c> jobsToUpdate = [SELECT Id, Next_Job__c, Second_Next_Job__c FROM Job__c WHERE Next_Job__c IN: jobsIdForDeletion AND Second_Next_Job__c != null];

        for(Job__c job : jobsToUpdate) {
            job.Next_Job__c = job.Second_Next_Job__c;
            job.Second_Next_Job__c = null;
        }
        update jobsToUpdate;
    }

    public static void updateRelatedStreamJSON(Map<Id, Job__c> jobsToUpdateStreamJSON) {
        Map<Id, Map<Id, Job__c>> streamToJobsMap = new Map<Id, Map<Id, Job__c>>();
        for(Job__c job : jobsToUpdateStreamJSON.values()) {
            if(streamToJobsMap.containsKey(job.Stream__c)) {
                streamToJobsMap.get(job.Stream__c).put(job.Id, job);
            } else {
                streamToJobsMap.put(job.Stream__c, new Map<Id, Job__c>{job.Id => job});
            }
        }

        List<Stream__c> streamToUpdate = [SELECT Id, JSON_Description__c
                                            FROM Stream__c 
                                            WHERE Id IN: streamToJobsMap.keySet()];

        List<Stream__c> tempListStream = new List<Stream__c>();
        for(Stream__c stream : streamToUpdate) {
            if(stream.JSON_Description__c != null) {
                tempListStream.add(stream);
            }
        }
        streamToUpdate = tempListStream;

        for(Stream__c stream : streamToUpdate) {
            Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(stream.JSON_Description__c);
            //NODES
            List<Object> lstNodes = (List<Object>)results.get('nodes');
            for(Object node : lstNodes) {
                Map<String, Object> nodeAttributes = (Map<String, Object>)node;
                String jobId = (String)nodeAttributes.get('jobId');
                if(streamToJobsMap.get(stream.Id).containsKey(jobId)) {
                    nodeAttributes.put('Name', streamToJobsMap.get(stream.Id).get(jobId).Name);
                    nodeAttributes.put('status', streamToJobsMap.get(stream.Id).get(jobId).Status__c);
                }
            }
            //EDGES
            List<Object> lstEdges = (List<Object>)results.get('edges');
            for(Object edge : lstEdges) {
                Map<String, Object> edgeAttributes = (Map<String, Object>)edge;
                Map<String, Object> nodeStart = (Map<String, Object>)edgeAttributes.get('nodeStart');
                Map<String, Object> nodeEnd = (Map<String, Object>)edgeAttributes.get('nodeEnd');
                String nodeStartId = (String)nodeStart.get('jobId');
                String nodeEndId = (String)nodeEnd.get('jobId');
                if(streamToJobsMap.get(stream.Id).containsKey(nodeStartId)) {
                    nodeStart.put('Name', streamToJobsMap.get(stream.Id).get(nodeStartId).Name);
                    nodeStart.put('status', streamToJobsMap.get(stream.Id).get(nodeStartId).Status__c);
                }
                if(streamToJobsMap.get(stream.Id).containsKey(nodeEndId)) {
                    nodeEnd.put('Name', streamToJobsMap.get(stream.Id).get(nodeEndId).Name);
                    nodeEnd.put('status', streamToJobsMap.get(stream.Id).get(nodeEndId).Status__c);
                }
            }
            stream.JSON_Description__c = JSON.serialize(results);
        }
        update streamToUpdate;
    }

    @AuraEnabled
    public static FrontResponseWrapper cloneStreamWithJobs(String streamId) {
        Stream__c streamToClone = [SELECT Id, Name, Client__c, JSON_Description__c, (SELECT Id, Status__c, Assigned_To__c, Name, Time_planned__c, Next_Job__c, Second_Next_Job__c FROM Jobs__r) FROM Stream__c WHERE Id =: streamId];
        Stream__c clonedStream = streamToClone.clone(false, false, false, false);
        clonedStream.Name += ' from Template';
        insert clonedStream;
        Map<Id, Job__c> jobsToClone = new Map<Id, Job__c>(streamToClone.Jobs__r);
        Map<Id, Id> nextJobMap = new Map<Id, Id>();
        Map<Id, Id> secondNextJobMap = new Map<Id, Id>();
        Map<Id, Job__c> toCloneToClonedJobsMap = new Map<Id, Job__c>();
        for(Job__c jobToClone : jobsToClone.values()) {
            nextJobMap.put(jobToClone.Id, jobToClone.Next_Job__c);
            secondNextJobMap.put(jobToClone.Id, jobToClone.Second_Next_Job__c);
            Job__c clonedJob = jobToClone.clone(false, false, false, false);
            clonedJob.Stream__c = clonedStream.Id;
            toCloneToClonedJobsMap.put(jobToClone.Id, clonedJob);
        }
        try{
            insert toCloneToClonedJobsMap.values();
            for(Id jobToCloneId : toCloneToClonedJobsMap.keySet()) {
                if(nextJobMap.get(jobToCloneId) != null) {
                    toCloneToClonedJobsMap.get(jobToCloneId).Next_Job__c = toCloneToClonedJobsMap.get(nextJobMap.get(jobToCloneId)).Id;
                }
                if(secondNextJobMap.get(jobToCloneId) != null) {
                    toCloneToClonedJobsMap.get(jobToCloneId).Second_Next_Job__c = toCloneToClonedJobsMap.get(secondNextJobMap.get(jobToCloneId)).Id;
                }
                if(clonedStream.JSON_Description__c != null) {
                    clonedStream.JSON_Description__c.replace((String)jobToCloneId, (String)toCloneToClonedJobsMap.get(jobToCloneId).Id);
                }
            }
            update clonedStream;
            update toCloneToClonedJobsMap.values();
            return new FrontResponseWrapper(true, Label.TST_MSG_StreamCreatedFromTemplate, clonedStream.Id);
        } catch(Exception e) {
            return new FrontResponseWrapper(false, e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Job__c> getUserJobs(Integer pagenumber, Integer numberOfRecords, Integer pageSize) {
        Integer calculatedOffset = (pageSize * (pagenumber - 1));
        return [SELECT Id, Name, Stream__r.Name, Status__c, Due_Date__c, Time_Spent__c, Time_Planned__c
                FROM Job__c 
                WHERE Assigned_To__c =: UserInfo.getUserId() 
                AND RecordTypeId =: CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_JOB, CommonUtility.JOB_TYPE_STANDARD)
                AND (Status__c =: CommonUtility.JOB_STATUS_TODO
                    OR Status__c =: CommonUtility.JOB_STATUS_INPROGRESS)
                ORDER BY Due_Date__c
                LIMIT :pageSize OFFSET :calculatedOffset];
    }

    @AuraEnabled
    public static Integer getUserJobsCount() {
        return [SELECT Id, Name, Stream__r.Name, Status__c, Due_Date__c, Time_Spent__c, Time_Planned__c, Stream__c
                FROM Job__c 
                WHERE Assigned_To__c =: UserInfo.getUserId() 
                AND RecordTypeId =: CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_JOB, CommonUtility.JOB_TYPE_STANDARD)
                AND (Status__c =: CommonUtility.JOB_STATUS_TODO
                    OR Status__c =: CommonUtility.JOB_STATUS_INPROGRESS)
                ORDER BY Due_Date__c].size();
    }
}