

SELECT TOP 10 SUBSTRING( qt.TEXT , ( qs.statement_start_offset /2)+ 1,
((CASE qs.statement_end_offset
WHEN - 1 THEN DATALENGTH(qt .TEXT)
ELSE qs .statement_end_offset
END - qs. statement_start_offset)/2 )+1),
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
CROSS APPLY sys. dm_exec_sql_text(qs .sql_handle) qt
CROSS APPLY sys. dm_exec_query_plan(qs .plan_handle) qp
ORDER BY qs .total_worker_time DESC -- tempo de CPU