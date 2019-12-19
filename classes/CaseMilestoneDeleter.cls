public class CaseMilestoneDeleter {
    
    static Map<id,String> caseEntitlement = new Map<id,String>();
    static Map<id,String> caseStatus = new Map<id,String>();

    static Map<String,String> saveReason = new Map<String,String>();
    static Map<String,String> saveSubReason = new Map<String,String>();
	
	//choose a not closed status here
	static String EXISTINGNOTCLOSEDCASESTATUS='PUT YOUR OWN CASE STATUS HERE';
    
    public static integer deleteMilestoneStep1(List<Id> idCases){




		/*
			!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!WARNING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			Selected user should be able to bypass all trigger,validation Rules and any process that could be started du to Case modification
		*/

        List<Case> cases = prepareCases(idCases);

        List<CaseMilestone> cmsToUpdate = [select Id, completionDate,case.status from CaseMilestone cm where caseId in :idCases];
        for(CaseMilestone cms :cmsToUpdate ){
            cms.completionDate = null;
        }

        update cmsToUpdate;
        for(Case aCase : cases){
            caseEntitlement.put(aCase.id,aCase.EntitlementId);
            aCase.EntitlementId=null; 
        } 
        update cases; 
        
        cmsToUpdate = [select Id, completionDate,case.status from CaseMilestone cm where caseId in :idCases];
        integer limit101 =0;
        while(cmsToUpdate.size()>0){
			// I know , DML operation within a loop is horrible but it's a requirement for this process to work
            update cases; 
            cmsToUpdate = [select Id, completionDate,case.status from CaseMilestone cm where caseId in :idCases];
            for(CaseMilestone cms :cmsToUpdate ){
                cms.completionDate = null;
            }
            
            // in case we have too many milestone on a case, this will prevent a SOQL101 error
            limit101++;
            if(limit101>20)break;
        }
        
        for(Case aCase : cases){
            aCase.status=caseStatus.get(aCase.id);
            aCase.EntitlementId=caseEntitlement.get(aCase.id);
            aCase.dateResolution__c=aCase.ClosedDate;
        } 
        update cases;
        

        return 0;
    }

    public static List<Case> prepareCases(List<Id> idCases){
        // nullify the id of the entitlement
        List<Case> cases = [select id,status,EntitlementId from Case where id in :idCases];
        
        // reopen the case in order to remove the slaexitdate from case (choose a not closed status here)
        for(Case aCase : cases){
            caseStatus.put(aCase.id,aCase.status);
            caseEntitlement.put(aCase.id,aCase.EntitlementId);
            aCase.status=EXISTINGCASESTATUS;
        } 
        update cases;
        
        for(Case aCase : cases){
            aCase.EntitlementId=null;
        } 
        update cases;
        // reassign an entitlement
        for(Case aCase : cases){
            aCase.EntitlementId=caseEntitlement.get(aCase.id);
        } 
        update cases;
        
        return cases;
    }

    
}