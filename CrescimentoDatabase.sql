USE DBMANAGEMENTDBA
go
CREATE TABLE RESULTDIAS 
(
	DIA DATE
,	TAMANHO INT 	
)
INSERT INTO RESULTDIAS
SELECT  
	sum(TamanhoArquivoMB)				AS Tamanho
,	CAST( DataVerificacao as DATE)	    AS Dia
FROM 
	TbArquivosSQL AS A
WHERE
	TipoArquivo = 'ROWS'	
AND EXISTS (select * from master.sys.databases AS B WHERE A.NomeBanco = B.name 	AND  iS_read_only = 0 and database_id > 4		)
GROUP BY 
		CAST( DataVerificacao as DATE)
        

SELECT 
	avg(z.CrescimentoDia) 
FROM 
(
	SELECT
		ROW_NUMBER() OVER (ORDER BY X.DIA ) AS ID
	,	X.DIA
	,	x.TamanhoDiaAnterior
	,	X.TAMANHO AS TamanhoDiaAtual	
	,	(X.TAMANHO - X.TamanhoDiaAnterior) as CrescimentoDia 
	FROM
	(
		SELECT 
			DIA
		,	LAG(TAMANHO, 1,0 ) OVER (ORDER BY DIA ) AS TamanhoDiaAnterior
		,	TAMANHO	
		FROM
			#T
	) AS X
	WHERE  	
		dia > '2018-06-16'
	AND (X.TAMANHO - X.TamanhoDiaAnterior) > 0 	
	--AND DATEPART(WEEKDAY, X.DIA ) NOT IN (1,2,7)	--ELIMINA SABADO, DOMINGO, SEGUNDA 
)  as Z;