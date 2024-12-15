trigger accountPostalCodeChange on Account (before update) {
    switch on Trigger.OperationType{
        when BEFORE_UPDATE {
            accountPostalCodeHandler.manageTerritoryOwners(Trigger.new, Trigger.oldMap);
        }
    } 
}
