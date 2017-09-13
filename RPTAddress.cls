/* RPTAddress Handler Methods
*  September 2017
*  Methods to manage updating addresses on scheudle, insert and update
*  Called from RPTAddressTriggerHandler and DailyRPTAddressUpdater
*/
public without sharing class RPTAddress 
{

    /******************************************************/
    /* Validate that Start Month, Start Day, End Month    */
    /* and End Day are populated and not the dame day     */
    /******************************************************/
    public static void ValidateStartAndEndDates ( List<RPT_Address__c> addresses)
    {
        for(RPT_Address__c a : addresses)
        {
        	if(!IsIntervalComplete(a))
    	    {
        		a.addError('Valid start and end dates must be supplied');
                system.debug('Start Date must be before End Date');
            }
        } 
    }


    /******************************************************/
    /* Confirm before insert or before update that the    */
    /* RPT Address interval doesn't overlap with an       */
    /* existing RPT Address interval                      */
    /******************************************************/
    public static void CheckForOverlappingIntervals ( List<RPT_Address__c> addresses)
    {
    	// Query all RPT Addresses on Contact
        List<RPT_Address__c> allAddresses = [Select ID, Name, Start_Month__c, Start_Day__c, End_Month__c, End_Day__c, Inactive__c FROM RPT_Address__c]; // ??? add LIMIT 1000
    
    	for(RPT_Address__c a : addresses)
    	{
        
			// Iterate through all RPT Address on Contact to confirm intervals do not overlap 
            for(RPT_Address__c b : allAddresses)
			{
                // Don't compare to self - in case of update 
                // No need to check against Inactive RPT Addresses
				if(a.Id != b.Id && !a.Inactive__c  && !b.Inactive__c &&
                   a.Start_Month__c != null && a.End_Month__c != null && 
                   b.Start_Month__c != null && a.End_Month__c != null) 
				{
                    // Declare variables required to translate picklists for comparison
					Integer aStartMonth, aEndMonth, bStartMonth, bEndMonth;
					Integer aStartYear, aEndYear, bStartYear, bEndYear;


					// Convert picklist values to numbers  
                    aStartMonth = ConvertMonthNameToNumber(a.Start_Month__c);
					aEndMonth = ConvertMonthNameToNumber(a.End_Month__c);
					bStartMonth = ConvertMonthNameToNumber(b.Start_Month__c);
					bEndMonth = ConvertMonthNameToNumber(b.End_Month__c);

					// Determine if intervals are overlapping by checking if each 
                    // interval start date occurs within other interval
                    if(IsInInterval(aStartMonth, integer.valueof(a.Start_Day__c), aEndMonth, integer.valueof(a.End_Day__c), bStartMonth, integer.valueof(b.Start_Day__c)) ||
					IsInInterval(bStartMonth, integer.valueof(b.Start_Day__c), bEndMonth, integer.valueof(b.End_Day__c), aStartMonth, integer.valueof(a.Start_Day__c)) )
					{
                        a.addError('The dates specifeid overlap with an existing RPT Address');
						system.debug(a.Name + ' and ' + b.Name +' are overlaping');	
					}
					else
					{
    					system.debug(a.Name + ' and ' + b.Name +' are discreet');
                        // add error
					}

   				}
   			}
   		}
   	}


    /******************************************************/
    /* Inserted/updated RPT Addresses with                */
    /* Start Date < Today < End Date should update the    */
    /* Contact.MailiingAddress and Account.ShippingAddress*/
    /******************************************************/
    public static void UpdateMailingAddress ( List<RPT_Address__c> addresses)
    {
		// Create a Set of Contact IDs from RPT Addresses to retrieve for update
		Set<Id> addressContactIDs = new Set<Id>();
    
		// Build today's date to check if Today is in the RPT Address interval
        Integer currentMonth = System.Today().month();
		Integer currentDay = System.Today().day();

        Integer aStartMonth, aEndMonth, bStartMonth, bEndMonth;

        // Iterate through the triggered RPT Addresses
		for(RPT_Address__c a : addresses)
		{
            // Convert picklist values to numbers for comparison
            aStartMonth = ConvertMonthNameToNumber(a.Start_Month__c);
            aEndMonth = ConvertMonthNameToNumber(a.End_Month__c);

            // Filter for only Triggered Addresses that Is Current
            // and where today is in the RPT Address interval
			if( a.Inactive__c == false &&

            IsInInterval (aStartMonth, integer.valueof(a.Start_Day__c), aEndMonth, integer.valueof(a.End_Day__c), currentMonth, currentDay))
            {
                // Add Contact ID to Set
				addressContactIDs.add(a.Contact__c);
            }
		}

        system.debug('Contact IDs for all Trigger Addresses with current intervals:' + addressContactIDs);

        // Confirm there are Contacts to update
        if(addressContactIDs.size() > 0)
        {
            // Query Contacts related to RPT Addresses that require updating
            List<Contact> addressContacts = [Select ID, AccountId, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Disable_Multiple_Address_Functionality__c FROM Contact WHERE Contact.Id IN :addressContactIDs];
            system.debug('addressContacts ' + addressContacts);
            
            // Build a  set or AccountIDs to query for update
            Set<Id> addressAccountIDs = new Set<Id>();

            // Build a map of Account IDs and related Contacts to push
            // Contact.MailingAddress to Account.ShippingAddress
            Map<Id, Contact> contactIDAccountID = new Map<Id, Contact>();

            for(RPT_Address__c b : addresses)
            {
                // Convert picklist values to numbers for comparison
                bStartMonth = ConvertMonthNameToNumber(b.Start_Month__c);
                bEndMonth = ConvertMonthNameToNumber(b.End_Month__c);

                // Filter for only Triggered Addresses that Is Current
                // and where today is in the RPT Address interval
                if( b.Inactive__c == false &&
                IsInInterval (bStartMonth, integer.valueof(b.Start_Day__c), bEndMonth, integer.valueof(b.End_Day__c), currentMonth, currentDay))
                {
                    // Iterate of find related Contact and update MailingAddress
                    for(Contact c : addressContacts)
                    {
                        // Only update related Contact
                        // and where mulitple address functionality is not disabled in Contact
                        if(b.Contact__c == c.id && c.Disable_Multiple_Address_Functionality__c == false)
                        {
                            c.MailingStreet = b.Street__c;
                            c.MailingCity = b.City__c;
                            c.MailingState = b.State__c;
                            c.MailingPostalCode = b.Postal_Code__c;
                            c.MailingCountry = b.Country__c;
                            b.Is_Current_Address__c = true;     //  !!!!!!!!!!!!!!!!!!!!
                            addressAccountIDs.add(c.AccountId);
                            contactIDAccountID.put(c.AccountId, c);
                            system.debug('Updating' + c.Id + ' with ' + b.Id);
 
                        }
                    }
                }
            }

            update addressContacts;

            // On to querying the Accounts for update
           
            if(addressAccountIDs.size() > 0)
            {
                List<Account> addressAccounts = [Select ID, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode FROM Account WHERE Account.Id IN :addressAccountIDs];
                system.debug('addressAccounts '+ addressAccounts);

                for(Account d : addressAccounts)
                {
                    Contact childContact = new Contact();
                    childContact = contactIDAccountID.get(d.Id);
                    // check functionality is disabled in Contact
                    if(childContact.Disable_Multiple_Address_Functionality__c == false)
                    {
                        d.ShippingStreet = childContact.MailingStreet;
                        d.ShippingCity = childContact.MailingCity;
                        d.ShippingState = childContact.MailingState;
                        d.ShippingPostalCode = childContact.MailingPostalCode;
                        // c.MailingCountry;     !!!!!!!!!!!!!!!!!!!!!
                    
                    }
                //try {
                    update addressAccounts;
                //} catch(Exception ex) {
                    //system.debug('Error occurred while perfoming DML Operation :::::'+ ex.getMessage());
                //}
                }
            
            }   
        }  
    }


    /******************************************************/
    /* Confirm all date fields are populated and Start    */
    /* Date != End Date                                   */
    /******************************************************/
	private static boolean IsIntervalComplete(RPT_Address__c address) {

		return (address.Start_Month__c != null && 
			address.Start_Day__c != null && 
			address.End_Day__c != null && 
			address.End_Month__c != null &&
			!(address.Start_Month__c == address.End_Month__c && address.Start_Day__c == address.End_Day__c)
		);

	}


    /******************************************************/
    /* Determine if first date is before, after or equal to  */
    /* second date                                        */
    /******************************************************/
	public static integer CompareDates (Integer aMonth, Integer aDay, Integer bMonth, Integer bDay)
    {
    	if(aMonth < bmonth || (aMonth == bMonth && aDay < bDay))
    		return 1; // a before b
    	else if(aMonth == bMonth && aDay == bDay)
			return 0; // a == b
		else
			return 2; // b before a 
	}


    /******************************************************/
    /* Determine if test date occurs within the interval  */ 
    /* by the start and end dates                         */
    /******************************************************/
	public static boolean IsInInterval (Integer startMonth, Integer startDay, Integer endMonth, Integer endDay, Integer testMonth, Integer testDay)
    {
    	// Two simlpe tests!
        // For intervals that don't span the calendar year (don't extend past Dec 31 into next year)
        // IsInInterval if start date < test date < end date
        // For intervals that do extend past Dec 31 we test the inverse
        // !IsInInterval if end date < test date < start date
    	if(CompareDates( startMonth, startDay, endMonth, endDay) <= 1) // Interval doesn't span calendar year
    	{
    		if(CompareDates( startMonth, startDay, testMonth, testDay) <= 1 &&
    			CompareDates( testMonth, testDay, endMonth, endDay) <= 1) // testDate occurs in interval
    		{
				system.debug('testDate occurs in interval');
				return true;
			}
			else
			{
				system.debug('testDate occurs outside interval');
				return false;
			}


    	} 
    	else
    	{
			if(CompareDates( startMonth, startDay, testMonth, testDay) == 2 &&
    			CompareDates( testMonth, testDay, endMonth, endDay) == 2) // testDate occurs outside interval
			{
				system.debug('testDate occurs outside interval');
				return false;
			}
			else
			{
				system.debug('testDate occurs inside interval');
				return true;
			}
    	}

	}


    /******************************************************/
    /* Nice touch to have Month names instead of numbers  */
    /* Convert to month numbers for comparisons           */
    /******************************************************/
    public static integer ConvertMonthNameToNumber (String month)
    {
        if(month == 'January')
          return 1;
        else if(month == 'February')
          return 2;
        else if(month == 'March')
          return 3;
        else if(month == 'April')
          return 4;
        else if(month == 'May')
          return 5;
        else if(month == 'June')
          return 6;
        else if(month == 'July')
          return 7;
        else if(month == 'August')
          return 8;
        else if(month == 'September')
          return 9;
        else if(month == 'October')
          return 10;
        else if(month == 'November')
          return 11;
        else
          return 12;
    }


    /******************************************************/
    /* Convert Date back to month names                   */
    /******************************************************/
    public static string ConvertNumberToMonthName (Integer month)
    {
        if(month == 1)
          return 'January';
        else if(month == 2)
          return 'February';
        else if(month == 3)
          return 'March';
        else if(month == 4)
          return 'April';
        else if(month == 5)
          return 'May';
        else if(month == 6)
          return 'June';
        else if(month == 7)
          return 'July';
        else if(month == 8)
          return 'August';
        else if(month == 9)
          return 'September';
        else if(month == 10)
          return 'October';
        else if(month == 11)
          return 'November';
        else
          return 'December';
    }    
}