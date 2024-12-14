public class updateRelatedRecords {
    public static void updateOwners (List<Territory__c> newTerritories, Map<Id, Territory__c> oldTerritoryMap) {
        
        Set<Id> accIds = new Set<Id>();
        Map<String, Id> zipToOwnerMap = new Map<String, Id>();
        Map<Id, Id> accountToOwnerMap = new Map<Id, Id>();
        
        for (Territory__c terr : newTerritories) {
            zipToOwnerMap.put(terr.Zip_Code__c, terr.Owner__c);
        }
        
        if (zipToOwnerMap.keySet().isEmpty()) {
            return;
        }
        
        Set<String> zip = zipToOwnerMap.keySet();
        
        List<Account> accounts = [SELECT BillingPostalCode, OwnerId FROM Account WHERE BillingPostalCode IN :zip];
        
        List<Account> accountsToUpdate = new List<Account>();
        
        for (Account acc : accounts) {
            accIds.add(acc.Id);
            if (acc.OwnerId != zipToOwnerMap.get(acc.BillingPostalCode)) {
                acc.OwnerId = zipToOwnerMap.get(acc.BillingPostalCode);
                system.debug(acc.OwnerId);
                accIds.add(acc.Id);
                accountToOwnerMap.put(acc.Id, acc.OwnerId);
                accountsToUpdate.add(acc);
            }
        }   
        
        List<Contact> contacts = [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accIds];
        List<Contact> contactsToUpdate = new List<Contact>();
        
        for (Contact con : contacts) {
            con.OwnerId = accountToOwnerMap.get(con.AccountId);
            contactsToUpdate.add(con);
        } 
        
        List<Opportunity> opportunity = [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :accIds];
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        
        for (Opportunity opp : opportunity) {
            opp.OwnerId = accountToOwnerMap.get(opp.AccountId);
            opportunitiesToUpdate.add(opp);
        }
        
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
        
        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }
        
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    } 
}