import {
    LightningElement,
    track,
    api
} from 'lwc';
import getUserJobs from '@salesforce/apex/JobManager.getUserJobs';
import getUserJobsCount from '@salesforce/apex/JobManager.getUserJobsCount';
export default class RecordList extends LightningElement {
    @track jobs;
    @track error;
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
                            this.jobs = jobList;
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