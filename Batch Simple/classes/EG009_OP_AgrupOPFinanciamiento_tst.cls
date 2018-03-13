@isTest
public class EG009_OP_AgrupOPFinanciamiento_tst {

	static{

		EG009_UtilitysUnitTest_tst.AmbientacionGeneral();

	}

	public static TestMethod void AgruparOportunidadesHijasHuerfanas_SinMadre(){

		User u = [SELECT Id, VP_ls_Banca__c FROM User WHERE Email = 'adminBBVA@bbva.tst.deploy.com'];
		System.runAs(u){

			Map<String, RecordType> AllRT = EG009_UtilitysUnitTest_tst.getRecordType();
			Account Cliente = EG009_UtilitysUnitTest_tst.creaCliente(AllRT, null, null, '562634987');
			EG009_UtilitysUnitTest_tst.creaOportunidad(Cliente.Id, EG009_Utility_cls.GetActiveRecordTypes('Opportunity').get('EG009_tre_OpFinanciamiento').Id, 'Crédito Líquido');
			Account GrupoEconomico = EG009_UtilitysUnitTest_tst.creaGrupoEconomico(AllRT, 'G020992');
			Cliente.EG009_tx_NumeroGrupoEconomico__c = GrupoEconomico.EG009_tx_NumeroGrupoEconomico__c;
			Cliente.EG009_rb_GrupoEconomicoPertenece__c = GrupoEconomico.Id;
			Update Cliente;

			Test.startTest();
				String CRON_EXP = '0 0 0 15 3 ? *';
	            String jobId = System.schedule('ScheduleApexClassTest',  CRON_EXP, new EG009_OP_AgrupOPFinanciamiento_Sch());
	            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
	            System.assertEquals(CRON_EXP, ct.CronExpression);
	            System.assertEquals(0, ct.TimesTriggered);
	        Test.stopTest();
    	}
    }

    public static TestMethod void AgruparOportunidadesHijasHuerfanas_ConMadre(){

		User u = [SELECT Id, VP_ls_Banca__c FROM User WHERE Email = 'adminBBVA@bbva.tst.deploy.com'];
		System.runAs(u){

			Map<String, RecordType> AllRT = EG009_UtilitysUnitTest_tst.getRecordType();
			Account Cliente = EG009_UtilitysUnitTest_tst.creaCliente(AllRT, null, null, '562634987');
			EG009_UtilitysUnitTest_tst.creaOportunidad(Cliente.Id, EG009_Utility_cls.GetActiveRecordTypes('Opportunity').get('EG009_tre_OpFinanciamiento').Id, 'Crédito Líquido');
			Account GrupoEconomico = EG009_UtilitysUnitTest_tst.creaGrupoEconomico(AllRT, 'G020992');
			Cliente.EG009_tx_NumeroGrupoEconomico__c = GrupoEconomico.EG009_tx_NumeroGrupoEconomico__c;
			Cliente.EG009_rb_GrupoEconomicoPertenece__c = GrupoEconomico.Id;
			Update Cliente;
			EG009_UtilitysUnitTest_tst.creaOportunidad(Cliente.Id, EG009_Utility_cls.GetActiveRecordTypes('Opportunity').get('EG009_tre_OpFinanciamiento').Id, 'Crédito Líquido');
			
			Test.startTest();
				String CRON_EXP = '0 0 0 15 3 ? *';
	            String jobId = System.schedule('ScheduleApexClassTest',  CRON_EXP, new EG009_OP_AgrupOPFinanciamiento_Sch());
	            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
	            System.assertEquals(CRON_EXP, ct.CronExpression);
	            System.assertEquals(0, ct.TimesTriggered);
	        Test.stopTest();
    	}
    }

}