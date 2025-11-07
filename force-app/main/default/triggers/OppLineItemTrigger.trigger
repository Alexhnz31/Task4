trigger OppLineItemTrigger on OpportunityLineItem (
before insert,
before update,
after update
) {
TriggerFactory.run();
}