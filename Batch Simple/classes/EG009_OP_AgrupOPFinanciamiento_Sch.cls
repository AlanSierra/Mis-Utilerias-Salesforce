global class EG009_OP_AgrupOPFinanciamiento_Sch implements Schedulable{
	
    global void execute(SchedulableContext SC){
        EG009_OP_AgrupOPFinanciamiento_cls RunAgrupacion = new EG009_OP_AgrupOPFinanciamiento_cls();
        Database.Executebatch(RunAgrupacion, 5);
    }
    
}