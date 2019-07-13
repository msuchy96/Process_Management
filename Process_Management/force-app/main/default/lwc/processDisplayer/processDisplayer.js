/* eslint-disable vars-on-top */
/* global d3 */
import {
    LightningElement, api, track
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

// Import custom labels
import errorLoadingMsg from '@salesforce/label/c.D3_ErrorLoading';
import toastTitleError from '@salesforce/label/c.TST_TITLE_Error';

// Apex methods
import retrieveJSONStreamDescription from '@salesforce/apex/ProcessCreatorController.retrieveJSONStreamDescription';

export default class ProcessDisplayer extends LightningElement {

    @track svg;
    @track curGraph;
    @api recordId;

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
                this.fireToastEvent(errorLoadingMsg, error.message, 'error');
            });
    }

    initializeCreator() {
        this.svg = d3.select(this.template.querySelector('svg.d3'));
        this.defineDefaults();
        this.curGraph = null;
        if(this.recordId) {
            this.retrieveStream();
        }
    }

    retrieveStream() {
        retrieveJSONStreamDescription({streamId: this.recordId})
            .then(result => {
                this.curGraph = this.prepareGraphFromJSON(result.dataJSON);
                this.clearAndRedrawGraph();
            })
            .catch(error => {
                this.fireToastEvent(toastTitleError, JSON.stringify(error), 'error');
            });
    }

    prepareGraphFromJSON(dataJSON) {
        let parsedGraphFromJSON = JSON.parse(dataJSON);
        let tempNodes = [];
        let tempEdges = [];
        let tempNodesMap = new Map();
        parsedGraphFromJSON.nodes.forEach(function (node) {
            let tempNode = new Node(node.x_pos, node.y_pos, node.edgeCounter, node.selected, node.jobId, node.Name, node.status)
            tempNodes.push(tempNode);
            tempNodesMap.set(tempNode.jobId, tempNode);
        });
        parsedGraphFromJSON.edges.forEach(function (edge) {
            tempEdges.push(new Edge(tempNodesMap.get(edge.nodeStart.jobId), tempNodesMap.get(edge.nodeEnd.jobId), edge.selected));
        });
        return new Graph(tempNodes, tempEdges, parsedGraphFromJSON.streamId);
    }

    clearAndRedrawGraph() {
        this.svg.selectAll("circle").remove();
        this.svg.selectAll("line").remove();
        this.svg.selectAll("text").remove();
        this.drawEdges();
        this.drawNodes();
        this.drawLabels();
        this.curGraph.clearTempParams();
    }

    drawEdges() {
        this.svg.selectAll("line")
            .data(this.curGraph.edges)
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
            .attr("stroke-width", function (d) {
                return d.consts.strokeWidth;
            })
            .attr("stroke", function(d) {
                if(d.selected) return d.consts.selectedColor;
                return d.consts.standardColor;
            })
            .attr('marker-end', 'url(#marker)');
    }

    drawNodes() {
        this.svg.selectAll("circle")
            .data(this.curGraph.nodes)
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
                if(d.selected) this.curGraph.selectedJobId = d.jobId;
                return d.jobId;
            })
            .attr("fill", function(d) {
                var color = '';
                if(d.selected) {
                    color = d.consts.selectedColor;
                } else if(d.jobId !== '') {
                    switch(d.status) {
                        case d.consts.statusTODO:
                            color = d.consts.savedColorTODO;
                        break;
                        case d.consts.statusINPROGRESS:
                            color = d.consts.savedColorINPROGRESS;
                        break;
                        case d.consts.statusDONE:
                            color = d.consts.savedColorDONE;
                        break;
                        default:
                            color = d.consts.standardColor;
                    }
                } else {
                    color = d.consts.standardColor;
                }
                return color;
            });
    }

    drawLabels() {
        this.svg.selectAll("text")
            .data(this.curGraph.nodes)
            .enter()
            .append("text")
            .attr("class", function(d) {
                if(d.selected) return d.consts.classSelected;
                return d.consts.classNotSelected;
            })
            .attr("x", function(d) {
                var nameLength = d.Name === undefined || d.Name === null ? 0 : d.Name.length;
                return d.x_pos - nameLength * d.consts.labelXTranslation; 
            })
            .attr("y", function(d) {
                return d.y_pos + d.consts.labelYTranslation;
            })
            .text(function(d) {
                return d.Name;
            })
            .attr("font-family", "sans-serif")
            .attr("font-size", "15px")
            .attr("fill", "black");
    }

    defineDefaults() {
        this.svg.append('defs').append('marker')
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

    fireToastEvent(title, msg, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: msg,
                variant: variant
            })
        );
    }
}