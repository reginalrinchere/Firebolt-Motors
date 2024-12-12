trigger validateTerritoryOwners on Territory__c (before update) {
    
    List<String> zipCodes = new List<String>();
    
    for (Territory__c terr : Trigger.new) {
        zipcodes.add(terr.Zip_Code__c);
    }
    
    List<Territory__c> territories = [SELECT Zip_Code__c, Owner__c FROM Territory__c WHERE Zip_Code__c IN :zipCodes];
    
    Map<String, List<Id>> zipToOwner = new Map<String, List<Id>>();
    
    for (Territory__c territory : territories) {
        if (!zipToOwner.containsKey(territory.Zip_Code__c)) {
            zipToOwner.put(territory.Zip_Code__c, new List<Id>());            
        }
        zipToOwner.get(territory.Zip_Code__c).add(territory.Owner__c);
    }
    
    for (Territory__c terr : Trigger.new) {
        List<Id> owners = ziptoOwner.get(terr.Zip_Code__c);
        if (owners.size() > 2) {
            terr.addError('No more than three Sales Representatives can be assigned to a zip code.');
        }
    }
}