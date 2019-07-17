import {
    LightningElement,
    track,
    api
} from 'lwc';
import getUserJobs from '@salesforce/apex/JobManager.getUserJobs';
import getUserJobsCount from '@salesforce/apex/JobManager.getUserJobsCount';
import getBaseURL from '@salesforce/apex/CommonUtility.getBaseURL';
export default class RecordList extends LightningElement {
    @track jobs;
    @track error;
    @track baseURL;
    @api currentpage;
    @api pagesize;
    totalpages;
    localCurrentPage = null;
    isSearchChangeExecuted = false;
    // not yet implemented  
    pageSizeOptions = [{
            label: '5',
            value: 5
        },
        {
            label: '10',
            value: 10
        },
        {
            label: '25',
            value: 25
        },
        {
            label: '50',
            value: 50
        },
        {
            label: 'All',
            value: ''
        },
    ];

    renderedCallback() {
        // This line added to avoid duplicate/multiple executions of this code.  
        if (this.isSearchChangeExecuted && (this.localCurrentPage === this.currentpage)) {
            return;
        }
        this.isSearchChangeExecuted = true;
        this.localCurrentPage = this.currentpage;

        getBaseURL({}) 
        .then( result => {
            this.baseURL = result + '/';
        })
        
        getUserJobsCount({})
            .then(recordsCount => {
                this.totalrecords = recordsCount;
                if (recordsCount !== 0 && !isNaN(recordsCount)) {
                    this.totalpages = Math.ceil(recordsCount / this.pagesize);
                    getUserJobs({
                            pagenumber: this.currentpage,
                            numberOfRecords: recordsCount,
                            pageSize: this.pagesize,
                        })
                        .then(jobList => {
                            var url = this.baseURL;
                            this.jobs = jobList;
                            this.jobs.forEach(function (item, index) {                                
                                item.Id = url + item.Id;
                                item.Stream__c = url + item.Stream__c;
                                if(item.Due_Date__c !== undefined && item.Due_Date__c !== null && item.Due_Date__c.length > 16) {
                                    item.Due_Date__c = new Date(item.Due_Date__c.substring(0, 4), item.Due_Date__c.substring(5, 7), item.Due_Date__c.substring(8, 10), item.Due_Date__c.substring(11, 13), item.Due_Date__c.substring(14, 16), 0, 0);
                                    item.Due_Date__c = item.Due_Date__c.toString().substring(4,21);
                                }
                            });
                            this.error = undefined;
                        })
                        .catch(error => {
                            this.error = error;
                            this.jobs = undefined;
                        });
                } else {
                    this.jobs = [];
                    this.totalpages = 1;
                    this.totalrecords = 0;
                }
                const event = new CustomEvent('recordsload', {
                    detail: recordsCount
                });
                this.dispatchEvent(event);
            })
            .catch(error => {
                this.error = error;
                this.totalrecords = undefined;
            });
    }
}