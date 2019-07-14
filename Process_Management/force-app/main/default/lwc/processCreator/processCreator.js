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
import streamCreator from '@salesforce/label/c.BTN_StreamCreator';
import deleteSelectedElement from '@salesforce/label/c.BTN_DeleteElement';
import edgeMode from '@salesforce/label/c.BTN_EdgeMode';
import buttonVariantNeutral from '@salesforce/label/c.BTN_VariantNeutral';
import buttonVariantSuccess from '@salesforce/label/c.BTN_VariantSuccess';
import toastTitleSuccess from '@salesforce/label/c.TST_TITLE_Success';
import toastTitleError from '@salesforce/label/c.TST_TITLE_Error';
import toastTitleNotPossible from '@salesforce/label/c.TST_TITLE_EdgeCreationNotPossible';
import toastMsgJobSaved from '@salesforce/label/c.TST_MSG_JobSaved';
import toastMsgStreamSaved from '@salesforce/label/c.TST_MSG_StreamSaved';
import toastMsgJobNotSaved from '@salesforce/label/c.TST_MSG_JobsNotSaved';
import toastMsgSameNode from '@salesforce/label/c.TST_MSG_SameNode';
import toastMsgEdgeExist from '@salesforce/label/c.TST_MSG_EdgeExist';
import toastMsgTwoEdgesExist from '@salesforce/label/c.TST_MSG_JobHasTwoEdges';

// Apex methods
import deleteSelectedJob from '@salesforce/apex/ProcessCreatorController.deleteSelectedJob';
import createConnectionBetweenJobs from '@salesforce/apex/ProcessCreatorController.createConnectionBetweenJobs';
import saveStreamAsTemplate from '@salesforce/apex/ProcessCreatorController.saveStreamAsTemplate';
import updateStreamJSONDescription from '@salesforce/apex/ProcessCreatorController.updateStreamJSONDescription';
import retrieveJSONStreamDescription from '@salesforce/apex/ProcessCreatorController.retrieveJSONStreamDescription';

export default class ProcessCreator extends LightningElement {
    d3Initialized = false;
    @track edgeModeVariant = buttonVariantNeutral;
    @track configureJobVariant = buttonVariantNeutral;
    @track disableDeleteElementButton = false;
    @track disableEdgeModeButton = false;
    @track disableConfigureJobButton = false;

    @track configureJobEnable = false;
    @api recordId;

    @track selectedJobId;
    @track showJobFormArea = false;
    @track showStreamFormArea;
    @track cardTitle = streamCreator;

    @track streamName;
    @track streamClient;
    @track streamTemplate = false;

    label = {
        deleteSelectedElement,
        edgeMode
    };

    renderedCallback() {
        if (this.d3Initialized) {
            return;
        }
        this.d3Initialized = true;
        this.showStreamFormArea = !this.valueValidation(this.recordId);

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

    // define graphcreator object 
    initializeCreator() {
        const svg = d3.select(this.template.querySelector('svg.d3'));

        var svgWidth = svg.style("width");
        var svgHeight = svg.style("height");
        svgWidth = parseInt(svgWidth.substring(0, svgWidth.length-2), 10);
        svgHeight = parseInt(svgHeight.substring(0, svgHeight.length-2), 10);

        var curGraph = null;
        defineDefaults();
        if(this.recordId) {
            retrieveJSONStreamDescription({streamId: this.recordId})
            .then(result => {
                curGraph = this.graph = prepareGraphFromJSON(result.dataJSON);
                this.streamTemplate = curGraph.template;
                clickBehaviour();
                clearAndRedrawGraph();
            })
            .catch(error => {
                fireToastEvent(toastTitleError, JSON.stringify(error), 'error');
            });
        } else {
            var nodes = [];
            var edges = [];
            curGraph = this.graph = new Graph(nodes, edges);
            clickBehaviour();
        }

        function prepareGraphFromJSON(dataJSON) {
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
            return new Graph(tempNodes, tempEdges, parsedGraphFromJSON.streamId, parsedGraphFromJSON.template);
        }

        function clickBehaviour() {
            svg.on('click', function () {
                this.selectedJobId = null;
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
            curGraph.selectedJobId = null;
            if (curGraph.edgeMode) {
                if (!valueValidation(curGraph.startNodeForEdge)) {
                    firstNodeInEdgeModeSelection();
                } else { // create edge
                    var edgeCreationValidation = checkIfNodeCreationIsPossible();
                    if(edgeCreationValidation.isPossible) {
                        createEdge();
                    } else {
                        fireToastEvent(toastTitleNotPossible, edgeCreationValidation.msg, 'error');
                    }
                }
            } else {
                normalNodeSelection();
            }

            function checkIfNodeCreationIsPossible() {
                var secondSelectedCircle = null;
                let response = {
                    'isPossible': true,
                    'msg': ''
                };
                d3.select(clickedCircle).attr("class", function (d) { 
                    secondSelectedCircle = d; 
                });
                if(!checkIfSecondNodeIsNotFirst(secondSelectedCircle)) {
                    response.isPossible = false;
                    response.msg = toastMsgSameNode;
                } else if (!checkIfEdgeNotExist(secondSelectedCircle)) {
                    response.isPossible = false;
                    response.msg = toastMsgEdgeExist;
                } else if (!checkIfNodesAreSaved(secondSelectedCircle)) {
                    response.isPossible  = false;
                    response.msg = toastMsgJobNotSaved;
                } else if (!checkNumberOfNodes(secondSelectedCircle)) {
                    response.isPossible  = false;
                    response.msg = toastMsgTwoEdgesExist;
                }
                return response;
            }

            function checkIfSecondNodeIsNotFirst(secondSelectedCircle) {
                return curGraph.startNodeForEdge !== secondSelectedCircle;
            }

            function checkIfEdgeNotExist(secondSelectedCircle) {
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
                return !nodeExist;
            }
            
            function checkIfNodesAreSaved(secondSelectedCircle) {
                return valueValidation(curGraph.startNodeForEdge.jobId) && valueValidation(secondSelectedCircle.jobId);
            }
            
            function checkNumberOfNodes() {
                return curGraph.startNodeForEdge.edgeCounter !== 2;
            }

            function valueValidation(variable) {
                return (variable !== null && variable !== undefined && variable !== '');
            }

            function createEdge() {
                var secondSelectedCircle = null;
                d3.select(clickedCircle).attr("class", function (d) { 
                    secondSelectedCircle = d; 
                });

                createConnectionBetweenJobs({firstJobId: curGraph.startNodeForEdge.jobId, secondJobId: secondSelectedCircle.jobId})
                .then(result => {
                    if(result.isSuccess) {
                        curGraph.addEdge(curGraph.startNodeForEdge, secondSelectedCircle);
                        clearAndRedrawGraph();
                        fireToastEvent(toastTitleSuccess, result.msg, 'success');
                        updateStreamJSON(curGraph);
                    } else {
                        fireToastEvent(toastTitleError, result.msg, 'error');
                    }
                })
                .catch(error => {
                    fireToastEvent(toastTitleError, JSON.stringify(error), 'error');
                });
            }

            function normalNodeSelection() {
                curGraph.selectedJobId = null;
                deselectAllEdges();
                svg.selectAll("circle").each(function () {
                    var currCircle = this;
                    d3.select(this)
                        .attr("class", function (d) {
                            if (currCircle === clickedCircle) {
                                d.selected = true;
                                curGraph.selectedJobId = d.jobId;
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
                            } else if(valueValidation(d.jobId)){
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
                });
            }
        }

        function selectEdge() {
            d3.event.stopPropagation();
            var clickedEdge = this;
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

            svg.selectAll("text").each(function() {
                d3.select(this)
                .attr("x", function(d) {                    
                    var nameLength = d.Name === undefined || d.Name === null ? 0 : d.Name.length;
                    return d.x_pos - nameLength * d.consts.labelXTranslation; 
                })
                .attr("y", function(d) {
                    return d.y_pos + d.consts.labelYTranslation;
                })
            });
        }

        function dragended() {
            d3.select(this).classed("active", false);
            updateStreamJSON(curGraph);
        }

        function deselectAllNodes() {
            svg.selectAll("circle").each(function () {
                d3.select(this)
                    .attr("class", function (d) {
                       d.selected = false;
                    });
            });
            curGraph.selectedJobId = null;
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
            svg.selectAll("text").remove();
            drawEdges();
            drawNodes();
            drawLabels();
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
                    if(d.selected) curGraph.selectedJobId = d.jobId;
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
                })
                .on("click", selectNode)
                .call(d3.drag()
                    .on("start", dragstarted)
                    .on("drag", dragged)
                    .on("end", dragended)
                );
        }

        function drawLabels() {
            svg.selectAll("text")
                .data(curGraph.nodes)
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

        function updateStreamJSON(graph) {
            updateStreamJSONDescription({jsonStream: JSON.stringify(graph), streamId: graph.streamId})
            .then(result => {
                if(result.isSuccess) {
                    console.log(result.msg);
                } else {
                    this.fireToastEvent(toastTitleSuccess, result.msg, 'error');
                }
            })
            .catch(error => {
                this.fireToastEvent(toastTitleError, JSON.stringify(error), 'error');
            });
        }

        function fireToastEvent(title, msg, variant) {
            dispatchEvent(
                new ShowToastEvent({
                    title: title,
                    message: msg,
                    variant: variant
                })
            );
        }

    }

    deleteSelectedElement() {
        this.selectedJobId = this.graph.selectedJobId;
        if(this.selectedJobId !== '' && this.selectedJobId !== undefined && this.selectedJobId !== null) {
            deleteSelectedJob({jobId: this.selectedJobId})
            .then(result => {
                if(result.isSuccess) {
                    this.fireToastEvent(toastTitleSuccess, result.msg, 'success');
                    this.removeNodeFromSVG();
                    this.updateStreamJSON(this.graph);
                } else {
                    this.fireToastEvent(toastTitleError, result.msg, 'error');
                }
            })
            .catch(error => {
                this.fireToastEvent(toastTitleError, JSON.stringify(error), 'error');
            });
        } else {
            this.removeNodeFromSVG();
            this.updateStreamJSON(this.graph);
        }
    }

    removeNodeFromSVG() {
        const svg = d3.select(this.template.querySelector('svg.d3'));
        svg.selectAll(".selected").remove();
        this.graph.edges = this.graph.edges.filter(el => {
            var keepThisNode = '';
            if(el.selected) {
                el.nodeStart.edgeDeleted();
                keepThisNode = false;
            } else {
                keepThisNode = true;
            }
            return keepThisNode;
        });
        this.graph.nodes = this.graph.nodes.filter(el => !el.selected);
        this.selectedJobId = null;
        this.graph.selectedJobId = null;
        this.updateStreamJSON(this.graph);
    }

    changeEdgeModeStatus() {
        this.graph.edgeMode = !this.graph.edgeMode;
        this.edgeModeVariant = this.graph.edgeMode ? buttonVariantSuccess : buttonVariantNeutral ;
        this.disableDeleteElementButton = this.disableConfigureJobButton = this.graph.edgeMode;
        this.graph.clearTempParams();
        this.resetSelectedElements();
    }

    resetSelectedElements() {
        const svg = d3.select(this.template.querySelector('svg.d3'));
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
                    var color = '';
                    if(d.jobId === '') {
                        color = d.consts.standardColor;
                    } else {
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
                    }
                    return color;
                });
        });
        svg.selectAll("line").each(function () {
            d3.select(this)
                .style("stroke", function (d) {
                    return d.consts.standardColor;
                });
        });
        svg.selectAll("text").each(function () {
            d3.select(this)
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
                .attr("font-family", function(d) {
                    return d.consts.labelFont;
                })
                .attr("font-size",function(d) {
                    return d.consts.labelSize;
                })
                .attr("fill", function(d) {
                    return d.consts.labelFill;
                });
        });
        this.selectedJobId = null;
        this.graph.selectedJobId = null;
    }

    openForm() {
        const svg = d3.select(this.template.querySelector('svg.d3'));
        var tempShowFormArea = false;
        var tempJobId = '';
        svg.selectAll("circle").each(function () {
            d3.select(this)
                .attr("class", function (d) {
                    if (d.selected) {
                        tempShowFormArea = true;
                        tempJobId = d.jobId;
                    } 
                });
        });
        this.showJobFormArea = tempShowFormArea;
        this.selectedJobId = tempJobId;
    }

    handleSavingJobSuccess(event) {
        var upsertedJobId = event.detail.id;
        var upsertedName = event.detail.fields.Name.value;
        var upsertedStatus = null;
        if(JSON.stringify(event.detail.fields).includes('Status__c')) {
            upsertedStatus = event.detail.fields.Status__c.value;
        }
        this.updateAttributesToSelectedNode(upsertedJobId, upsertedName, upsertedStatus);
        this.selectedJobId = upsertedJobId;
        this.showJobFormArea = false;
        this.resetSelectedElements();
        this.fireToastEvent(toastTitleSuccess, toastMsgJobSaved, 'success');
        this.updateStreamJSON(this.graph);
    }

    handleSavingStreamSuccess(event) {
        this.recordId = event.detail.id;
        this.showStreamFormArea = false;
        this.graph.streamId = this.recordId;
        this.fireToastEvent(toastTitleSuccess, toastMsgStreamSaved, 'success');
    }

    updateStreamNameValue(event) {
        this.streamName = event.detail.value;
        this.cardTitle = streamCreator + ': ' + this.streamName;
    }

    updateStreamJSON(graph) {
        updateStreamJSONDescription({jsonStream: JSON.stringify(graph), streamId: graph.streamId})
        .then(result => {
            if(result.isSuccess) {
                console.log(result.msg);
            } else {
                this.fireToastEvent(toastTitleSuccess, result.msg, 'error');
            }
        })
        .catch(error => {
            this.fireToastEvent(toastTitleError, JSON.stringify(error), 'error');
        });
    }

    updateStreamClientValue(event) {
        this.streamClient = event.detail.value;
    }

    valueValidation(variable) {
        return (variable !== null && variable !== undefined && variable !== '');
    }

    submitTemplate(event) {
        let streamClientToConnect = this.valueValidation(this.streamClient) ? this.streamClient.toString() : null;
        saveStreamAsTemplate({streamNameSelection: this.streamName, streamClientId: streamClientToConnect})
        .then(result => {
            if(result.isSuccess) {
                this.graph.streamId = this.recordId = JSON.parse(result.dataJSON);
                this.streamTemplate = true;
                this.graph.template = true;
                this.fireToastEvent(toastTitleSuccess, result.msg, 'success');
                this.showStreamFormArea = false;
            } else {
               this.fireToastEvent(toastTitleError, result.msg, 'error');
            }
        })
        .catch(error => {
            this.fireToastEvent(toastTitleError, JSON.stringify(error), 'error');
        });
    }

    updateAttributesToSelectedNode(jobId, upsertedName, upsertedStatus) {
        const svg = d3.select(this.template.querySelector('svg.d3'));
        if(jobId !== null && upsertedName !== null) {
            svg.selectAll("circle").each(function () {
                d3.select(this)
                    .attr("class", function (d) {
                        if (d.selected) {
                            d.jobId = jobId;
                            d.Name = upsertedName;
                            if(upsertedStatus !== null) d.status = upsertedStatus;
                        }
                    });
            });
        }
    }

    removeElement(array, element) {
        return array.filter(el => el !== element);
    }

    closeJobModal() {
        this.showJobFormArea = !this.showJobFormArea;
    }

    closeStreamModal() {
        this.showStreamFormArea = false;
        this.disableDeleteElementButton = true;
        this.disableConfigureJobButton = true;
        this.disableEdgeModeButton = true;
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