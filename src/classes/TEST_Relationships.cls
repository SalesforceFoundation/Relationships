/*
    Copyright (c) 2009, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.com Foundation
* @date 2011 
* @description Testing for the Relationships class
*/
@isTest
private class TEST_Relationships {
    
    private static Contact c1;//male
    private static Contact c2;//female
    private static Contact c3;//unknown
    
    //helper for test methods
    private static void setupRelationshipTestData(Relationship_Settings__c rs){
        
        //set running user to avoid dml issue            
        System.runAs(new User(id = UserInfo.getUserId())){ 
        
            //remove any existing settings
            delete [select id from Relationship_Settings__c];
            if (rs != null)
                insert rs;
            else{
                rs = new Relationship_Settings__c(Reciprocal_Method__c = 'List Setting');
                insert rs;           
            }
            
            //add autocreate settings for CMs 
            delete [select id from Relationship_Auto_Create__c];
            insert new Relationship_Auto_Create__c(Name='AutoCreate',Object__c='CampaignMember',
                                                    Field__c='ContactId',Relationship_Type__c = 'TestType');            
            
            //add Reciprocal Relationship
            delete [select id from Relationship_Lookup__c];
            insert new Relationship_Lookup__c(Name='TestLookupType',Male__c='TestMaleType',
                                                Female__c='TestFemaleType',Neutral__c='TestNeutralType');                                
        
            c1 = new Contact(Salutation = 'Mr.', FirstName = 'Walter_Test', LastName = 'Roosevelt_Test');
            insert c1;
            c2 = new Contact(Salutation = 'Mrs.', FirstName = 'Jane_Test', LastName = 'Nixon_Test');    	
            insert c2;
            c3 = new Contact(Salutation = 'Dr.', FirstName = 'Pat_Test', LastName = 'Cleveland_Test');
            insert c3;
        }
    }
    
	/// <name> TestContactRel </name>
	/// <summary> test method for relationships and the mirroring </summary>
	static testMethod void TestContactRel() {
			 
		setupRelationshipTestData(null);	 
      
		Relationship__c rel = new Relationship__c(
		      contact__c = c1.id, 
		      relatedcontact__c = c2.id, 
		      Type__c='Friend',
		      Status__c='Active',
		      Description__c='notes');
		insert rel;
		
		List<Relationship__c> relList = new List<Relationship__c>();
		// check that rel gets created
		relList = [select id,contact__c,Relatedcontact__c,Status__c,
		                                  Type__c, ReciprocalRelationship__c
		                                  from Relationship__c where Id= :rel.Id limit 1];
		List<Relationship__c> mirrorList = new List<Relationship__c>();
		// check for mirror rel
		mirrorList = [select id,contact__c,Relatedcontact__c,Status__c,
		                                      Type__c,ReciprocalRelationship__c  
		                                      from Relationship__c where ReciprocalRelationship__c=:relList[0].Id limit 1];
		
		
        //reference eachother
        System.assertEquals(relList[0].ReciprocalRelationship__c, mirrorList[0].Id);
		System.assertEquals(mirrorList[0].ReciprocalRelationship__c, relList[0].Id);

		//same types
		System.assertEquals(mirrorList[0].Type__c, 'Friend');
		System.assertEquals(relList[0].Type__c, 'Friend');  
		
		// test changing the relationship
		relList[0].Type__c = 'Colleague';
		relList[0].Description__c = 'test desc';        
		
		//reset the process controller to mimic a second user action
		Relationships_ProcessControl.hasRun = false;
		
		Test.startTest();
		update relList[0];
		Test.stopTest();		
		
		// test change to the rel
		Relationship__c updated_original = [select id, Description__c, Type__c,ReciprocalRelationship__c 
		                                      from Relationship__c where id = :relList[0].Id limit 1];
		                                      
		//original should have updated relationship
		System.assertEquals('Colleague', updated_original.Type__c);
		//original should have updated notes
		System.assertEquals('test desc', updated_original.Description__c);
		
		Relationship__c updated_mirror = [select id, Type__c, Description__c, ReciprocalRelationship__c
		                                      from Relationship__c where ReciprocalRelationship__c = :relList[0].Id limit 1];
	    //mirror should have relationship set right
		System.assertEquals('Colleague', updated_mirror.Type__c);	
		//mirror should have updated notes
		System.assertEquals('test desc', updated_mirror.Description__c);
	
		// test deleting the rel
		delete updated_original;
		Relationship__c[] mirror_after_original_deleted = [select id 
		                                                   from Relationship__c 
		                                                   where ReciprocalRelationship__c = :rel.Id];
		//mirror should be deleted as well
		System.assertEquals(0, mirror_after_original_deleted.size());
	}
	
	/// <name> TestOrphanedRelDelete </name>
	/// <summary> test method for relationships and deleting the mirror record </summary>
	static testMethod void TestOrphanedRelDelete() {	
        setupRelationshipTestData(null);

		Relationship__c[] crel = new Relationship__c[]{
			new Relationship__c(contact__c = c1.id, Relatedcontact__c = c2.id, Type__c='Buddies')
		};
		insert crel;
		
		// check that rel gets created
		Relationship__c crel_original = [select id, Description__c,Type__c,reciprocalrelationship__c from Relationship__c where id=:crel[0].Id];
		//relationship should be set right
		System.assertEquals(crel_original.Type__c, 'Buddies');

		// check for mirror rel
		Relationship__c crel_mirror = [select id, Description__c, reciprocalrelationship__c, Type__c from Relationship__c where reciprocalrelationship__c=:crel_original.Id];
		//mirror should reference the original
		System.assertEquals(crel_mirror.reciprocalrelationship__c, crel_original.Id);
		Contact secondContactForDelete = [select id from contact where id=:c2.id];
		Test.startTest();
		delete secondContactForDelete;
		Test.stopTest();
		// test change to the rel
		Relationship__c[] orphanedCrel = [select id from Relationship__c where id = :crel_original.Id];
		//original should have updated relationship
		System.assertEquals(0, orphanedCrel.size());
	}
}