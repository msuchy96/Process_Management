class Node {
    constructor(x, y, edgeCounter = 0, selected = false, jobId = '', Name = '') {
        console.log('new Node:  ' + x + ' ' + y);
        this.x_pos = x;
        this.y_pos = y;
        this.edgeCounter = edgeCounter;
        this.selected = selected;
        this.jobId = jobId;
        this.Name = Name;
    }
}

Node.prototype.consts =  {
    radius: 20,
    standardColor: "grey",
    selectedColor: "blue",
    savedColor: "green",
    strokeColor: "black",
    strokeWidth: 1,
    createEdgeColor: "purple",
    classSelected: "selected",
    classNotSelected: "notSelected",
    labelYTranslation : 35,
    labelXTranslation : 3.5,
    labelSize: '15px',
    labelFont: 'sans-serif',
    labelFill: 'black'
};

Node.prototype.edgeAdded = function() {
    this.edgeCounter++;
};

Node.prototype.edgeDeleted = function() {
    this.edgeCounter--;
};

export default Node;