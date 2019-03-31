import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import D3 from '@salesforce/resourceUrl/d3';

export default class ProcessCreator extends LightningElement {
    svgWidth = 400;
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

    

    initializeCreator() {
        
        const svg = d3.select(this.template.querySelector('svg.d3'));
        const width = this.svgWidth;
        const height = this.svgHeight;
        const color = d3.scaleOrdinal(d3.schemeDark2);

        var GraphCreator = function(svg, nodes, edges) {
            var thisGraph = this;
                thisGraph.idct = 0;

                console.log('teeeeeeest');
        }

        var xLoc = width/2 - 25,
        yLoc = 100;
        
        // initial node data
        var nodes = [{title: "new concept", id: 0, x: xLoc, y: yLoc},
                        {title: "new concept", id: 1, x: xLoc, y: yLoc + 200}];

        var edges = [{source: nodes[1], target: nodes[0]}];

        var graph = new GraphCreator(svg, nodes, edges);
       // graph.setIdCt(2);
        //graph.updateGraph();
    }

    
    


       
}