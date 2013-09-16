/*
    Copyright (c) 2012, Salesforce.com Foundation
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
* @date 2011, 2012 
* @description Implements relationships behavior 
*/
public with sharing class Relationships {

/// <name> Relationships </name>
	/// <summary> Default Constructor </summary>
	public Relationships(){}
	
	public Relationships(Map<Id, Contact> newMap, Map<Id, Contact> oldMap, Relationships_Utils.triggerAction ta){
        List<Id> ContactIds = new List<Id>();
        List<Id> ReciprocalIds = new List<Id>();
        List<String> Types = new List<String>();        
        
        for (Id i : newMap.keySet()){
        	Contact c = newMap.get(i);
        	for(String s : Relationships_Utils.getAutoCreateMap().keySet()){
        		Relationship_Auto_Create__c rac = Relationships_Utils.getAutoCreateMap().get(s);
        		if (rac.Object__c == 'Contact'){
                    Id relatedContactId;
                    try{
                        //get the id from the field                        
                        relatedContactId = (Id)c.get(rac.Field__c);
                    }catch(Exception e){
                        c.addError(system.Label.AutoCreateFieldError);
                    }    
                    
                    if(ta == Relationships_Utils.triggerAction.afterInsert && relatedContactId != null){                        
                        ContactIds.add(c.Id);
                        ReciprocalIds.add(relatedContactId);
                        Types.add(rac.Relationship_Type__c);
                    }
                    else if (ta == Relationships_Utils.triggerAction.afterUpdate && relatedContactId != null && relatedContactId != oldMap.get(c.id).get(rac.Field__c)){
                    	ContactIds.add(c.Id);
                        ReciprocalIds.add(relatedContactId);
                        Types.add(rac.Relationship_Type__c);
                    }
        		}        		
        	}        	
        }	
        //use @future for inserts
        if (!ContactIds.isEmpty() && !Relationships_Utils.getRelationshipSettings().Force_Synchronous_Auto_Create__c){
        	createNewRelationshipsFuture(ContactIds, ReciprocalIds, Types);
        }        		
        else if (!ContactIds.isEmpty() && Relationships_Utils.getRelationshipSettings().Force_Synchronous_Auto_Create__c){
        	createNewRelationships(ContactIds, ReciprocalIds, Types);
        }
	}
	
	public Relationships(Map<Id, CampaignMember> newMap, Map<Id, CampaignMember> oldMap, Relationships_Utils.triggerAction ta){
        List<Id> ContactIds = new List<Id>();
        List<Id> ReciprocalIds = new List<Id>();
        List<String> Types = new List<String>();
        List<Id> cIds = new List<Id>();  
        
        //CREATE CAMPAIGN MAP BASED ON newMAP KEYSET, THEN GET TYPE AND USE THAT MAP TO DETERMINE IF TYPE MATCHED rac.CMType
        //requery newMap to get Campaign type
        for (Id i : newMap.keySet()){
        	cIds.add(newMap.get(i).CampaignId);
        }
        
        map<Id, Campaign> cMap = new Map<Id, Campaign>([select id, Type from Campaign where Id IN :cIds]);
                
        for (Id i : newMap.keySet()){
            CampaignMember cm = newMap.get(i);
            if (cm.ContactId != null){
	            for(String s : Relationships_Utils.getAutoCreateMap().keySet()){
	                Relationship_Auto_Create__c rac = Relationships_Utils.getAutoCreateMap().get(s);
	                //retrieve the campaign for matching type
	                Campaign c = cMap.get(cm.CampaignId);
	                //create a set from the rac
	                if (rac.Object__c == 'CampaignMember'){
                        List<String> cTypeList = rac.Campaign_Types__c.split(';'); 
                        Set<String> cTypeSet = new Set<String>();
                        cTypeSet.addAll(cTypeList);                        	                	
	                	if (cTypeSet.contains(c.Type)){	                	
		                    Id relatedContactId;
		                    try{
		                        //get the id from the field                        
		                        relatedContactId = (Id)cm.get(rac.Field__c);
		                    }catch(Exception e){
		                        cm.addError(system.Label.AutoCreateFieldError); 
		                    }
		                    if(ta == Relationships_Utils.triggerAction.afterInsert && relatedContactId != null){                        
		                        ContactIds.add(cm.ContactId);
	                            ReciprocalIds.add(relatedContactId);
	                            Types.add(rac.Relationship_Type__c);
		                    }
		                    else if (ta == Relationships_Utils.triggerAction.afterUpdate && relatedContactId != null && relatedContactId != oldMap.get(cm.id).get(rac.Field__c)){
		                        ContactIds.add(cm.ContactId);
	                            ReciprocalIds.add(relatedContactId);
	                            Types.add(rac.Relationship_Type__c);
		                    }
	                	}		                    
	                }               
	            }
            }           
        }   
        //use @future for inserts
        if (!ContactIds.isEmpty() && !Relationships_Utils.getRelationshipSettings().Force_Synchronous_Auto_Create__c){
            createNewRelationshipsFuture(ContactIds, ReciprocalIds, Types);
        }               
        else if (!ContactIds.isEmpty() && Relationships_Utils.getRelationshipSettings().Force_Synchronous_Auto_Create__c){
            createNewRelationships(ContactIds, ReciprocalIds, Types);
        }
	}

	/// <name> Relationships </name>
	/// <summary> Overloads the Relationships object constructor to handle Relationship processing </summary>
	/// <param name="Relationships"> Relationship objects that are being triggered </param>
	/// <param name="oldRelationships"> Relationships object values before trigger event </param>
	/// <param name="ta"> Trigger action that is occuring </param>
	public Relationships(Relationship__c[] Relationships, Relationship__c[] oldRelationships, Relationships_Utils.triggerAction ta) 
	{	
		// Relationship list for termination updates
		List<Relationship__c> origrelationships = new List<Relationship__c>();
		List<Relationship__c> relationshipsToCreate = new List<Relationship__c>();
		List<Relationship__c> relationshipsToUpdate = new List<Relationship__c>();
		List<Relationship__c> relationshipsToDelete = new List<Relationship__c>();
		List<Relationship__c> reciprocalsToUpdate = new List<Relationship__c>();
		
		if (ta==Relationships_Utils.triggerAction.afterUpdate){
			Relationships_ProcessControl.hasRun = true;
		}
		Integer i = 0;			// processing counter		
		
		for(Relationship__c r : Relationships) 
		{
			// AFTER INSERT
			if (ta==Relationships_Utils.triggerAction.afterInsert) 
			{
				if (r.ReciprocalRelationship__c == null)
				{
					relationshipsToCreate.add(r);
				}
				if (r.ReciprocalRelationship__c != null) 
				{
					reciprocalsToUpdate.add(r);
				}
			}
			
			// AFTER UPDATE
			if (ta==Relationships_Utils.triggerAction.afterUpdate) 
			{				
				if (r.ReciprocalRelationship__c == oldRelationships[i].ReciprocalRelationship__c && r.RelatedContact__c != null)
				{
					relationshipsToUpdate.add(r);
					origRelationships.add(oldRelationships[i]);
				}
				if (r.RelatedContact__c == null)
				{
					relationshipsToDelete.add(r);
				}
			}

			// AFTER DELETE
			if (ta==Relationships_Utils.triggerAction.afterDelete) 
			{
				if (r.ReciprocalRelationship__c != null)
				{
					relationshipsToDelete.add(r);
				}
			}

			i += 1;
		}

		if (relationshipsToCreate.size() > 0 ) {
			createRelationship(relationshipsToCreate);
		}
		if (relationshipsToUpdate.size() > 0 ) {
			updateRelationship(relationshipsToUpdate, origRelationships);
		}
		if (reciprocalsToUpdate.size() > 0 ) {
			reciprocate(reciprocalsToUpdate);
		}
		if (relationshipsToUpdate.size() > 0 ) {
			updateRelationship(relationshipsToUpdate, origRelationships);
		}
		if (relationshipsToDelete.size() > 0 ) {
			deleteRelationship(relationshipsToDelete);
		}

		if (ta==Relationships_Utils.triggerAction.afterUpdate){
            Relationships_ProcessControl.hasRun = false;
		}

	}


	/// <name> deleteRelationships </name>
	/// <summary> Deletes Reciprocal Relationships when a Relationship is deleted </summary>
	/// <param name="relationships">  </param>
	public static void deleteRelationship(Relationship__c[] relationships)
	{
		List<Id> relationshipsToDelete = new List<Id>();
		for(Relationship__c r : Relationships) 
		{
			if (r.ReciprocalRelationship__c != null)
			{
				relationshipsToDelete.add(r.ReciprocalRelationship__c);
			} else
			if (r.RelatedContact__c == null)
			{
				relationshipsToDelete.add(r.Id);
			}
		}
		if ( relationshipsToDelete.size() > 0 )
		{
			Database.DeleteResult[] lsr = Database.delete(relationshipsToDelete, false);
		}
		
	}

	/// <name> deleteEmptyRelationships </name>
	/// <summary> Deletes Relationships when a Contact is deleted </summary>
	/// <param name="contacts"> List of Contacts that were deleted </param>
	@future
	public static void deleteEmptyRelationships()
	{
		List<Relationship__c> relationshipsToDelete = new List<Relationship__c>();
		for (Relationship__c r : [Select Id from Relationship__c where RelatedContact__c = null])
		{
			relationshipsToDelete.add(r);
		}
		if ( relationshipsToDelete.size() > 0 )
		{
			Database.DeleteResult[] lsr = Database.delete(relationshipsToDelete, false);
		}
	}
	
	/// <name> reciprocate </name>
	/// <summary>  </summary>
	/// <param name="Relationships">  </param>
	public static void reciprocate(Relationship__c[] Relationships)
	{
		List<Relationship__c> relationshipsToUpdate = new List<Relationship__c>();
		for(Relationship__c r : Relationships) 
		{
			Relationship__c copy = new Relationship__c(Id=r.ReciprocalRelationship__c, ReciprocalRelationship__c=r.Id);
			relationshipsToUpdate.add(copy);
		}
		update relationshipsToUpdate;
	}
	
	/// <name> createRelationship </name>
	/// <summary> Inserts a new reciprocal Relationship After a relationship is Inserted</summary>
	/// <param name="Relationships">  </param>
	public static void createRelationship(Relationship__c[] Relationships)
	{
		List<Relationship__c> relationshipsToCreate = new List<Relationship__c>();
		List<Relationship__c> relationshipsToUpdate = new List<Relationship__c>();
	            
        for(Relationship__c r : Relationships) 
        {
            Relationship__c copy = new Relationship__c();        	   
        	copy.Contact__c = r.RelatedContact__c;
            copy.RelatedContact__c = r.Contact__c;
            copy.Status__c = r.Status__c;
			copy.ReciprocalRelationship__c = r.Id;
			copy.Description__c = r.Description__c;
			copy.SYSTEM_SystemCreated__c = true;
			relationshipsToCreate.add(copy);
		}
		
		//evaluate and add the type
		addType(Relationships, relationshipstoCreate);		
		Database.Saveresult[] sr = Database.insert(relationshipsToCreate, false);
		inspectSaveResults(sr, relationshipsToCreate);
	}

	/// <name> updateRelationship </name>
	/// <summary> Updates the Status and/or Type of a relationship After its reciprocal has been updated </summary>
	/// <param name="Relationships">  </param>
	/// <param name="oldRelationships">  </param>
	public static void updateRelationship(Relationship__c[] Relationships, Relationship__c[] oldRelationships)
	{		
		List<Relationship__c> originalRelationships = new List<Relationship__c>();
		List<Relationship__c> relationshipsToUpdate = new List<Relationship__c>();
		Integer counter = 0;											// processing counter		

		for(Relationship__c r : Relationships) 
		{
			//SWA 2009-05-13 removed a duplicate check for change to Status__c from this OR statement
			if ((r.Status__c != oldRelationships[counter].Status__c || r.Type__c != oldRelationships[counter].Type__c || r.Description__c != oldRelationships[counter].Description__c)&& r.ReciprocalRelationship__c != null)
			{
				Relationship__c copy = new Relationship__c(Id=r.ReciprocalRelationship__c);
				
				//SWA 2009-05-13 - only attempt to modify the Contact field if the Related Contact  has changed
				if(oldRelationships[counter].RelatedContact__c!=r.RelatedContact__c){
					copy.Contact__c = r.RelatedContact__c;
				}
				copy.Status__c = r.Status__c;
				copy.Description__c = r.Description__c;
				relationshipsToUpdate.add(copy);
				originalRelationships.add(r);
			}
			counter += 1;
		}
		//add type info as needed
		if (!originalRelationships.isEmpty() && !relationshipsToUpdate.isEmpty()){
            addType(originalRelationships, relationshipstoUpdate);
            Database.Saveresult[] sr = Database.update(relationshipsToUpdate,false);		
            inspectSaveResults(sr, relationshipsToUpdate);
		}            
	}
    
    @future
    public static void createNewRelationshipsFuture(List<Id> ContactIds, List<Id> RelatedContactIds, List<String> Types){
        createNewRelationships(ContactIds, RelatedContactIds, Types);	
    }    
    public static void createNewRelationships(List<Id> ContactIds, List<Id> RelatedContactIds, List<String> Types){
    	Integer i = 0;
    	List<Relationship__c> relationshipsForInsert = new List<Relationship__c>();
        
        //used to hold existing relationships for the group of contacts and check for dupes
        List<Relationship__c> existingRelationships = new List<Relationship__c>();
        Map<Id, List<Relationship__c>> relationshipsByContact = new Map<Id, List<Relationship__c>>();
        
        if (!Relationships_Utils.getRelationshipSettings().Allow_AutoCreated_Duplicates__c){
            existingRelationships = [select Id, Contact__c, RelatedContact__c, Type__c from Relationship__c where Contact__c IN :ContactIds limit 2000];
            
            //sort by Contact__c so we can pull relationships based on the inserted Contact
            for(Relationship__c r : existingRelationships){
            	if(relationshipsByContact.containsKey(r.Contact__c)){
                    List<Relationship__c> rList = relationshipsByContact.get(r.Contact__c);
            		rList.add(r);
            		relationshipsByContact.put(r.Contact__c, rList);
            	}
            	else{
            		relationshipsByContact.put(r.Contact__c, new List<Relationship__c>{r});
            	}            	
            }        
        }        
        	
    	for (Id conId : ContactIds){
    		boolean doNotCreate = false;
    		
    		//prevent duplicates from being created if they exist and setting is enabled
    		if (relationshipsByContact.containsKey(conId)){
                for (Relationship__c r : relationshipsByContact.get(conId)){
                	if (r.Type__c == Types[i] && r.RelatedContact__c == RelatedContactIds[i]){
                        doNotCreate = true;                		
                        break;
                	}                	
                }    
    		}
    		
    		if (!doNotCreate){
	    		Relationship__c r = new Relationship__c(
	                Contact__c = conId, 
	                RelatedContact__c = RelatedContactIds[i],
	                Type__c = Types[i],    		  
	                Status__c = 'Current'    		      
	    		);
	    		relationshipsForInsert.add(r);
    		}
    		i++;
    	}    	
    	
    	if (!relationshipsForInsert.isEmpty()){
    		Database.Saveresult[] sr = Database.insert(relationshipsForInsert, false);
            inspectSaveResults(sr, relationshipsForInsert);
    	}
    }
	
	private static void addType(list<Relationship__c> rList, list<Relationship__c> rCopy){
		
		Relationship_Settings__c rs = Relationships_Utils.getRelationshipSettings();
        
        //used for tracking place in array
        integer counter = 0;		    
		    
        if (rs.Reciprocal_Method__c == 'List Setting'){            
            map<string, Relationship_Lookup__c> rlMap = Relationship_Lookup__c.getAll().clone();
        
            //remove inactive values
            for (string s : rlMap.keySet()){
                if (rlMap.get(s).Active__c != true){
                    rlMap.remove(s);
                }
            }
        
            list<id> rIDs = new list<id>();
                
            for (Relationship__c r : rList){
            //    rIDs.add(r.RelatedContact__c);
                rIDs.add(r.Contact__c);
            }            
            
            String query_string = 'select id, Salutation';            
            String gender_field = '';
            
            if (rs.Gender_Field__c != null){
                gender_field = rs.Gender_Field__c;
                query_string += ', ' + gender_field;            	
            }
            
            query_string += ' from Contact where Id IN :rIDs';                         
            
            map<id, Contact> cMap = new map<id,Contact>((List<Contact>)database.query(query_string));
            
            for(Relationship__c r : rList){
            	
                Relationship__c copy = rCopy[counter];

                Contact relatedContact = cMap.get(r.Contact__c);
            
                if (rlMap.containsKey(r.Type__c)){
                    
                    List<String> malelist = system.label.Male.split(',');                                                                                                        
                    List<String> femalelist = system.label.Female.split(',');
                    
                    Set<String> maleset = new Set<String>();
                    Set<String> femaleset = new Set<String>();
                    maleset.addAll(malelist);
                    femaleset.addAll(femalelist);                    
                                        
                    //was a gender field defined? 
                    if (gender_field != null && gender_field != '' && relatedContact.get(gender_field) != null){                        
                        
                        String contact_gender = (String)relatedContact.get(gender_field);                                               
                        String match_type = '';                        
                        
                        //try male
                        for (String s : malelist){
                        	if (contact_gender.toLowerCase() == s.toLowerCase().trim()){
                                match_type = 'male';
                        		break;
                        	}
                        }
                        //if we haven't found it, try female
                        if(match_type == ''){
                            for (String s : femalelist){
                                if (contact_gender.toLowerCase() == s.toLowerCase().trim()){
                                    match_type = 'female';
                                    break;
                                }
                            }
                        }     
                        
                        if (match_type == 'male' && rlMap.get(r.Type__c).Male__c != null)
                            copy.Type__c = rlMap.get(r.Type__c).Male__c;
                        else if (match_type == 'female' && rlMap.get(r.Type__c).Female__c != null)                            
                            copy.Type__c = rlMap.get(r.Type__c).Female__c;
                        else
                            copy.Type__c = rlMap.get(r.Type__c).Neutral__c;
                    }
                    else if ((relatedContact.Salutation == 'Mr.' || maleset.contains(relatedContact.Salutation))  && rlMap.get(r.Type__c).Male__c != null){
                        copy.Type__c = rlMap.get(r.Type__c).Male__c;
                    }
                    else if (((relatedContact.Salutation == 'Ms.' || relatedContact.Salutation == 'Mrs.') || femaleset.contains(relatedContact.Salutation)) && rlMap.get(r.Type__c).Female__c != null){
                        copy.Type__c = rlMap.get(r.Type__c).Female__c;
                    }
                    
                    //can't match up gender, bad field or otherwise
                    else{                    	
                    	copy.Type__c = rlMap.get(r.Type__c).Neutral__c;                    	
                    }          
                }                            
                //no matching custom list setting, use provided type
                else{
                    copy.Type__c = r.Type__c;
                }                
                counter++;
            }            
        }
        
        else if(rs.Reciprocal_Method__c == 'Value Inversion'){
            for (Relationship__c r : rList){                           
                //instead lets split the type
                List<string> splitrelationship = r.Type__c.split(system.label.Relationship_Split);
                String newstring = '';
                if (splitrelationship.size() > 1)
                    newstring = splitrelationship[1] + system.label.Relationship_Split + splitrelationship[0];
                else
                    newstring = r.Type__c;
            
                rCopy[counter].Type__c = newstring;
                counter++;
            }
        }
        else{
        	for (Relationship__c r : rList){
            	rCopy[counter].Type__c = r.Type__c;
            	counter++; 
        	}	
        }
	}	
	
	private static void inspectSaveResults(Database.SaveResult[] sr, List<Relationship__c> rl){
		List<Relationship_Error__c> elist = new List<Relationship_Error__c>();
        //needed to match errors to update list index
        integer i = 0;
        for(Database.SaveResult s: sr){         
            if (!s.isSuccess()){
                elist.add(Relationships_Utils.createRelationshipError(s, rl[i]));                              
            }
            i++;
        }        
        if(!elist.isEmpty()){
            insert elist;
        }
	}
}