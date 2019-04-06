/* eslint-disable vars-on-top */
/* eslint-disable no-console */
/* eslint-disable no-unused-vars */
import Node from './Node';

class Graph {
    constructor(nodes) {
        this.nodes = nodes;
        this.numberOfNodes = 0;
    }
}

Graph.prototype.addNode = function(coords) {
    console.log('Graph.addNode');
    var node = new Node(coords[0], coords[1], this.numberOfNodes);
    this.nodes.push(node);
    this.numberOfNodes++; 
    console.log('nodes list: ' + JSON.stringify(this.nodes));
}


export default Graph;