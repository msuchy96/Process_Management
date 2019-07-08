import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import submitDueDateApproval from '@salesforce/apex/ManageApprovalProcess.submitDueDateApproval';

export default class SubmitDueDateForApproval extends LightningElement {
    @api recordId;

    updateAndSubmitApproval() {
        var inputCmp = this.template.querySelector(".inputCmp");
        var value = inputCmp.value;

        submitDueDateApproval({ jobId: this.recordId, dueDateToChange: value })
        .then(result => {
            if(result.isSuccess) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: result.msg,
                        variant: 'success',
                    }),
                );
            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: result.msg,
                        variant: 'Error',
                    }),
                );
            }
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: JSON.stringify(error),
                    variant: 'Error',
                }),
            );
        });
    }

}