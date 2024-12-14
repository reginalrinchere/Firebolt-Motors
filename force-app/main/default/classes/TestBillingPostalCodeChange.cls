@isTest
private class AccountPostalCodeChangeTest {
    
    @isTest
    static void testPostalCodeChange() {
        // Original test setup as is
        List<Territory__c> territories = new List<Territory__c>{
            new Territory__c(Name = 'Territory 1', Zip_Code__c = '67890', Owner__c = UserInfo.getUserId()),
                new Territory__c(Name = 'Territory 2', Zip_Code__c = '67890', Owner__c = UserInfo.getUserId())
                };
                    insert territories;
        
        Account testAccount = new Account(Name = 'Test Account', BillingPostalCode = '12345');
        insert testAccount;
        
        Contact testContact = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = testAccount.Id, OwnerId = UserInfo.getUserId());
        insert testContact;
        
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = testAccount.Id, OwnerId = UserInfo.getUserId());
        insert testOpportunity;
        
        // Change the postal code to trigger the owner update
        testAccount.BillingPostalCode = '67890';
        
        Test.startTest();
        update testAccount; // This will trigger the after update context
        Test.stopTest();
        
        // Re-query to verify changes
        testAccount = [SELECT Id, BillingPostalCode, OwnerId FROM Account WHERE Id = :testAccount.Id];
        System.assertNotEquals('12345', testAccount.BillingPostalCode, 'Postal code was not updated correctly.');
        
        // Verify the Account owner was updated based on the new postal code
        List<Territory__c> updatedTerritories = [SELECT Owner__c FROM Territory__c WHERE Zip_Code__c = '67890'];
        Set<Id> expectedOwners = new Set<Id>{updatedTerritories[0].Owner__c};
            System.assert(expectedOwners.contains(testAccount.OwnerId), 'Account owner was not changed based on the new postal code.');
        
        // Verify that Contacts have been updated with the correct owner
        List<Contact> updatedContacts = [SELECT Id, OwnerId FROM Contact WHERE AccountId = :testAccount.Id];
        for (Contact con : updatedContacts) {
            System.assert(expectedOwners.contains(con.OwnerId), 'Contact owner was not changed to the expected territory owner.');
        }
        
        // Verify that Opportunities have been updated with the correct owner
        List<Opportunity> updatedOpportunities = [SELECT Id, OwnerId FROM Opportunity WHERE AccountId = :testAccount.Id AND StageName NOT IN ('Closed Won','Closed Lost')];
        for (Opportunity opp : updatedOpportunities) {
            System.assert(expectedOwners.contains(opp.OwnerId), 'Opportunity owner was not changed to the expected territory owner.');
        }
    }
    
    @isTest
    static void testNoPostalCodeChange() {
        // Original test setup as is
        List<Territory__c> territories = new List<Territory__c>{
            new Territory__c(Name = 'Territory 2', Zip_Code__c = '12345', Owner__c = UserInfo.getUserId()),
                new Territory__c(Name = 'Territory 2', Zip_Code__c = '12345', Owner__c = UserInfo.getUserId()),
                new Territory__c(Name = 'Territory 2', Zip_Code__c = '12345', Owner__c = UserInfo.getUserId())
                };
                    insert territories;
        
        Account testAccount = new Account(Name = 'Test Account No Change', BillingPostalCode = '12345');
        insert testAccount;
        
        // Simulate no change in postal code
        testAccount.BillingPostalCode = '12345';
        
        Test.startTest();
        update testAccount; // This will not trigger any change in owner
        Test.stopTest();
        
        // Re-query to verify no changes
        Account reVerifiedAccount = [SELECT Id, BillingPostalCode, OwnerId FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('12345', reVerifiedAccount.BillingPostalCode, 'Postal code should remain the same.');
        
        List<Contact> relatedContacts = [SELECT Id, OwnerId FROM Contact WHERE AccountId = :testAccount.Id];
        for (Contact con : relatedContacts) {
            System.assertEquals(UserInfo.getUserId(), con.OwnerId, 'Contact owner should remain unchanged.');
        }
        
        List<Opportunity> relatedOpportunities = [SELECT Id, OwnerId FROM Opportunity WHERE AccountId = :testAccount.Id AND StageName NOT IN ('Closed Won','Closed Lost')];
        for (Opportunity opp : relatedOpportunities) {
            System.assertEquals(UserInfo.getUserId(), opp.OwnerId, 'Opportunity owner should remain unchanged.');
        }
    }
    
    @isTest
    static void testUpdateRelatedOwners() {
        // New test to specifically cover the updateOwners method in an after update context
        List<Territory__c> territories = new List<Territory__c>{
            new Territory__c(Name = 'Territory 3', Zip_Code__c = '12345', Owner__c = UserInfo.getUserId()),
                new Territory__c(Name = 'Territory 4', Zip_Code__c = '67890', Owner__c = UserInfo.getUserId())
                };
                    insert territories;
        
        Account testAccount = new Account(Name = 'Test Account For Owner Update', BillingPostalCode = '12345');
        insert testAccount;
        
        // Create related Contact and Opportunity
        Contact testContact = new Contact(FirstName = 'Jane', LastName = 'Smith', AccountId = testAccount.Id, OwnerId = UserInfo.getUserId());
        insert testContact;
        
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity For Update', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = testAccount.Id, OwnerId = UserInfo.getUserId());
        insert testOpportunity;
        
        // Simulate change in the postal code (which triggers the owner update)
        testAccount.BillingPostalCode = '67890';
        
        Test.startTest();
        // Update the Account, which should fire the trigger
        update testAccount;
        Test.stopTest();
        
        // Re-query to verify updates after the trigger
        testAccount = [SELECT Id, BillingPostalCode, OwnerId FROM Account WHERE Id = :testAccount.Id];
        List<Contact> updatedContacts = [SELECT Id, OwnerId FROM Contact WHERE AccountId = :testAccount.Id];
        List<Opportunity> updatedOpportunities = [SELECT Id, OwnerId FROM Opportunity WHERE AccountId = :testAccount.Id];
        
        // Assert that the Account owner has been updated based on postal code change
        System.assertNotEquals(UserInfo.getUserId(), testAccount.OwnerId, 'Account owner should be updated based on new postal code.');
        
        // Assert that Contacts and Opportunities owner has been updated correctly
        for (Contact con : updatedContacts) {
            System.assertNotEquals(UserInfo.getUserId(), con.OwnerId, 'Contact owner should be updated based on the Account owner.');
        }
        
        for (Opportunity opp : updatedOpportunities) {
            System.assertNotEquals(UserInfo.getUserId(), opp.OwnerId, 'Opportunity owner should be updated based on the Account owner.');
        }
    }
    
    @isTest
    static void testTerritoryOwnerChange() {
        // Test that when the Territory's sales representative (Owner__c) changes, associated Accounts are updated
        List<Territory__c> territories = new List<Territory__c>{
            new Territory__c(Name = 'Territory 5', Zip_Code__c = '12345', Owner__c = '005bm000008TMrlAAG'),
                new Territory__c(Name = 'Territory 6', Zip_Code__c = '12345', Owner__c = UserInfo.getUserId())
                };
                    insert territories;
        
        Account account1 = new Account(Name = 'Test Account 1', BillingPostalCode = '12345');
        Account account2 = new Account(Name = 'Test Account 2', BillingPostalCode = '12345');
        insert new List<Account>{ account1, account2 };
            
            Contact contact1 = new Contact(LastName = 'TestName', AccountId = account1.Id);
        insert contact1;
        
        Opportunity opp = new Opportunity(Name = 'TestOpportunity', CloseDate = Date.today(), StageName = 'Prospecting', AccountId = account1.Id);
        insert opp;
        
        // Link Accounts to Territory (via Zip Code or another relation)
        account1.OwnerId = territories[0].Owner__c;
        account2.OwnerId = territories[1].Owner__c;
        update new List<Account>{ account1, account2 };
            
            contact1.OwnerId = account1.OwnerId;
        update contact1;
        
        opp.OwnerId = account1.OwnerId;
        update opp;
        
        // Simulate Territory Owner change (the sales representative)
        Territory__c territoryToUpdate = territories[0];
        territoryToUpdate.Owner__c = UserInfo.getUserId(); // New owner (different sales rep)
        update territoryToUpdate;
        
        // Re-query the accounts and verify that their owner field is updated accordingly
        account1 = [SELECT Id, OwnerId FROM Account WHERE Id = :account1.Id];
        account2 = [SELECT Id, OwnerId FROM Account WHERE Id = :account2.Id];
        
        System.assertEquals(UserInfo.getUserId(), account1.OwnerId, 'Account 1 owner was not updated after Territory owner change.');
        System.assertEquals(UserInfo.getUserId(), account2.OwnerId, 'Account 2 owner was not updated after Territory owner change.');
    }
}