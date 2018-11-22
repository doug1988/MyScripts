CREATE OR ALTER FUNCTION dbo.fnSplitStr (@str varchar(1000))
RETURNS @TABLE TABLE 
(
	N CHAR(1)
)
AS
BEGIN
		DECLARE @SIZE INT 
		SET @SIZE = LEN(@STR)
		WHILE @SIZE > 0
			BEGIN
				INSERT INTO @TABLE (N)
				SELECT LEFT (@STR, 1 )
		
				SET @STR =  RIGHT (@STR, @SIZE-1)
				SET @SIZE = @SIZE -1
			END
		   RETURN 
END
GO
SELECT * FROM DBO.fnSplitStr ('51       <>45616515616514545456456156465456121516515454156454546+546562626262356565656343^$&&#&##t$$$')

USE TSQLFundamentals2008
GO

SET NOCOUNT ON
	CREATE PROC SpCOunt
	AS
	BEGIN
		DECLARE @t table
		(
			n int primary key
		)
		DECLARE @INICIO INT 
		DECLARE @FIM INT
		SET @INICIO = 1
		SET @FIM = 10
		WHILE @FIM >= @INICIO
			BEGIN
				INSERT INTO @t (N)
				VALUES( @INICIO )

				SET @INICIO = @INICIO + 1
			END
		SELECT N FROM @t
	END 
	GO


	exec SpCOunt
	go
	SELECT N FROM GETNUMS (1,10)



SELECT 
	CONCAT_WS( ',', database_id, recovery_model_desc, containment_desc) AS DatabaseInfo
FROM 
	sys.databases




create table #tb  
(
	Id int identity (1,1)
,	DataIn datetime 
,	Campo varchar(5)	
)
insert into  #tb  (DataIn, Campo)
select getdate(), 'dwdsd'
go 500

select  CONCAT_WS(',', Id, CONVERT(VARCHAR,DataIn, 120) , Campo) from #tb
