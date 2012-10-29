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
* @description Controller for Relationships Setings VF page 
*/
public with sharing class RelationshipsSettings_CTRL {
	
	public Relationship_Settings__c relSettings{get;set;}
	
	/** Handling Auto-creation vars **/	
	public List<Relationship_Auto_Create__c> relAutoCreateList{get{
        relACMap = Relationship_Auto_Create__c.getAll();	   
        return relACMap.values();
	}set;}
	public Integer acListSize{get{return relACMap.keySet().size();}set;}
	private Map<String, Relationship_Auto_Create__c> relACMap = new Map<String, Relationship_Auto_Create__c>();
	public String selectedACName{get;set;}
	public Relationship_Auto_Create__c activeAC{get;set;}
	public Boolean canCRUDAC{get;set;}
	
	/******/
	
	
	//controls the active tab
	public String active_tab{get;set;}
	//edit controls
	public Boolean canEditRelSettings{get;set;}
	//dynamically load possible custom gender fields for selection options
	public List<SelectOption> genderFieldOptions{get{
        if (genderFieldOptions == null){
            genderFieldOptions = new List<SelectOption>();
            //add a default option
            genderFieldOptions.add(new SelectOption('', '-None-'));
                    	
        	map<String, Schema.SObjectField> conFieldTokenList = Schema.SObjectType.Contact.fields.getMap(); 
           
            //only get the describe information for custom fields
            for(string fieldName : conFieldTokenList.keyset()){
                if (fieldname.endsWith('__c')){
                    genderFieldOptions.add(new SelectOption(fieldName, fieldName));	
                }            	
            }
        }	   			
		return genderFieldOptions;
	}set;}
	
	
	
	public RelationshipsSettings_CTRL(){
		relSettings = Relationships_Utils.getRelationshipSettings();
		relACMap = Relationship_Auto_Create__c.getAll();  
		active_tab = 'general_settings'; 
		canEditRelSettings = false;
		canCRUDAC = false;
		
		
	}
	
	public PageReference cancel(){		
		
		//reset general settings
		canEditRelSettings = false;
		relSettings = Relationships_Utils.getRelationshipSettings();
		
		//reset autocreate rel
		activeAC = new Relationship_Auto_Create__c();			
		canCRUDAC = false;
		return null;
	}
	
	/** General Settings Methods **/
	
	public PageReference saveGeneralSettings(){
		return null;
	}
	public PageReference editGeneralSettings(){
		canEditRelSettings = true;		
		return null;		
	}
	
	
	/** Autorelationships Methods **/
	public PageReference deleteAC(){
        system.debug('ACNAME: ' + selectedACName);
        activeAC = relACMap.get(selectedACName);
        delete activeAC;        	   
		return null;
	}
	public PageReference editAC(){
		system.debug('ACNAME: ' + selectedACName);
		activeAC = relACMap.get(selectedACName);
		canCRUDAC = true;
		return null;
	}
	public PageReference addAC(){
		activeAC = new Relationship_Auto_Create__c();
		canCRUDAC = true;
		return null;
	}
	public PageReference saveAC(){
		canCRUDAC = true;
		activeAC = new Relationship_Auto_Create__c();
		try{
			upsert activeAC;
		}catch(Exception e){
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Error Saving Auto-Relationship Record.  Please refresh your page and try again.'));
		}
		return null;
	}	

    static testMethod void RelationshipsSettings_CTRL_TEST(){
    	//create a new instance of the controller
    	RelationshipsSettings_CTRL rsCTRL = new RelationshipsSettings_CTRL();
    	
    	
    	
    }

}