/* DailyRPTAddressUpdater 
*  September 2017
*  Scheduler for identifying Address schedules that begin or end today
*  in order to update Contact.MailingAddress and Account.ShippingAddress accordingly
*/
global class DailyRPTAddressUpdater implements Schedulable
{
	//public static String CRON_EXP = '0 0 1 ? * *';


	global static void execute(SchedulableContext sc)
    {
    	// Build today's date to check for active RPT Addresses wit Intervals begining or ending today
    	Integer currentMonthNumber = System.Today().month();  
    	String currentMonth = RPTAddress.ConvertNumberToMonthName(currentMonthNumber);

    	String currentDay = String.valueOf( System.Today().day() );
    
    	// Query for Addresses with intervals that start or end today
    	// Inactive addresses will get filtered in handler method
        List<RPT_Address__c> addresses = [Select ID, Name, Start_Month__c, Start_Day__c, End_Month__c, End_Day__c, Inactive__c, Contact__c,
                                          Street__c, City__c, State__c, Postal_Code__c, Country__c, Is_Current_Address__c
        	                              FROM RPT_Address__c
            	                          WHERE (Start_Month__c =: currentMonth AND Start_Day__c =: currentDay) OR
                	                      (End_Month__c =: currentMonth AND End_Day__c =: currentDay)];
                                        
    	system.debug('List RPT Addresses:' + addresses);
      
    	// Send addresses to handler method to populate Contact.MailingAddress and Account.ShippingAddress
        RPTAddress.UpdateMailingAddress(addresses);
        
        // Update Is Current Address - handler built for before insert/update
        // so it doesn't update
        for(RPT_Address__c b : addresses)
        {
        	b.Is_Current_Address__c = true;
        }
        
		update addresses;
        
	}  
}