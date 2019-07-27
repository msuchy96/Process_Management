@isTest
private class CommonUtilityTest {

    @isTest 
    static void getRecordTypeIdErrorHandling() {
        try {
            Id resultID = CommonUtility.getRecordTypeId(CommonUtility.SOBJECT_APINAME_ACCOUNT, CommonUtility.JOB_TYPE_STANDARD);
        } catch (Exception e) {
            System.assert(e.getMessage().contains(CommonUtility.NO_SUCH_RT_FOUND));
        }

        try {
            Id resultID = CommonUtility.getRecordTypeId(null, CommonUtility.JOB_TYPE_STANDARD);
        } catch (Exception e) {
            System.assert(e.getMessage().contains(CommonUtility.OBJECTNAME_AND_RT_NEEDS_TO_BE_DELIVERED));
        }
    }
    
}
