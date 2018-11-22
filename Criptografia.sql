CREATE DATABASE DB_EXEMPLO;
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '*tgs123MANUTE*' ;
GO
CREATE CERTIFICATE MeuCertificado WITH SUBJECT = 'Desc';
GO
USE DB_EXEMPLO;
GO
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_128
ENCRYPTION BY SERVER CERTIFICATE MeuCertificado;
GO
ALTER DATABASE DB_EXEMPLO
SET ENCRYPTION ON;
GO



USE MASTER
GO

BACKUP CERTIFICATE MeuCertificado
TO FILE = 'C:\BackupDouglasPorto\Bases_SQL2012\Data\MSSQL11.MSSQL2012\MSSQL\DATA\Cert\Meu_CERT_1.cer'
WITH PRIVATE KEY
(FILE = 'C:\BackupDouglasPorto\Bases_SQL2012\Data\MSSQL11.MSSQL2012\MSSQL\DATA\Cert\certificate_DB_EX_Test_Key_02.pvk' ,
ENCRYPTION BY PASSWORD = '*tgs123MANUTE*' )


-------------------------------------------------Descriptografando
USE master
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '*tgs123MANUTE*'


CREATE CERTIFICATE MeuCertificado
FROM FILE = 'C:\AtachEnc\Cert\Meu_CERT_1.cer'    
WITH PRIVATE KEY ( FILE = 'C:\AtachEnc\Cert\certificate_DB_EX_Test_Key_02.pvk', DECRYPTION BY PASSWORD = '*tgs123MANUTE*' )



select * from sys.certificates


USE [master]
RESTORE DATABASE [DB_EXEMPLO] FROM  DISK = N'C:\AtachEnc\DB_EXEMPLO.bak' WITH  FILE = 1, 
MOVE N'DB_EXEMPLO' TO N'C:\AtachEnc\Cert\DB_EXEMPLO.mdf',  MOVE N'DB_EXEMPLO_log' TO N'C:\AtachEnc\Cert\DB_EXEMPLO_log.ldf' ,  NOUNLOAD ,  STATS = 5
GO






ALTER DATABASE DB_SERVIDOR_BLOB_AL_P
SET ENCRYPTION OFF;
GO
/* Wait for decryption operation to complete, look for a
value of  1 in the query below. */
SELECT db_name (database_id), encryption_state FROM sys.dm_database_encryption_keys
GO
USE DB_SERVIDOR_BLOB_AL_P;
GO
DROP DATABASE ENCRYPTION KEY;
GO


backup database [DB_AL_PROVA_PRATICA] to disk = 'D:\Prova.bak' with stats = 01

















SELECT * FROM SYS.certificates

use master

OPEN MASTER KEY DECRYPTION BY PASSWORD = '*tgs123*'


ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY;


CLOSE MASTER KEY;


use master
select * from sys.certificates


EXEC sp_control_dbmasterkey_password
    @db_name   = N'DB_AL_PROVA_PRATICA',
    @password  = N'*tgs123*' ,
    @action    = N'drop' ;



        select * from sys.dm_database_encryption_keys
SELECT db_name (database_id), encryption_state FROM sys.dm_database_encryption_keys

DROP CERTIFICATE Certtgs

use DB_AL_PROVA_PRATICA

exec sp_control_dbmasterkey_password



SELECT  d. name as database_name ,
        c .*,
        mkp .family_guid
 
FROM    master .sys. credentials c
 
        INNER JOIN master. sys.master_key_passwords mkp
            ON c. credential_id = mkp .credential_id
 
        INNER JOIN master. sys.database_recovery_status drs
            ON mkp. family_guid = drs .family_guid
 
        INNER JOIN master. sys.databases d
            ON drs. database_id = d .database_id

                     





  