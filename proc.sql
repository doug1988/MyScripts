CREATE  proc [dbo].[SpDefinirFaltososJob]    
    
as    

begin    
    

declare @Data datetime  = getdate()    
    
 if exists (
            SELECT top 1 1  FROM CandidatosAgendamentos 
            where CodEstadoCandidatoAtual = 10 
            and        DataAgendamento < convert(varchar,@Data,112) 
            and DataAgendamento > '20180507' 
            and CodCategoria in ('A','B') 
            and CodSala in (2010,2024,2005)
            )    

   update CandidatosAgendamentos    
    
   set     
    
    CodEstadoCandidatoAnterior  = 10    
   , CodEstadoCandidatoAtual =  -21    
   , DataOperacao = @Data    
   where     
    CodEstadoCandidatoAtual = 10     
   and DataAgendamento < convert(varchar,@Data,112)     
   and DataAgendamento > '20180507'     
   and CodCategoria in ('A','B')     
   and CodSala in (2010,2024)    
  
  update CandidatosAgendamentos    
   set     
    CodEstadoCandidatoAnterior  = 10    
   , CodEstadoCandidatoAtual =  -21    
   , DataOperacao = @Data    
   where     
    CodEstadoCandidatoAtual = 10     
   and DataAgendamento < convert(varchar,@Data,112)     
   and DataAgendamento > '20180507'  
   and CodCategoria in ('A')     
   and CodSala in (2005)    

 end    
 