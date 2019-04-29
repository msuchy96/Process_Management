class Node {
    constructor(x, y, nodeId) {
        console.log('new Node:  ' + x + ' ' + y);
        this.x_pos = x;
        this.y_pos = y;
        this.nodeId = nodeId;
        this.edgeCounter = 0;
    }
}

Node.prototype.consts =  {
    radius: 20,
    color: "grey"
};

Node.prototype.edgeAdded = function() {
    this.edgeCounter++;
};

Node.prototype.edgeDeleted = function() {
    this.edgeCounter--;
};

export default Node;