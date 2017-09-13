/* RPTAddressTrigger
*  September 2017
*  Trigger to manage RPT Address object used multiple, seasonal address. 
*  Main functionality is to populate addresses to the Contact.MailingAddress
*  and Account.ShippingAddress corresponding with RPT Address record schedules
*/
trigger RPTAddressTrigger on RPT_Address__c (
	before insert, before update)
    {
    // before delete, after delete, after undelete not addressed

    if(RPTAddressTriggerHandler.runOnce())
    {
    
        if( Trigger.isInsert )
        {
            if(Trigger.isBefore)
            {
                RPTAddressTriggerHandler.handleBeforeInsert(Trigger.new);
            }
        }
        else if ( Trigger.isUpdate )
        {
            if(Trigger.isBefore)
            {
        	   RPTAddressTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.Old);
            }
        }
        //else if ( Trigger.isDelete )
        //{
            //if(Trigger.isBefore)
            //{
            //	RPTAddressTriggerHandler.handleBeforeDelete(Trigger.new);
            //}
            //else
            //{
            //	RPTAddressTriggerHandler.handleAfterDelete(Trigger.new);
            //}

        //}
    }

}