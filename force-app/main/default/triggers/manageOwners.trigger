trigger manageOwners on Territory__c (after insert, after update) {
    switch on Trigger.OperationType{
        when AFTER_INSERT {
            manageTerritoryOwners.validateTerritoryOwners(Trigger.new);
        }
        when AFTER_UPDATE {
            updateRelatedRecords.updateOwners(Trigger.new, Trigger.oldMap);
        }
    }
}