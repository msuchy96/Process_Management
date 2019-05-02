class Edge {
    constructor(nodeStart, nodeEnd, edgeId) {
        console.log('new Edge:' + edgeId);
        console.log('nodeStart:' + JSON.stringify(nodeStart));
        console.log('nodeEnd:' + JSON.stringify(nodeEnd));

        this.nodeStart = nodeStart;
        this.nodeEnd = nodeEnd;
        this.edgeId = edgeId;
        this.selected = false; 
    }
}

Node.prototype.consts =  {
    radius: 20,
    standardColor: "black",
    selectedColor: "blue",
    classSelected: "selected",
    classNotSelected: "notSelected",
    strokeWidth: 3,
    marker: 'url(#marker)'
  };

export default Edge;