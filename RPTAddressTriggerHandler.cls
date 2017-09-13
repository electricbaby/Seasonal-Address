/* RPTAddressTriggerHandler 
*  September 2017
*  Handles logic for RPT Addrress Trigger
*/
public with sharing class RPTAddressTriggerHandler {

  // Prevent Recursion
  private static Boolean run = true;
  public static Boolean runOnce(){
    if(run){
     run=false;
     return true;
    }else{
        return run;
    }
  }

  public static void handleBeforeInsert(List<RPT_Address__c> addresses) {
    system.debug('RPT Address Trigger On Before Insert');

    // Validate that Start Month, Start Day, End Month and End Day are populated and not the same day   
    RPTAddress.ValidateStartAndEndDates(addresses);

    // Confirm before insert or before update that the RPT Address interval doesn't 
    // overlap with an existing RPT Address interval
    RPTAddress.CheckForOverlappingIntervals(addresses);
  
    // Inserted/updated RPT Addresses with Start Date < Today < End Date should
    // update the Contact.MailiingAddress and Account.ShippingAddress
    RPTAddress.UpdateMailingAddress(addresses);
  }

  public static void handleBeforeUpdate(List<RPT_Address__c> addresses, List<RPT_Address__c> oldAddresses) {
    system.debug('RPT Address Trigger On Before Update');
 
    // Validate that Start Month, Start Day, End Month and End Day are populated and not the same day   
    RPTAddress.ValidateStartAndEndDates(addresses);

    // Confirm before insert or before update that the RPT Address interval doesn't 
    // overlap with an existing RPT Address interval
    RPTAddress.CheckForOverlappingIntervals(addresses);
  
    // Inserted/updated RPT Addresses with Start Date < Today < End Date should
    // update the Contact.MailiingAddress and Account.ShippingAddress
    RPTAddress.UpdateMailingAddress(addresses);
        
  }

  //public static void handleBeforeDelete(List<RPT_Address__c> addresses) {
    //system.debug('RPT Address Trigger On Before Delete');
    
    // If this is the current address, Contact.MailingAddress and Account.ShippingAddress should be cleared

    // If using a default address make sure not to delete to default address 

  //}

  //public static void handleAfterDelete(List<RPT_Address__c> addresses) {
    //system.debug('Account Trigger On After Delete'); 
  //}

}