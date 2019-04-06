class Node {
    constructor(x, y, nodeId) {
        console.log('new Node:  ' + x + ' ' + y);
        this.x_pos = x;
        this.y_pos = y;
        this.nodeId = nodeId;
    }
}

Node.prototype.consts =  {
    radius: 20,
    color: "green"
  };

export default Node;