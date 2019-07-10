/* eslint-disable vars-on-top */
/* eslint-disable no-console */
/* eslint-disable no-unused-vars */
import Node from './Node';
import Edge from './Edge';

class Graph {
    constructor(nodes, edges, numberOfNodes = 0, numberOfEdges = 0, streamId = null) {
        this.nodes = nodes;
        this.edges = edges;
        this.numberOfNodes = numberOfNodes;
        this.numberOfEdges = numberOfEdges;
        this.startNodeForEdge = null;
        this.edgeMode = false;
        this.selectedJobId = null;
        this.streamId = streamId;
    }
}

Graph.prototype.addNode = function(coords) {
    var node = new Node(coords[0], coords[1]);
    this.nodes.push(node);
    this.numberOfNodes = this.numberOfNodes + 1;
}

Graph.prototype.addEdge = function(nodeStart, nodeEnd) {
    var createdEdge = new Edge(nodeStart, nodeEnd);
    nodeStart.edgeAdded();
    this.edges.push(createdEdge);
    this.numberOfEdges = this.numberOfEdges + 1;
}

Graph.prototype.clearTempParams = function() {
    this.startNodeForEdge = null;
}

export default Graph;