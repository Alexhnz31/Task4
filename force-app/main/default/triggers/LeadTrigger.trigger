trigger LeadTrigger on Lead (before insert, before update) {
    TriggerFactory.run();
}