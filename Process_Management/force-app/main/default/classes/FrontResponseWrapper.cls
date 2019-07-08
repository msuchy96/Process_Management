public with sharing class FrontResponseWrapper {
    @AuraEnabled
	public Boolean isSuccess {get; set;}
    @AuraEnabled
    public String msg {get; set;}
	@AuraEnabled
	public String dataJSON {get; set;}

	public FrontResponseWrapper(Boolean isSuccess, String msg) {
		this.isSuccess = isSuccess;
		this.msg = msg;
	}

	public FrontResponseWrapper(Boolean isSuccess, String msg, String dataJSON) {
		this.isSuccess = isSuccess;
		this.msg = msg;
		this.dataJSON = dataJSON;
	}
}