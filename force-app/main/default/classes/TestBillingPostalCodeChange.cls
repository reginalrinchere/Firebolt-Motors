@isTest
private class AccountPostalCodeChangeTest {
    @isTest
    static void testPostalCodeChange() {
        
        // Setup: Create territory records
        List<Territory__c> territories = new List<Territory__c>{
            new Territory__c(Name = 'Territory 1', Zip_Code__c = '67890', Owner__c = UserInfo.getUserId()), // Replace with a valid user Id
                new Territory__c(Name = 'Territory 2', Zip_Code__c = '67890', Owner__c = UserInfo.getUserId()) // Replace with a valid user Id
                };
                    insert territories;
        
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account', BillingPostalCode = '12345');
        insert testAccount;
        
        // Setup Contacts and Opportunities related to the account
        Contact testContact = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = testAccount.Id, OwnerId = UserInfo.getUserId());
        insert testContact;
        
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = testAccount.Id, OwnerId = UserInfo.getUserId());
        insert testOpportunity;
        
        // Change the postal code
        testAccount.BillingPostalCode = '67890'; // This should trigger the owner change
        
        Test.startTest();
        update testAccount;
        Test.stopTest();
        
        // Re-query to verify changes
        testAccount = [SELECT Id, BillingPostalCode, OwnerId FROM Account WHERE Id = :testAccount.Id];
        
        System.assertNotEquals('12345', testAccount.BillingPostalCode, 'Postal code was not updated correctly.');
        
        // Verify the OwnerId has been updated based on the zip code
        List<Territory__c> updatedTerritories = [SELECT Owner__c FROM Territory__c WHERE Zip_Code__c = '67890'];        
       
        Set<Id> expectedOwners = new Set<Id>{updatedTerritories[0].Owner__c};
            System.assert(expectedOwners.contains(testAccount.OwnerId), 'Account owner was not changed based on the new postal code.');
       
        // Verify Contacts
        List<Contact> updatedContacts = [SELECT Id, OwnerId FROM Contact WHERE AccountId = :testAccount.Id];
        
        for (Contact con : updatedContacts) {
            System.assert(expectedOwners.contains(con.OwnerId), 'Contact owner was not changed to the expected territory owner.');
        }
        
        // Verify Opportunities
        List<Opportunity> updatedOpportunities = [SELECT Id, OwnerId FROM Opportunity WHERE AccountId = :testAccount.Id AND StageName NOT IN ('Closed Won','Closed Lost')];
       
        for (Opportunity opp : updatedOpportunities) {
            System.assert(expectedOwners.contains(opp.OwnerId), 'Opportunity owner was not changed to the expected territory owner.');
        }
    }
    
    @isTest
    static void testNoPostalCodeChange() {
        
        // Setup: Create territory records
        List<Territory__c> territories = new List<Territory__c>{
            new Territory__c(Name = 'Territory 2', Zip_Code__c = '12345', Owner__c = UserInfo.getUserId()), // Replace with a valid user Id
                new Territory__c(Name = 'Territory 2', Zip_Code__c = '12345', Owner__c = UserInfo.getUserId()) // Replace with a valid user Id
                };
                    insert territories;
        
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account No Change', BillingPostalCode = '12345');
        insert testAccount;
        
        // Change of postal code with no change in value
        testAccount.BillingPostalCode = '12345'; // This should not trigger any change.
        
        Test.startTest();
        update testAccount;
        Test.stopTest();
        
        // Re-query to verify no changes
        Account reVerifiedAccount = [SELECT Id, BillingPostalCode, OwnerId FROM Account WHERE Id = :testAccount.Id];
        
        System.assertEquals('12345', reVerifiedAccount.BillingPostalCode, 'Postal code should remain the same.');
        // No assertion on OwnerId since it should remain unchanged, we can also directly check for updates.
        
        // Check that no related contacts or opportunities were updated
        List<Contact> relatedContacts = [SELECT Id, OwnerId FROM Contact WHERE AccountId = :testAccount.Id];
       
        for (Contact con : relatedContacts) {
            System.assertEquals(UserInfo.getUserId(), con.OwnerId, 'Contact owner should remain unchanged.');
        }
        
        List<Opportunity> relatedOpportunities = [SELECT Id, OwnerId FROM Opportunity WHERE AccountId = :testAccount.Id AND StageName NOT IN ('Closed Won','Closed Lost')];
        
        for (Opportunity opp : relatedOpportunities) {
            System.assertEquals(UserInfo.getUserId(), opp.OwnerId, 'Opportunity owner should remain unchanged.');
        }
    }
}