global with sharing class RelationshipViewerController {
    
    global RelationshipViewerController(ApexPages.StandardController controller) {
	}  

    @RemoteAction
    global static list<Node> getRelationships(id cid) {
        list<Node> returnList = new list<Node>();
        list<Relationship__c> relationshipList = new list<Relationship__c>();
		
        //base node
        Node basenode = new Node();
      
        Contact c = [select LastName, FirstName, id, Title, Account.Name from Contact where id = :cid];
        basenode.LastName = c.LastName;
        basenode.FirstName = c.FirstName;
        basenode.Title = c.Title;
        basenode.AccountName = c.Account.Name;
        basenode.id = c.id;
        returnList.add(basenode);
        
        relationshipList = [select id, RelatedContact__r.LastName, Type__c, Status__c, RelatedContact__r.FirstName, RelatedContact__r.id, RelatedContact__r.Account.Name, RelatedContact__r.Title from Relationship__c where Contact__c = :cid];

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
			
        	returnList.add(n);
        	
        }

        return returnList;
    }

    global class Node { 
    	string FirstName;
        string LastName;
        string id;            	
    	string Status;
    	string Type;
    	string link; 	
    	string AccountName;
    	string Title;
    }  

}