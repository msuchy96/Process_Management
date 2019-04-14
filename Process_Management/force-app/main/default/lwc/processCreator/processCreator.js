/* eslint-disable vars-on-top */
/* global d3 */
import {
    LightningElement
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

    d3Initialized = false;

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
        var curGraph = new Graph(nodes);
        var selectedNode = null;

        svg.on('click', function() {
            svg.selectAll("*").remove();
            var coords = d3.mouse(this);
            console.log('click!!');
            curGraph.addNode(coords);

            svg.selectAll("circle")
                .data(curGraph.nodes)
                .enter().append("circle")
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
                    return d.nodeId })
                .style("fill", function(d) {
                    return d.consts.color;
                })
                .on("click", onClick)
                .call(d3.drag()
                    .on("start", dragstarted)
                    .on("drag", dragged)
                    .on("end", dragended));
        });


        function onClick() {
            d3.event.stopPropagation();
            var selectedID = d3.select(this).attr("id");
            console.log('circle clicked w/ ID: ' + selectedID);

            var clickedCircle = this;
            svg.selectAll("circle").each(function() {
                var currCircle = this;
                d3.select(this).style("fill", function(d) {
                    if(currCircle === clickedCircle) {
                        curGraph.selectedNode = d;
                        return "blue";
                    } return "gray";
                });
            });

            console.log('selected node:' + JSON.stringify(curGraph.selectedNode));

            /*
            curGraph.nodes.forEach(node => {
                console.log('compare: .'  + node.nodeId + '.' + selectedID +'.');
                console.log('compare result: '  + isNaN(node.nodeId) + ' ' + isNaN(selectedID));
                if(node.noteId == selectedID) {
                    console.log('picked nodee:'  + node);
                    node.selected = true;
                    selectedNode = node;
                } else {
                    console.log('not this node :'  + node);
                    node.selected = false;
                }
            });
            */
        }
        
        function dragstarted(d) {
            d3.select(this).raise().classed("active", true);
        }

        function dragged(d) {
            var x = Math.max(d.consts.radius, Math.min(1000-d.consts.radius, d3.event.x));
            var y = Math.max(d.consts.radius, Math.min(400-d.consts.radius, d3.event.y));
            console.log('drag2.2' + JSON.stringify(d));
            d3.select(this).attr("cx", d.x_pos = x).attr("cy", d.y_pos = y);
        }

        function dragended(d) {
            d3.select(this).classed("active", false);
        }

    }

}