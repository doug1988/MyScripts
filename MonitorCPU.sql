 --Verificaçaõ das Bases
 SELECT  name , recovery_model_desc, log_reuse_wait_desc FROM SYS.DATABASES   order by 1


--Bancos que mais usam CPU
WITH DB_CPU_Stats
AS
(
SELECT DatabaseID , DB_Name (DatabaseID) AS [DatabaseName] , SUM (total_worker_time ) AS [CPU_Time_Ms]
FROM sys .dm_exec_query_stats AS qs
CROSS APPLY (SELECT CONVERT( int, value ) AS [DatabaseID]
FROM sys .dm_exec_plan_attributes ( qs. plan_handle )
WHERE attribute = N'dbid') AS F_DB
GROUP BY DatabaseID)
SELECT ROW_NUMBER () OVER (ORDER BY [CPU_Time_Ms] DESC ) AS [row_num] ,
DatabaseName, [CPU_Time_Ms] ,
CAST([CPU_Time_Ms] * 1.0 / SUM( [CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL( 5 , 2 )) AS [CPUPercent]
FROM DB_CPU_Stats
WHERE DatabaseID > 4 -- system databases
AND DatabaseID <> 32767 -- ResourceDB
ORDER BY row_num OPTION ( RECOMPILE);


--Query mais Lentas
SELECT
        TOP 10 SUBSTRING ( qt. TEXT , ( qs .statement_start_offset / 2)+ 1 ,
((CASE qs .statement_end_offset
WHEN - 1 THEN DATALENGTH(qt .TEXT)
ELSE qs . statement_end_offset
END - qs. statement_start_offset )/2 )+ 1),
qs.execution_count ,
qs.total_logical_reads as total_leitura_memoria, qs.last_logical_reads as ultima_leitura_memoria,
qs.total_logical_writes as total_escrita_memoria, qs.last_logical_writes as ultima_escrita_memoria,
qs.total_physical_reads as total_leitura_disco, qs.last_physical_reads as ultima_leitura_disco,
qs.total_worker_time as tempo_CPU_total, qs.last_worker_time as ultimo_tempo_CPU,
qs.total_elapsed_time /1000000 as tempo_total_execucao,
qs.last_elapsed_time /1000000 as ultimo_tempo_execucao,
qs.last_execution_time as data_ultima_execucao,
qp.query_plan as plano_execucao
FROM sys .dm_exec_query_stats qs
CROSS APPLY sys. dm_exec_sql_text( qs .sql_handle ) qt
CROSS APPLY sys. dm_exec_query_plan( qs .plan_handle ) qp
--ORDER BY qs.total_logical_reads DESC -- ordenando por leituras em memória
-- ORDER BY qs.total_logical_writes DESC -- escritas em memória
 ORDER BY qs . total_worker_time DESC -- tempo de CPU
-- ORDER BY qs.total_physical_reads DESC -- leituras do disco
OPTION ( RECOMPILE);



----Query mais Lentas_2
SELECT
TOP 10
total_worker_time/execution_count AS AvgCPU 
, total_worker_time AS TotalCPU
, total_elapsed_time/ execution_count AS AvgDuration 
, total_elapsed_time AS TotalDuration 
, ( total_logical_reads+total_physical_reads )/execution_count AS AvgReads
, ( total_logical_reads+total_physical_reads ) AS TotalReads
, execution_count  
, SUBSTRING (st. TEXT, (qs. statement_start_offset/2 )+1 
, (( CASE qs. statement_end_offset  WHEN -1 THEN datalength( st.TEXT ) 
ELSE qs. statement_end_offset 
END - qs.statement_start_offset )/2) + 1 ) AS txt 
, query_plan
FROM sys .dm_exec_query_stats AS qs 
cross apply sys. dm_exec_sql_text(qs .sql_handle) AS st 
cross apply sys. dm_exec_query_plan ( qs.plan_handle ) AS qp
ORDER BY 1 DESC
OPTION ( RECOMPILE);



--Leitura do Log
execute xp_readerrorlog








