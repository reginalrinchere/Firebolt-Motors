public class accountPostalCodeHandler {
    public static void manageTerritoryOwners(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        
        List<String> updatedZipCodes = new List<String>();        
        List<Assignment_History__c> newAssignmentRecords = new List<Assignment_History__c>();        
        Set<Id> accountIds = new Set<Id>();
        
        for (Account newAccount : newAccounts) {      
            
            //Collect zipcodes from accounts where the BillingPostalCode field is populated for the first time or changed to a new value.
            if ((oldAccounts.get(newAccount.Id).BillingPostalCode == Null && newAccount.BillingPostalCode != Null) ||
                (oldAccounts.get(newAccount.Id).BillingPostalCode != newAccount.BillingPostalCode)) {
                    updatedZipCodes.add(newAccount.BillingPostalCode);
                    accountIds.add(newAccount.Id);
                }
        }
        
        //Being mindful of governor limits by performing a single query against our updatedZipCodes collection.
        List<Territory__c> relatedTerritories = [SELECT Owner__c, Zip_Code__c FROM Territory__c WHERE Zip_Code__c IN :updatedZipCodes];
        
        //Here will will exit the code if no territories are found to avoid unnecessary processing.
        if (relatedTerritories.isEmpty()) {
            return;
        }
        
        //We will use this map to set the ownerId on our account records to match the owner field on related territory records.
        Map<String, Id> zipCodeToOwnerMap = new Map<String, Id>();      
        
        //Set the key/value pair on our maps.
        for (Territory__c terr : relatedTerritories) {
            zipCodeToOwnerMap.put(terr.Zip_Code__c, terr.Owner__c);
        }
        
        //This map will be used to determine the number of salesreps per zipcode territory.
        Map<String, List<Id>> repsPerZipCodeMap = new Map<String, List<Id>>();
        
        // Map<String, List<Id>> terrOwner = new Map<String, List<Id>>();
        for (Territory__c terr : relatedTerritories) {
            if (!repsPerZipCodeMap.containsKey(terr.Zip_Code__c)) {
                repsPerZipCodeMap.put(terr.Zip_Code__c, new List<Id>());
            }
            repsPerZipCodeMap.get(terr.Zip_Code__c).add(terr.Owner__c);
        }
        
        for (Account newAccount : newAccounts) {
            if ((oldAccounts.get(newAccount.Id).BillingPostalCode == Null && newAccount.BillingPostalCode != Null) ||
                (oldAccounts.get(newAccount.Id).BillingPostalCode != newAccount.BillingPostalCode)) {
                    
                    Id ownerId = zipCodeToOwnerMap.get(newAccount.BillingPostalCode);                    
                    List<String> repsPerZipCode = repsPerZipCodeMap.get(newAccount.BillingPostalCode);
                    
                    if (repsPerZipCode.size() > 1) {
                        Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), repsPerZipCode.size());
                        Id selectedOwner = repsPerZipCode[randomIndex];
                        newAccount.OwnerId = selectedOwner;
                    } else {
                        if(ownerId != null) {
                            newAccount.OwnerId = ownerId;
                        }
                    }
                    
                    Assignment_History__c History = new Assignment_History__c();  
                    History.Previous_Owner__c = oldAccounts.get(newAccount.Id).OwnerId;
                    History.New_Owner__c = newAccount.OwnerId;
                    History.Changed_By__c = UserInfo.getUserId();
                    History.Account__c = newAccount.Id;
                    
                    List<Territory__c> newTerritories = [SELECT Id FROM Territory__c WHERE Zip_Code__c = :newAccount.BillingPostalCode];
                    List<Territory__c> previousTerritories = [SELECT Id FROM Territory__c WHERE Zip_Code__c = :oldAccounts.get(newAccount.Id).BillingPostalCode];
                    
                    if (!previousTerritories.isEmpty()) {
                        history.Previous_Territory__c = previousTerritories[0].Id;
                    }                    
                    if (!newTerritories.isEmpty()) {
                        history.New_Territory__c = newTerritories[0].Id;
                    }
                    newAssignmentRecords.add(History);
                }
        }  
        
        
        //Create a map to set the ownerId on related opportunity and contact records to match account ownerIds.
        Map<Id, Id> setOwnerId = new Map<Id, Id>();
        for (Account newAccount : newAccounts) {
            if ((oldAccounts.get(newAccount.Id).BillingPostalCode == Null && newAccount.BillingPostalCode != Null) ||
                (oldAccounts.get(newAccount.Id).BillingPostalCode != newAccount.BillingPostalCode)) {
                    newAccount.OwnerId = zipCodeToOwnerMap.get(newAccount.BillingPostalCode);
                    setOwnerId.put(newAccount.Id, newAccount.OwnerId);
                }
        }
        
        //Pull related contacts while running a single SOQL query against our accountIds collection to avoid receiving a limit exception.
        List<Contact> relatedContacts = [SELECT OwnerId, AccountId FROM Contact WHERE AccountId IN :accountIds];
        
        //We are using bulkification here by storing our updated contacts that will be persisted with a single DML execution.
        List<Contact> updatedContacts = new List<Contact>();
        
        //Here we will use a for each to loop through our relatedContacts which stores our SOQL query results and match the account ownerid.
        for (Contact con : relatedContacts) {
            con.OwnerId = setOwnerId.get(con.AccountId);
            updatedContacts.add(con);
        }
        
        //We will do the same with related opportunities.
        List<Opportunity> relatedOpportunities = [SELECT OwnerId, AccountId, StageName FROM Opportunity WHERE AccountId IN :accountIds];
        
        //We are utilizing bulkification here as well.
        List<Opportunity> updatedOpportunities = new List<Opportunity>();
        
        //Again we are doing the same with related opportunities in this for each.
        for (Opportunity opp : relatedOpportunities) {
            if (opp.StageName != 'Closed Won' && opp.StageName != 'Closed Lost') {
                opp.OwnerId = setOwnerId.get(opp.AccountId);
                updatedOpportunities.add(opp);
            }
        }
        
        if (!updatedContacts.isEmpty()) {
            update updatedContacts;
        }
        
        if (!updatedOpportunities.isEmpty()) {
            update updatedOpportunities;
        }
        
        if (!newAssignmentRecords.isEmpty()) {
            insert newAssignmentRecords;
        }
    }  
}