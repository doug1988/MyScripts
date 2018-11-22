--GET SIZE OF ALL DATA FILES 
IF OBJECT_ID('tempdb..##tempfreDB') IS NOT NULL
    DROP TABLE ##tempfreDB
CREATE TABLE ##tempfreDB
(
    DatabaseName sysname,
    Name sysname,
    physical_name nvarchar(500),
    size decimal (18,2),
    FreeSpace decimal (18,2),
	percent_free int
) 
GO
DECLARE @exec nvarchar(maX)
SET @EXEC =
'Exec sp_msforeachdb ''
Use [?];
Insert Into ##tempfreDB (DatabaseName, Name, physical_name, Size, FreeSpace, percent_free) 
Select 
	DatabaseName
,	Name
,	physical_name
,	Size, FreeSpace
,	100-(FreeSpace * 100 / size) as [percent_free]
from (
	Select DB_NAME() AS [DatabaseName]
		,	Name
		,	physical_name
		,	Cast(Cast(Round(cast(size as int) * 8.0/1024.0,2) as decimal(18,2)) as int) Size
		,	Cast(Cast(Round(cast(size as decimal) * 8.0/1024.0,2) as decimal(18,2)) - Cast(FILEPROPERTY(name, ''''SpaceUsed'''') * 8.0/1024.0 as decimal(18,2)) as int) As FreeSpace
	From 
		sys.database_files
	--WHERE max_size <> -1
)  D
'''
EXEC (@EXEC)
GO
SELECT * FROM ##tempfreDB