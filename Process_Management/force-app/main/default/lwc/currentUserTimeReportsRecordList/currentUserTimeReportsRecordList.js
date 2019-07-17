import {
    LightningElement,
    track,
    api
} from 'lwc';
import getUserTimeReports from '@salesforce/apex/TimeReportManager.getUserTimeReports';
import getUserTimeReportsCount from '@salesforce/apex/TimeReportManager.getUserTimeReportsCount';
import getBaseURL from '@salesforce/apex/CommonUtility.getBaseURL';


export default class CurrentUserTimeReportsRecordList extends LightningElement {
    @track timeReports;
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
        
        getUserTimeReportsCount({})
            .then(recordsCount => {
                this.totalrecords = recordsCount;
                if (recordsCount !== 0 && !isNaN(recordsCount)) {
                    this.totalpages = Math.ceil(recordsCount / this.pagesize);
                    getUserTimeReports({
                            pagenumber: this.currentpage,
                            numberOfRecords: recordsCount,
                            pageSize: this.pagesize,
                        })
                        .then(timeReportList => {
                            var url = this.baseURL;
                            this.timeReports = timeReportList;
                            
                            this.timeReports.forEach(function (item, index) {                                
                                item.Id = url + item.Id;
                                item.Job__c = url + item.Job__c;
                            });
                            this.error = undefined;
                        })
                        .catch(error => {
                            this.error = error;
                            this.timeReports = undefined;
                        });
                } else {
                    this.timeReports = [];
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