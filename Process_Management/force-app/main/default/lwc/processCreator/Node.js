class Node {
    constructor(x, y) {
        console.log('new Node:  ' + x + ' ' + y);
        this.x_pos = x;
        this.y_pos = y;
        this.edgeCounter = 0;
        this.selected = false;
        this.jobId = '';
    }
}

Node.prototype.consts =  {
    radius: 20,
    standardColor: "grey",
    selectedColor: "blue",
    savedColor: "green",
    strokeColor: "black",
    strokeWidth: 1,
    createEdgeColor: "green",
    classSelected: "selected",
    classNotSelected: "notSelected",
};

Node.prototype.edgeAdded = function() {
    this.edgeCounter++;
};

Node.prototype.edgeDeleted = function() {
    this.edgeCounter--;
};

export default Node;