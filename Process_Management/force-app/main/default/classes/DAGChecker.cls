public without sharing class DAGChecker {

    private class Graph {
        List<List<Integer>> adjacencyList = null;
        public Graph(List<Edge> edges, Integer numberOfNodes) {
		    adjacencyList = new List<List<Integer>>();

		    for (Integer i = 0; i < numberOfNodes; i++) {
			    adjacencyList.add(new List<Integer>());
		    }

		    // add edges
		    for (Edge edge: edges) {
			    adjacencyList.get(edge.sourceNode).add(edge.destionationNode);
		    }
	    }
    }

    private class Edge {
        Integer sourceNode, destionationNode;
        public Edge(Integer sourceNode, Integer destionationNode) {
            this.sourceNode = sourceNode;
            this.destionationNode = destionationNode;
        }
    }

    // Perform DFS on graph and set departure time of all
	// vertices of the graph
	private static Integer DFS(Graph graph, Integer v, Map<Integer, Boolean> discovered, Map<Integer, Integer> departure, Integer timeConsumed) {
		// mark current node as discovered
		discovered.put(v, true);

		// do for every edge (v -> u)
		for (Integer u : graph.adjacencyList.get(v)) {

			// u is not discovered
			if (!discovered.get(u)) {
                timeConsumed = DFS(graph, u, discovered, departure, timeConsumed);
            }
		}

		// ready to backtrack
		// set departure time of vertex v
		departure.put(v, timeConsumed++);
		return timeConsumed;
	}

    private static Boolean isDAG(Graph currentGraph, Integer numberOfNodes) {
        // stores vertex is discovered or not
		Map<Integer, Boolean> discovered = new Map<Integer, Boolean>();
        Map<Integer, Integer> departure = new Map<Integer, Integer>();
        for (Integer i = 0; i < numberOfNodes; i++) {
            discovered.put(i, false);
            departure.put(i, 0);
        }

		Integer timeConsumed = 0;

		// Do DFS traversal from all undiscovered vertices
		// to visit all connected components of graph
		for (Integer i = 0; i < numberOfNodes; i++) {
			if (!discovered.get(i)) {
				timeConsumed = DFS(currentGraph, i, discovered, departure, timeConsumed);
            }
        }
		// check if given directed graph is DAG or not
		for (Integer u = 0; u < numberOfNodes; u++) {
			// check if (u, v) forms a back-edge.
			for (Integer v : currentGraph.adjacencyList.get(u)) {
				// If departure time of vertex v is greater
				// than equal to departure time of u, then
				// they form a back edge
                
				if (departure.get(u) <= departure.get(v)) {
                    return false;
                }
			}
		}
		// no back edges
		return true;
    }

    @AuraEnabled
    public static FrontResponseWrapper checkIfGraphIsDAG(String edges, String startNodeNewEdge, String endNodeNewEdge, Integer numberOfNodes) {

        Map<String, Integer> idToNumberNodes = new Map<String, Integer>();
        List<Object> mappedEdges = (List<Object>)JSON.deserializeUntyped(edges);
        Map<String, Object> mappedStartNewNode = (Map<String, Object>)JSON.deserializeUntyped(startNodeNewEdge);
        Map<String, Object> mappedEndNewNode = (Map<String, Object>)JSON.deserializeUntyped(endNodeNewEdge);

        Integer nodeCounter = 0;
        List<Edge> edgeList = new List<Edge>();
        for(Object edgeObj : mappedEdges) {
            Map<String, Object> edgeAttribures = (Map<String, Object>)edgeObj;
            Map<String, Object> nodeStart = (Map<String, Object>)edgeAttribures.get('nodeStart');
            Map<String, Object> nodeEnd = (Map<String, Object>)edgeAttribures.get('nodeEnd');
            if(!idToNumberNodes.containsKey((String)nodeStart.get('jobId'))) {
                idToNumberNodes.put((String)nodeStart.get('jobId'), nodeCounter++);
            }
            if(!idToNumberNodes.containsKey((String)nodeEnd.get('jobId'))) {
                idToNumberNodes.put((String)nodeEnd.get('jobId'), nodeCounter++);
            }
        }

        if(!idToNumberNodes.containsKey((String)mappedStartNewNode.get('jobId'))) {
            idToNumberNodes.put((String)mappedStartNewNode.get('jobId'), nodeCounter++);
        }
        if(!idToNumberNodes.containsKey((String)mappedEndNewNode.get('jobId'))) {
            idToNumberNodes.put((String)mappedEndNewNode.get('jobId'), nodeCounter++);
        }
        
        for(Object edgeObj : mappedEdges) {
            Map<String, Object> edgeAttribures = (Map<String, Object>)edgeObj;
            Map<String, Object> nodeStart = (Map<String, Object>)edgeAttribures.get('nodeStart');
            Map<String, Object> nodeEnd = (Map<String, Object>)edgeAttribures.get('nodeEnd');
            edgeList.add(new Edge(idToNumberNodes.get((String)nodeStart.get('jobId')), idToNumberNodes.get((String)nodeEnd.get('jobId'))));
        }
        edgeList.add(new Edge(idToNumberNodes.get((String)mappedStartNewNode.get('jobId')), idToNumberNodes.get((String)mappedEndNewNode.get('jobId'))));
        Graph currentGraph = new Graph(edgeList, numberOfNodes);
        if(isDAG(currentGraph, numberOfNodes)) {
            return new FrontResponseWrapper(true, 'Succes');
        } else {
            return new FrontResponseWrapper(false, 'Graph has to be acyclic!');
        }
    }
}
