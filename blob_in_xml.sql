SELECT
    ROW_NUMBER() OVER (ORDER BY CD_PROVA   ) AS ID
, CD_PROVA
INTO #ENVIAR
FROM
    TB_IMAGENS_PROVAS
WHERE 
	DT_IMAGEM_PROVA	 > '20180901'
GROUP BY 
	CD_PROVA
CREATE TABLE #TEMP_XML
(
    ID INT IDENTITY (1,1) PRIMARY KEY
,
    CD_PROVA INT 
,
    CONTEUDO_XML XML 	
,
    DT_OPERACAO DATETIME DEFAULT GETDATE()
)
DECLARE @XML_PROVA XML  = NULL
DECLARE @COUNT INT = 1
DECLARE @MAX INT = (SELECT MAX(ID)
FROM #ENVIAR)
DECLARE @CD_PROVA INT = NULL
WHILE @COUNT <= @MAX
	BEGIN
    SELECT @CD_PROVA = CD_PROVA
    FROM #ENVIAR
    WHERE ID =  @COUNT

    SET @XML_PROVA  =
			(
				sELECT TOP 1
        CD_PROVA
				, NU_RENACH
				, NU_CPF
				, (
						SELECT
            X.DT_IMAGEM_PROVA
						, X.NU_ORDEM		
						, CAST(X.BLOB_IMAGEM_PROVA  as varbinary(max)	)	 AS BLOB_IMAGEM_PROVA
        FROM
            TB_IMAGENS_PROVAS  as X
        WHERE 
							X.CD_PROVA = Z.CD_PROVA
        ORDER BY X.NU_ORDEM
        FOR XML PATH('Blob'),TYPE
					) AS 'DadosImagem'
    FROM
        TB_IMAGENS_PROVAS AS Z
    WHERE 
					CD_PROVA = @CD_PROVA
    FOR XML PATH('Prova'), ROOT('ImagensCapturadasProva')			
			)
    INSERT INTO #TEMP_XML
        (CD_PROVA ,CONTEUDO_XML )
    SELECT @CD_PROVA , @XML_PROVA
    SET @COUNT = @COUNT + 1
END;
DECLARE @nvar XML
SELECT @nvar = CONTEUDO_XML
FROM #TEMP_XML
WHERE ID = 10

CodProva			 
		,	CPF					 
		,	Renach				 
		,	ConteudoXml

DECLARE @hDoc  INT
EXECUTE @hDoc OUTPUT , @nvar
SELECT
    convert(varchar, DT_IMAGEM_PROVA	,112)
+	REPLACE(convert(varchar, DT_IMAGEM_PROVA	,108), ':','')
+	'.JPG'
, cast (N'' as xml ).value( 'xs:base64Binary(sql:column("BLOB_IMAGEM_PROVA"))' , 'varbinary(max)')    AS BLOB_IMAGEM_PROVA
FROM
    OPENXML( @hdoc, 'ImagensCapturadasProva/Prova/DadosImagem/Blob',2)  
    with 
    (
		DT_IMAGEM_PROVA		datetime	
	,	BLOB_IMAGEM_PROVA  	VARCHAR(max)
	,	NU_ORDEM			int 
    )	