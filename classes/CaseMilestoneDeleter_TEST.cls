@isTest(SeeAllData=true)
private class CaseMilestoneDeleter_TEST {

	private static testMethod void test() {
	    List<CaseMilestone> cases = [Select CaseId from CaseMilestone where case.Status in ('Clôturé','Fermé','Réglé et clos') limit 10];
        List<Id> idCases = new List<Id>();
        for(CaseMilestone cm: cases){
            idCases.add(cm.caseid);
        }
        CaseMilestoneDeleter.deleteMilestoneStep1(idCases);
	}
	
	private static testMethod void testBatch() {
        Test.startTest();
        BatchDeleteMilestone b = new BatchDeleteMilestone();
        Id batchId = Database.executeBatch(b);
        Test.stopTest();
	}


}