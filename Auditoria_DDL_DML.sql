/****************DROP NAS AUDITORIAS*********************/
/*
USE MASTER
GO
ALTER SERVER AUDIT [Audit-Demo-DDL] WITH (STATE=OFF) ;
go
DROP SERVER AUDIT [Audit-Demo-DDL]; 
go
ALTER SERVER AUDIT SPECIFICATION [Spec-Demo-DDL] WITH (STATE=OFF);
go
DROP SERVER AUDIT SPECIFICATION [Spec-Demo-DDL] ;
go
ALTER SERVER AUDIT [Audit-Demo-DML] WITH (STATE=OFF) ;
go
DROP SERVER AUDIT [Audit-Demo-DML];
GO
USE DbVotosCFM--BANCO QUE SERA AUDITADO
GO
ALTER DATABASE AUDIT SPECIFICATION [DatabaseAuditSpec1] WITH (STATE = off)
drop DATABASE AUDIT SPECIFICATION [DatabaseAuditSpec1]
go
*/
EXEC sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
EXEC sp_configure 'xp_cmdshell', 1
GO
RECONFIGURE
GO
EXECUTE XP_CMDSHELL 'MD C:\AuditarCFM\Auditorias\adtDDL'
EXECUTE XP_CMDSHELL 'MD C:\AuditarCFM\Auditorias\adtDML'
/**********************************TRILHA AUDITORIA DDL**************************/
USE master
GO
CREATE SERVER AUDIT [Audit-Demo-DDL]
TO FILE 
(	FILEPATH = N'C:\AuditarCFM\Auditorias\adtDDL'
	,MAXSIZE = 1024 MB
	,MAX_ROLLOVER_FILES = 2147483647
	,RESERVE_DISK_SPACE = OFF
)
WITH
(	QUEUE_DELAY = 1000
	,ON_FAILURE = CONTINUE
)
CREATE SERVER AUDIT SPECIFICATION [Spec-Demo-DDL]
FOR SERVER AUDIT [Audit-Demo-DDL]
	ADD (DATABASE_CHANGE_GROUP),					 -- database is created, altered, or dropped
	ADD (DATABASE_OBJECT_CHANGE_GROUP),				 -- CREATE, ALTER, or DROP statement is executed on database objects, such as schemas
	ADD (DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP),	 -- 
	ADD (DATABASE_OBJECT_PERMISSION_CHANGE_GROUP),	 -- a GRANT, REVOKE, or DENY has been issued for database objects, such as assemblies and schemas
	ADD (DATABASE_OWNERSHIP_CHANGE_GROUP),			 -- use of ALTER AUTHORIZATION statement to change the owner of a database, and the permissions that are required to do that are checked
	ADD (DATABASE_PERMISSION_CHANGE_GROUP),			 -- GRANT, REVOKE, or DENY is issued for a statement permission by any principal in SQL Server 
	ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),			 -- raised when principals, such as users, are created, altered, or dropped from a database.
	ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),		 -- a login is added to or removed from a database role. This event class is raised for the sp_addrolemember, sp_changegroup, and sp_droprolemember stored procedures
	ADD (LOGIN_CHANGE_PASSWORD_GROUP),				 -- a login password is changed by way of ALTER LOGIN statement or sp_password stored procedure
	ADD (SERVER_OBJECT_CHANGE_GROUP),				 -- CREATE, ALTER, or DROP operations on server objects
	ADD (SERVER_OBJECT_OWNERSHIP_CHANGE_GROUP),		 -- owner is changed for objects in the server scope. 
	ADD (SERVER_OBJECT_PERMISSION_CHANGE_GROUP),	 -- GRANT, REVOKE, or DENY is issued for a server object permission by any principal in SQL Server
	ADD (SERVER_PERMISSION_CHANGE_GROUP),			 -- GRANT, REVOKE, or DENY is issued for permissions in the server scope, such as creating a login.
	ADD (SERVER_PRINCIPAL_CHANGE_GROUP),			
    ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP),          -- server principals are created, altered, or dropped. 
	ADD ( DATABASE_LOGOUT_GROUP ),					-- a principal issues the sp_defaultdb or sp_defaultlanguage stored procedures or ALTER LOGIN statements
	ADD ( FAILED_DATABASE_AUTHENTICATION_GROUP ),			 -- sp_addlogin and sp_droplogin stored procedures.
	ADD ( USER_DEFINED_AUDIT_GROUP ),						 -- sp_grantlogin or sp_revokelogin stored procedures
	ADD ( SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP ),						-- a login is added or removed from a fixed server role. This event is raised for the sp_addsrvrolemember and sp_dropsrvrolemember stored procedures. 
	ADD (FAILED_LOGIN_GROUP),
	ADD (SUCCESSFUL_LOGIN_GROUP),
	ADD (AUDIT_CHANGE_GROUP)
--DATABASE_OBJECT_CHANGE_GROUP
WITH (STATE=ON)
ALTER SERVER AUDIT [Audit-Demo-DDL] WITH (STATE=ON) ;
ALTER SERVER AUDIT SPECIFICATION [Spec-Demo-DDL] WITH (STATE=ON);
/**********************************TRILHA AUDITORIA DDL**************************/ 
select * from sys.dm_server_audit_status
/**********************************TRILHA AUDITORIA DDL**************************/ 
/**********************************TRILHA AUDITORIA DML**************************/ 
USE MASTER
CREATE SERVER AUDIT [Audit-Demo-DML]
TO FILE 
(	FILEPATH = N'C:\AuditarCFM\Auditorias\adtDML'
	,MAXSIZE = 1024 MB
	,MAX_ROLLOVER_FILES = 2147483647
	,RESERVE_DISK_SPACE = OFF
)
WITH
(	QUEUE_DELAY = 1000
	,ON_FAILURE = CONTINUE
)
USE DbVotosCFM
GO
CREATE DATABASE AUDIT SPECIFICATION [DatabaseAuditSpec1]
FOR SERVER AUDIT [Audit-Demo-DML]
ADD (INSERT ON DATABASE::[DbVotosCFM] BY [public]),
ADD (UPDATE ON DATABASE::[DbVotosCFM] BY [public]),
ADD (DELETE ON DATABASE::[DbVotosCFM] BY [public]),
ADD (DATABASE_OBJECT_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_CHANGE_GROUP)
WITH (STATE = ON);
GO
USE master
GO
ALTER SERVER AUDIT [Audit-Demo-DML] WITH (STATE = ON);
GO
USE DbVotosCFM
GO
ALTER DATABASE AUDIT SPECIFICATION [DatabaseAuditSpec1] WITH (STATE = ON)
GO
/**********************************TRILHA AUDITORIA DML**************************/ 
USE [master]
GO
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel', REG_DWORD, 3
GO
/**********************************CONSULTA AUITORIA DDL**************************/ 
SELECT
CAST( SERVERPROPERTY( 'MachineName' ) AS varchar( 30 ) ) AS MachineName ,
CAST( SERVERPROPERTY( 'InstanceName' ) AS varchar( 30 ) ) AS Instance ,
CAST( SERVERPROPERTY( 'ProductVersion' ) AS varchar( 30 ) ) AS ProductVersion ,
CAST( SERVERPROPERTY( 'ProductLevel' ) AS varchar( 30 ) ) AS ProductLevel ,
CAST( SERVERPROPERTY( 'Edition' ) AS varchar( 30 ) ) AS Edition ,
( CASE SERVERPROPERTY( 'EngineEdition')
WHEN 1 THEN 'Personal or Desktop'
WHEN 2 THEN 'Standard'
WHEN 3 THEN 'Enterprise'
END ) AS EngineType ,
CAST( SERVERPROPERTY( 'LicenseType' ) AS varchar( 30 ) ) AS LicenseType ,
SERVERPROPERTY( 'NumLicenses' ) AS #Licenses;


/**********************************CONSULTA AUDITORIA DDL**************************/ 
SELECT  
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
SELECT  
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
/**************************TRACE BASEADO EM fn_trace_gettable*******************************/
--https://blog.sqlauthority.com/2015/09/12/sql-server-who-dropped-table-or-database/
--https://blog.sqlauthority.com/2014/07/07/sql-server-ssms-schema-change-history-report/
--https://blog.sqlauthority.com/2014/07/04/sql-server-ssms-configuration-changes-history/
/**************************TRACE BASEADO EM fn_trace_gettable*******************************/
DECLARE @current VARCHAR(500);
DECLARE @start VARCHAR(500);
DECLARE @indx INT;
SELECT @current = path
FROM sys.traces
WHERE is_default = 1;
SET @current = REVERSE(@current)
SELECT @indx = PATINDEX('%\%', @current)
SET @current = REVERSE(@current)
SET @start = LEFT(@current, LEN(@current) - @indx) + '\log.trc';
-- CHNAGE FILER AS NEEDED
SELECT *
FROM::fn_trace_gettable(@start, DEFAULT)
--WHERE EventClass IN (92,93) -- growth event
where NTUserName not in ('SQLTELEMETRY$DEV_2017' , 'SSISScaleOutMaster140')
--and TextData like '%drop%'
ORDER BY StartTime DESC
/**************************TRACE BASEADO EM fn_trace_gettable*******************************/
go
/**************************PEGAR DROP TABLE  EM fn_trace_gettable*******************************/
DECLARE @current VARCHAR(500);
DECLARE @start VARCHAR(500);
DECLARE @indx INT;
SELECT @current = path
FROM sys.traces
WHERE is_default = 1;
SET @current = REVERSE(@current)
SELECT @indx = PATINDEX('%\%', @current)
SET @current = REVERSE(@current)
SET @start = LEFT(@current, LEN(@current) - @indx) + '\log.trc';
-- CHNAGE FILER AS NEEDED
SELECT CASE EventClass
WHEN 46 THEN 'Object:Created'
WHEN 47 THEN 'Object:Deleted'
WHEN 164 THEN 'Object:Altered'
END, DatabaseName, ObjectName, HostName, ApplicationName, LoginName, StartTime, TextData
FROM::fn_trace_gettable(@start, DEFAULT)
WHERE 
	--EventClass IN (46,47,164) 
	EventSubclass = 0 
AND DatabaseID <> 2 
and ObjectName <> 'telemetry_xevents'
ORDER BY StartTime DESC
/***********************************************************************************************/

 