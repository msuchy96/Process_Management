/* eslint-disable no-alert */
import { LightningElement, track } from 'lwc';
import cystoscape from '@salesforce/resourceUrl/cytoscapeLibrary';

// importing resource loader
import { loadScript } from 'lightning/platformResourceLoader';
// imported for to show toast messages
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
 
export default class ThirdPartyLibraryDemo extends LightningElement {
    @track error;
    @track successMessage = '';
    svgWidth = 400;
    svgHeight = 400;
 
    renderedCallback() { // invoke the method when component rendered or loaded
        Promise.all([
            loadScript(this, cystoscape) // cytoscape js file
        ])
        .then(() => { 
            this.error = undefined;
            // Call back function if scripts loaded successfully
            this.showSuccessMessage('test2');
        })
        .catch(error => {
            this.error = error;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!!',
                    message: error.message,
                    variant: 'error',
                }),
            );
        });
        
    }

    showSuccessMessage() { // call back method 
        this.successMessage = 'Scripts are loaded successfully!!';
    }
}