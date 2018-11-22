use msdb 
go
/*
select * from sysmail_account
select * from sysmail_attachments
select * from sysmail_attachments_transfer
select * from sysmail_configuration
select top 10 * from sysmail_log order by 1 desc
select * from sysmail_mailitems
select * from sysmail_principalprofile
select * from sysmail_profile
select * from sysmail_profileaccount
select * from sysmail_query_transfer
select * from sysmail_send_retries
select * from sysmail_server
select * from sysmail_servertype
select * from sysmail_profile
sysmail_stop_sp  
go
sysmail_start_sp  
*/
--================================================================
-- DATABASE MAIL CONFIGURATION
--================================================================
--==========================================================
-- Create a Database Mail account
--==========================================================
EXECUTE msdb.dbo.sysmail_add_account_sp
    @account_name = 'DBA_ALERT',
    @description = 'Envio de alertas de email',
    @email_address = 'dba@thomasgreg.com.br',
    @replyto_address = 'dba@thomasgreg.com.br',
    @display_name = 'DBA ALERT',
    @mailserver_name = '10.11.0.89',
	@port = 25;

--==========================================================
-- Create a Database Mail Profile
--==========================================================
DECLARE @profile_id INT, @profile_description sysname;
SELECT @profile_id = COALESCE(MAX(profile_id),1) FROM msdb.dbo.sysmail_profile
SELECT @profile_description = 'Database Mail Profile for ' + @@servername 


EXECUTE msdb.dbo.sysmail_add_profile_sp
    @profile_name = 'DBA',
    @description = @profile_description;

-- Add the account to the profile
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = 'DBA',
    @account_name = 'DBA_ALERT',
    @sequence_number = @profile_id;

-- Grant access to the profile to the DBMailUsers role
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = 'DBA',
    @principal_id = 0,
    @is_default = 1 ;


--==========================================================
-- Enable Database Mail
--==========================================================
USE master;
GO
sp_CONFIGURE 'show advanced', 1
GO
RECONFIGURE
GO
sp_CONFIGURE 'Database Mail XPs', 1
GO
RECONFIGURE
GO 
--EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'DatabaseMailProfile', N'REG_SZ', N''
--EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'UseDatabaseMail', N'REG_DWORD', 1
--GO

EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder = 0
GO
--==========================================================
-- Review Outcomes
--==========================================================
SELECT * FROM msdb.dbo.sysmail_profile;
SELECT * FROM msdb.dbo.sysmail_account;
GO
--==========================================================
-- Test Database Mail
--==========================================================
DECLARE @sub VARCHAR(100)
DECLARE @body_text NVARCHAR(MAX)
SELECT @sub = 'Test from New SQL install on ' + @@servername
SELECT @body_text = N'This is a test of Database Mail.' + CHAR(13) + CHAR(13) + 'SQL Server Version Info: ' + CAST(@@version AS VARCHAR(500))

EXEC msdb.dbo.[sp_send_dbmail] 
    @profile_name = 'DBA'
  , @recipients = 'dba@thomasgreg.com.br'
  , @subject = @sub
  , @body = @body_text
--================================================================
-- SQL Agent Properties Configuration
--================================================================
EXEC msdb.dbo.sp_set_sqlagent_properties 
	@databasemail_profile = 'DBA'
	, @use_databasemail=1
GO
USE MSDB 
select top 10 * from sysmail_log order by 1 desc
GO
USE DbManagementDBA
GO
if object_id('SpVerUltimoBackup') is not null drop proc SpVerUltimoBackup;
go
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
		AND sdb.state_desc   = 'ONLINE'
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
GO
IF OBJECT_ID('SpEnviaEmailBackupNaoEfetuado') is not null drop proc SpEnviaEmailBackupNaoEfetuado;
go
CREATE PROCEDURE SpEnviaEmailBackupNaoEfetuado
AS
BEGIN
	IF OBJECT_ID('TEMPDB..#RetornaUlltimoBackup') IS NOT NULL DROP TABLE #RetornaUlltimoBackup;
	create table #RetornaUlltimoBackup
	(
		DatabaseName			varchar(500)
	,	RecoveryDesc			varchar(500)
	,	DataUltimoBackup		varchar(500)
	,	HoraUltimoBackup		varchar(500)
	,	DiasSemBackup			int 
	,	DataVerificacao			varchar(500) default convert(varchar,  getdate() , 103)
	)
	insert into #RetornaUlltimoBackup
	(
		DatabaseName	
	,	RecoveryDesc	
	,	DataUltimoBackup
	,	HoraUltimoBackup
	,	DiasSemBackup	
	)
	EXECUTE DbManagementDBA..SpVerUltimoBackup
	IF EXISTS (SELECT TOP 1 1 FROM #RetornaUlltimoBackup )
		BEGIN 
			DECLARE @xml NVARCHAR(MAX)
			DECLARE @body NVARCHAR(MAX)
			DECLARE @MACHINENAME VARCHAR(MAX)
			DECLARE @subject_ENVIO  VARCHAR(MAX)
		
			SET @MACHINENAME  = REPLACE(CAST(SERVERPROPERTY('MachineName')  AS VARCHAR(MAX)) ,'-','' )
			SET @subject_ENVIO   = 'Verificar Backups pendentes em ' + @MACHINENAME 

			SET @xml = 
			CAST(
					( 
						SELECT 
							DatabaseName			AS 'td'
						,	''
						,	RecoveryDesc			AS 'td'
						,	''
						,   DataUltimoBackup		AS 'td'
						,	''
						,	HoraUltimoBackup		AS 'td'
						,	''
						,	DiasSemBackup			AS 'td'
						,	''
						,	DataVerificacao			AS 'td'
			
				FROM  
					#RetornaUlltimoBackup 
				ORDER BY 
					DatabaseName 
				FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX)
			)

			SET @body ='<html><body><H3>Os bancos informados abaixo estão sem backup a mais de um dia</H3>
			<table border = 1> 
			<tr>
			<th> DatabaseName </th> <th> RecoveryDesc  </th> <th> DataUltimoBackup </th> <th> HoraUltimoBackup  </th> <th> DiasSemBackup  </th> <th> DataVerificacao <th>'   
			SET @body = @body + @xml +'</table></body></html>'
			EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'DBA', -- replace with your SQL Database Mail Profile 
			@body = @body,
			@body_format ='HTML',
			@recipients = 'dba@thomasgreg.com.br;douglas.porto@thomasgreg.com.br;dporto.ti@gmail.com', -- replace with your email address
			@subject =  @subject_ENVIO
		END;
END;
GO
use DbManagementDBA
go
IF OBJECT_ID('SpEnviaEmailTamanhoUnidadesLocais') is not null drop proc SpEnviaEmailTamanhoUnidadesLocais;
go
CREATE  PROCEDURE SpEnviaEmailTamanhoUnidadesLocais
AS
BEGIN
	DECLARE @xml NVARCHAR(MAX)
	DECLARE @body NVARCHAR(MAX)
	DECLARE @MACHINENAME VARCHAR(MAX)
	DECLARE @subject_ENVIO  VARCHAR(MAX)

	SET @MACHINENAME  = REPLACE(CAST(SERVERPROPERTY('MachineName')  AS VARCHAR(MAX)) ,'-','' )
	SET @subject_ENVIO   = 'Tamanho unidades de Disco locais do servidor: ' + @MACHINENAME 

	SET @xml = 
	CAST(					
		( 
			SELECT
				ServerName AS 'td' 
			,	''
			,	ServiceName AS 'td'
			,	''
			,	convert(varchar, DataVerificacao,103)    AS 'td'
			,	''
			,	UnidadeDisco AS 'td'
			,	''
			,	Livre_MB AS 'td'
			,	''
			,	Total_MB AS 'td'
			,	''
			,	Livre_PCT AS 'td'
			FROM
				TamanhoUnidadesLocais 
			WHERE
				DataVerificacao = (select max(DataVerificacao) from TamanhoUnidadesLocais)
			and Livre_PCT <= 20
			ORDER BY UnidadeDisco
			FOR XML PATH('tr'), ELEMENTS 
			) AS NVARCHAR(MAX)
		)

		SET @body ='<html><body><H3>Espaço das Unidades de Disco</H3>
		<table border = 1> 
		<tr>
		<th> ServerName </th> <th> ServiceName  </th> <th> DataVerificacao </th> <th> UnidadeDisco  </th> <th> Livre_MB  </th> <th> Total_MB </th> <th> Livre_PCT <th>'   
		SET @body = @body + @xml +'</table></body></html>'
		EXEC msdb.dbo.sp_send_dbmail
		@profile_name = 'DBA', 
		@body = @body,
		@body_format ='HTML',
		@recipients = 'dba@thomasgreg.com.br;douglas.porto@thomasgreg.com.br;dporto.ti@gmail.com',
		@subject =  @subject_ENVIO
END
gO