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

// Import custom labels
import errorLoadingMsg from '@salesforce/label/c.D3_ErrorLoading';
import streamCreator from '@salesforce/label/c.BTN_StreamCreator';
import deleteSelectedElement from '@salesforce/label/c.BTN_DeleteElement';
import edgeMode from '@salesforce/label/c.BTN_EdgeMode';
import buttonVariantNeutral from '@salesforce/label/c.BTN_VariantNeutral';
import buttonVariantSuccess from '@salesforce/label/c.BTN_VariantSuccess';

export default class ProcessCreator extends LightningElement {
    d3Initialized = false;
    @api edgeModeVariant = buttonVariantNeutral;
    @api edgeModeEnable = false; 

    label = {
        streamCreator,
        deleteSelectedElement,
        edgeMode
    };

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
                        title: errorLoadingMsg,
                        message: error.message,
                        variant: 'error'
                    })
                );
            });
    }

    // define graphcreator object 
    initializeCreator() {
        const svg = d3.select(this.template.querySelector('svg.d3'));

        var svgWidth = svg.style("width");
        var svgHeight = svg.style("height");
        svgWidth = parseInt(svgWidth.substring(0, svgWidth.length-2), 10);
        svgHeight = parseInt(svgHeight.substring(0, svgHeight.length-2), 10);

        var nodes = [];
        var edges = [];
        var curGraph = this.graph = new Graph(nodes, edges);

        defineDefaults();
        clickBehaviour();

        function clickBehaviour() {
            svg.on('click', function () {
                if (!curGraph.edgeMode) {
                    var coords = d3.mouse(this);
                    curGraph.addNode(coords);
                }
                clearAndRedrawGraph();
            });
        }

        function defineDefaults() {
            svg.append('defs').append('marker')
            .attr("id", "marker")
            .attr("viewBox", "0 -5 10 10")
            .attr("refX", 23)
            .attr("refY", 0)
            .attr("markerWidth", 5)
            .attr("markerHeight", 5)
            .attr("orient", "auto")
            .append('svg:path')
            .attr('d', 'M 0,-5 L 10 ,0 L 0,5')
            .attr('fill', 'black')
            .attr('stroke', 'black');
        }

        function selectNode() {
            d3.event.stopPropagation();
            var clickedCircle = this;
            console.log('selected node  ' + JSON.stringify(clickedCircle));
            if (curGraph.edgeMode) {
                if (curGraph.startNodeForEdge == null) {
                    firstNodeInEdgeModeSelection();
                } else { // create edge
                    createEdge();
                }
            } else {
                normalNodeSelection();
            }

            function normalNodeSelection() {
                deselectAllEdges();
                svg.selectAll("circle").each(function () {
                    var currCircle = this;
                    d3.select(this)
                        .attr("class", function (d) {
                            if (currCircle === clickedCircle) {
                                d.selected = true;
                                selectEdgesConnectedToNode(d);
                            } else {
                                d.selected = false;
                            }
                        });
                });
                clearAndRedrawGraph();
            }

            function firstNodeInEdgeModeSelection() {
                svg.selectAll("circle").each(function () {
                    var currCircle = this;
                    d3.select(this)
                        .style("fill", function (d) {
                            var color = '';
                            if (currCircle === clickedCircle && d.edgeCounter !== 2) {
                                curGraph.startNodeForEdge = d;
                                color = d.consts.createEdgeColor;
                            } else {
                                color = d.consts.standardColor;
                            }
                            return color;
                        });
                });
            }

            function createEdge() {
                console.log('create Edge to the : ' + JSON.stringify(clickedCircle));
                var secondSelectedCircle = null;
                d3.select(clickedCircle).attr("class", function (d) { 
                    secondSelectedCircle = d; 
                });

                //check if there is an edge between nodes
                var nodeExist = false;
                curGraph.edges.forEach(function (edge) {
                    if(
                        (edge.nodeStart === curGraph.startNodeForEdge 
                            && edge.nodeEnd === secondSelectedCircle)
                        || (edge.nodeStart === secondSelectedCircle 
                            && edge.nodeEnd === curGraph.startNodeForEdge)
                    ) nodeExist = true;
                });

                if(curGraph.startNodeForEdge !== secondSelectedCircle && !nodeExist) {
                    if(curGraph.startNodeForEdge.edgeCounter !== 2) {
                        curGraph.addEdge(curGraph.startNodeForEdge, secondSelectedCircle);
                        clearAndRedrawGraph();
                    }
                }
                
            }
        }

        function selectEdge() {
            d3.event.stopPropagation();
            var clickedEdge = this;
            console.log('selected edge  ' + JSON.stringify(clickedEdge));
            if(!curGraph.edgeMode) {
                svg.selectAll("line").each(function () {
                    var currEdge = this;
                    d3.select(this)
                        .attr("class", function (d) {
                            if (currEdge === clickedEdge) {
                                d.selected = true;
                            } else {
                                d.selected = false;
                            }
                        });
                });
                deselectAllNodes();
                clearAndRedrawGraph();
            }
        }

        function dragstarted() {
            d3.select(this).raise().classed("active", true);
        }

        function dragged(d) {
            var x = Math.max(d.consts.radius, Math.min(svgWidth - d.consts.radius, d3.event.x));
            var y = Math.max(d.consts.radius, Math.min(svgHeight - d.consts.radius, d3.event.y));
            d3.select(this).attr("cx", d.x_pos = x).attr("cy", d.y_pos = y);
            updateEdges(d, x, y);
        }

        function updateEdges(node, x, y) {
            svg.selectAll("line").each(function () {
                d3.select(this)
                    .attr("x1", function (edge) {
                        if (edge.nodeStart === node) return x;
                        return edge.nodeStart.x_pos;
                    })
                    .attr("y1", function (edge) {
                        if (edge.nodeStart === node) return y;
                        return edge.nodeStart.y_pos;
                    })
                    .attr("x2", function (edge) {
                        if (edge.nodeEnd === node) return x;
                        return edge.nodeEnd.x_pos;
                    })
                    .attr("y2", function (edge) {
                        if (edge.nodeEnd === node) return y;
                        return edge.nodeEnd.y_pos;
                    });
            });
        }

        function dragended() {
            d3.select(this).classed("active", false);
        }

        function deselectAllNodes() {
            svg.selectAll("circle").each(function () {
                d3.select(this)
                    .attr("class", function (d) {
                       d.selected = false;
                    });
            });
        }

        function deselectAllEdges() {
            svg.selectAll("line").each(function () {
                d3.select(this)
                    .attr("class", function (edge) {
                       edge.selected = false;
                    });
            });
        }

        function selectEdgesConnectedToNode(node) {
            svg.selectAll("line").each(function () {
                d3.select(this)
                    .attr("class", function (edge) {
                        if (edge.nodeEnd === node || edge.nodeStart === node) {
                            edge.selected = true;
                        } else {
                            edge.selected = false;
                        }
                    });
            });
        }

        function clearAndRedrawGraph() {
            svg.selectAll("circle").remove();
            svg.selectAll("line").remove();
            drawEdges();
            drawNodes();
            curGraph.clearTempParams();
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
                .attr("class", function(d) {
                    if(d.selected) return d.consts.classSelected;
                    return d.consts.classNotSelected;
                })
                .on("click", selectEdge)
                .attr("stroke-width", function (d) {
                    return d.consts.strokeWidth;
                })
                .attr("stroke", function(d) {
                    if(d.selected) return d.consts.selectedColor;
                    return d.consts.standardColor;
                })
                .attr('marker-end', 'url(#marker)');
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
                .attr("class", function(d) {
                    if(d.selected) return d.consts.classSelected;
                    return d.consts.classNotSelected;
                })
                .attr("stroke", function(d) {
                    return d.consts.strokeColor;
                })
                .attr("stroke-width", function(d) {
                    return d.consts.strokeWidth;
                })
                .attr("id", function (d) {
                    return d.nodeId
                })
                .attr("fill", function(d) {
                    if(d.selected) return d.consts.selectedColor;
                    return d.consts.standardColor;
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
        svg.selectAll(".selected").remove();
        this.graph.edges = this.graph.edges.filter(el => {
            var result ='';
            if(el.selected) {
                el.nodeStart.edgeDeleted();
                result = false;
            } else {
                result = true;
            }
            return result;
        });
        this.graph.nodes = this.graph.nodes.filter(el => !el.selected);
    }

    removeElement(array, element) {
        return array.filter(el => el !== element);
    }

    changeEdgeModeStatus() {
        function resetSelectedElements(svg) {
            svg.selectAll(".selected").each(function () {
                d3.select(this)
                    .attr("class", function (d) {
                        d.selected = false;
                        return d.consts.classNotSelected;
                    });
            });
    
            svg.selectAll("circle").each(function () {
                d3.select(this)
                    .style("fill", function (d) {
                        return d.consts.standardColor;
                    });
            });
    
            svg.selectAll("line").each(function () {
                d3.select(this)
                    .style("stroke", function (d) {
                        return d.consts.standardColor;
                    });
            });
        }
        this.graph.edgeMode = !this.graph.edgeMode;
        this.edgeModeVariant = this.graph.edgeMode ? buttonVariantSuccess : buttonVariantNeutral ;
        this.edgeModeEnable = this.graph.edgeMode;
        this.graph.clearTempParams();
        const svg = d3.select(this.template.querySelector('svg.d3'));
        resetSelectedElements(svg);
    }

}