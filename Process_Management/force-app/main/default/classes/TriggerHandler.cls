public with sharing class TriggerHandler{

    public interface Delegate {
        void prepareBefore();
        void prepareAfter();

        void beforeInsert(List<sObject> o);
        void beforeUpdate(Map<Id, sObject> old, Map<Id, sObject> o);
        void beforeDelete(Map<Id, sObject> o);

        void afterInsert(Map<Id, sObject> o);
        void afterUpdate(Map<Id, sObject> old, Map<Id, sObject> o);
        void afterDelete(Map<Id, sObject> o);
        void afterUndelete(Map<Id, sObject> o);

        void finish();
    }

    public abstract class DelegateBase implements Delegate {

        public virtual void prepareBefore() {}
        public virtual void prepareAfter() {}

        public virtual void beforeInsert(List<sObject> o) {}
        public virtual void beforeUpdate(Map<Id, sObject> old, Map<Id, sObject> o) {}
        public virtual void beforeDelete(Map<Id, sObject> o) {}

        public virtual void afterInsert(Map<Id, sObject> o) {}
        public virtual void afterUpdate(Map<Id, sObject> old, Map<Id, sObject> o) {}
        public virtual void afterDelete(Map<Id, sObject> o) {}
        public virtual void afterUndelete(Map<Id, sObject> o) {}

        public virtual void finish() {}

    }

    public static void execute(Delegate d) {
        if (Trigger.isBefore) {
            d.prepareBefore();

            if (Trigger.isInsert) {
                d.beforeInsert(Trigger.new);
            } else if (Trigger.isUpdate) {
                d.beforeUpdate(Trigger.oldMap, Trigger.newMap);
            } else if (Trigger.isDelete) {
                d.beforeDelete(Trigger.oldMap);
            }
        } else {
            d.prepareAfter();
            if (Trigger.isInsert) {
                d.afterInsert(Trigger.newMap);
            } else if (Trigger.isUpdate) {
                d.afterUpdate(Trigger.oldMap, Trigger.newMap);
            } else if (Trigger.isDelete) {
                d.afterDelete(Trigger.oldMap);
            }
            else if (Trigger.isUndelete) {
                d.afterUndelete(Trigger.newMap);
            }
        }
        d.finish();
    }
}