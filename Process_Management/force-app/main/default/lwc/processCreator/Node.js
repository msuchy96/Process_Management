function Node(x, y) {
    console.log('Node1: ' + x + ' ' + y);
    this.x_pos = x;
    this.y_pos = y;
}

Node.prototype.consts =  {
    radius: 20,
    color: "green"
  };

export default Node;