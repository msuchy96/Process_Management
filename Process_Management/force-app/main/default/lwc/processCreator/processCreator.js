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

// Import custom labels
import errorLoadingMsg from '@salesforce/label/c.D3_ErrorLoading';
import streamCreator from '@salesforce/label/c.BTN_StreamCreator';
import deleteSelectedElement from '@salesforce/label/c.BTN_DeleteElement';
import edgeMode from '@salesforce/label/c.BTN_EdgeMode';
import buttonVariantNeutral from '@salesforce/label/c.BTN_VariantNeutral';
import buttonVariantSuccess from '@salesforce/label/c.BTN_VariantSuccess';
import toastTitleSuccess from '@salesforce/label/c.TST_TITLE_Success';
import toastTitleError from '@salesforce/label/c.TST_TITLE_Error';
import toastMsgJobSaved from '@salesforce/label/c.TST_MSG_JobSaved';

// Apex methods
import deleteSelectedJob from '@salesforce/apex/ProcessCreatorController.deleteSelectedJob';

export default class ProcessCreator extends LightningElement {
    d3Initialized = false;
    @api edgeModeVariant = buttonVariantNeutral;
    @api configureJobVariant = buttonVariantNeutral;
    @api edgeModeEnable = false;
    @api configureJobEnable = false;
    @track selectedJobId;
    @track streamId = 'a011t00000AOQy9AAH';
    @track assignId = '0051t000002KZfRAAW';
    @track showFormArea = false;

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
                this.fireToastEvent(errorLoadingMsg, error.message, 'error');
            });
    }

    handleSuccess(event) {
        var upsertedJobId = event.detail.id;
        var upsertedName = event.detail.Name;
        this.assignJobIdToSelectedNode(upsertedJobId, upsertedName);
        this.selectedJobId = upsertedJobId;
        this.showFormArea = false;
        this.resetSelectedElements();
        this.fireToastEvent(toastTitleSuccess, toastMsgJobSaved, 'success');
    }

    assignJobIdToSelectedNode(jobId, upsertedName) {
        const svg = d3.select(this.template.querySelector('svg.d3'));
        svg.selectAll("circle").each(function () {
            d3.select(this)
                .attr("class", function (d) {
                    if (d.selected) {
                        d.jobId = jobId;
                        d.Name = upsertedName;
                    }
                });
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
            console.log('selected node  ' + JSON.stringify(clickedCircle));
            curGraph.selectedJobId = null;
            if (curGraph.edgeMode) {
                if (curGraph.startNodeForEdge == null) {
                    firstNodeInEdgeModeSelection();
                } else { // create edge
                    var edgeCreationValidation = checkIfNodeCreationIsPossible();
                    if(edgeCreationValidation.isPossible) {
                        createEdge();
                    } else {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Edge creation is not possible',
                                message: edgeCreationValidation.msg,
                                variant: 'error'
                            })
                        );
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
                    response.msg = 'You can not create edge to the same node!';
                } else if (!checkIfEdgeNotExist(secondSelectedCircle)) {
                    response.isPossible = false;
                    response.msg = 'Edge already exist!';
                } else if (!checkIfSecondNodeIsSaved(secondSelectedCircle)) {
                    response.isPossible  = false;
                    response.msg = 'Job is not saved!';
                } else if (!checkNumberOfNodes(secondSelectedCircle)) {
                    response.isPossible  = false;
                    response.msg = 'This job already has two edges!';
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
            
            function checkIfSecondNodeIsSaved(secondSelectedCircle) {
                return (secondSelectedCircle.jobId !== '' && secondSelectedCircle.jobId !== undefined && secondSelectedCircle.jobId != null);
            }
            function checkNumberOfNodes() {
                return curGraph.startNodeForEdge.edgeCounter !== 2;
            }

            function createEdge() {
                console.log('create Edge to the : ' + JSON.stringify(clickedCircle));
                var secondSelectedCircle = null;
                d3.select(clickedCircle).attr("class", function (d) { 
                    secondSelectedCircle = d; 
                });
                curGraph.addEdge(curGraph.startNodeForEdge, secondSelectedCircle);
                clearAndRedrawGraph();
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
          //  drawLabels();
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
            var selectedtempJobId = '123';
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
                    if(d.selected) curGraph.selectedtempJobId = d.jobId;
                    return d.jobId;
                })
                .attr("fill", function(d) {
                    if(d.selected) return d.consts.selectedColor;
                    if(d.jobId !== '') return d.consts.savedColor;
                    return d.consts.standardColor;
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
                .attr("x", function(d) {
                    return d.x_pos; 
                })
                .attr("y", function(d) {
                    return d.y_pos;
                })
                .text(function(d) {
                    return d.name;
                })
                .attr("font-family", "sans-serif")
                .attr("font-size", "20px")
                .attr("fill", "black");
        }
    }

    deleteSelectedElement() {
        console.log('selected job id to deletion: ' + this.graph.selectedJobId);
        this.selectedJobId = this.graph.selectedJobId;
        if(this.selectedJobId !== '' && this.selectedJobId !== undefined && this.selectedJobId !== null) {
            deleteSelectedJob({jobId: this.selectedJobId})
            .then(result => {
                if(result.isSuccess) {
                    this.fireToastEvent(toastTitleSuccess, result.msg, 'success');
                    this.removeNodeFromSVG();
                } else {
                    this.fireToastEvent(toastTitleError, result.msg, 'error');
                }
            })
            .catch(error => {
                this.fireToastEvent(toastTitleError, JSON.stringify(error), 'error');
            });
        } else {
            this.removeNodeFromSVG();
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
    }

    removeElement(array, element) {
        return array.filter(el => el !== element);
    }

    changeEdgeModeStatus() {
        this.graph.edgeMode = !this.graph.edgeMode;
        this.edgeModeVariant = this.graph.edgeMode ? buttonVariantSuccess : buttonVariantNeutral ;
        this.edgeModeEnable = this.graph.edgeMode;
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
                    return d.jobId === '' ? d.consts.standardColor : d.consts.savedColor;
                });
        });

        svg.selectAll("line").each(function () {
            d3.select(this)
                .style("stroke", function (d) {
                    return d.consts.standardColor;
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
        this.showFormArea = tempShowFormArea;
        this.selectedJobId = tempJobId;
    }

    closeModal() {
        this.showFormArea = !this.showFormArea;
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