/*
    Copyright (c) 2009, 2012, Salesforce.com Foundation
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
* @date 2011,2012 
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
                rs = new Relationship_Settings__c(Reciprocal_Method__c = 'List Setting', Gender_Field__c = 'Description');
                insert rs;           
            }
            
            //add autocreate settings for CMs 
            delete [select id from Relationship_Auto_Create__c];
            insert new Relationship_Auto_Create__c(Name='AutoCreate',Object__c='CampaignMember',
                                                    Field__c='ContactId',Relationship_Type__c = 'TestType',
                                                    Campaign_Types__c = 'Other;');    
            
            insert new Relationship_Auto_Create__c(Name='AutoCreate2',Object__c='Contact',
                                                    Field__c='ReportsToId',Relationship_Type__c = 'TestType');
            
            //add Reciprocal Relationship
            delete [select id from Relationship_Lookup__c];
            insert new Relationship_Lookup__c(Name='TestLookupType',Male__c='TestMaleType',
                                                Female__c='TestFemaleType',Neutral__c='TestNeutralType');
            insert new Relationship_Lookup__c(Name='TestLookupType2',Male__c='TestMaleType2',
                                                Female__c='TestFemaleType2',Neutral__c='TestNeutralType2',
                                                Active__c=false);                                
        
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
    static testMethod void testContactRel() {
             
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
        //Relationships_ProcessControl.hasRun = false;
        
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
    static testMethod void testOrphanedRelDelete() {    
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
    //deleting the original should delete the reciprocal
    static testMethod void testRelationshipDelete(){
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
        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        Test.startTest();
        delete crel_original;
        Test.stopTest();        
        system.assertEquals(0, [select count() from Relationship__c where id = :crel_mirror.id]);
    }  
    static testMethod void testAutoCreateCampaignMemberInsert(){
        setupRelationshipTestData(null);
        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        //insert a campaignmember
        Campaign c = new Campaign(Name='TestCampaign', isActive=true, Type='Other');
        insert c;
        CampaignMember cm = new CampaignMember(ContactId = c2.id, CampaignId = c.id);
        
        Test.startTest();        
        insert cm;
        Test.stopTest();
         
        Relationship__c rel = [select id, Type__c from Relationship__c where Contact__c = :c2.id limit 1];
        system.assertEquals('TestType', rel.Type__c);
        Relationship__c recRel = [select id, Type__c from Relationship__c where ReciprocalRelationship__c = :rel.id];
        system.assertEquals('TestType', recRel.Type__c);
    }    
    //test the synchronous process as well
    static testMethod void testAutoCreateCampaignMemberInsertSynch(){
        setupRelationshipTestData(new Relationship_Settings__c(Reciprocal_Method__c = 'List Setting', Force_Synchronous_Auto_Create__c = true));
        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        //insert a campaignmember
        Campaign c = new Campaign(Name='TestCampaign', isActive=true, Type='Other');
        insert c;
        CampaignMember cm = new CampaignMember(ContactId = c2.id, CampaignId = c.id);
        
        Test.startTest();        
        insert cm;
        Test.stopTest();
         
        Relationship__c rel = [select id, Type__c from Relationship__c where Contact__c = :c2.id limit 1];
        system.assertEquals('TestType', rel.Type__c);
        Relationship__c recRel = [select id, Type__c from Relationship__c where ReciprocalRelationship__c = :rel.id];
        system.assertEquals('TestType', recRel.Type__c);
    }    
    //can't do a true test as ContactId is not updatable, but we'll hit the update for coverage
    static testMethod void testAutoCreateCampaignMemberUpdate(){    	
        setupRelationshipTestData(null);        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;        
        //insert a campaignmember
        Campaign c = new Campaign(Name='TestCampaign', isActive=true);
        insert c;
        CampaignMember cm = new CampaignMember(ContactId = c2.id, CampaignId = c.id);
        insert cm;        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;        
        //do an update and check that a second relationship set is created for the new Contact
        cm.Status = 'SomethingDifferentForUpdate';        
        Test.startTest();        
        update cm;
        Test.stopTest();        
    }
    static testMethod void testAutoCreateContactInsert(){
        setupRelationshipTestData(null);
        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        //insert a new Contact
        Contact c = new Contact(LastName='ReportingIn', ReportsToId = c1.id);        
        
        Test.startTest();        
        insert c;
        Test.stopTest();
         
        Relationship__c rel = [select id, Type__c, RelatedContact__c from Relationship__c where Contact__c = :c.id limit 1];
        system.assertEquals('TestType', rel.Type__c);
        system.assertEquals(c1.id, rel.RelatedContact__c);
        
        Relationship__c recRel = [select id, Type__c, RelatedContact__c, Contact__c from Relationship__c where ReciprocalRelationship__c = :rel.id];
        system.assertEquals('TestType', recRel.Type__c);
        system.assertEquals(c.id, recRel.RelatedContact__c);
    }	
    static testMethod void testAutoCreateContactInsertSynch(){
        setupRelationshipTestData(new Relationship_Settings__c(Reciprocal_Method__c = 'List Setting', Force_Synchronous_Auto_Create__c = true));
        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        //insert a new Contact
        Contact c = new Contact(LastName='ReportingIn', ReportsToId = c1.id);        
        
        Test.startTest();        
        insert c;
        Test.stopTest();
         
        Relationship__c rel = [select id, Type__c, RelatedContact__c from Relationship__c where Contact__c = :c.id limit 1];
        system.assertEquals('TestType', rel.Type__c);
        system.assertEquals(c1.id, rel.RelatedContact__c);
        
        Relationship__c recRel = [select id, Type__c, RelatedContact__c, Contact__c from Relationship__c where ReciprocalRelationship__c = :rel.id];
        system.assertEquals('TestType', recRel.Type__c);
        system.assertEquals(c.id, recRel.RelatedContact__c);
    }
    static testMethod void testAutoCreateContactUpdate(){
        setupRelationshipTestData(null);
        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        //insert a new Contact
        Contact c = new Contact(LastName='ReportingIn', ReportsToId = c1.id);        
        insert c;
        //Relationships_ProcessControl.hasRun = false;
        c.ReportsToId = c2.id;
        
        Test.startTest();        
        update c;
        Test.stopTest();
         
        Relationship__c rel = [select id, Type__c, RelatedContact__c from Relationship__c where Contact__c = :c.id and RelatedContact__c = :c2.id limit 1];
        system.assertEquals('TestType', rel.Type__c);
        system.assertEquals(c2.id, rel.RelatedContact__c);
    }    
    static testMethod void testInversionSettingsHaveType(){
    	setupRelationshipTestData(new Relationship_Settings__c(Reciprocal_Method__c = 'Value Inversion'));
    	
    	Relationship__c[] crel = new Relationship__c[]{
            new Relationship__c(contact__c = c1.id, Relatedcontact__c = c2.id, Type__c='Buddies-Friends')
        };
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        Test.startTest();
        insert crel;
        Test.stopTest();
        
        // check that rel gets created
        Relationship__c crel_original = [select id, Description__c,Type__c,reciprocalrelationship__c from Relationship__c where id=:crel[0].Id];
        //relationship should be set right
        system.assertEquals(crel_original.Type__c, 'Buddies-Friends');

        // check for mirror rel
        Relationship__c crel_mirror = [select id, Description__c, reciprocalrelationship__c, Type__c from Relationship__c where reciprocalrelationship__c=:crel_original.Id];
        //mirror should reference the original
        system.assertEquals(crel_mirror.reciprocalrelationship__c, crel_original.Id);
        system.assertEquals('Friends-Buddies', crel_mirror.Type__c);    	
    }    
    static testMethod void testInversionSettingsNoType(){
        setupRelationshipTestData(new Relationship_Settings__c(Reciprocal_Method__c = 'Value Inversion'));
        
        Relationship__c[] crel = new Relationship__c[]{
            new Relationship__c(contact__c = c1.id, Relatedcontact__c = c2.id, Type__c='BuddiesFriends')
        };
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        Test.startTest();
        insert crel;
        Test.stopTest();
        
        // check that rel gets created
        Relationship__c crel_original = [select id, Description__c,Type__c,reciprocalrelationship__c from Relationship__c where id=:crel[0].Id];
        //relationship should be set right
        system.assertEquals(crel_original.Type__c, 'BuddiesFriends');

        // check for mirror rel
        Relationship__c crel_mirror = [select id, Description__c, reciprocalrelationship__c, Type__c from Relationship__c where reciprocalrelationship__c=:crel_original.Id];
        //mirror should reference the original
        system.assertEquals(crel_mirror.reciprocalrelationship__c, crel_original.Id);
        system.assertEquals('BuddiesFriends', crel_mirror.Type__c);
    }    
    static testMethod void testNoValidSettingsConfig(){
        setupRelationshipTestData(new Relationship_Settings__c(Reciprocal_Method__c = 'BAD_VALUE'));
        
        Relationship__c[] crel = new Relationship__c[]{
            new Relationship__c(contact__c = c1.id, Relatedcontact__c = c2.id, Type__c='BuddiesFriends')
        };
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        Test.startTest();
        insert crel;
        Test.stopTest();
        
        // check that rel gets created
        Relationship__c crel_original = [select id, Description__c,Type__c,reciprocalrelationship__c from Relationship__c where id=:crel[0].Id];
        //relationship should be set right
        system.assertEquals(crel_original.Type__c, 'BuddiesFriends');

        // check for mirror rel
        Relationship__c crel_mirror = [select id, Description__c, reciprocalrelationship__c, Type__c from Relationship__c where reciprocalrelationship__c=:crel_original.Id];
        //mirror should reference the original
        system.assertEquals(crel_mirror.reciprocalrelationship__c, crel_original.Id);
        system.assertEquals('BuddiesFriends', crel_mirror.Type__c);
    }    
    static testMethod void testMaleSalutationReciprocal(){
    	setupRelationshipTestData(null);
    	Relationship__c[] crel = new Relationship__c[]{
            new Relationship__c(contact__c = c1.id, Relatedcontact__c = c2.id, Type__c='TestLookupType')
        };        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;    	
    	
    	Test.startTest();
    	insert crel;
    	Test.stopTest();      
    	
    	Relationship__c recRel = [select id, Type__c from Relationship__c where ReciprocalRelationship__c = :crel[0].id];
    	system.assertEquals('TestMaleType', recRel.Type__c);
    }
    static testMethod void testFemaleSalutationReciprocal(){
        setupRelationshipTestData(null);
        Relationship__c[] crel = new Relationship__c[]{
            new Relationship__c(contact__c = c2.id, Relatedcontact__c = c1.id, Type__c='TestLookupType')
        };        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;        
        
        Test.startTest();
        insert crel;
        Test.stopTest();      
        
        Relationship__c recRel = [select id, Type__c from Relationship__c where ReciprocalRelationship__c = :crel[0].id];
        system.assertEquals('TestFemaleType', recRel.Type__c);
    }
    static testMethod void testNeutralSalutationReciprocal(){
        setupRelationshipTestData(null);
        Relationship__c[] crel = new Relationship__c[]{
            new Relationship__c(contact__c = c3.id, Relatedcontact__c = c2.id, Type__c='TestLookupType')
        };        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;        
        
        Test.startTest();
        insert crel;
        Test.stopTest();      
        
        Relationship__c recRel = [select id, Type__c from Relationship__c where ReciprocalRelationship__c = :crel[0].id];
        system.assertEquals('TestNeutralType', recRel.Type__c);
    }    
    static testMethod void testNeutralGenderFieldReciprocal(){
        setupRelationshipTestData(new Relationship_Settings__c(Reciprocal_Method__c = 'List Setting', Gender_Field__c = 'Description'));
        Relationship__c[] crel = new Relationship__c[]{
            new Relationship__c(contact__c = c3.id, Relatedcontact__c = c2.id, Type__c='TestLookupType')
        };                
        c3.Description = 'Neutral';
        update c3;
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;        
        
        Test.startTest();
        insert crel;
        Test.stopTest();      
        
        Relationship__c recRel = [select id, Type__c from Relationship__c where ReciprocalRelationship__c = :crel[0].id];
        system.assertEquals('TestNeutralType', recRel.Type__c);
    }
    static testMethod void testMaleGenderFieldReciprocal(){
        setupRelationshipTestData(new Relationship_Settings__c(Reciprocal_Method__c = 'List Setting', Gender_Field__c = 'Description'));
        c1.Description = 'Male';
        update c1;
        Relationship__c[] crel = new Relationship__c[]{
            new Relationship__c(contact__c = c1.id, Relatedcontact__c = c2.id, Type__c='TestLookupType')
        };        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;        
        
        Test.startTest();
        insert crel;
        Test.stopTest();      
        
        Relationship__c recRel = [select id, Type__c from Relationship__c where ReciprocalRelationship__c = :crel[0].id];
        system.assertEquals('TestMaleType', recRel.Type__c);
    }
    static testMethod void testFemaleGenderFieldReciprocal(){
        setupRelationshipTestData(new Relationship_Settings__c(Reciprocal_Method__c = 'List Setting', Gender_Field__c = 'Description'));
        c2.Description = 'Female';
        update c2;
        
        Relationship__c[] crel = new Relationship__c[]{
            new Relationship__c(contact__c = c2.id, Relatedcontact__c = c2.id, Type__c='TestLookupType')
        };
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;        
        
        Test.startTest();
        insert crel;
        Test.stopTest();      
        
        Relationship__c recRel = [select id, Type__c from Relationship__c where ReciprocalRelationship__c = :crel[0].id];
        system.assertEquals('TestFemaleType', recRel.Type__c);
    }
    static testMethod void testErrorRecordCreation(){
    	setupRelationshipTestData(null);
    	Relationship__c[] crel = new Relationship__c[]{
            new Relationship__c(contact__c = c2.id, Type__c='TestLookupType')
        };
        //Relationships_ProcessControl.hasRun = false;
        Database.SaveResult[] sr = Database.insert(crel, false);
        //assert an error
        system.assertNotEquals(0, [select count() from Relationship_Error__c]);
        //Relationships_ProcessControl.hasRun = false;
        crel[0].RelatedContact__c = c1.id;
        sr = Database.update(crel, false);
        Relationship_Error__c re = Relationships_Utils.createRelationshipError(sr[0], crel[0]);
    }
    static testMethod void testExceptionRecordCreation(){
    	setupRelationshipTestData(null);
    	
    	try{
    		throw new MyException('TestException');
    	}
    	catch(Exception e){
            Relationship_Error__c er = Relationships_Utils.createRelationshipError(e);
            system.assertEquals('TestException', er.Full_Error_Message__c);
    	}    	
    }
    
    static testMethod void testAutoCreateDupePrevention(){
    	setupRelationshipTestData(null);
    	
    	Relationship__c[] crel = new Relationship__c[]{
            new Relationship__c(contact__c = c1.id, Relatedcontact__c = c2.id, Type__c='TestType')
        };
        crel.add(new Relationship__c(contact__c = c1.id, Relatedcontact__c = c2.id, Type__c='TestType2'));
        insert crel;
        
        //update the ReportsToId to trigger autocreation 
        c1.ReportsToId = c2.id;
        //Relationships_ProcessControl.hasRun = false;
                
        Test.startTest();        
        update c1;
        Test.stopTest();
        
        //assert we only have one relationship since we've deduped the auto-created one   
    	Relationship__c[] rel = [select id, Type__c, RelatedContact__c from Relationship__c where Contact__c = :c1.id and Type__c = 'TestType'];
        system.assertEquals('TestType', rel[0].Type__c);
        system.assertEquals(rel.size(), 1);    	
    }
    
    static testMethod void testRelationshipUTILS(){
    	//to test the Relationship_Utils class    	
    	System.runAs(new User(id = UserInfo.getUserId())){ 
    	   delete [select id from Relationship_Settings__c];
    	   Relationship_Settings__c rs = Relationships_Utils.getRelationshipSettings();
    	   Boolean cAuto = Relationships_Utils.hasContactAutoCreate;
    	   Boolean cmAuto = Relationships_Utils.hasCMAutoCreate;
    	}
    }    
    
    static testMethod void testInstallScript() {
        Relationships_INST postinstall = new Relationships_INST();
        Test.testInstall(postinstall, null);
        Test.testInstall(postinstall, new Version(2,0), true);
        
        Relationship_Lookup__c[] rlList = [select id from Relationship_Lookup__c where Name = 'Father'];
        System.assertEquals(rlList.size(), 1, 'Relationship Lookup not found');
  	}
  
  	static testmethod void test2Rels1Transaction() {
		 // Create three contacts
		Contact mainClient = new Contact(FirstName='Main',LastName='AAAClient');
		insert mainClient;
		Contact friend = new Contact(FirstName='Test',LastName='AAAFriend');
		insert friend;
		Contact coworker = new Contact(FirstName='Test',LastName='AAACoworker');
		insert coworker;
		
		// Create two relationships
		Relationship__c r = new Relationship__c(Contact__c=mainClient.Id,RelatedContact__c=friend.Id,Type__c='Friend');
		insert r;
		Relationship__c nr = [select id, ReciprocalRelationship__c from Relationship__c where Id = :r.id];		
		system.assert(nr.ReciprocalRelationship__c != null); 		

		// if done one at a time, we have to reset our static to mimic transaction scope
        //Relationships_ProcessControl.hasRun = false;
		r = new Relationship__c(Contact__c=mainClient.Id,RelatedContact__c=coworker.Id,Type__c='Coworker');
		insert r;		
		Relationship__c nr2 = [select id, ReciprocalRelationship__c from Relationship__c where Id = :r.id];
		system.assert(nr2.ReciprocalRelationship__c != null); 		
		
		// ensure that we do correctly handle inserting two at once within a single transaction.
        //Relationships_ProcessControl.hasRun = false;
		list<Relationship__c> rels = new list<Relationship__c>(); 
		rels.add(new Relationship__c(Contact__c=mainClient.Id,RelatedContact__c=friend.Id,Type__c='Friend2'));
		rels.add(new Relationship__c(Contact__c=mainClient.Id,RelatedContact__c=coworker.Id,Type__c='Coworker2'));
		insert rels;
		list<Relationship__c> rels2 = [select id, ReciprocalRelationship__c from Relationship__c where Id = :rels[0].Id or Id = :rels[1].Id];
		system.assertEquals(2, rels2.size());
		system.assert(rels2[0].ReciprocalRelationship__c != null); 		
		system.assert(rels2[1].ReciprocalRelationship__c != null); 		
		
  	}  
  
  public class MyException extends Exception{}
}