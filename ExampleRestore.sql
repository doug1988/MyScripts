USE [master]
RESTORE DATABASE [DB_MA_PROVA_DIGITAL] 
FROM  DISK = N'C:\PROVA\Bak\DB_MA_PROVA_DIGITAL.bak' WITH  FILE = 1,  MOVE N'DB_MA_PROVA_DIGITAL' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.SQLEXPRESS\MSSQL\DATA\DB_MA_PROVA_DIGITAL.mdf',  MOVE N'DB_MA_PROVA_DIGITAL_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.SQLEXPRESS\MSSQL\DATA\DB_MA_PROVA_DIGITAL_1.ldf',  NOUNLOAD,  STATS = 5
GO
USE [master]
RESTORE DATABASE [DB_SERVIDOR_BLOB_MA_P] 
FROM  DISK = N'C:\PROVA\Bak\DB_SERVIDOR_BLOB_MA_P_Primary.bak' WITH  FILE = 1,  MOVE N'DB_SERVIDOR_BLOB_MA_P' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.SQLEXPRESS\MSSQL\DATA\DB_SERVIDOR_BLOB_MA_P_Primary.mdf',  MOVE N'BLOB_9B7AEB6' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.SQLEXPRESS\MSSQL\DATA\DB_SERVIDOR_BLOB_MA_P_BLOB_9B7AEB6.mdf',  MOVE N'DB_SERVIDOR_BLOB_MA_P_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.SQLEXPRESS\MSSQL\DATA\DB_SERVIDOR_BLOB_MA_P_Primary.ldf',  NOUNLOAD,  STATS = 5
GO
USE [master]
RESTORE DATABASE [DB_SICCA] FROM  DISK = N'C:\PROVA\Bak\DB_SICCA.bak' WITH  FILE = 1,  
MOVE N'DB_AC_SICCA' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.SQLEXPRESS\MSSQL\DATA\DB_SICCA.mdf',  MOVE N'DB_AC_SICCA_BLOB' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.SQLEXPRESS\MSSQL\DATA\DB_SICCA_1.mdf',  MOVE N'DB_AC_SICCA_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.SQLEXPRESS\MSSQL\DATA\DB_SICCA_1.ldf',  NOUNLOAD,  STATS = 5
GO
USE [master]
RESTORE DATABASE [DbImagensProvasMa] FROM  DISK = N'C:\PROVA\Bak\DbImagensProvasMa.bak' WITH  FILE = 1,  MOVE N'DbImagensProvasMa' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.SQLEXPRESS\MSSQL\DATA\DbImagensProvasMa.mdf',  MOVE N'DbImagensProvasMa_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.SQLEXPRESS\MSSQL\DATA\DbImagensProvasMa_log.LDF',  NOUNLOAD,  STATS = 5
GO
CREATE LOGIN blob	 WITH password = '*blob*'	, check_policy =off, check_expiration=off, sid =  0x7D14C568F0A5DC45B497C41BCE3CD4C8
CREATE LOGIN polma	 WITH password = '*polma*', check_policy =off, check_expiration=off, sid = 	 0xAF736862B20D7B4FB2C2FB4DB6E234BE
CREATE LOGIN sicca	 WITH password = '*sicca*', check_policy =off, check_expiration=off, sid =  0x96EF3B5F8DA2CE43944BC47E7BA00512
CREATE LOGIN tgsqg	 WITH password = '*tgsqg*', check_policy =off, check_expiration=off, sid = 	 0x660AA29F65D2F84E9A9EF65EB7C10005
GO


	    [Site]						    
	,	[SalaOffLine]				
	,	[DataAgendamento]			
	,	[BiometriasTotais]			
	,	[BiometriasPendentes]		
	,	[Data]						
	,	[Observacao]				 