import { LightningElement, api } from 'lwc';

export default class CreateStreamFromTemplate extends LightningElement {
    @api recordId;
    @api isLoaded = false;  

    renderedCallback() {
        //  the required business logic to be executed when component is rendered
    }
    
    toggle() {
        this.isLoaded = !this.isLoaded;
    }
}