import { 
    LightningElement,
    api
} from 'lwc';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
import {
    NavigationMixin 
} from 'lightning/navigation';

import toastTitleSuccess from '@salesforce/label/c.TST_TITLE_Success';
import toastTitleError from '@salesforce/label/c.TST_TITLE_Error';

import cloneStreamWithJobs from '@salesforce/apex/JobManager.cloneStreamWithJobs';

export default class CreateStreamFromTemplate extends NavigationMixin(LightningElement) {
    @api recordId;
    @api isLoaded = false;  

    renderedCallback() {
        if(this.isLoaded) {
            return;
        }
        cloneStreamWithJobs({streamId: this.recordId})
        .then(result => {
            if(result.isSuccess) {
                this.fireToastEvent(toastTitleSuccess, result.msg, 'success');
                this.isLoaded = true;
                this.navigateToRecordViewPage(result.dataJSON)  
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

    navigateToRecordViewPage(streamId) {
        // View a custom object record.
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: streamId,
                objectApiName: 'Stream__c',
                actionName: 'view'
            }
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