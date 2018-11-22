use master
go
declare 
	@ini datetime  =  cast(getdate() as date )
,	@fim datetime   =  DATEADD(DAY,1, cast(getdate() as date ))	 
declare @table table
(
    Data datetime
,	Processo varchar(100)
,	descricao varchar(max)
)
insert into @table
exec xp_readerrorlog
    0
,   1
,   null
,   null
,   @ini  -- Data inicio 
,   @fim; -- data fim 
select * from @table 
WHERE 	Processo NOT IN ('BACKUP', 'LOGON')
order by 1 desc



EXEC sp_CYCLE_ERRORLOG   --limpar o log de erro
GO




--elimina Database  is being recovered. Waiting until recovery is finished.
ALTER DATABASE DB_SERVIDOR_BLOB_MA_P SET AUTO_CLOSE OFF WITH NO_WAIT
ALTER DATABASE DbImagensProvasMa SET AUTO_CLOSE OFF WITH NO_WAIT
ALTER DATABASE DB_MA_PROVA_DIGITAL SET AUTO_CLOSE OFF WITH NO_WAIT
ALTER DATABASE DB_SICCA SET AUTO_CLOSE OFF WITH NO_WAIT
ALTER DATABASE DB_SERVIDOR_BLOB_MA_P SET AUTO_CLOSE OFF WITH NO_WAIT