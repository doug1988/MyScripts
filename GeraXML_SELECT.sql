SELECT  TOP 1
	CD_PROVA
,	NU_RENACH
,	NU_CPF
,	(
		SELECT  			
			X.DT_IMAGEM_PROVA
		,	X.NU_ORDEM		
		,	X.BLOB_IMAGEM_PROVA
		FROM 
			TB_IMAGENS_PROVAS  as X
		WHERE 
			X.CD_PROVA = Z.CD_PROVA
		ORDER BY X.NU_ORDEM		
		FOR XML PATH('BlobsProva'),TYPE  -- varios dados 
	) AS ImagensProva
FROM 
	TB_IMAGENS_PROVAS AS Z 
WHERE 
	CD_PROVA = 99998	--chave primaria
FOR XML PATH('Prova'), ROOT('ImagensProva')				
