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
        var curGraph = this.graph = new Graph(nodes);
        var edgeMode = this.edgeMode;
        console.log('edge mode: ' + this.edgeMode);
        
        svg.on('click', function() {
            svg.selectAll("circle").remove();
            console.log('edge mode status: ' + curGraph.edgeMode);
            console.log('click!!');

            if (!curGraph.edgeMode) {
                console.log('edge mode status2: ' + curGraph.edgeMode);
                var coords = d3.mouse(this);
                curGraph.addNode(coords);
            }              
                
            svg.selectAll("circle")
                .data(curGraph.nodes)
                .enter()
                .append("circle")
                .attr("cx", function(d) {
                    return d.x_pos;
                })
                .attr("cy", function(d) {
                    return d.y_pos;
                })
                .attr("r", function(d) {
                    return d.consts.radius;
                })
                .attr("stroke", "black")
                .attr("stroke-width", 1)
                .attr("id", function(d) {
                    return d.nodeId
                })
                .style("fill", function(d) {
                    return d.consts.color;
                })
                .on("click", selectNode)
                .call(d3.drag()
                    .on("start", dragstarted)
                    .on("drag", dragged)
                    .on("end", dragended)
                );
        });

        function selectNode() {
            d3.event.stopPropagation();
            var selectedID = d3.select(this).attr("id");
            console.log('circle clicked w/ ID: ' + selectedID);

            var clickedCircle = this;
            svg.selectAll("circle").each(function() {
                var currCircle = this;
                d3.select(this)
                .attr("class", function(d) {
                    return currCircle === clickedCircle && !curGraph.edgeMode ? "selected" : "notSelected";
                })
                .style("fill", function(d) {        
                    var color = '';
                    if (currCircle === clickedCircle) {
                        if(curGraph.edgeMode) {
                            curGraph.startNodeForEdge = d;
                            color = 'green';
                        } else {
                            curGraph.selectedElement = d;
                            color = "blue";
                        }
                    } else {
                        color = "gray";
                    }
                    return color;
                });
            });

            if(curGraph.edgeMode) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Build an enge!',
                        message: 'Please select secont node to build edge.',
                        variant: 'info'
                    })
                );
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
        svg.selectAll(".selected").each(function() {
            d3.select(this)
                .attr("class", function(d) {
                    return "notSelected";
                });
        });

        svg.selectAll("circle").each(function() {
            d3.select(this)
                .style("fill", function(d) {        
                    return "gray";
                });
        });

        
    }


   
}