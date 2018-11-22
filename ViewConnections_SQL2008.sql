;WITH ConnectionsSessions AS
(
SELECT 
		Z.DatabaseName,
        Z.ObjName,
        Z.Query,		
		s.client_interface_name,
		C.client_net_address,
		C.session_id,
        C.connect_time,
        S.login_time,
        S.login_name,
        C.net_transport,
        C.num_reads,
        C.last_read,
        C.num_writes,
        C.last_write,        
        --C.most_recent_sql_handle,
        S.status,
        CASE WHEN S.status = 'Running' THEN 'Executando Uma ou Mais Requisições'
                WHEN S.status = 'Sleeping' THEN 'Executando Sem Requisições'
                WHEN S.status = 'Dormant' THEN 'Reiniciada pelo Pool de Conexões' ELSE S.status END ASTipoStatus,
        S.cpu_time,
        S.memory_usage,
        S.reads,
        S.logical_reads,
        S.writes,
        CASE WHEN S.transaction_isolation_level = 0 THEN 'Não Especificado'
                WHEN S.transaction_isolation_level = 1 THEN 'Read Uncomitted'
                WHEN S.transaction_isolation_level = 2 THEN 'Read Committed'
                WHEN S.transaction_isolation_level = 3 THEN 'Repeatable'
                WHEN S.transaction_isolation_level = 4 THEN 'Serializable'
                WHEN S.transaction_isolation_level = 5 THEN 'Snapshot' END AS TipoIsolationLevel,
        S.last_request_start_time,
        S.last_request_end_time,
        program_name      
        
FROM sys.dm_exec_connections AS C
INNER JOIN sys.dm_exec_sessions AS S
ON C.session_id = S.session_id
CROSS APPLY 
	(
		SELECT DB_NAME(dbid) AS DatabaseName
			,OBJECT_NAME(objectid) AS ObjName
			,COALESCE((
				SELECT TEXT AS [processing-instruction(definition)]
				FROM sys.dm_exec_sql_text(C.most_recent_sql_handle)
				FOR XML PATH('')
					,TYPE
				), '') AS Query

		FROM sys.dm_exec_sql_text(C.most_recent_sql_handle)
	) AS Z
)
SELECT 
	*
FROM 
	ConnectionsSessions
WHERE 
	net_transport = 'TCP'	

ORDER BY 
	client_net_address
