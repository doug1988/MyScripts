USE [msdb]
GO
EXEC master .dbo. sp_MSsetalertinfo @failsafeoperator =N'DBA',
              @notificationmethod =1
GO



sp_configure 'Allow Updates' , 0;
reconfigure with override;
go


sp_CONFIGURE 'show advanced' , 1
GO
RECONFIGURE
GO
sp_CONFIGURE 'Database Mail XPs' , 1
GO
RECONFIGURE
GO



USE msdb
GO
EXEC sp_send_dbmail
@profile_name='DBA' ,
@recipients='dba@thomasgreg.com.br' ,
@subject='Test message' ,
@body='This is the body of the test message.Congrates Database Mail Received By you Successfully.'



SELECT * FROM sysmail_mailitems ORDER BY SEND_REQUEST_DATE DESC
GO
SELECT * FROM sysmail_log order by 3 desc