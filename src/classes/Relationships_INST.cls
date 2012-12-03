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
* @description Install script for the Relationships package
*/
global class Relationships_INST implements InstallHandler{

    global static final String RECIPROCAL_DEFAULT_RESOURCE_NAME = 'DefaultReciprocalRelationships';
    
    global void onInstall(InstallContext context){
        
        //only run if this is a user install 
        if(!context.isPush()){
            //load some default custom settings
            List<Relationship_Lookup__c> rlList = new List<Relationship_Lookup__c>();
            StaticResource sr = [select body from StaticResource where Name = :RECIPROCAL_DEFAULT_RESOURCE_NAME];
            List<List<String>> recipRelList = Relationships_Utils.parseCSV(sr.Body.toString(), false);
            for (List<String> ls : recipRelList){
                Relationship_Lookup__c rl = new Relationship_Lookup__c();                
                rl.Name = ls[0];
                rl.Male__c = ls[1];
                rl.Female__c = ls[2];
                rl.Neutral__c = ls[3];
                rl.Active__c = true;             	
            	rlList.add(rl);            	
            }
            
            if (!rlList.isEmpty())
                insert rlList;            
            
            //autodetect a gender field
            
        
            //detect other npsp packages
        
               
        
            //load default reciprocals
      
        	
        	
        }
        
        
          
        
      
    }
}