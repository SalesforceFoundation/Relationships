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

	/// <name> TestContactRel </name>
	/// <summary> test method for relationships and the mirroring </summary>
	static testMethod void TestContactRel() {
			 
		Contact firstContact = new Contact (
			FirstName='Joe',
			LastName='Johanssen'
		);
		insert firstContact;

		Contact secondContact = new Contact (
			FirstName='Bobby',
			LastName='Johanssen'
		);
		insert secondContact;

		Relationship__c[] crel = new Relationship__c[]{
			new Relationship__c(contact__c = firstContact.id, relatedcontact__c = secondContact.id, Type__c='Friend',Status__c='Active',Description__c='notes')
		};
		insert crel;
		
		// check that rel gets created
		Relationship__c crel_original = [select id,contact__c,Relatedcontact__c,Status__c,Type__c,ReciprocalRelationship__c  from Relationship__c where id=:crel[0].Id];
		//relationship should be set right
		System.assertEquals(crel_original.Type__c, 'Friend');
		
		// check for mirror rel
		Relationship__c crel_mirror = [select id,contact__c,Relatedcontact__c,Status__c,Type__c,ReciprocalRelationship__c  from Relationship__c where ReciprocalRelationship__c=:crel_original.Id];
		//mirror should reference the original
		System.assertEquals(crel_mirror.ReciprocalRelationship__c, crel_original.Id);
		//mirror should have the relationship set right
		System.assertEquals(crel_mirror.Type__c, 'Friend');
		
		//original should reference the mirror
		System.assertEquals(crel_original.ReciprocalRelationship__c, crel_mirror.Id);
		
		
		// test changing the relationship
		Relationship__c updated_original = 
			new Relationship__c(id = crel_original.id, Type__c='Colleague', Description__c = 'test desc')
		;
		update updated_original;
		
		// test change to the rel
		updated_original = [select id, Description__c, Type__c,ReciprocalRelationship__c from Relationship__c where id = :crel_original.Id];
		//original should have updated relationship
		System.assertEquals('Colleague', updated_original.Type__c);
		
		//original should have updated notes
		System.assertEquals('test desc', updated_original.Description__c);
		
		Relationship__c updated_mirror = [select id, Type__c, Description__c, ReciprocalRelationship__c from Relationship__c where ReciprocalRelationship__c = :crel_original.Id];
		//mirror should have relationship set right
		System.assertEquals('Colleague', updated_mirror.Type__c);
		
		//mirror should have updated notes
		System.assertEquals('test desc', updated_mirror.Description__c);

		// test deleting the rel
		delete updated_original;
		Relationship__c[] mirror_after_original_deleted = [select id from Relationship__c where ReciprocalRelationship__c = :crel_original.Id];
		//mirror should be deleted as well
		System.assertEquals(0, mirror_after_original_deleted.size());

	}
	/// <name> TestOrphanedRelDelete </name>
	/// <summary> test method for relationships and deleting the mirror record </summary>
	static testMethod void TestOrphanedRelDelete() {	
		Contact firstContact = new Contact (
			FirstName='Joe',
			LastName='Johanssen'
		);
		insert firstContact;

		Contact secondContact = new Contact (
			FirstName='Bobby',
			LastName='Johanssen'
		);
		insert secondContact;

		Relationship__c[] crel = new Relationship__c[]{
			new Relationship__c(contact__c = firstContact.id, Relatedcontact__c = secondContact.id, Type__c='Buddies')
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
		Contact secondContactForDelete = [select id from contact where id=:secondContact.id];
		Test.startTest();
		delete secondContactForDelete;
		Test.stopTest();
		// test change to the rel
		Relationship__c[] orphanedCrel = [select id from Relationship__c where id = :crel_original.Id];
		//original should have updated relationship
		System.assertEquals(0, orphanedCrel.size());
	}
}