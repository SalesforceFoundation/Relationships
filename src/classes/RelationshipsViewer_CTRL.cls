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
* @date 2012 
* @description Controller for Relationships viewer VF page 
*/
public with sharing class RelationshipsViewer_CTRL{
    
    public RelationshipsViewer_CTRL(ApexPages.StandardController controller){}
    
    @RemoteAction
    public static List<Node> getRelationships(id cid, boolean isInitialLoad, List<String> relIds) {
        list<Node> returnList = new list<Node>();
        list<Relationship__c> relationshipList = new list<Relationship__c>();
        
        List<Id> renderedRelationships;
        if (relIds != null)
            renderedRelationships = (List<Id>)relIds;
        else
            renderedRelationships = new List<Id>();
        
        if (isInitialLoad){        	
            //base node
            Node basenode = new Node();
      
            Contact c = [select LastName, FirstName, id, Title, Account.Name from Contact where id = :cid];
            basenode.LastName = c.LastName;
            basenode.FirstName = c.FirstName;
            basenode.Title = c.Title;
            basenode.AccountName = c.Account.Name;
            basenode.id = c.id;
            returnList.add(basenode);
        }        
        else{
        	relationshipList.clear();
        	returnList.clear();
        }        
        
        relationshipList = [select id, RelatedContact__r.LastName, Type__c, Status__c, RelatedContact__r.FirstName, 
                                    RelatedContact__r.id, RelatedContact__r.Account.Name, RelatedContact__r.Title,
                                    ReciprocalRelationship__r.id 
                                    from Relationship__c 
                                    where Contact__c = :cid and id NOT IN :renderedRelationships 
                                    and ReciprocalRelationship__r.id NOT IN :renderedRelationships];

        for (Relationship__c r : relationshipList){
            Node n = new Node();             
            n.LastName = r.RelatedContact__r.LastName;
            n.id = r.RelatedContact__r.id;
            n.Type = r.Type__c;
            n.Status = r.Status__c;
            n.FirstName = r.RelatedContact__r.FirstName;
            n.link =  URL.getSalesforceBaseUrl().toExternalForm() + '/' + r.RelatedContact__r.id;
            n.AccountName = r.RelatedContact__r.Account.Name;
            n.Title = r.RelatedContact__r.Title;
            n.relId = r.id;            
            returnList.add(n);
        }
        return returnList;
    }
        
    //get Relationship object prefix for links
    @RemoteAction
    public static RelationshipInfo getRelationshipInfo(){
    	return new RelationshipInfo();
    }
    
    public class RelationshipInfo{
    	String prefix;
    	String NameField;
    	String NameIdField;
    	public RelationshipInfo(){
    		Relationship_Settings__c rs = Relationships_Utils.getRelationshipSettings();
    		
    		this.prefix = Relationship__c.sObjectType.getDescribe().getKeyPrefix();
    		if (rs.Relationship_Name_Field_Id__c != null){
    			this.NameField = rs.Relationship_Name_Field_Id__c;
    		}
    		if (rs.Relationship_Name_Id_Field_Id__c != null){
    			this.NameIdField = rs.Relationship_Name_Id_Field_Id__c;
    		}    		
    	}    	
    }

    public class Node { 
        String FirstName;
        String LastName;
        String id;              
        String Status;
        String Type;
        String link;    
        String AccountName;
        String Title;
        String relId;
    }  
    
    public static testMethod void RelationshipsViewer_TEST(){
        //set running user to avoid dml issue            
        System.runAs(new User(id = UserInfo.getUserId())){ 
	        //insert two contacts
	        Contact c1 = new Contact(LastName = 'Testy');
	        insert c1;
	        Contact c2 = new Contact(LastName = 'McTester');
	        insert c2;
	        //create a relationship between them
	        Relationship__c rel = new Relationship__c(
	              contact__c = c1.id, 
	              relatedcontact__c = c2.id, 
	              Type__c='Friend',
	              Status__c='Active',
	              Description__c='notes');
	        insert rel;
	        //list to hold nodes
	        List<RelationshipsViewer_CTRL.Node> nodeList = new List<RelationshipsViewer_CTRL.Node>();
	        
	        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(c1);
	        RelationshipsViewer_CTRL rvc = new RelationshipsViewer_CTRL(sc);
	        
	        //call the remote static method to get the node list
	        nodeList = RelationshipsViewer_CTRL.getRelationships(c1.id, true, null);
	        
	        //check that a base node (contact) and the related contact are in the node list
	        system.assertEquals(2, nodeList.size());
	        system.assertEquals('Testy', nodeList[0].LastName);
	        system.assertEquals('McTester', nodeList[1].LastName);	   
	        List<String> sList = new List<String>();
	        sList.add('01r80000000Gty5');     
	        nodeList = RelationshipsViewer_CTRL.getRelationships(c1.id, false, sList);
	        RelationshipsViewer_CTRL.RelationshipInfo ri = RelationshipsViewer_CTRL.getRelationshipInfo();
	        system.assertNotEquals(null, ri);	        	        
        }
    }
}