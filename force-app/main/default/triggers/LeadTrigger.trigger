trigger LeadTrigger on Lead (before insert, 
    before update, 
    after update
) {
    TriggerFactory.run();
}