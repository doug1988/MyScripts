create procedure SpVerUltimoBackup
AS
BEGIN
	;WITH CteDataUltimosBackups
	as
	(
		SELECT 
			sdb.Name AS DatabaseName
        ,	sdb.recovery_model_desc
		,	COALESCE(CONVERT(VARCHAR(108), MAX(bus.backup_finish_date), 120),'-')  AS DataUltimoBackup
		,	COALESCE(CONVERT(VARCHAR(108), MAX(bus.backup_finish_date), 108),'-')  AS HoraUltimoBackup
		FROM 
			sys.databases sdb
		LEFT OUTER JOIN msdb.dbo.backupset bus 
			ON bus.database_name = sdb.name
		where
			sdb.database_id <> 2
		AND sdb.state_desc = 'ONLINE'
		AND sdb.is_read_only = 0 
		AND bus.is_copy_only = 0 
		GROUP BY 
			sdb.Name, sdb.recovery_model_desc
	)
	select 
		DatabaseName
	,	recovery_model_desc
	,	convert(varchar, cast(DataUltimoBackup as date) ,103) as DataUltimoBackup
	,	HoraUltimoBackup
	,	DATEDIFF(Day, cast(DataUltimoBackup as date), GETDATE()) 'Dias Sem Backup'
	from 
		CteDataUltimosBackups
	WHERE
		DATEDIFF(Day, cast(DataUltimoBackup as date), GETDATE()) > 1
	order by 1 
END;

