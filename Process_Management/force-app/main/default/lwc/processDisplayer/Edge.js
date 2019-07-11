class Edge {
    constructor(nodeStart, nodeEnd, selected = false) {
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