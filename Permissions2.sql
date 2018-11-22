DROP TABLE #Users
create table #Users
(
       Username              varchar(max )
,      RoleName              varchar(max )
,      LoginName             varchar(max )
,      DefDBName             varchar(max )
,      DefSchemaName varchar( max)
,      userid                varchar(max )
,      SID                          varchar(max )
,      DBNAME                VARCHAR(MAX ) DEFAULT DB_NAME()
)
insert into #Users
(
       Username             
,      RoleName             
,      LoginName            
,      DefDBName            
,      DefSchemaName 
,      userid               
,      SID                         
)
EXEC sp_MSforeachdb
'use [?]
exec sp_helpuser'


select * from #Users
where LoginName is null 
order by 1