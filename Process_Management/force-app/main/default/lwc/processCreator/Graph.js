/* eslint-disable vars-on-top */
/* eslint-disable no-console */
/* eslint-disable no-unused-vars */
import Node from './Node';
import Edge from './Edge';

class Graph {
    constructor(nodes, edges) {
        this.nodes = nodes;
        this.edges = edges;
        this.numberOfNodes = 0;
        this.numberOfEdges = 0;
        this.selectedElement = null;
        this.startNodeForEdge = null;
        this.edgeMode = false;
    }
}

Graph.prototype.addNode = function(coords) {
    console.log('Graph.addNode');
    var node = new Node(coords[0], coords[1], this.numberOfNodes);
    this.nodes.push(node);
    this.numberOfNodes = this.numberOfNodes + 1;
    console.log('nodes list: ' + JSON.stringify(this.nodes));
}

Graph.prototype.addEdge = function(nodeStart, nodeEnd) {
    console.log('Graph.addEdge');
    var edge = new Edge(nodeStart, nodeEnd, this.numberOfEdges);
    this.edges.push(edge);
    this.numberOfEdges = this.numberOfEdges + 1;
    console.log('edge list: ' + JSON.stringify(this.edges));
}


export default Graph;