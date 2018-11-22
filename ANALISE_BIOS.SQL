use DB_SERVIDOR_BLOB_ES_P
GO
IF OBJECT_ID('TEMPDB..#TEMP') IS NOT NULL DROP TABLE #TEMP;
go
IF OBJECT_ID('TEMPDB..#AgendasComBios') IS NOT NULL DROP TABLE #AgendasComBios;
go
IF OBJECT_ID('TEMPDB..#LOOP') IS NOT NULL DROP TABLE #LOOP;
go 
    /**************************************************************************************************/
    DECLARE @CD_SALA	INT  = NULL
    DECLARE @DT_DIA		DATE  = '20180828'
    DECLARE @I INT = 1    
    DECLARE @LK          VARCHAR(50)
    DECLARE @EXEC		NVARCHAR(MAX)    
    /**************************************************************************************************/
    --DECLARO VARIAVEL...
    /**************************************************************************************************/
    declare @BiometriasTransferidas table   
	 (  
		[Site]     varchar(30)  
	,	[SalaOffLine]   varchar(30)  
	,	[DataAgendamento]  daTE  
	,	[BiometriasTotais]  int  
	,	[BiometriasPendentes] int   
	,	 [Data]     datetime  
	,	[Observacao]   varchar(100)  
	)  	  
    DECLARE @TABLE TABLE 
	(
		SALA			 VARCHAR(50) 
	,	TOTAL_AGENDAS	 INT 
	,	TOTAL_BIOS_SITE	 INT 
	,	TOTAL_BIOS_OFF	 INT 
	,	TOTAL_PENDENTE   INT 
	)
    DECLARE @CpfRenach TABLE 
    (
        nu_cpf				bigint
    ,	id_documento		bigint
    ,	id_tipo_documento	varchar(50)
    ,	dt_aquisicao		datetime
    )        
    /**************************************************************************************************/
    CREATE TABLE #LOOP 
    (
		ID		INT IDENTITY (1,1)
	,	CD_SALA INT 
	,	DS_SALA	VARCHAR(50)		
    )
    INSERT INTO #LOOP (CD_SALA,DS_SALA)
    SELECT  CD_SALA , DS_SALA FROM  DB_ES_PROVA_DIGITAL.DBO.TB_LKS 
    WHERE  CD_SALA = ISNULL(@CD_SALA,CD_SALA)
    
    WHILE @I < = (SELECT MAX(ID) FROM #LOOP)
    BEGIN 
		SELECT  @CD_SALA =  CD_SALA,  @LK = DS_SALA FROM  #LOOP  WHERE ID = @I
		;WITH AnalisaRenachCpf   --Armazena Agendas que o PAR (RENACH\CPF) contenham imagens 
		as
		(
			SELECT
				nu_cpf
			,	id_documento
			,	id_tipo_documento
			,	MAX(dt_aquisicao) AS dt_aquisicao
			FROM
				DB_SERVIDOR_BLOB_ES_P.DBO.TB_AQUISICOES AS A
			WHERE
				EXISTS (
							SELECT TOP 1 1 FROM DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B
							WHERE A.nu_cpf = B.NU_CPF
							AND A.id_documento = B.NU_RENACH
							AND B.CD_SALA = @CD_SALA
							AND B.DT_DIA = @DT_DIA
						)	
			GROUP BY 
				nu_cpf
			,	id_documento
			,	id_tipo_documento            
			)
			INSERT INTO @CpfRenach
			(
				nu_cpf
			,	id_documento
			,	id_tipo_documento
			,	dt_aquisicao
			)
			select 
				nu_cpf
			,	id_documento
			,	id_tipo_documento
			,	dt_aquisicao
			from 
				AnalisaRenachCpf 
			;WITH AnalisaCpf --Armazena Agendas que apenas o CPF contenham imagens 
			as
			(
			SELECT
				nu_cpf
			,	id_documento
			,	id_tipo_documento
			,	MAX(dt_aquisicao) AS dt_aquisicao
			FROM
				DB_SERVIDOR_BLOB_ES_P.DBO.TB_AQUISICOES AS A
			WHERE
				EXISTS (
							SELECT TOP 1 1 FROM DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B
							WHERE 
								A.nu_cpf = B.NU_CPF				
							AND B.CD_SALA = @CD_SALA
							AND B.DT_DIA = @DT_DIA
						)	
				AND NOT EXISTS 
				(
						SELECT * FROM @CpfRenach AS C
						WHERE
						A.id_documento = C.id_documento
					AND	A.nu_cpf = C.NU_CPF
					AND A.id_tipo_documento = C.id_tipo_documento
					AND A.dt_aquisicao     =C.dt_aquisicao 
				) 
			GROUP BY 
				nu_cpf
			,	id_documento
			,	id_tipo_documento   
			)	 
			SELECT
				*
			INTO #TEMP  --armaenza os os renachs e CPF´distintos emuma temp
			FROM
			(
				SELECT  * FROM @CpfRenach
				UNION  
				SELECT  * FROM AnalisaCpf
			) AS X    
		    
			SELECT 
				nu_cpf
			,	id_documento
			,	id_tipo_documento
			,	dt_aquisicao
			INTO #AgendasComBios
			FROM 
				#TEMP  AS A
			WHERE 
				EXISTS 
				(
					SELECT * FROM 
					(
						SELECT 
							nu_cpf		
						,	MAX(dt_aquisicao) AS dt_aquisicao
						FROM 
							#TEMP 
						GROUP BY 
							nu_cpf
					) AS Z 
					WHERE 
						A.dt_aquisicao = Z.dt_aquisicao 
					AND A.nu_cpf = Z.nu_cpf
				)		
				/**************************************************************************************************/ 
			   SELECT @EXEC =  'SELECT '
				+	''''
				+	@LK				
				+	''''
				+	'AS SALA'
				+	'
				,	TOTAL_AGENDAS
				,	TOTAL_BIOS_SITE
				,	TOTAL_BIOS_OFF         
				,	(TOTAL_BIOS_SITE - TOTAL_BIOS_OFF) AS TOTAL_PENDENTE         
				FROM 
				(
					SELECT  DISTINCT 
						 A.DT_DIA
					,	 COUNT(A.CD_SALA) OVER (PARTITION BY A.CD_SALA)		AS  TOTAL_AGENDAS
					,	(select COUNT(id_documento) from #AgendasComBios)    as  TOTAL_BIOS_SITE 
					,	COUNT(Z.CD_SALA ) OVER (PARTITION  BY Z.CD_SALA)	AS  TOTAL_BIOS_OFF         
					FROM      
						DB_ES_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS A
					LEFT OUTER JOIN #AgendasComBios AS B   
						ON A.NU_CPF = B.nu_cpf 		
					LEFT OUTER JOIN		'  
				+			@LK
				+	'.DB_SERVIDOR_BLOB_ES_P.DBO.VwAquisicoesTransferidas as Z
						on	Z.id_documento		= B.id_documento
						AND	Z.nu_cpf			= B.NU_CPF    
						AND Z.dt_aquisicao		= B.dt_aquisicao 
					WHERE
						A.CD_SALA = '
					+  CAST(@CD_SALA      AS VARCHAR(10))
					+ 'AND A.DT_DIA =  '
					+ ''''
					+ CONVERT(VARCHAR, @DT_DIA,112)
					+ ''''
					+ 'AND Z.CD_SALA = '
					+  CAST(@CD_SALA      AS VARCHAR(10))
					+ ') AS RELATORIO_AQUISICOES '
		    
				BEGIN TRY 	
					INSERT INTO @TABLE  
					EXEC (@EXEC)
					IF  EXISTS (SELECT  TOP 1 1 FROM @TABLE)
					BEGIN
						INSERT INTO @BiometriasTransferidas
						SELECT 
							'ES'			 AS [Site] 
						,	SALA			 AS [SalaOffLine]		 
						,	@DT_DIA			 AS DataAgendamento				  
						,	TOTAL_BIOS_SITE	 AS [BiometriasTotais] 
						,	TOTAL_PENDENTE   AS [BiometriasPendentes]
						,	GETDATE()		 AS	[Data]     
						,	''			     AS [Observacao]
						FROM 
							@TABLE 
					END	
					ELSE
						BEGIN
							INSERT INTO @BiometriasTransferidas
							SELECT 
								'ES'					AS [Site] 
							,	@LK							AS [SalaOffLine]		 
							,	@DT_DIA			AS DataAgendamento				  
							,	0				AS [BiometriasTotais] 
							,	0				AS [BiometriasPendentes]
							,	GETDATE()		AS	[Data]     
							,	'Não existe agendamento para a data informada'			    AS [Observacao]
						END	
				END TRY 
				BEGIN CATCH 
					INSERT INTO @BiometriasTransferidas
					SELECT 
						'ES'					AS [Site] 
					,	@LK						AS [SalaOffLine]		 
					,	@DT_DIA					AS DataAgendamento				  
					,	(SELECT COUNT(1) FROM  #AgendasComBios )	 AS [BiometriasTotais] 
					,	NULL					AS		[BiometriasPendentes]
					,	GETDATE()				AS	[Data]     
					,	ERROR_MESSAGE()		AS [Observacao]			 
				END CATCH 
				
		
		IF OBJECT_ID('TEMPDB..#AgendasComBios') IS NOT NULL DROP TABLE #AgendasComBios;
		IF OBJECT_ID('TEMPDB..#TEMP') IS NOT NULL DROP TABLE #TEMP;
		DELETE @TABLE
		DELETE @CpfRenach
		SET @I =  @I + 1 
    END    
    SELECT * FROM @BiometriasTransferidas ORDER BY 1
    
    
    
    
    
    