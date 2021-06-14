Bachelor's Degree project
===============================

Application supporting task planning for an agile organization employee</br></br>
<b>Abstract</b></br>
The aim of this thesis was to design, implement and test an application on CRM platform that enables planning, monitoring and analyzing processes created from consecutive jobs. The application should be designed in such a way that it can serve any agile organization or those who want to implement agile elements for their work, regardless of the field they deals with. The key aspect was realization of organization virtualization, where employees using system functionalities can independently organize their work and transfer the most important elements of the company management to one program. The implemented process creator helps in managing processes consisting of tasks in the form of directed acyclic graphs which supports quick work reconfiguration to find the most cost-effective solution. Triggers which are responsible for application logic during operations on the integrated database have used the delegation pattern in order to protect from errors related to the limits imposed by the platform and help in further development of the application.
</br>

Technologies used
===============================

* LWC
* D3.js
* JavaScript
* APEX
* SOQL
* SFDX
* Ant Migration Tool
</br>

Worth attention
===============================

<b>Stream creator in LWC with D3.js</b></br>
![image](https://user-images.githubusercontent.com/24355089/120639787-07234580-c472-11eb-9506-2f258e2781b1.png)
</br></br>
<b>Directed graph acyclicity validation</b></br>
<pre><code>
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
</code></pre></br>
<b>Delegation pattern in triggers</b></br>
<pre><code>
public with sharing class TriggerHandler{

    public interface Delegate {
        void prepareBefore();
        void prepareAfter();

        void beforeInsert(List<sObject> o);
        void beforeUpdate(Map<Id, sObject> old, Map<Id, sObject> o);
        void beforeDelete(Map<Id, sObject> o);

        void afterInsert(Map<Id, sObject> o);
        void afterUpdate(Map<Id, sObject> old, Map<Id, sObject> o);
        void afterDelete(Map<Id, sObject> o);
        void afterUndelete(Map<Id, sObject> o);

        void finish();
    }

    public abstract class DelegateBase implements Delegate {

        public virtual void prepareBefore() {}
        public virtual void prepareAfter() {}

        public virtual void beforeInsert(List<sObject> o) {}
        public virtual void beforeUpdate(Map<Id, sObject> old, Map<Id, sObject> o) {}
        public virtual void beforeDelete(Map<Id, sObject> o) {}

        public virtual void afterInsert(Map<Id, sObject> o) {}
        public virtual void afterUpdate(Map<Id, sObject> old, Map<Id, sObject> o) {}
        public virtual void afterDelete(Map<Id, sObject> o) {}
        public virtual void afterUndelete(Map<Id, sObject> o) {}

        public virtual void finish() {}

    }

    public static void execute(Delegate d) {
        if (Trigger.isBefore) {
            d.prepareBefore();
            if (Trigger.isInsert) {
                d.beforeInsert(Trigger.new);
            } else if (Trigger.isUpdate) {
                d.beforeUpdate(Trigger.oldMap, Trigger.newMap);
            } else if (Trigger.isDelete) {
                d.beforeDelete(Trigger.oldMap);
            }
        } else {
            d.prepareAfter();
            if (Trigger.isInsert) {
                d.afterInsert(Trigger.newMap);
            } else if (Trigger.isUpdate) {
                d.afterUpdate(Trigger.oldMap, Trigger.newMap);
            } else if (Trigger.isDelete) {
                d.afterDelete(Trigger.oldMap);
            } else if (Trigger.isUndelete) {
                d.afterUndelete(Trigger.newMap);
            }
        }
        d.finish();
    }
}
</code></pre></br>
