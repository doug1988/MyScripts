CREATE  procedure [dbo].[Usp_VerificaProvasTransferidasES]                       
as                      
BEGIN                      
                   
             
declare @Contador int                  
declare @data datetime                  
declare @RetornoLk int = null                       
                  
declare @table table                       
(                      
 CD_PROVA bigint                      
, NU_RENACH bigint                      
, NU_CPF bigint                      
, DT_INICIO datetime                      
, DT_FIM  datetime                      
, DT_DIA  datetime                      
, HR_PROVA varchar(5)                      
, CD_SALA   int                      
)                      
                      
 ------------------------------------------------------------------------------------------------------------------------------------------------                      
 EXEC @RetornoLk = [checkLinkedServer]  BOLA15                      
                       
 IF @RetornoLk = 1                      
 BEGIN                      
  SET @Contador = 1                      
  SET @data =  convert(varchar,getdate(),112)                    
                    
  insert into @table                      
  select * from  BOLA15.DB_ES_PROVA_DIGITAL.dbo.VwProvaEnviada where DT_DIA between @data  and DATEADD(DAY,5,@data) order by dt_dia, hr_prova                      
                        
  WHILE @CONTADOR <= 5                      
  BEGIN                      
  insert into TB_MONITORAMENTO                      
   select  DISTINCT                      
    'ES'                      
   , 'BOLA15'                      
   , @Data                      
   , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  51)  as [Total Agendas]                      
   , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  51)                        
   +                       
    (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a                       
    inner join DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B                      
    ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  51)  as [Total Provas]                      
   , (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS AS A (NOLOCK)  WHERE NOT EXISTS (SELECT  top 1 1                       
                          from @table as B                      
                          where                       
                           A.DT_DIA = B.DT_DIA                      
                          and A.HR_PROVA = B.HR_PROVA                      
                          and A.CD_SALA = B.CD_SALA                      
                          and A.NU_RENACH = B.NU_RENACH                      
                          and A.NU_CPF = B.NU_CPF)                      
                      AND  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  51)                      
   , getdate()                      
   , ''                      
   from                       
    DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS AS A with (nolock)                      
   where                       
    CD_SALA = 51                      
  -- and  DT_DIA between @data  and DATEADD(DAY,5,@data)                      
                         
   SET @DATA = @DATA + 1                       
   SET @CONTADOR = @Contador + 1                        
  END                       
                         
 END                      
                       
 ELSE                      
 BEGIN                      
     insert into TB_MONITORAMENTO 
     (                      
      [Site]                      
     , SalaOffline                      
     , DataAgendamento                    
     ,  AgendasTotais                      
     , ProvasTotais                        
     , ProvasPendentes                       
     , DataVerificacao                         
     , Observacao                      
     )                      
     values                      
     (                      
      'ES'                      
     , 'BOLA15'                      
     , DATEADD(DAY,1,@data)                      
     , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  51)                       
     , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  51)                        
     +                       
      (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a inner join DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B                      
      ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  51)                       
     , NULL                      
     , GETDATE()                      
     , 'Sem link de Comunicação com BOLA15!'                      
     )                      
 END                      
 -------------------------------------------------------------------------------------------------------------------------------------------------------------------                      
                      
             
 ------------------------------------------------------------------------------------------------------------------------------------------------                      
 --EXEC @RetornoLk = [checkLinkedServer] COLATINA                      
                       
 --IF @RetornoLk = 1                      
 --BEGIN                      
 -- SET @Contador = 1                      
 -- SET @data =  convert(varchar,getdate(),112)                      
                        
 -- delete @table                      
 -- insert into @table                      
 -- select * from  COLATINA.DB_ES_PROVA_DIGITAL.dbo.VwProvaEnviada where DT_DIA between @data  and DATEADD(DAY,5,@data) order by dt_dia, hr_prova                      
                        
 -- WHILE @CONTADOR <= 5                      
 -- BEGIN                      
 -- insert into TB_MONITORAMENTO                      
 --  select  DISTINCT                      
 --   'ES'                      
 --  , 'COLATINA'                      
 --  , @Data                      
 --  , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  53)  as [Total Agendas]                      
 --  , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  53)                        
 --  +                       
 --   (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a                       
 --   inner join DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B                      
 --   ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  53)  as [Total Provas]                      
 --  , (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS AS A (NOLOCK)  WHERE NOT EXISTS (SELECT  top 1 1                       
 --                         from @table as B                      
 --                         where                       
 --                          A.DT_DIA = B.DT_DIA             
 --                 and A.HR_PROVA = B.HR_PROVA                      
 --                         and A.CD_SALA = B.CD_SALA                      
 --                         and A.NU_RENACH = B.NU_RENACH                      
 --                         and A.NU_CPF = B.NU_CPF)    
 --                     AND  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  53)                      
 --  , getdate()                      
 --  , ''                      
 --  from                       
 --   DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS AS A with (nolock)                      
 --  where                       
 --   CD_SALA = 53                      
 --  --and  DT_DIA between @data  and DATEADD(DAY,5,@data)                      
                         
 --  SET @DATA = @DATA + 1                       
 --  SET @CONTADOR = @Contador + 1                      
 -- END                     
                         
 --END                      
                       
 --ELSE                      
 --    insert into TB_MONITORAMENTO                      
 --    (                      
 --     [Site]                      
 --    , SalaOffline                      
 --    , DataAgendamento                      
 --    ,   AgendasTotais                     
 --    , ProvasTotais                        
 --    , ProvasPendentes                       
 --    , DataVerificacao                         
 --    , Observacao                      
 --    )                      
 --    values                      
 --    (                      
 --     'ES'                      
 --    , 'COLATINA'                      
 --    , DATEADD(DAY,1,@data)                  
 --    , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  53)                       
 --    , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  53)                        
 --    +             
 --     (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a inner join DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B                      
 --     ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  53)                       
 --    , NULL                      
 --    , GETDATE()                      
 --    , 'Sem link de Comunicação com COLATINA!'                      
 --    )                      
 -----------------------------------------------------------------------------------------------------------------------------------------------------------------                      
                      
 ------------------------------------------------------------------------------------------------------------------------------------------------                      
               
EXEC @RetornoLk = [checkLinkedServer] GUARAPARI                      
                       
 IF @RetornoLk = 1                      
 BEGIN                      
  SET @Contador = 1                      
  SET @data =  convert(varchar,getdate(),112)                      
                    
  delete @table                      
  insert into @table                      
  select * from  GUARAPARI.DB_ES_PROVA_DIGITAL.dbo.VwProvaEnviada where DT_DIA between @data  and DATEADD(DAY,5,@data) order by dt_dia, hr_prova                      
                        
  WHILE @CONTADOR <= 5                      
  BEGIN                      
  insert into TB_MONITORAMENTO                      
   select  DISTINCT                      
    'ES'                      
   , 'GUARAPARI'                      
   , @Data                      
   , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  54)  as [Total Agendas]                      
   , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  54)                        
   +                       
    (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a                       
    inner join DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B                      
    ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  54)  as [Total Provas]                      
    , (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS AS A (NOLOCK)  WHERE NOT EXISTS (SELECT  top 1 1                       
                          from @table as B                      
                          where                       
                           A.DT_DIA = B.DT_DIA                      
                          and A.HR_PROVA = B.HR_PROVA                      
                          and A.CD_SALA = B.CD_SALA                      
                          and A.NU_RENACH = B.NU_RENACH                      
                          and A.NU_CPF = B.NU_CPF)           
                      AND  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  54)                      
   , getdate()                      
   , ''                      
   from                       
    DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS AS A with (nolock)                      
   where                       
    CD_SALA = 54                      
   --and  DT_DIA between @data  and DATEADD(DAY,5,@data)                      
                         
   SET @DATA = @DATA + 1                       
   SET @CONTADOR = @Contador + 1                      
  END                       
                         
 END                      
                       
 ELSE                      
     insert into TB_MONITORAMENTO                      
     (                      
      [Site]                      
     , SalaOffline                      
     , DataAgendamento                      
     ,   AgendasTotais                      
     , ProvasTotais                        
     , ProvasPendentes             
     , DataVerificacao                         
     , Observacao                      
     )                      
     values                      
     (                      
      'ES'                      
     , 'GUARAPARI'                      
     , DATEADD(DAY,1,@data)                      
     , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  54)                       
     , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  54)                        
     +                       
      (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a inner join DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B                      
      ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  54)                       
     , NULL                      
   , GETDATE()                      
     , 'Sem link de Comunicação com GUARAPARI!'                      
     )                
 ------------------------------------------------------------------------------------------------------------------------------------------------                      
 ------------------------------------------------------------------------------------------------------------------------------------------------                      
       
-- ------------------------------------------------------------------------------------------------------------------------------------------------                      
               
EXEC @RetornoLk = [checkLinkedServer] CACHOEIRA                      
                       
 IF @RetornoLk = 1                      
 BEGIN                      
  SET @Contador = 1                      
  SET @data =  convert(varchar,getdate(),112)                      
                    
  delete @table                      
  insert into @table                      
  select * from  CACHOEIRA.DB_ES_PROVA_DIGITAL.dbo.VwProvaEnviada where DT_DIA between @data  and DATEADD(DAY,5,@data) order by dt_dia, hr_prova                      
                        
  WHILE @CONTADOR <= 5                      
  BEGIN                      
  insert into TB_MONITORAMENTO                      
   select  DISTINCT                      
    'ES'                      
   , 'CACHOEIRO'                      
   , @Data                      
   , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  52)  as [Total Agendas]                      
   , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  52)                        
   +                       
    (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a                       
    inner join DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B                      
    ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  52)  as [Total Provas]                      
   , (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS AS A (NOLOCK)  WHERE NOT EXISTS (SELECT  top 1 1                       
                          from @table as B                      
                          where                       
                           A.DT_DIA = B.DT_DIA                      
                          and A.HR_PROVA = B.HR_PROVA                      
                          and A.CD_SALA = B.CD_SALA                     
                          and A.NU_RENACH = B.NU_RENACH                      
                          and A.NU_CPF = B.NU_CPF)                      
                      AND  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  52)                      
   , getdate()                      
   , ''                      
   from                       
    DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS AS A with (nolock)                      
   where                       
    CD_SALA = 52                      
   --and  DT_DIA between @data  and DATEADD(DAY,5,@data)                      
                         
   SET @DATA = @DATA + 1                       
   SET @CONTADOR = @Contador + 1                 
  END                       
                         
 END                      
                       
 ELSE                      
     insert into TB_MONITORAMENTO                      
     (                      
      [Site]                      
     , SalaOffline                      
     , DataAgendamento                      
     ,   AgendasTotais                      
     , ProvasTotais                        
     , ProvasPendentes                       
     , DataVerificacao                         
     , Observacao                      
     )                      
     values                      
     (                      
      'ES'                      
     , 'CACHOEIRO'                      
     , DATEADD(DAY,1,@data)                      
     , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  52)               
  , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  52)                        
     +                       
      (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a inner join DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B                      
      ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  52)                       
     , NULL                      
    , GETDATE()                      
     , 'Sem link de Comunicação com CACHOEIRO!'                      
 )                
 ------------------------------------------------------------------------------------------------------------------------------------------------                      
 ------------------------------------------------------------------------------------------------------------------------------------------------                      
              
              
     
EXEC @RetornoLk = [checkLinkedServer] SAOFRANCISCO                      
                       
 IF @RetornoLk = 1                      
 BEGIN                      
  SET @Contador = 1                      
  SET @data =  convert(varchar,getdate(),112)                      
                    
  delete @table                      
  insert into @table                      
  select * from  SAOFRANCISCO.DB_ES_PROVA_DIGITAL.dbo.VwProvaEnviada where DT_DIA between @data  and DATEADD(DAY,5,@data) order by dt_dia, hr_prova                      
                        
  WHILE @CONTADOR <= 5                      
  BEGIN                      
  insert into TB_MONITORAMENTO                      
   select  DISTINCT                      
    'ES'                      
   , 'SAO FRANCISCO'                      
   , @Data                      
   , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  55)  as [Total Agendas]                      
   , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  55)                        
   +                       
    (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a                       
    inner join DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B                      
    ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  55)  as [Total Provas]                      
   , (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS AS A (NOLOCK)  WHERE NOT EXISTS (SELECT  top 1 1                       
                          from @table as B                      
                          where                       
                           A.DT_DIA = B.DT_DIA                      
                          and A.HR_PROVA = B.HR_PROVA                      
                          and A.CD_SALA = B.CD_SALA                      
                          and A.NU_RENACH = B.NU_RENACH                      
                          and A.NU_CPF = B.NU_CPF)                      
                      AND  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  55)                      
   , getdate()                      
   , ''                      
   from                       
    DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS AS A with (nolock)             
   where                       
    CD_SALA = 55                      
   --and  DT_DIA between @data  and DATEADD(DAY,5,@data)                      
                         
   SET @DATA = @DATA + 1                       
   SET @CONTADOR = @Contador + 1      
  END                       
                         
 END                      
                       
 ELSE                      
     insert into TB_MONITORAMENTO                      
     (                      
      [Site]                      
     , SalaOffline                      
     , DataAgendamento                      
     ,   AgendasTotais                      
     , ProvasTotais                        
     , ProvasPendentes                       
     , DataVerificacao                         
     , Observacao                      
     )                      
     values                      
     (                      
      'ES'                      
     , 'SAO FRANCISCO'        
     , DATEADD(DAY,1,@data)                      
     , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  55)                       
     , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  55)                        
     +                       
      (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a inner join DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B                      
      ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  55)                       
     , NULL                      
     , GETDATE()                      
     , 'Sem link de Comunicação com SAO FRANCISCO!'                      
   )                             
 ------------------------------------------------------------------------------------------------------------------------------------------------                      
 ------------------------------------------------------------------------------------------------------------------------------------------------                      
                   
EXEC @RetornoLk = [checkLinkedServer] LINHARES                      
                       
 IF @RetornoLk = 1                      
 BEGIN                      
  SET @Contador = 1                      
  SET @data =  convert(varchar,getdate(),112)                      
                    
  delete @table                      
  insert into @table                      
  select * from  LINHARES.DB_ES_PROVA_DIGITAL.dbo.VwProvaEnviada where DT_DIA between @data  and DATEADD(DAY,5,@data) order by dt_dia, hr_prova                      
                        
  WHILE @CONTADOR <= 5                      
  BEGIN                      
  insert into TB_MONITORAMENTO                      
   select  DISTINCT                      
    'ES'                      
   , 'LINHARES'                      
   , @Data                      
   , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  56)  as [Total Agendas]                      
   , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  56)                        
  +                       
    (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a                       
    inner join DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B                      
    ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  56)  as [Total Provas]                      
   , (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS AS A (NOLOCK)  WHERE NOT EXISTS (SELECT  top 1 1                       
                          from @table as B                      
                          where              
                           A.DT_DIA = B.DT_DIA                      
                          and A.HR_PROVA = B.HR_PROVA                      
                          and A.CD_SALA = B.CD_SALA                      
                          and A.NU_RENACH = B.NU_RENACH                      
                          and A.NU_CPF = B.NU_CPF)                      
                      AND  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  56)                      
   , getdate()                      
   , ''                      
   from                       
    DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS AS A with (nolock)                      
   where                       
    CD_SALA = 56                      
   --and  DT_DIA between @data  and DATEADD(DAY,5,@data)               
                         
   SET @DATA = @DATA + 1                       
   SET @CONTADOR = @Contador + 1                      
  END                       
                         
 END                      
                       
 ELSE                      
     insert into TB_MONITORAMENTO                      
     (                      
      [Site]                      
     , SalaOffline                      
     , DataAgendamento                      
     ,   AgendasTotais                      
     , ProvasTotais                        
     , ProvasPendentes                       
     , DataVerificacao                         
     , Observacao                      
     )                      
     values                      
     (                      
      'ES'                    
     , 'LINHARES'                      
     , DATEADD(DAY,1,@data)                      
     , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  56)                       
     , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  56)                        
     +                       
      (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a inner join DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B                      
      ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  56)                       
     , NULL                      
     , GETDATE()                      
     , 'Sem link de Comunicação com LINHARES!'                      
     )                      
------------------------------------------------------------------------------------------------------------------------------------------------                      
------------------------------------------------------------------------------------------------------------------------------------------------                      
     EXEC @RetornoLk = [checkLinkedServer] VILAVELHA                      
                       
 IF @RetornoLk = 1                      
 BEGIN                      
  SET @Contador = 1                      
  SET @data =  convert(varchar,getdate(),112)                      
                    
  delete @table                      
  insert into @table                      
  select * from  VILAVELHA.DB_ES_PROVA_DIGITAL.dbo.VwProvaEnviada where DT_DIA between @data  and DATEADD(DAY,5,@data) order by dt_dia, hr_prova                      
                        
  WHILE @CONTADOR <= 5                      
  BEGIN                      
  insert into TB_MONITORAMENTO          
   select  DISTINCT                      
    'ES'                      
   , 'VILA VELHA'                   
   , @Data                      
   , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  57)  as [Total Agendas]                      
   , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  57)                        
   +                       
    (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a                       
    inner join DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B                      
    ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  57)  as [Total Provas]                      
   , (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS AS A (NOLOCK)  WHERE NOT EXISTS (SELECT  top 1 1                       
                          from @table as B                      
                          where   
                           A.DT_DIA = B.DT_DIA                      
                          and A.HR_PROVA = B.HR_PROVA                      
     and A.CD_SALA = B.CD_SALA                      
                          and A.NU_RENACH = B.NU_RENACH                      
                          and A.NU_CPF = B.NU_CPF)                      
                      AND  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  57)                      
   , getdate()                      
   , ''                      
   from                       
    DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS AS A with (nolock)                      
   where                       
    CD_SALA = 57                      
   --and  DT_DIA between @data  and DATEADD(DAY,5,@data)                      
                         
   SET @DATA = @DATA + 1                       
   SET @CONTADOR = @Contador + 1      
  END                       
                         
 END                      
                       
 ELSE                      
     insert into TB_MONITORAMENTO                      
     (                      
      [Site]                      
     , SalaOffline                      
     , DataAgendamento                      
     ,   AgendasTotais                      
     , ProvasTotais                        
     , ProvasPendentes                       
     , DataVerificacao                         
     , Observacao             
     )                      
     values                      
     (                      
      'ES'                      
     , 'VILA VELHA'                      
     , DATEADD(DAY,1,@data)                      
     , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  57)                       
     , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  57)                        
     +                       
      (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a inner join DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B                      
 ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  57)                       
     , NULL                      
     , GETDATE()                      
     , 'Sem link de Comunicação com VILA VELHA!'                      
     )                      
                     
          
------------------------------------------------------------------------------------------------------------------------------------------------                      
------------------------------------------------------------------------------------------------------------------------------------------------                      
 EXEC @RetornoLk = [checkLinkedServer] SAOMATEUS                      
                       
 IF @RetornoLk = 1                      
 BEGIN                      
  SET @Contador = 1                      
  SET @data =  convert(varchar,getdate(),112)                      
                    
  delete @table                      
  insert into @table                      
  select * from  SAOMATEUS.DB_ES_PROVA_DIGITAL.dbo.VwProvaEnviada where DT_DIA between @data  and DATEADD(DAY,5,@data) order by dt_dia, hr_prova                      
                        
  WHILE @CONTADOR <= 5                      
  BEGIN                      
  insert into TB_MONITORAMENTO                      
   select  DISTINCT                      
    'ES'                      
   , 'SAO MATEUS'                      
   , @Data                      
   , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  58)  as [Total Agendas]                      
   , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  58)                        
   +                       
    (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a                       
    inner join DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B                      
    ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  58)  as [Total Provas]                      
   , (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS AS A (NOLOCK)  WHERE NOT EXISTS (SELECT  top 1 1                       
                          from @table as B                     
                          where                       
                           A.DT_DIA = B.DT_DIA                      
                          and A.HR_PROVA = B.HR_PROVA                      
                          and A.CD_SALA = B.CD_SALA                      
         and A.NU_RENACH = B.NU_RENACH                      
                          and A.NU_CPF = B.NU_CPF)                      
                      AND  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  58)                      
   , getdate()                      
   , ''                      
   from                       
    DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS AS A with (nolock)                      
   where                       
    CD_SALA = 58                      
   --and  DT_DIA between @data  and DATEADD(DAY,5,@data)                      
                         
   SET @DATA = @DATA + 1                       
   SET @CONTADOR = @Contador + 1                      
  END                       
                         
 END                      
                       
 ELSE                      
     insert into TB_MONITORAMENTO                      
     (                      
      [Site]                      
     , SalaOffline                      
     , DataAgendamento                      
     , AgendasTotais                      
     , ProvasTotais                        
     , ProvasPendentes                       
     , DataVerificacao                         
     , Observacao             
     )                      
     values                      
     (                      
      'ES'                      
     , 'SAO MATEUS'                      
     , DATEADD(DAY,1,@data)        
     , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  58)                       
     , (select count(1) from DB_ES_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  58)                        
     +                       
      (SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a inner join DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B                      
      ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  58)                       
     , NULL                      
     , GETDATE()                      
     , 'Sem link de Comunicação com SAO MATEUS!'                      
     )                      
                      
                       
END 




GO




    
    DECLARE @CD_SALA INT = 52
    DECLARE @data datetime                  
    DECLARE @LK SYSNAME
    DECLARE @EXEC NVARCHAR(MAX)

    DECLARE @TABLE TABLE                       
    (                      
        CD_PROVA bigint                      
    , 	NU_RENACH bigint                      
    , 	NU_CPF bigint                      
    , 	DT_INICIO datetime                      
    , 	DT_FIM  datetime                      
    , 	DT_DIA  datetime                      
    , 	HR_PROVA varchar(5)                      
    , 	CD_SALA   int                      
    ) 
    BEGIN TRY 
        SET @LK = (SELECT DS_SALA FROM TB_LKS WHERE CD_SALA = @CD_SALA)
        SET @EXEC = 
            'DECLARE @data datetime                  
            SET @data =  convert(varchar,getdate(),112)   
            SELECT * FROM  '
        +	@LK
        +   '.DB_ES_PROVA_DIGITAL.DBO.VWPROVAENVIADA WHERE DT_DIA BETWEEN @DATA  AND DATEADD(DAY,5,@DATA) ORDER BY DT_DIA, HR_PROVA'
        INSERT INTO @table
        EXEC (@EXEC) 
        INSERT INTO TB_MONITORAMENTO                      
        (
            Site
        ,	SalaOffline
        ,	DataAgendamento
        ,	AgendasTotais
        ,	ProvasTotais
        ,	ProvasPendentes
        ,	DataVerificacao
        ,	Observacao
        )
        SELECT  
            DISTINCT                      
            'ES'                      
        ,	@LK                      
        ,	@DATA                      
        , 	(SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS(NOLOCK) 
                    WHERE  DT_DIA = CONVERT(VARCHAR,@DATA ,112) AND CD_SALA =  @CD_SALA)  AS [TOTAL AGENDAS]                      
        , 	(SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.DBO.TB_PROVAS(NOLOCK) 
                        WHERE  DT_DIA = CONVERT(VARCHAR,@DATA ,112) AND CD_SALA =  @CD_SALA)                         
        +   (
                SELECT COUNT(1) FROM DB_ES_PROVA_DIGITAL.DBO.TB_HISTORICOS_PROVAS_EXCLUIDAS AS A                       
                INNER JOIN DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B                      
                    ON A.DT_DIA = B.DT_DIA 
                    AND A.NU_RENACH = B.NU_RENACH 
                    AND A.NU_CPF = B.NU_CPF 
                    AND A.HR_PROVA = B.HR_PROVA 
                    AND A.CD_SALA = B.CD_SALA 
                    WHERE A.DT_DIA = CONVERT(VARCHAR,@DATA ,112) AND A.CD_SALA =  @CD_SALA
            )  AS [TOTAL PROVAS]                      
        , 	(
                SELECT COUNT(1) 
                FROM DB_ES_PROVA_DIGITAL.DBO.TB_PROVAS AS A (NOLOCK)  
                WHERE NOT EXISTS 
                (
                    SELECT  TOP 1 1                       
                    FROM 
                        @TABLE AS B                      
                    WHERE                       
                        A.DT_DIA = B.DT_DIA                      
                    AND 	A.HR_PROVA = B.HR_PROVA                      
                    AND 	A.CD_SALA = B.CD_SALA                      
                    AND 	A.NU_RENACH = B.NU_RENACH                      
                    AND 	A.NU_CPF = B.NU_CPF
            )                      
            AND  	DT_DIA = CONVERT(VARCHAR,@DATA ,112) 
            AND CD_SALA =  @CD_SALA
            ) 
        ,	GETDATE()            
        , 	''                      
        FROM                       
            DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS A WITH (NOLOCK)                      
        WHERE                       
            CD_SALA = @CD_SALA
    END TRY
    BEGIN CATCH
        SELECT  
        ERROR_LINE() AS [ERROR_LINE],
        ERROR_MESSAGE() AS [ERROR_MESSAGE],
        ERROR_NUMBER() AS [ERROR_NUMBER],
        ERROR_PROCEDURE() AS [ERROR_PROCEDURE],
        ERROR_SEVERITY() AS [ERROR_SEVERITY],
        ERROR_STATE() AS [ERROR_STATE]; 
    END CATCH 