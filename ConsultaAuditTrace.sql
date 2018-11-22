declare @trc_id int  = (select max(id) from sys.traces)
declare @path varchar(max) = null
select @path = path from sys.traces   
where id = @trc_id
select    
	EventSequence
,	TextData
,	HostName
,	ApplicationName
,	LoginName
,	SPID
,	Duration
,	StartTime
,	EndTime
,	ServerName
,	ObjectName
,	DatabaseName
from 
    ::fn_trace_gettable (@path,@trc_id) 
--where 
--	TextData not like  'exec sp_reset_connection%'
	--ApplicationName = '.Net SqlClient Data Provider'
order by StartTime , 1
go 
/**********************************CONSULTA PROFILER**************************/ 
exec sp_trace_setstatus 2,0 --STOP PRPOFILER
go 
exec sp_trace_setstatus 2,2 --DELETE PROFILER
go
execute xp_cmdshell 'DEL C:\ProfilerProd\GetProfiler_01\*.* /q' --LIMPAR ARQUIVOS TABELA 

/**********************************CONSULTA AUDITORIA DDL**************************/ 
SELECT top 100	
	CONVERT(datetime,SWITCHOFFSET(CONVERT(datetimeoffset, event_time), DATENAME(TzOffset, SYSDATETIMEOFFSET())))  AS 'horario',
	database_name + '.' + schema_name + '.' + object_name 'objeto',
	statement,
	server_principal_name 'login',
	session_server_principal_name 'user',
	succeeded,
	IIF(succeeded <> 1 , 'Falha', 'Sucesso') ,
	action_id,
	db_name(target_database_principal_id) as [Database],
	session_id
FROM 
	sys.fn_get_audit_file (N'C:\AuditarCFM\Auditorias\adtDDL\*',default,default)
ORDER BY horario   desc
select * from sys.server_file_audits
/**********************************CONSULTA AUDITORIA DDL**************************/ 
/**********************************CONSULTA AUDITORIA DML**************************/ 
SELECT top 500
	CONVERT(datetime,SWITCHOFFSET(CONVERT(datetimeoffset, event_time), DATENAME(TzOffset, SYSDATETIMEOFFSET())))  AS 'horario',
	database_name + '.' + schema_name + '.' + object_name 'objeto',
	statement,
	server_principal_name 'login',
	session_server_principal_name 'user',
	succeeded,
	IIF(succeeded <> 1 , 'Falha', 'Sucesso') ,
	action_id
FROM 
	sys.fn_get_audit_file (N'C:\AuditarCFM\Auditorias\adtDml\*',null,null)
ORDER BY 1  desc
/**********************************CONSULTA AUDITORIA DML**************************/ 