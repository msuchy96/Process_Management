/* eslint-disable vars-on-top */
/* eslint-disable no-console */
/* eslint-disable no-unused-vars */
import Node from './Node';
function GraphCreator(svg, d3) {
  var thisGraph = this;

  function drawNode(node) {
    console.log('Drawing node at', node.x_pos, node.y_pos, node.consts.radius);
    var circleAdded = svg.append("circle");
    var circleAtt = circleAdded
      .attr('class', 'node')
      .attr("cx", node.x_pos)
      .attr("cy",  node.y_pos)
      .attr("r", node.consts.radius)
      .attr("fill", node.consts.color);
        
}

svg.on('click', function() {
    var coords = d3.mouse(this);
    var newNode = new Node(coords[0], coords[1]);
    console.log(coords);
    drawNode(newNode);
});

}

export default GraphCreator;