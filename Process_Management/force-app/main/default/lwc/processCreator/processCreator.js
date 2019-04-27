/* eslint-disable vars-on-top */
/* global d3 */
import {
    LightningElement, api
} from 'lwc';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
import {
    loadScript,
    loadStyle
} from 'lightning/platformResourceLoader';
import D3 from '@salesforce/resourceUrl/d3';
import Graph from './Graph';
import Node from './Node';
import Edge from './Edge';

export default class ProcessCreator extends LightningElement {
    svgWidth = 1000;
    svgHeight = 400;
    graph = null;
    d3Initialized = false;
    @api edgeModeVariant = 'neutral';

    renderedCallback() {
        if (this.d3Initialized) {
            return;
        }
        this.d3Initialized = true;

        Promise.all([
            loadScript(this, D3 + '/d3.v5.min.js'),
            loadStyle(this, D3 + '/style.css')
        ])
            .then(() => {
                this.initializeCreator();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading D3 lib',
                        message: error.message,
                        variant: 'error'
                    })
                );
            });
    }

    // define graphcreator object 
    initializeCreator() {
        const svg = d3.select(this.template.querySelector('svg.d3'));
        var nodes = [];
        var edges = [];
        var curGraph = this.graph = new Graph(nodes, edges);
        var edgeMode = this.edgeMode;

        svg.on('click', function () {
            if (!curGraph.edgeMode) {
                var coords = d3.mouse(this);
                curGraph.addNode(coords);
            }
            clearAndRedrawGraph();
        });

        function selectNode() {

            d3.event.stopPropagation();
            var selectedID = d3.select(this).attr("id");
            var clickedCircle = this;

            console.log('selected node with id: ' + JSON.stringify(clickedCircle));

            if (curGraph.edgeMode) {
                if (curGraph.startNodeForEdge == null) {
                    firstNodeInEdgeModeSelection();
                } else { // create edge
                    createEdge(clickedCircle);
                }
            } else {
                normalNodeSelection();
            }

            function normalNodeSelection() {
                svg.selectAll("circle").each(function () {
                    var currCircle = this;
                    d3.select(this)
                        .attr("class", function (d) {
                            return currCircle === clickedCircle ? "selected" : "notSelected";
                        })
                        .style("fill", function (d) {
                            var color = '';
                            if (currCircle === clickedCircle) {
                                curGraph.selectedElement = d;
                                color = "blue";
                            } else {
                                color = "gray";
                            }
                            return color;
                        });
                });
            }

            function firstNodeInEdgeModeSelection() {
                svg.selectAll("circle").each(function () {
                    var currCircle = this;
                    d3.select(this)
                        .style("fill", function (d) {
                            var color = '';
                            if (currCircle === clickedCircle) {
                                curGraph.startNodeForEdge = d;
                                color = "green";
                            } else {
                                color = "gray";
                            }
                            return color;
                        });
                });

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Build an enge!',
                        message: 'Please select second node to build edge.',
                        variant: 'info'
                    })
                );
            }

            function createEdge(clickedCircle) {
                console.log('create Edge to the : ' + JSON.stringify(clickedCircle));
                var secondSelectedCircle = null;
                d3.select(clickedCircle).attr("class", function (d) { secondSelectedCircle = d; })
                curGraph.addEdge(curGraph.startNodeForEdge, secondSelectedCircle)
                clearAndRedrawGraph();
                curGraph.startNodeForEdge = null;
            }
        }


        function dragstarted(d) {
            d3.select(this).raise().classed("active", true);
        }

        function dragged(d) {
            var x = Math.max(d.consts.radius, Math.min(1000 - d.consts.radius, d3.event.x));
            var y = Math.max(d.consts.radius, Math.min(400 - d.consts.radius, d3.event.y));
            d3.select(this).attr("cx", d.x_pos = x).attr("cy", d.y_pos = y);
        }

        function dragended(d) {
            d3.select(this).classed("active", false);
        }

        function clearAndRedrawGraph() {
            svg.selectAll("circle").remove();
            svg.selectAll("line").remove();
            drawEdges();
            drawNodes();
        }

        function drawEdges() {
            svg.selectAll("line")
                .data(curGraph.edges)
                .enter()
                .append("line")
                .attr("x1", function (d) {
                    return d.nodeStart.x_pos;
                })
                .attr("y1", function (d) {
                    return d.nodeStart.y_pos;
                })
                .attr("x2", function (d) {
                    return d.nodeEnd.x_pos;
                })
                .attr("y2", function (d) {
                    return d.nodeEnd.y_pos;
                })
                .attr("stroke-width", 3)
                .attr("stroke", "black")
                .attr("marker-end", "url(#triangle)");
        }

        function drawNodes() {
            svg.selectAll("circle")
                .data(curGraph.nodes)
                .enter()
                .append("circle")
                .attr("cx", function (d) {
                    return d.x_pos;
                })
                .attr("cy", function (d) {
                    return d.y_pos;
                })
                .attr("r", function (d) {
                    return d.consts.radius;
                })
                .attr("stroke", "black")
                .attr("stroke-width", 1)
                .attr("id", function (d) {
                    return d.nodeId
                })
                .style("fill", function (d) {
                    return d.consts.color;
                })
                .on("click", selectNode)
                .call(d3.drag()
                    .on("start", dragstarted)
                    .on("drag", dragged)
                    .on("end", dragended)
                );
        }
    }

    deleteSelectedElement() {
        const svg = d3.select(this.template.querySelector('svg.d3'));
        this.graph.nodes = this.removeElement(this.graph.nodes, this.graph.selectedElement);
        this.graph.selectedElement = null;
        svg.selectAll(".selected").remove();
    }

    removeElement(array, element) {
        return array.filter(el => el !== element);
    }

    addingEdgeMode() {
        console.log('edge mode enable');
        this.graph.edgeMode = !this.graph.edgeMode;
        this.edgeModeVariant = this.graph.edgeMode ? 'success' : 'neutral';
        this.graph.selectedElement = null;
        this.graph.startNodeForEdge = null;
        const svg = d3.select(this.template.querySelector('svg.d3'));
        svg.selectAll(".selected").each(function () {
            d3.select(this)
                .attr("class", function (d) {
                    return "notSelected";
                });
        });

        svg.selectAll("circle").each(function () {
            d3.select(this)
                .style("fill", function (d) {
                    return "gray";
                });
        });


    }



}