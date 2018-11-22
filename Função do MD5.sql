use master
go
execute sp_addextendedproc 'fn_md5', 'D:\DadosSql\MSSQL13.MSSQLSERVER\MSSQL\DATA\dll_hash\md5Hash.dll';  --Local que consta a DLL do md5
go
use master
go
sp_CONFIGURE 'clr_enabled',1
GO
RECONFIGURE
GO




/*
use Dbrnsicca


select distinct   OBJECT_NAME(id) from syscomments  where text like  '%md5%' order by 1
fn_md5
SP_ALTERAR_SENHA
SP_ALTERAR_SENHA_USUARIO
SP_ALTERAR_USUARIO
SP_INSERIR_USUARIO
SP_SYNC_ALTERAR_USUARIO
sp_helptext fn_md5
Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE FUNCTION [dbo].[fn_md5] (@data TEXT) 
RETURNS char(32) 
AS 
BEGIN 
DECLARE @hash CHAR(32) 
SET @hash = substring(master.dbo.fn_varbintohexstr(HASHBYTES('MD5', cast(@data as varchar(50)))), 3, 32) 

--select CONVERT(VARCHAR(32), HashBytes('MD5', @data), 2) 

RETURN @hash 

END
use dbrnsicca
select dbo.fn_Md5('gfesgwsg')
*/
