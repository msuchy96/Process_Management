class Edge {
    constructor(nodeStart, nodeEnd, selected = false) {
        console.log('new Edge:');
        console.log('nodeStart:' + JSON.stringify(nodeStart));
        console.log('nodeEnd:' + JSON.stringify(nodeEnd));

        this.nodeStart = nodeStart;
        this.nodeEnd = nodeEnd;
        this.selected = selected; 
    }
}

Edge.prototype.consts =  {
    radius: 20,
    standardColor: "black",
    selectedColor: "blue",
    classSelected: "selected",
    classNotSelected: "notSelected",
    strokeWidth: 3
  };

export default Edge;