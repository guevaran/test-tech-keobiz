public without sharing class AccountTriggerHandler implements TriggerHandler {
    private boolean triggerIsExecuting;
    private integer triggerSize;
    public AccountTriggerHelper helper;
    
    public AccountTriggerHandler(boolean triggerIsExecuting, integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.helper = new AccountTriggerHelper();
    }

    public void beforeInsert(List<Account> newAccounts) {}
    public void afterInsert(List<Account> newAccounts, Map<ID, SObject> newAccountMap) {}


    public void beforeUpdate(List<Account> oldAccounts, List<Account> newAccounts, Map<ID, SObject> oldAccountMap, Map<ID, SObject> newAccountMap) {
        for (Account acc : newAccounts) {
            Account oldAcc = (Account) oldAccountMap.get(acc.Id);
            // If MissionStatus changed to 'canceled' then set MissionCanceledDate
            if (acc.MissionStatus__c == 'canceled' && oldAcc.MissionStatus__c != 'canceled') {
                acc.MissionCanceledDate__c = Date.today();
            }
        }
    }
    
    public void afterUpdate(List<Account> oldAccounts, List<Account> newAccounts, Map<ID, SObject> oldAccountMap, Map<ID, SObject> newAccountMap) {
        Account[] canceledAccs = new Account[]{};
        for (Account acc : newAccounts) {
            Account oldAcc = (Account) oldAccountMap.get(acc.Id);
            // If MissionStatus changed to 'canceled'
            if (acc.MissionStatus__c == 'canceled' && oldAcc.MissionStatus__c != 'canceled') {
                canceledAccs.add(acc);
            }
        }
        Set<Id> canceledAccIds = (new Map<Id,Account>(canceledAccs)).keySet();

        List<AccountContactRelation__c> linkedACRs = [SELECT Id, Account__c, Contact__c FROM AccountContactRelation__c WHERE Account__c IN :canceledAccIds];
        Set<Id> contactIds = new Set<Id>();

        System.debug('linkedACRs: ' + linkedACRs);
        
        for (AccountContactRelation__c arc : linkedACRs) {
            contactIds.add(arc.Contact__c);
        }
        // Contacts by id
        Map<Id,Contact> contactsById = new Map<Id,Contact>([SELECT Id, IsActive__c FROM Contact WHERE Id IN :contactIds]);
        // Contacts by accountId
        Map<Id,Contact[]> contactsByAccId = new Map<Id,Contact[]>();
        for (AccountContactRelation__c arc : linkedACRs) {
            if (!contactsByAccId.containsKey(arc.Account__c)) {
                contactsByAccId.put(arc.Account__c, new List<Contact>());
            }
            contactsByAccId.get(arc.Account__c).add(contactsById.get(arc.Contact__c));
        }

        System.debug('contactsByAccId: ' + contactsByAccId);
        
        // Aggregated query to know if all accounts linked to a contact are canceled or not
        AggregateResult[] groupedACRByContact = [SELECT Contact__c, COUNT(Account__c) nbAccs, MIN(Account__r.MissionStatus__c) minStatus, COUNT_DISTINCT(Account__r.MissionStatus__c) nbDiffStatus FROM AccountContactRelation__c WHERE Contact__c IN :contactIds GROUP BY Contact__c];
        Map<Id,Boolean> isAllAccsCanceledByContactId = new Map<Id,Boolean>();
        for (AggregateResult ar : groupedACRByContact) {
            Id contactId = (Id) ar.get('Contact__c');
            // Number of accounts linked to the contact
            Integer nbAccs = (Integer) ar.get('nbAccs');
            // Number of different status in the list of accounts (1 if only canceled status or only active status and 2 if both)
            Integer nbDiffStatus = (Integer) ar.get('nbDiffStatus');
            // Minimal status ('active' if there is still active accounts or 'canceled' if there is only canceled accounts)
            String minStatus = (String) ar.get('minStatus');
            // if (minStatus == 'canceled' && nbDiffStatus == 1) then all mission status are canceled
            isAllAccsCanceledByContactId.put(contactId, (minStatus == 'canceled' && nbDiffStatus == 1));
        }

        System.debug('isAllAccsCanceledByContactId: ' + isAllAccsCanceledByContactId);

        List<Contact> contactsToDisable = new List<Contact>();

        // Loop through accounts with mission status changed to 'canceled' in this transaction
        for (Id accId : contactsByAccId.keySet()) {
            // Loop through contacts linked to those accounts
            for (Contact contact : contactsByAccId.get(accId)) {
                System.debug('isAllAccsCanceledByContactId.get('+contact.Id+'): '+ contactsToDisable);
                if (isAllAccsCanceledByContactId.get(contact.Id)) {
                    contactsToDisable.add(new Contact(Id = contact.Id, IsActive__c = false));
                }
            }
        }

        System.debug('contactsToDisable: ' + contactsToDisable);

        // Disable contacts
        Database.SaveResult[] contactSaveResults = Database.update(contactsToDisable, false);
        Set<Id> disabledContactIds = new Set<Id>();
        for (Database.SaveResult sr : contactSaveResults) {
            if (sr.isSuccess()) {
                disabledContactIds.add(sr.getId());
            } else {
                System.debug('Error disabling contact ' + sr.getId() + ' : ' + sr.getErrors());
            }
        }

        // Send disabled contacts to the external ContactDB system
        if (!disabledContactIds.isEmpty()) {
            AccountTriggerHelper.sendContactInactiveInfo(new List<Id>(disabledContactIds));
        }
    }

    public void beforeDelete(List<Account> oldAccounts, Map<ID, SObject> oldAccountMap) {}
    public void afterDelete(List<Account> oldAccounts, Map<ID, SObject> oldAccountMap) {}
    public void afterUndelete(List<Account> newAccounts, Map<ID, SObject> newAccountMap) {}
}