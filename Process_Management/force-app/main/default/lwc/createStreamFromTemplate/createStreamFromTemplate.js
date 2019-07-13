import { LightningElement, api } from 'lwc';

import toastTitleSuccess from '@salesforce/label/c.TST_TITLE_Success';
import toastTitleError from '@salesforce/label/c.TST_TITLE_Error';

import cloneStreamWithJobs from '@salesforce/apex/JobManager.cloneStreamWithJobs';

export default class CreateStreamFromTemplate extends LightningElement {
    @api recordId;
    @api isLoaded = false;  

    renderedCallback() {
        //  the required business logic to be executed when component is rendered

        cloneStreamWithJobs({streamId: this.recordId})
        .then(result => {
            if(result.isSuccess) {
                this.fireToastEvent(toastTitleSuccess, result.msg, 'success');
                this.isLoaded = true;  
            } else {
                this.fireToastEvent(toastTitleError, result.msg, 'error');
                this.isLoaded = true;  
            }
        })
        .catch(error => {
            this.fireToastEvent(toastTitleError, JSON.stringify(error), 'error');
            this.isLoaded = true;  
        });
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