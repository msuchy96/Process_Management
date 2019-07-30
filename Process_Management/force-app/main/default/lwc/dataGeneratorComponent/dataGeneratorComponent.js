import { LightningElement } from 'lwc';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';

import toastTitleSuccess from '@salesforce/label/c.TST_TITLE_Success';
import toastTitleError from '@salesforce/label/c.TST_TITLE_Error';

import generateRandomData from '@salesforce/apex/DataGenerator.generateRandomData';
import deleteAllData from '@salesforce/apex/DataGenerator.deleteAllData';

export default class DataGeneratorComponent extends LightningElement {
    
    deleteAllData() {
        deleteAllData({})
        .then(result => {
            if(result.isSuccess) {
                this.fireToastEvent(toastTitleSuccess, result.msg, 'success');
            } else {
                this.fireToastEvent(toastTitleError, result.msg, 'error');
            }
        })
        .catch(error => {
            this.fireToastEvent(toastTitleError, JSON.stringify(error), 'error');
        });
    }

    generateData() {
        generateRandomData({})
        .then(result => {
            if(result.isSuccess) {
                this.fireToastEvent(toastTitleSuccess, result.msg, 'success');
            } else {
                this.fireToastEvent(toastTitleError, result.msg, 'error');
            }
        })
        .catch(error => {
            this.fireToastEvent(toastTitleError, JSON.stringify(error), 'error');
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