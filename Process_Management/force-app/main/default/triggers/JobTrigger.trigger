trigger JobTrigger on Job__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete)
{
    TriggerHandler.execute(new TH_JobTrigger());
}