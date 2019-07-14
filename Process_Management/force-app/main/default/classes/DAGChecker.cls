public without sharing class DAGChecker {

    private class Graph {
        List<List<Integer>> adjacencyList = null;
        public Graph(List<Edge> edges, Integer numberOfNodes) {
		    adjacencyList =  new List<List<Integer>>();

		    for (Integer i = 0; i < numberOfNodes; i++) {
			    adjacencyList.add(i, new List<Integer>());
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
	private static Integer DFS(Graph graph, Integer v, Boolean[] discovered, Integer[] departure, Integer timeConsumed) {
		// mark current node as discovered
		discovered[v] = true;

		// do for every edge (v -> u)
		for (Integer u : graph.adjacencyList.get(v)) {
			// u is not discovered
			if (!discovered[u]) {
                timeConsumed = DFS(graph, u, discovered, departure, timeConsumed);
            }
		}

		// ready to backtrack
		// set departure time of vertex v
		departure[v] = timeConsumed++;

		return timeConsumed;
	}

    private static Boolean isDAG(Graph currentGraph, Integer numberOfNodes) {
        // stores vertex is discovered or not
		Boolean[] discovered = new Boolean[numberOfNodes];

		// stores departure time of a vertex in DFS
		Integer[] departure = new Integer[numberOfNodes];

		Integer timeConsumed = 0;

		// Do DFS traversal from all undiscovered vertices
		// to visit all connected components of graph
		for (Integer i = 0; i < numberOfNodes; i++) {
			if (discovered[i] == false) {
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
				if (departure[u] <= departure[v]) {
                    return false;
                }
			}
		}
		// no back edges
		return true;
    }

    @AuraEnabled
    public static FrontResponseWrapper checkIfGraphIsDAG() {
        Integer numberOfNodes = null;

        List<Edge> edgeList = new List<Edge>{
            // add new Edges
        };

        Graph currentGraph = new Graph(edgeList, numberOfNodes);
        if(isDAG(currentGraph, numberOfNodes)) {
            return new FrontResponseWrapper(true, 'Success');
        } else {
            return new FrontResponseWrapper(false, 'Error');
        }
    }
}
