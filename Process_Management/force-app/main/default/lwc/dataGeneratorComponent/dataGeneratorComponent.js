import { LightningElement, api } from 'lwc';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';

import toastTitleSuccess from '@salesforce/label/c.TST_TITLE_Success';
import toastTitleError from '@salesforce/label/c.TST_TITLE_Error';

import generateRandomData from '@salesforce/apex/DataGenerator.generateRandomData';
import deleteAllData from '@salesforce/apex/DataGenerator.deleteAllData';

export default class DataGeneratorComponent extends LightningElement {

    @api showSpinner = false;
    
    deleteAllData() {
        this.showSpinner = true;
        deleteAllData({})
        .then(result => {
            if(result.isSuccess) {
                this.fireToastEvent(toastTitleSuccess, result.msg, 'success');
            } else {
                this.fireToastEvent(toastTitleError, result.msg, 'error');
            }
            this.showSpinner = false;
        })
        .catch(error => {
            this.fireToastEvent(toastTitleError, JSON.stringify(error), 'error');
            this.showSpinner = false;
        });
    }

    generateData() {
        this.showSpinner = true;
        generateRandomData({})
        .then(result => {
            if(result.isSuccess) {
                this.fireToastEvent(toastTitleSuccess, result.msg, 'success');
            } else {
                this.fireToastEvent(toastTitleError, result.msg, 'error');
            }
            this.showSpinner = false;
        })
        .catch(error => {
            this.fireToastEvent(toastTitleError, JSON.stringify(error), 'error');
            this.showSpinner = false;
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