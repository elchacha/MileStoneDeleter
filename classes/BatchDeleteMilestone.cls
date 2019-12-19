global class BatchDeleteMilestone implements Database.Batchable<sObject>, Database.Stateful {
    Integer successes { get; set; }
    Integer errors { get; set; }
    
    global BatchDeleteMilestone() {
        successes = 0;
        errors = 0;
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime dPurgeMilestones = Datetime.now().addMonths(-6); // 6 mois 
        String strdPurgeMilestones = dPurgeMilestones.format('yyyy-MM-dd') + 'T' + dPurgeMilestones.format('hh:mm:ss') + 'Z';        
        
        String query = 	'Select CaseId from CaseMilestone where case.Status in (\'Clôturé\',\'Fermé\',\'Réglé et clos\') and case.CreatedDate <'+strdPurgeMilestones;
        if(Label.BatchMilestoneLimit!=null&&Label.BatchMilestoneLimit.equals('')){
            query+=' limit '+Label.BatchMilestoneLimit;
        }
        if(Test.isRunningTest()){
            query = 	'Select CaseId from CaseMilestone where case.Status in (\'Clôturé\',\'Fermé\',\'Réglé et clos\') limit 10';
        }
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext sc, List<sObject> scope) {
        List<Id> idCases = new List<Id>();
        for(sObject obj: scope){
            CaseMilestone cm = (CaseMilestone)obj;
            idCases.add(cm.caseid);
        }
        CaseMilestoneDeleter.deleteMilestoneStep1(idCases);        
        errors=Database.countQuery('Select count() from CaseMilestone where CaseId in :idCases');
        successes=scope.size()-errors;
        
    }
    
    global void finish(Database.BatchableContext BC) {
        AsyncApexJob aJob = [select Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :bc.getJobId()];
        //Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> toAddresses = new List<String>{aJob.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Batch de suppression des milestone : ' + aJob.Status);
        mail.setHtmlBody('Batch Apex réalisé sur ' + (successes + errors) + ' milestone avec ' + errors + ' milestone non supprimé.');
        mail.setSaveAsActivity(false);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    }

}