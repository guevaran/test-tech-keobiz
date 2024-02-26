@isTest
public class AccountTriggerHandler_TEST {
    @isTest
    static void testAfterUpdate() {
        // Prepare test data
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();

        accounts.add(new Account(Name = 'Acc A1', MissionStatus__c = 'active'));
        accounts.add(new Account(Name = 'Acc A2', MissionStatus__c = 'active'));
        accounts.add(new Account(Name = 'Acc B1', MissionStatus__c = 'active'));
        accounts.add(new Account(Name = 'Acc B2', MissionStatus__c = 'canceled'));
        accounts.add(new Account(Name = 'Acc B3', MissionStatus__c = 'canceled'));

        contacts.add(new Contact(LastName = 'Con A1', IsActive__c = true));
        contacts.add(new Contact(LastName = 'Con B1', IsActive__c = true));

        insert accounts;
        insert contacts;

        List<AccountContactRelation__c> acrs = new List<AccountContactRelation__c>();

        acrs.add(new AccountContactRelation__c(Account__c = accounts[0].Id, Contact__c = contacts[0].Id));
        acrs.add(new AccountContactRelation__c(Account__c = accounts[1].Id, Contact__c = contacts[0].Id));
        acrs.add(new AccountContactRelation__c(Account__c = accounts[2].Id, Contact__c = contacts[1].Id));
        acrs.add(new AccountContactRelation__c(Account__c = accounts[3].Id, Contact__c = contacts[1].Id));
        acrs.add(new AccountContactRelation__c(Account__c = accounts[4].Id, Contact__c = contacts[1].Id));

        insert acrs;

        System.assertEquals(true, contacts[0].IsActive__c);
        System.assertEquals(true, contacts[1].IsActive__c);

        Test.setMock(HttpCalloutMock.class, new ContactDBWebService_MOCK());

        // Update the accounts
        Test.startTest();
        Account[] accsToUpdate = [SELECT Id, MissionStatus__c FROM Account WHERE Name IN ('Acc A1', 'Acc B1')];
        accsToUpdate[0].MissionStatus__c = 'canceled';
        accsToUpdate[1].MissionStatus__c = 'canceled';
        update accsToUpdate;
        Test.stopTest();

        Contact[] cons = [SELECT Id, IsActive__c FROM Contact WHERE LastName IN ('Con A1', 'Con B1')];
        System.assertEquals(true, cons[0].IsActive__c);
        System.assertEquals(false, cons[1].IsActive__c);
    }
}