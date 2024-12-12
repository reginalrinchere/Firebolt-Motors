trigger accountPostalCodeChange on Account (before update) {
    if(Trigger.isUpdate) {
        accountPostalCodeHandler.manageTerritoryOwners(Trigger.new, Trigger.oldMap);
    }  
}