@isTest
private class DAGCheckerTest {

    @testSetup
    static void dataSetup() {
        User testUser = TestHelper.createUser(null, true);
        Stream__c stream = TestHelper.createStream(new Stream__c() , true);
        List<Job__c> jobList = TestHelper.createJobs(new Job__c(Stream__c = stream.Id, Assigned_To__c = testUser.Id), 10, true, false);
        for(Integer i = 0; i < jobList.size(); i++) {
            if(i > 0) {
                jobList.get(i).Next_Job__c = jobList.get(i-1).Id;
            } 
            if(i > 1) {
                jobList.get(i).Second_Next_Job__c = jobList.get(i-2).Id;
            }
        }
        update jobList;
        TestHelper.generateGraphJSONDescription(new Set<Id>{stream.Id});
    }

    @isTest
    static void notDAGgraph() {
        Stream__c testStream = [SELECT Id, JSON_Description__c FROM Stream__c LIMIT 1];
        Map<String, Object> mappedGraph = (Map<String, Object>)JSON.deserializeUntyped(testStream.JSON_Description__c);
        List<Object> edges = (List<Object>)mappedGraph.get('edges');
        List<Object> nodes = (List<Object>)mappedGraph.get('nodes');
        Map<String, Object> startNodeNewEdge;
        Map<String, Object> endNodeNewEdge;
        for(Integer i = 0; i < nodes.size(); i++) {
            if(i == 2) {
                startNodeNewEdge = (Map<String, Object>)nodes.get(i);
            } 
            if(i == 4) {
                endNodeNewEdge = (Map<String, Object>)nodes.get(i);
            }
        }
        Test.startTest();
        FrontResponseWrapper response = DAGChecker.checkIfGraphIsDAG(JSON.serialize(edges), JSON.serialize(startNodeNewEdge), JSON.serialize(endNodeNewEdge), 10);
        Test.stopTest();
        System.assert(!response.isSuccess);
    }

    @isTest
    static void DAGgraph() {
        Stream__c testStream = [SELECT Id, JSON_Description__c FROM Stream__c LIMIT 1];
        List<Job__c> jobList = [SELECT Id, Name, Next_Job__c, Second_Next_Job__c FROM Job__c WHERE Stream__c =: testStream.Id ORDER BY Name ASC];
        for(Integer i = 0; i < jobList.size(); i++) {
            jobList.get(i).Next_Job__c = null;
            jobList.get(i).Second_Next_Job__c = null;
        }
        update jobList;
        TestHelper.generateGraphJSONDescription(new Set<Id>{testStream.Id});
        testStream = [SELECT Id, JSON_Description__c FROM Stream__c LIMIT 1];
        Map<String, Object> mappedGraph = (Map<String, Object>)JSON.deserializeUntyped(testStream.JSON_Description__c);
        List<Object> edges = (List<Object>)mappedGraph.get('edges');
        List<Object> nodes = (List<Object>)mappedGraph.get('nodes');
        Map<String, Object> startNodeNewEdge;
        Map<String, Object> endNodeNewEdge;
        for(Integer i = 0; i < nodes.size(); i++) {
            if(i == 4) {
                startNodeNewEdge = (Map<String, Object>)nodes.get(i);
            } 
            if(i == 0) {
                endNodeNewEdge = (Map<String, Object>)nodes.get(i);
            }
        }
        Test.startTest();
        FrontResponseWrapper response = DAGChecker.checkIfGraphIsDAG(JSON.serialize(edges), JSON.serialize(startNodeNewEdge), JSON.serialize(endNodeNewEdge), 10);
        Test.stopTest();
        System.assert(response.isSuccess);
    }
}