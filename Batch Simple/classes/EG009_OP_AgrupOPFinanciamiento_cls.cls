/** 
*----------------------------------Desarrollado por INDRA---------------------------------
*@author        Lic. Luis Ruben Quinto Muñoz
*@proyect       Pipeline Financiamiento PI8 BEyG
*@description   Batch que agrupa oportunidades huerfanas a los procesos de crédito.
*				Debe unir las oportunidades cuando se actualiza el grupo economico del cliente
*				las oportunidades del cliente solo si son del proceso de crédito
*
*_______________________________________________________________________________________
*Versión   			 Fecha           Autor                               Descripción
*@version 1.0        27/FEB/2018     Lic. Luis Ruben Quinto Muñoz	     Creación.
*----------------------------------------------------------------------------------------- 
**/

global class EG009_OP_AgrupOPFinanciamiento_cls implements Database.Batchable<sObject> {
	

	//buscar oportunidades que no tengan proceso de credito
	//si no tiene grupo no crearlo
	global Database.QueryLocator start(Database.BatchableContext BC) {
		 String query = 'SELECT Id, AccountID, EG009_rb_ProcesoDeCredito__c, RecordTypeId, StageName, RecordType.DeveloperName FROM Opportunity WHERE '+
		 'RecordType.DeveloperName = \'EG009_tre_OportunidadFinanciamiento\' AND EG009_rb_ProcesoDeCredito__c = null '+
		 'AND ( StageName != \'Descartada / Rechazada\' AND  StageName != \'Cerrada Ganada\' ) AND AccountID != null AND Account.EG009_rb_GrupoEconomicoPertenece__c != null';
		return Database.getQueryLocator(query);
	}	

   	global void execute(Database.BatchableContext BC, List<Opportunity> scope) {

   		map<Id, RecordType> mapRecordTypesOpp = new map<Id, RecordType>([Select Id, DeveloperName from RecordType where sObjectType='Opportunity']);
   		
   		//Declaración de variables.
        Set<Id> AccIds = new Set<Id>();
        List<Account> listClientes = new List<Account>();
        Map<Id, Account> MapClientes = new Map<Id, Account>();
        Set<Id> IdsGruposEconomicos = new Set<Id>();
        Map<Id, Opportunity> OppMadresExistentes = new Map<Id, Opportunity>();
        List<Opportunity> OppMadresCrear = new List<Opportunity>();
        Id RTIdOppMadre;
        Map<Id, Id> RelacionOpps = new Map<Id, Id>();
        Boolean CrearOppMadre = true;

        //Comprobamos que la oportunidad que se esté creando sea una Oportunidad de Financiamiento (Hija) y extraemos los Ids.
        for(Opportunity IteraTN : scope){
			AccIds.add(IteraTN.AccountId);
        }

        if(!AccIds.isEmpty()){

            //Traemos todos los clientes que tengan un Grupo Económico ligado de las oportundiades en el scope.
            listClientes = [SELECT Id, EG009_rb_GrupoEconomicoPertenece__c,EG009_rb_GrupoEconomicoPertenece__r.EG009_tx_NumeroGrupoEconomico__c FROM Account WHERE Id IN: AccIds AND EG009_rb_GrupoEconomicoPertenece__c != null];
            for(Account cliente: listClientes) {
                MapClientes.put(cliente.Id,cliente); // 
            }

            if(!MapClientes.isEmpty()){

                //Sacamos exclusivamente los IDs de los Grupos Economicos existentes (De los clientes)
                for(Account IteraMapClientes : MapClientes.values()){
                    IdsGruposEconomicos.add(IteraMapClientes.EG009_rb_GrupoEconomicoPertenece__c);
                }

                //Traemos los Procesos de Crédito Vigentes (Oportunidades Madre)
                OppMadresExistentes = new Map<Id, Opportunity>([SELECT Id, EG009_rb_GrupoEconomico__c FROM Opportunity WHERE EG009_rb_GrupoEconomico__c IN: IdsGruposEconomicos AND RecordType.DeveloperName =: 'EG009_tre_ProgramaFinanciero' AND EG009_fh_FechaInicioVigencia__c <= Today AND CloseDate >= Today AND StageName != 'Cerrada Ganada' AND StageName != 'Descartada / Rechazada']);

                //Obtenemos el ID del Tipo de Registro de Los Procesos de Crédito (Oportunidades Madres)
                for(RecordType IteraRT : mapRecordTypesOpp.values()){
                    if(IteraRT.DeveloperName == 'EG009_tre_ProgramaFinanciero'){
                        RTIdOppMadre = IteraRT.Id;
                    }
                }

                for(Opportunity IteraTN : scope){
                    if(EG009_Utility_cls.RTEquals(mapRecordTypesOpp, IteraTN.RecordTypeId, 'EG009_tre_OportunidadFinanciamiento') && IteraTN.AccountId != null){
                        for(Account IteraMapClientes : MapClientes.values()){
                            //Si existen oportunidades Madre, liga las existentes a la hija que se está creando
                            if(!OppMadresExistentes.isEmpty() && IteraTN.AccountId == IteraMapClientes.Id){
                                for(Opportunity IteraOppMadres : OppMadresExistentes.values()){
                                    if(IteraOppMadres.EG009_rb_GrupoEconomico__c == IteraMapClientes.EG009_rb_GrupoEconomicoPertenece__c){
                                        IteraTN.EG009_rb_ProcesoDeCredito__c = IteraOppMadres.Id;
                                        CrearOppMadre = false;
                                    }
                                }
                            }
                            //En caso de que no existen madres la agrega a una lista para despúes crearla.
                            if(IteraTN.AccountId == IteraMapClientes.Id && CrearOppMadre){
                                Opportunity IndexOppMadre = new Opportunity();
                                IndexOppMadre.EG009_rb_GrupoEconomico__c = IteraMapClientes.EG009_rb_GrupoEconomicoPertenece__c;
                                IndexOppMadre.Amount = 0;
                                IndexOppMadre.StageName = 'Promoción';
                                IndexOppMadre.Name = 'Proceso de Crédito - del ' + String.ValueOf(System.today()).substring(0, 10) + ' al ' + String.ValueOf(System.today().addMonths(12)).substring(0, 10);
                                IndexOppMadre.EG009_fh_FechaInicioVigencia__c = System.today();
                                IndexOppMadre.CloseDate = System.today().addMonths(12);
                                IndexOppMadre.RecordTypeId = RTIdOppMadre;
                                IndexOppMadre.EG009_tx_NumeroGrupoEconomico__c = IteraMapClientes.EG009_rb_GrupoEconomicoPertenece__r.EG009_tx_NumeroGrupoEconomico__c;//Se agrega el Numero de grupo economico 
                                OppMadresCrear.add(IndexOppMadre);
                                RelacionOpps.put(IteraTN.Id, IteraMapClientes.EG009_rb_GrupoEconomicoPertenece__c);
                            }

                            CrearOppMadre = true;

                        }
                    }
                }

                Update scope;

                if(!OppMadresCrear.isEmpty()){

                    //Se Crean las Oportunidades Madres
                    Insert OppMadresCrear;

                    //Se ligan las Oportunidades Madres a las Hijas
                    for(Opportunity IteraTN : scope){
                        if(EG009_Utility_cls.RTEquals(mapRecordTypesOpp, IteraTN.RecordTypeId, 'EG009_tre_OportunidadFinanciamiento') && IteraTN.AccountId != null){
                            for(Opportunity MadresCreadas : OppMadresCrear){
                                if(RelacionOpps.get(IteraTN.Id) == MadresCreadas.EG009_rb_GrupoEconomico__c){
                                    IteraTN.EG009_rb_ProcesoDeCredito__c = MadresCreadas.Id;
                                }
                            }
                        }
                    }

                }

                

            }

        }


	//si no tiene madre crearla
	// asociar la oportunidad al proceso de credito a las oportunidades hijas
	
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}