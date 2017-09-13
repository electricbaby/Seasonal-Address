@isTest
public class TestRPTAddress {
//	public static Account testAccount = new Account(Name='TestAccount');
    
    /******************************************************/
    /* Create Account and Contact for testing             */
    /******************************************************/
    public static List<Contact> CreateTestAccountContact() {

        Account testAccount = new Account(Name='TestAccount');
        insert testAccount;
        
        Contact testContact = new Contact(firstname='Test',
                                 lastname='Contact',
                                 AccountId=testAccount.Id);
              
        List <Contact> allContacts = new List <Contact>();
        
        allContacts.add(testContact);
        
        insert allContacts; 
        
        return allContacts;
        
    }
    
    
    /******************************************************/
    /* Create test addresses				              */
    /******************************************************/
    public static List<RPT_Address__c> CreateTestAddresses() {
		List <Contact> testContact = new List <Contact>();
        testContact = CreateTestAccountContact();
        
        List<RPT_Address__c> addresses = new List<RPT_Address__c>();
        
    	RPT_Address__c TestAddress0 = new RPT_Address__c();
    	TestAddress0.Contact__c = testContact[0].id;
    	TestAddress0.Inactive__c = false;
    	TestAddress0.Street__c = '123 First St'; 
    	TestAddress0.City__c = 'Frisco';
    	TestAddress0.State__c = 'CO';
    	TestAddress0.Postal_Code__c = '80443';
    	TestAddress0.Country__c = 'USA';
    	TestAddress0.Start_Month__c = 'November';
    	TestAddress0.Start_Day__c = '1';
    	TestAddress0.End_Month__c = 'January';
    	TestAddress0.End_Day__c = '31';
    	TestAddress0.Is_Current_Address__c = false;
        
		addresses.add(TestAddress0);        
        
       	RPT_Address__c TestAddress1 = new RPT_Address__c();
    	TestAddress1.Contact__c = testContact[0].id;
    	TestAddress1.Inactive__c = false;
    	TestAddress1.Street__c = '345 Third St'; 
    	TestAddress1.City__c = 'Breck';
    	TestAddress1.State__c = 'CO';
    	TestAddress1.Postal_Code__c = '80443';
    	TestAddress1.Country__c = 'USA';
    	TestAddress1.Start_Month__c = 'February';
    	TestAddress1.Start_Day__c = '1';
    	TestAddress1.End_Month__c = 'June';
    	TestAddress1.End_Day__c = '30';
    	TestAddress1.Is_Current_Address__c = false;
        
        addresses.add(TestAddress1);  
        
        return addresses; 
    }
    
    /******************************************************/
    /* Test inserting addresses				              */
    /******************************************************/    
    static testMethod void TestInsert(){
        List<RPT_Address__c> addresses = new List<RPT_Address__c>();
        addresses = CreateTestAddresses(); 
                
        // Perform tests
        Test.startTest();
    	Database.SaveResult[] resultList = Database.insert(addresses, false);
        Test.stopTest();
        
    	// Iterate through each returned result
		for (Database.SaveResult result : resultList) {
    		if (result.isSuccess()) {
    	    System.debug('Successfully inserted RPT Address: ' + result.getId());
    		}
    		else 
    		{
    	    	// Operation failed, so get all errors                
       			for(Database.Error err : result.getErrors()) {
            		System.debug('The following error has occurred.');                    
            		System.debug(err.getStatusCode() + ': ' + err.getMessage());
            		System.debug('Field errors: ' + err.getFields());
        		}
            }
    	}
        
    	// Verify that the deletion was successful
    	System.assert(resultList[0].isSuccess());
    	System.assert(resultList[1].isSuccess());
        
    }

    /******************************************************/
    /* Test updating addresses				              */
    /******************************************************/
    static testMethod void TestUpdate(){
        List<RPT_Address__c> addresses = new List<RPT_Address__c>();
        addresses = CreateTestAddresses(); 
        insert addresses; 
        
    	// Dispaly results created
        List<RPT_Address__c> allAddresses = [Select ID, Name, Start_Month__c, Start_Day__c, End_Month__c, End_Day__c, Inactive__c, Is_Current_Address__c, Contact__c FROM RPT_Address__c]; 

        for(RPT_Address__c a : allAddresses)
      	{
            System.debug('result address: ' +a);
            a.Inactive__c = false;
            a.End_Day__c = '29';
        }
                
        // Perform tests
        Test.startTest();
    	Database.SaveResult[] resultList = Database.update(allAddresses, false);
        Test.stopTest();
              
    	// Verify that the deletion was successful
    	System.assert(resultList[0].isSuccess());
    	System.assert(resultList[1].isSuccess());
        
    }    
    
    
    /******************************************************/
    /* Test updating addresses with overlapping dates     */
    /******************************************************/    
	static testMethod void TestOverlapUpdate()
	{
    
    	List<RPT_Address__c> addresses = new List<RPT_Address__c>();
        addresses = CreateTestAddresses(); 
        insert addresses; 
        
    	// Dispaly results created
        List<RPT_Address__c> allAddresses = [Select ID, Name, Start_Month__c, Start_Day__c, End_Month__c, End_Day__c, Inactive__c, Is_Current_Address__c, Contact__c FROM RPT_Address__c]; 

        for(RPT_Address__c a : allAddresses)
      	{
            a.Inactive__c = false;
            a.Start_Month__c = 'September';	
            a.Start_Day__c = '29';
            a.End_Month__c = 'September';	
            a.End_Day__c = '29';
        }
                
        // Perform tests
        Test.startTest();
    	Database.SaveResult[] resultList = Database.update(allAddresses, false);
        Test.stopTest();
         List<RPT_Address__c> allAddresses2 = [Select ID, Name, Start_Month__c, Start_Day__c, End_Month__c, End_Day__c, Inactive__c, Is_Current_Address__c FROM RPT_Address__c]; 

        for(RPT_Address__c a : allAddresses2)
      {
            System.debug('result address: ' +a);
        }
    	// Iterate through each returned result
		for (Database.SaveResult result : resultList) {
    		if (result.isSuccess()) {
    	    System.debug('Successfully updated RPT Address: ' + result.getId());
    		}
    		else 
    		{
    	    	// Operation failed, so get all errors                
       			for(Database.Error err : result.getErrors()) {
            		System.debug('The following error has occurred.');                    
            		System.debug(err.getStatusCode() + ': ' + err.getMessage());
            		System.debug('Field errors: ' + err.getFields());
        		}
            }
    	}
                
    	// Failures
    	// Need to give this some love
		//System.assert(!resultList[0].isSuccess());
        //System.assert(resultList[0].getErrors().size() > 0);
    	//System.assertEquals('bad value for restricted picklist field', resultList[0].getErrors()[0].getMessage());
	    //System.assert(!resultList[1].isSuccess());
    	//System.assertEquals('The dates specifeid overlap with an existing RPT Address', resultList[1].getErrors()[0].getMessage());
    	
    }        
    
    /******************************************************/
    /* Month to Number method                             */
    /******************************************************/    
	static testMethod void TestMonthToNumber()
	{
        System.assertEquals(1, RPTAddress.ConvertMonthNameToNumber('January'));
        System.assertEquals('January', RPTAddress.ConvertNumberToMonthName(1));

        System.assertEquals(2, RPTAddress.ConvertMonthNameToNumber('February'));
        System.assertEquals('February', RPTAddress.ConvertNumberToMonthName(2));

        System.assertEquals(3, RPTAddress.ConvertMonthNameToNumber('March'));
        System.assertEquals('March', RPTAddress.ConvertNumberToMonthName(3));

        System.assertEquals(4, RPTAddress.ConvertMonthNameToNumber('April'));
        System.assertEquals('April', RPTAddress.ConvertNumberToMonthName(4));

        System.assertEquals(5, RPTAddress.ConvertMonthNameToNumber('May'));
        System.assertEquals('May', RPTAddress.ConvertNumberToMonthName(5));

        System.assertEquals(6, RPTAddress.ConvertMonthNameToNumber('June'));
        System.assertEquals('June', RPTAddress.ConvertNumberToMonthName(6));

        System.assertEquals(7, RPTAddress.ConvertMonthNameToNumber('July'));
        System.assertEquals('July', RPTAddress.ConvertNumberToMonthName(7));

        System.assertEquals(8, RPTAddress.ConvertMonthNameToNumber('August'));
        System.assertEquals('August', RPTAddress.ConvertNumberToMonthName(8));

        System.assertEquals(9, RPTAddress.ConvertMonthNameToNumber('September'));
        System.assertEquals('September', RPTAddress.ConvertNumberToMonthName(9));

        System.assertEquals(10, RPTAddress.ConvertMonthNameToNumber('October'));
        System.assertEquals('October', RPTAddress.ConvertNumberToMonthName(10));

        System.assertEquals(11, RPTAddress.ConvertMonthNameToNumber('November'));
        System.assertEquals('November', RPTAddress.ConvertNumberToMonthName(11));

        System.assertEquals(12, RPTAddress.ConvertMonthNameToNumber('December'));
        System.assertEquals('December', RPTAddress.ConvertNumberToMonthName(12));


    }
}