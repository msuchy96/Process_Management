class Node {
    constructor(x, y, nodeId) {
        console.log('new Node:  ' + x + ' ' + y);
        this.x_pos = x;
        this.y_pos = y;
        this.nodeId = nodeId;
        this.edgeCounter = 0;
        this.selected = false;
    }
}

Node.prototype.consts =  {
    radius: 20,
    standardColor: "grey",
    selectedColor: "blue",
    strokeColor: "black",
    strokeWidth: 1,
    createEdgeColor: "green"
};

Node.prototype.edgeAdded = function() {
    this.edgeCounter++;
};

Node.prototype.edgeDeleted = function() {
    this.edgeCounter--;
};

export default Node;