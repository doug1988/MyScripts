create PROCEDURE SpMonitoraEspacoServer
as
begin

       --(INICIO) - DECLARA VARIAVEIS TEMPORARIAS...
       DECLARE @HR INT
       DECLARE @FSO INT
       DECLARE @DRIVE CHAR (1)
       DECLARE @ODRIVE INT
       DECLARE @TOTALSIZE VARCHAR (20)
       DECLARE @MB BIGINT ;
       SET @MB = 1048576

       CREATE TABLE #DRIVES
       (
            DRIVE CHAR(1 ) PRIMARY KEY
       ,     FREESPACE INT NULL
       ,     TOTALSIZE INT NULL
       )
       --(FIM) - DECLARA VARIAVEIS TEMPORARIAS.                                

       INSERT #DRIVES( DRIVE,FREESPACE )
       EXEC MASTER .DBO. XP_FIXEDDRIVES

      EXEC @HR=SP_OACREATE 'SCRIPTING.FILESYSTEMOBJECT', @FSO OUT
       IF @HR <> 0 EXEC SP_OAGETERRORINFO @FSO

       DECLARE DCUR CURSOR LOCAL FAST_FORWARD
       FOR SELECT DRIVE FROM #DRIVES
       ORDER BY DRIVE

       OPEN DCUR

       FETCH NEXT FROM DCUR INTO @DRIVE

       WHILE @@FETCH_STATUS =0
       BEGIN

                   EXEC @HR = SP_OAMETHOD @FSO,'GETDRIVE' , @ODRIVE OUT , @DRIVE
                   IF @HR <> 0 EXEC SP_OAGETERRORINFO @FSO
                   EXEC @HR = SP_OAGETPROPERTY @ODRIVE,'TOTALSIZE' , @TOTALSIZE OUT
                   IF @HR <> 0 EXEC SP_OAGETERRORINFO @ODRIVE
                   UPDATE #DRIVES
                   SET TOTALSIZE= @TOTALSIZE/@MB
                   WHERE DRIVE= @DRIVE
                   FETCH NEXT FROM DCUR INTO @DRIVE

       END

       CLOSE DCUR
       DEALLOCATE DCUR

       EXEC @HR= SP_OADESTROY @FSO
       IF @HR <> 0 EXEC SP_OAGETERRORINFO @FSO

       SELECT DRIVE,
               FREESPACE AS 'LIVRE(MB)' ,
               TOTALSIZE AS 'TOTAL(MB)' ,
               CAST((FREESPACE /(TOTALSIZE* 1.0))*100.0 AS INT ) AS 'LIVRE(%)'
       INTO #enviar       
       FROM #DRIVES
       ORDER BY DRIVE
      
      
       if exists (select 1 from #enviar where [LIVRE(%)] <= 10)
             begin
                   EXEC msdb. dbo.sp_send_dbmail
                   @profile_name = 'DBA',
                  @recipients = 'dba@thomasgreg.com.br' ,
                  @body_format = html,
                  @body = 'Espaço em disco inferior ou igual a 10%' ,
                  @subject = 'ALERTA - RECIFE - Espaço em Disco estourando'
             end

       DROP TABLE #enviar
       DROP TABLE #DRIVES
            
         RETURN         
end