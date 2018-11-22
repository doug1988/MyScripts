USE DB_SERVIDOR_BLOB_MA_P_OFF
GO
CREATE PROCEDURE SpTransferirAgendaBlobsXML
(
    @XML XML    
)
AS
    /*
     Douglas Porto
    27/08/2018
    Procedure recebe oS dados do cancidato em forma de XML e insere os dados nas tabelas finais, sendo
    TB_CANDIDATOS
    TB_AGENDAS_RENACHS
    TB_PROVAS
    TB_PROVAS_GERADAS   
    TB_AQUISICOES
    TB_AQUISICOES_BLOBS 
    OBS.    procedure baseada na proc de JSON do site de RN:    
        banco:  DbRnProvaDigitalOff    
    */
    
    BEGIN    
        IF OBJECT_ID('tempdb..#Aquisicoes') IS NOT NULL DROP TABLE #Aquisicoes;
        IF OBJECT_ID('tempdb..#DadosProvaCandidato') IS NOT NULL DROP TABLE #DadosProvaCandidato;
        
        DECLARE @ErroSQL VARCHAR(MAX)
        DECLARE @hDoc  INT         
        EXECUTE sp_xml_preparedocument @hDoc OUTPUT , @XML

        --(INICIO) - EXTRAI OS DADOS DO XML EM UMA VARIAVEL...
            select 
                * 
            INTO #DadosProvaCandidato
            from 
            (
            SELECT 
                Dia
            ,	Hora	
            ,	CodSala
            ,	ConfiguracaoProva
            ,	CodigoUsuario
            ,	FlagSurdez
            ,	Cnpj	
            from 
                OPENXML( @hdoc, 'AgendaRenach',2) 
                with 
                    (
                        [Dia]				DATETIME 
                    ,	[Hora]				CHAR(5) 
                    ,	[CodSala]			INT 
                    ,	[ConfiguracaoProva] BIGINT 
                    ,	[CodigoUsuario]		BIGINT
                    ,	[FlagSurdez]		BIT 
                    ,	[Cnpj]				BIGINT 		
                    )
            )as DadosAgenda  
            ,
            (
            SELECT 
                [CPF]	
            ,	[Renach]
            ,	[Nome]		
            from 
                OPENXML( @hdoc, 'AgendaRenach/Candidato',2) 
                with 
                    (
                        [CPF]		BIGINT
                    ,	[Renach]	BIGINT  
                    ,	[Nome]		VARCHAR(100)		
                    )
            )	as DadosCandidato
            ,
            (
            SELECT 
                CodigoProva	
            from 
                OPENXML( @hdoc, 'AgendaRenach/Prova',2) 
                with 
                    (
                        CodigoProva INT	
                    )
            ) as Prova
            ,
            (
            SELECT 
                        CodigoPergunta 
                    ,	Ordem			   
            from 
                OPENXML( @hdoc, 'AgendaRenach/Prova/ListaPergunta/Pergunta',2) 
                with 
                    (
                        CodigoPergunta INT	
                    ,	Ordem		   INT 	
                    )
            )as ProvasGeradas
            SELECT 
                * 
            INTO #Aquisicoes
            FROM 
            (
            SELECT 
                [CPF]	
            ,	[IdTipoDocumento]
            ,	[Renach]
            ,	[DataAquisicao]
            ,	[DataEntrada]		
            FROM 
                OPENXML( @hdoc, 'AgendaRenach/Candidato/Aquisicao',2) 
                WITH 
                (
                    [CPF]			BIGINT
                ,	[IdTipoDocumento] VARCHAR(20)
                ,	[Renach]		BIGINT  
                ,	[DataAquisicao]	DATETIME 
                ,	[DataEntrada]	DATETIME 
                )
            ) AS X
            ,
            (
            SELECT 
                [IdSubTipoBlob]  
            ,	cast (N'' as xml ).value( 'xs:base64Binary(sql:column("BlobConteudo"))' , 'varbinary(max)')    AS [BlobConteudo]		
            FROM 
                OPENXML( @hdoc, 'AgendaRenach/Candidato/Aquisicao/Blobs/Blob',2) 
                WITH 
                (
                    [IdSubTipoBlob]		INT
                ,	[BlobConteudo]		VARCHAR(MAX)
                )
            ) AS Z;
            --(FIM) - EXTRAI OS DADOS DO XML EM UMA VARIAVEL.
            /**********************************************************************/
            --(INICIO) INSERE DO DADOS DA PROVA...
            BEGIN TRY 	
            INSERT INTO DB_MA_PROVA_DIGITAL.DBO.TB_CANDIDATOS  
            (  
                NU_RENACH  
            ,	NU_CPF    
            ,	NM_CANDIDATO   
            ,	NU_IDENTIDADE  
            ,	DS_ORGAO_EXPEDIDOR_UF  
            ,	DS_UF_RENACH  
            ,	CD_STATUS_CANDIDATO  
            ,	DT_ESTADO_CANDIDATO  
            )  
            SELECT  TOP 1 
                Renach as NU_RENACH  
            ,	CPF as NU_CPF    
            ,	Nome as NM_CANDIDATO   
            ,	NULL AS NU_IDENTIDADE  
            ,	NULL AS DS_ORGAO_EXPEDIDOR_UF  
            ,	NULL AS DS_UF_RENACH  
            ,	10 CD_STATUS_CANDIDATO  
            , 	GETDATE() DT_ESTADO_CANDIDATO  
            FROM  
                #DadosProvaCandidato AS A 
            WHERE
                NOT EXISTS 
                (
                    SELECT * FROM TB_CANDIDATOS AS B WHERE B.NU_RENACH = A.[Renach] AND B.NU_CPF = B.NU_CPF
                )
            INSERT INTO DB_MA_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS
            (
                DT_DIA
            ,	HR_PROVA
            ,	CD_SALA
            ,	NU_RENACH
            ,	NU_CPF
            ,	CD_CNPJ
            ,	CD_CONFIGURACAO_PROVA
            ,	CD_ESTADO_AGENDA_RENACH
            ,	DT_ESTADO_AGENDA_RENACH
            ,	CD_USUARIO
            ,	CD_TIPO_PRODAM
            ,	CD_CATEGORIA
            ,	FL_SURDEZ
            )
            SELECT	TOP (1) 
                Dia		AS  DT_DIA
            ,	Hora	AS  HR_PROVA
            ,	CodSala	AS  CD_SALA
            ,	Renach	AS  NU_RENACH
            ,	CPF		AS  NU_CPF
            ,	CNPJ	AS  CD_CNPJ
            ,	ConfiguracaoProva AS  CD_CONFIGURACAO_PROVA
            ,	1				AS  CD_ESTADO_AGENDA_RENACH
            ,	GETDATE()	AS  DT_ESTADO_AGENDA_RENACH
            ,	CodigoUsuario AS  CD_USUARIO
            ,	NULL   AS   CD_TIPO_PRODAM
            ,	NULL AS  CD_CATEGORIA
            ,	FlagSurdez AS FL_SURDEZ
            FROM
                #DadosProvaCandidato AS A
            WHERE  NOT EXISTS 
                (
                    SELECT * FROM TB_AGENDAS_RENACHS AS B 
                    WHERE
                        B.DT_DIA	= A.Dia
                    AND	B.HR_PROVA	= A.Hora
                    AND	B.CD_SALA	= A.CodSala
                    AND	B.NU_RENACH	= A.Renach
                    AND	B.NU_CPF	= A.CPF
                )
            INSERT INTO DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS  
            (  
                CD_PROVA  
            ,	CD_CONFIGURACAO_PROVA  
            ,	NU_RENACH  
            ,	NU_CPF  
            ,	DT_DIA  
            ,	HR_PROVA  
            ,	CD_USUARIO  
            ,	CD_SALA  
            ,	CD_EXAMINADOR_SEARCH_01  
            ,	DT_GERACAO  
            )  
            SELECT	TOP (1)
                CodigoProva AS CD_PROVA  
            ,	ConfiguracaoProva AS CD_CONFIGURACAO_PROVA  
            ,	Renach AS NU_RENACH  
            ,	CPF AS NU_CPF  
            ,	Dia AS DT_DIA  
            ,	Hora AS HR_PROVA  
            ,	CodigoUsuario AS CD_USUARIO  
            ,	CodSala AS CD_SALA  
            ,	NULL AS CD_EXAMINADOR_SEARCH_01  
            ,	GETDATE() AS DT_GERACAO  
            FROM
                #DadosProvaCandidato AS A
            WHERE  NOT EXISTS 
                (
                    SELECT * FROM TB_PROVAS AS B 
                    WHERE
                        B.CD_PROVA = A.CodigoProva
                )
            INSERT INTO DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS_GERADAS
            (
                CD_PROVA
            ,	CD_PERGUNTA
            ,	CD_RESPOSTA_CANDIDATO
            ,	NU_ORDEM
            )
            SELECT
                CodigoProva AS CD_PROVA
            ,	CodigoPergunta CD_PERGUNTA
            ,	NULL AS CD_RESPOSTA_CANDIDATO
            ,	Ordem AS 	NU_ORDEM
            FROM
                #DadosProvaCandidato AS A
            WHERE  NOT EXISTS 
                (
                    SELECT * FROM TB_PROVAS_GERADAS AS B 
                    WHERE
                        B.CD_PROVA = A.CodigoProva AND  B.CD_PERGUNTA =  A.CodigoPergunta
                )
            --(FIM) INSERE DO DADOS DA PROVA.
            
            --(INICIO) INSERE OS BLOBS...
            INSERT INTO DB_SERVIDOR_BLOB_MA_P.DBO.TB_AQUISICOES
            (
                nu_cpf
            ,	id_documento
            ,	id_tipo_documento
            ,	dt_aquisicao
            ,	dt_entrada
            )
            SELECT   TOP (1)
                [CPF]	
            ,	[Renach]
            ,	[IdTipoDocumento]
            ,	[DataAquisicao]
            ,	[DataEntrada]		
            FROM 
                #Aquisicoes  AS A 
            WHERE   
                NOT EXISTS 
                (
                    SELECT * FROM DB_SERVIDOR_BLOB_MA_P.DBO.TB_AQUISICOES AS B
                    WHERE   
                            A.id_documento = B.id_documento
                        AND A.NU_CPF = B.NU_CPF 
                        AND A.id_tipo_documento = B.id_tipo_documento
                        AND A.dt_aquisicao = B.dt_aquisicao
                )    

            INSERT INTO DB_SERVIDOR_BLOB_MA_P.DBO.TB_AQUISICOES_BLOBS
            (
                nu_cpf
            ,	id_documento
            ,	id_tipo_documento
            ,	dt_aquisicao
            ,	id_subtipo_blob
            ,	blob_conteudo
            )
            SELECT    
                [CPF]	
            ,	[Renach]
            ,	[IdTipoDocumento]
            ,	[DataAquisicao]
            ,	[IdSubTipoBlob]		
            ,	[BlobConteudo]			
            FROM 
                #Aquisicoes AS A
             WHERE   
                NOT EXISTS 
                (
                    SELECT * FROM DB_SERVIDOR_BLOB_MA_P.DBO.TB_AQUISICOES_BLOBS AS B
                    WHERE   
                        A.id_documento = B.id_documento
                    AND A.NU_CPF = B.NU_CPF 
                    AND A.id_tipo_documento = B.id_tipo_documento
                    AND A.dt_aquisicao = B.dt_aquisicao
                    AND A.IdSubTipoBlob = B.id_subtipo_blob
                ) 
            --(FIM) INSERE OS BLOBS. 
         END TRY 
         BEGIN CATCH 
            SET @ErroSQL = 'Erro na execução da proc SpInserirCandidatoAgendaProvaXML	' +  ERROR_MESSAGE()
		
            INSERT INTO LogErrosGravacaoXML
            (
                DataOperacao
            ,	BlobConteudo
            ,	DescErro
            )
            SELECT
                getdate()
            ,	@XML
            ,	@ErroSQL
            RAISERROR   (@ErroSQL,16,1) WITH LOG --PODE SER CONSULTADO NO LOG DO WINDOWS 
            RETURN -1
         END CATCH    
        EXECUTE sp_xml_removedocument @hDoc
    END
GO

 



			

--SELECT *
--INTO #xmlDoc 
--FROM OPENXML( @hdoc, '//*',2)
with CteFodase
AS
(
SELECT  
	rt.localname 
+	'/' 
+	tbl.localname 
+	'/' 
+	col.localname AS NodePath
,	tbl.localname AS NodeRow
FROM #xmlDoc rt 
INNER JOIN #xmlDoc tbl
ON rt.id = tbl.parentID 
	AND rt.parentID IS NULL
INNER JOIN #xmlDoc col
ON tbl.id = col.parentID
)
select * from CteFodase 
--where NodePath like '%AgendaRenach/Candidato%'
order by len(NodePath)