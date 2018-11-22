EXEC sp_MSForEachTable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'
GO
EXEC sp_MSForEachTable '
IF OBJECTPROPERTY(object_id(''?''), ''TableHasForeignRef'') = 0
DELETE FROM ?
else
TRUNCATE TABLE ?
'
GO
-- reativa a integridade refencial
EXEC sp_MSForEachTable 'ALTER TABLE ? CHECK CONSTRAINT ALL'
GO