DECLARE @JobID uniqueidentifier
DECLARE @NewOwner varchar(200)
DECLARE @OldName varchar(200)
 
SET @NewOwner = 'dbadmin'
SET @OldName = 'sa'
 
SELECT
sv.name AS [Name],
sv.job_id AS [JobID],
l.name AS [OwnerName]
 
FROM
msdb.dbo.sysjobs_view AS sv
INNER JOIN [master].[sys].[syslogins] l
ON sv.owner_sid = l.sid WHERE l.name like 'operatorjob' ORDER BY sv.[Name] ASC
 
SELECT * FROM #SQLJobs
WHILE (SELECT COUNT(*) FROM #SQLJobs ) > 0 BEGIN
    SELECT TOP 1 @JobID = JobID FROM #SQLJobs
    EXEC msdb.dbo.sp_update_job
    @job_id= @JobID,
    @owner_login_name=@NewOwner
    DELETE FROM #SQLJobs WHERE JobID = @JobID
 
END
 
DROP TABLE #SQLJobs