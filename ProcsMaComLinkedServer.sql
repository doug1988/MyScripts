PRINT N'Creating [DBO].[RN_LIBERAR_RETOMADA_PROVA_QG]...';


GO
CREATE  PROCEDURE DBO.RN_LIBERAR_RETOMADA_PROVA_QG (
				@DT_DIA			DATETIME
				,@HR_PROVA		CHAR(5)
				,@CD_SALA		INT
				,@NU_RENACH		BIGINT
				,@NU_CPF		BIGINT
				,@CD_USUARIO	BIGINT
				,@DESCRICAO		VARCHAR(200)
				,@OBSERVACAO	VARCHAR(200) = NULL
)  AS
---------------------------------------------------------------------------------------------
-- DOCUMENTO ORIGEM DA SUB-ROTINA: 
---------------------------------------------------------------------------------------------
-- RN_LIBERAR_RETOMADA_PROVA_QG
-----------------------------------------------------------------------
-- Data			Desenvolvedor			Descrição
-- 14/10/2016	Willian Marciano		Chamado n°26150 - comentado o campo de update tb_provas no site, essa parte do código era utilizado quando a sala era online.
---------------------------------------------------------------------------------------------

BEGIN
	IF @CD_SALA = 803 -- Imperatriz
	BEGIN
		EXEC IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.RN_LIBERAR_RETOMADA_PROVA_SALA_OFFLINE_QG 	
			@DT_DIA		
			,@HR_PROVA	
			,@CD_SALA	
			,@NU_RENACH	
			,@NU_CPF	
			,@CD_USUARIO
			,@DESCRICAO	
			,@OBSERVACAO
	END

	IF @CD_SALA = 921 -- SÃO LUIS
	BEGIN
		EXEC SAOLUIZ.DB_MA_PROVA_DIGITAL.DBO.RN_LIBERAR_RETOMADA_PROVA_SALA_OFFLINE_QG 	
			@DT_DIA		
			,@HR_PROVA	
			,@CD_SALA	
			,@NU_RENACH	
			,@NU_CPF	
			,@CD_USUARIO
			,@DESCRICAO	
			,@OBSERVACAO
	END

	IF @CD_SALA = 727 -- BALSAS
	BEGIN
		EXEC BALSAS.DB_MA_PROVA_DIGITAL.DBO.RN_LIBERAR_RETOMADA_PROVA_SALA_OFFLINE_QG 	
			@DT_DIA		
			,@HR_PROVA	
			,@CD_SALA	
			,@NU_RENACH	
			,@NU_CPF	
			,@CD_USUARIO
			,@DESCRICAO	
			,@OBSERVACAO
	END

	ELSE
	BEGIN
		DECLARE @CD_PROVA BIGINT, @ERRO INT
		SET @ERRO = 0 

	IF NOT EXISTS(
		SELECT 1 
		FROM DBO.TB_AGENDAS_RENACHS (NOLOCK)
		WHERE DT_DIA = @DT_DIA
		AND HR_PROVA = @HR_PROVA 
		AND NU_CPF = @NU_CPF 
		AND NU_RENACH = @NU_RENACH 
		AND CD_SALA = @CD_SALA 
	)
	BEGIN
		RAISERROR('NÃO HÁ AGENDAMENTO PARA ESSA PROVA.', 16, 1)
		RETURN
	END
	IF NOT EXISTS(
		SELECT 1 
		FROM DBO.TB_PROVAS (NOLOCK)
		WHERE DT_DIA = @DT_DIA
		AND HR_PROVA = @HR_PROVA 
		AND NU_CPF = @NU_CPF 
		AND NU_RENACH = @NU_RENACH 
		AND CD_SALA = @CD_SALA 
	)
	BEGIN
		RAISERROR('NÃO EXISTE PROVA PARA SER COLOCADA PARA RETOMADA.', 16, 1)
		RETURN
	END
	
	IF NOT EXISTS (SELECT 1 FROM TB_SALAS WHERE CD_SALA = @CD_SALA AND CD_TIPO_PROVA = 1)
	BEGIN
		RAISERROR('A SALA INFORMADA NÃO É UMA SALA DE PROVA DIGITAL.', 16, 1)
		RETURN
	END

	----CARREGA A RESPECTIVA PROVA NA VARIÁVEL
	--SELECT @CD_PROVA  = CD_PROVA
	--FROM TB_PROVAS (NOLOCK)
	--WHERE DT_DIA = @DT_DIA
	--AND HR_PROVA = @HR_PROVA 
	--AND NU_CPF = @NU_CPF 
	--AND NU_RENACH = @NU_RENACH 
	--AND CD_SALA = @CD_SALA 
	
	--IF @CD_PROVA IS NOT NULL
	--BEGIN
	--	BEGIN TRAN A
	--	BEGIN TRY
	--		--COLOCANDO PARA RETOMADA
	--		UPDATE TB_PROVAS 
	--			SET DT_INICIO = ISNULL(DT_INICIO, DATEADD(MI, -2, GETDATE())), DT_FIM = NULL 
	--		WHERE CD_PROVA = @CD_PROVA
	--		SET @ERRO = @ERRO + @@ERROR
	
	--		--LOGA A AÇÃO NA TABELA DE LOGS
	--		EXEC DBO.SP_LOGAR_ACOES_QGS 4, @DESCRICAO , @OBSERVACAO, @CD_USUARIO, @DT_DIA, @HR_PROVA, @CD_SALA, @NU_RENACH, @NU_CPF 
	--		SET @ERRO = @ERRO + @@ERROR

	--	END TRY
	--	BEGIN CATCH
	--		ROLLBACK TRAN A
	--		DECLARE @A VARCHAR(MAX)
	--		SET @A = '#ERRO AO TENTAR COLOCAR PROVA PARA RETOMADA ' + ERROR_MESSAGE() + '#';
	--		RAISERROR(@A, 16, 1)
	--		RETURN
	--	END CATCH
	--		COMMIT TRAN A
		
	--END
	END
END
GO
PRINT N'Creating [dbo].[SP_CANCELAR_PROVA_SITE]...';


GO
CREATE PROCEDURE SP_CANCELAR_PROVA_SITE(@DT_DIA DATETIME, @HR_PROVA VARCHAR(5), @CD_SALA INT, @NU_CPF BIGINT = NULL, @NU_RENACH BIGINT = NULL, @CD_USUARIO BIGINT, @MOTIVO VARCHAR(200)=NULL, @FL_SURDEZ BIT = 0) 
AS
BEGIN
	DECLARE @CD_PROVA BIGINT, @ID INT, @NU_CPF_AUX BIGINT, @NU_RENACH_AUX BIGINT
	
	CREATE TABLE #TEMP(	  ID INT IDENTITY
						, DT_DIA DATETIME 
						, HR_PROVA CHAR(5)
						, CD_SALA INT
						, NU_CPF BIGINT
						, NU_RENACH BIGINT
					  )
	SET @ID = 1
					  
	--VERIFICA SE O PAR (CPF E RENACH) ESTÁ COMPLETO
	IF ((@NU_CPF IS NOT NULL AND @NU_RENACH IS NULL) OR (@NU_CPF IS NULL AND @NU_RENACH IS NOT NULL))
	BEGIN
		RAISERROR ('AÇÃO NÃO AUTORIZADA: SEMPRE É REQUERIDO O PAR CPF E RENACH',16,1)
		RETURN -1
	END
		
	--AJUSTANDO O MOTIVO DA EXCLUSÃO	
	IF ISNULL(@MOTIVO, '') = '' 
	BEGIN
		SET @MOTIVO = 'CANCELAMENTO DE PROVA'
	END 
	ELSE 
	BEGIN
		SET @MOTIVO = 'CANCELAMENTO DE PROVA - ' + ISNULL(@MOTIVO, '') 
	END
						  
	
	--POPULA A TABELA TEMPORÁRIA
	IF @NU_CPF IS NOT NULL AND @NU_RENACH IS NOT NULL --SE É CANCELAMENTO DE UM CANDIDATO ESPECÍFICO
	BEGIN
		INSERT INTO #TEMP (DT_DIA, HR_PROVA, CD_SALA, NU_CPF, NU_RENACH)
		VALUES (@DT_DIA, @HR_PROVA, @CD_SALA, @NU_CPF, @NU_RENACH)
	END
	ELSE --SE É CANCELAMENTO DE UMA TURMA INTEIRA
	BEGIN
		INSERT INTO #TEMP (DT_DIA, HR_PROVA, CD_SALA, NU_CPF, NU_RENACH)
		SELECT DISTINCT X.DT_DIA, X.HR_PROVA, X.CD_SALA, X.NU_CPF, X.NU_RENACH
		FROM (
				SELECT DT_DIA, HR_PROVA, CD_SALA, NU_CPF, NU_RENACH
				FROM TB_AGENDAS_RENACHS 
				WHERE DT_DIA = @DT_DIA AND HR_PROVA = @HR_PROVA AND CD_SALA = @CD_SALA
				UNION ALL
				SELECT DT_DIA, HR_PROVA, CD_SALA, NU_CPF, NU_RENACH
				FROM TB_HISTORICOS_AGENDAS_RENACHS 
				WHERE DT_DIA = @DT_DIA AND HR_PROVA = @HR_PROVA AND CD_SALA = @CD_SALA
			 ) AS X
	END
	
	--LOOP EM TODOS OS CANDIDATOS PARA CANCELAR A PROVA
	WHILE @ID <= (SELECT MAX(ID) FROM #TEMP)
	BEGIN
		SELECT	@NU_CPF_AUX = NU_CPF, 
				@NU_RENACH_AUX = NU_RENACH 
		FROM #TEMP 
		WHERE ID = @ID

		---VERIFICA SE HÁ AGENDA E PROVA NA SALA OFFLINE, SE HOUVER JOGA PARA HISTÓRICO
		DECLARE @RET INT
				
		EXEC @RET = IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.SP_CANCELAR_PROVA_SERVER_OFFLINE @NU_CPF_AUX, @NU_RENACH_AUX, @DT_DIA , @HR_PROVA, @CD_SALA
		IF @RET = -1
		BEGIN 
			RETURN -1
		END
			

		BEGIN TRAN A
		
		
		--SETANDO O CÓDIGO DA PROVA NO SITE
		SET @CD_PROVA = NULL
		SELECT @CD_PROVA = CD_PROVA 
		FROM TB_PROVAS (NOLOCK) 
		WHERE NU_CPF = @NU_CPF_AUX 
		AND NU_RENACH = @NU_RENACH_AUX
		AND DT_DIA = @DT_DIA 
		AND HR_PROVA  = @HR_PROVA  
		AND CD_SALA = @CD_SALA 
		
		--SE EXISTIR PROVA NO SITE, ELA É EXCLUIDA E ENVIADA PARA O HISTÓRICO
		IF @CD_PROVA IS NOT NULL
		BEGIN
			EXEC RN_EXCLUIR_PROVA @CD_PROVA, @MOTIVO, @CD_USUARIO
			IF @@ERROR <> 0 
			BEGIN 
				ROLLBACK TRAN A
				RETURN -1
			END
		END
		
		--SE EXISTIR AGENDAMENTO NO SITE, ELE É EXCLUÍDO E INSERINDO EM HISTÓRICO
		INSERT INTO TB_HISTORICOS_AGENDAS_RENACHS (DT_DIA,HR_PROVA,CD_SALA,NU_RENACH,NU_CPF,DT_ESTADO_AGENDA_RENACH,CD_CNPJ,CD_CONFIGURACAO_PROVA,CD_USUARIO,CD_TIPO_PRODAM,DT_HISTORICO, FL_SURDEZ )
		SELECT DT_DIA,HR_PROVA,CD_SALA,NU_RENACH,NU_CPF,DT_ESTADO_AGENDA_RENACH,CD_CNPJ,CD_CONFIGURACAO_PROVA,CD_USUARIO,CD_TIPO_PRODAM,GETDATE(), @FL_SURDEZ 
		FROM TB_AGENDAS_RENACHS 
		WHERE NU_CPF = @NU_CPF_AUX 
		AND NU_RENACH = @NU_RENACH_AUX
		AND DT_DIA = @DT_DIA 
		AND HR_PROVA  = @HR_PROVA  
		AND CD_SALA = @CD_SALA
		IF @@ERROR <> 0 
		BEGIN 
			ROLLBACK TRAN A
			RETURN -1
		END
		
		DELETE FROM TB_AGENDAS_RENACHS 
		WHERE NU_CPF = @NU_CPF_AUX 
		AND NU_RENACH = @NU_RENACH_AUX 
		AND DT_DIA = @DT_DIA 
		AND HR_PROVA  = @HR_PROVA  
		AND CD_SALA = @CD_SALA
		IF @@ERROR <> 0 
		BEGIN 
			ROLLBACK TRAN A
			RETURN -1
		END
		
		COMMIT TRAN A
		
		--INCREMENTANDO INDEXADOR
		SET @ID = @ID + 1
	END
	
	RETURN 0
END
GO
PRINT N'Creating [DBO].[SP_JOB_BUSCAR_AGENDAMENTOS_SALA_OFFLINE_OGT]...';


GO


CREATE PROCEDURE [DBO].[SP_JOB_BUSCAR_AGENDAMENTOS_SALA_OFFLINE_OGT] 
(
	@DT_DIA SMALLDATETIME = NULL
,	@HR_PROVA CHAR(5) = NULL
,	@CD_SALA INT = NULL
)
  
    
------------------------------------------------------------------------    
-- SP_JOB_BUSCAR_AGENDAMENTOS_SALA_OFFLINE_OGT    
--  DATA: 14/09/2015    
------------------------------------------------------------------------    
--  OBJETIVO:     
--  FAZ CHAMADA DA PROCEDURE PARA CADA SALA OFFLINE QUE BUSCA OS AGENDAMENTOS NO SITE E OS TRANSFERE PARA O SERVIDOR OFFLINE 
--  DESENVOLVEDOR: Willian Marciano    
--    
------------------------------------------------------------------------    
--  HISTÓRICO DE REVISÕES      
------------------------------------------------------------------------    
--  DATA:    
--        [DATA DA REVISAO DA PROCEDURE]    
--  DESENVOLVEDOR:    
--        [NOME DO DESENVOLVEDOR]    
--  DESCRICAO:    
--        [DESCRICAO DA ALTERACAO]    
------------------------------------------------------------------------    
AS
BEGIN  

 IF @DT_DIA IS NULL
 BEGIN
	SELECT 'INFORME A DATA DO AGENDAMENTO'
	RETURN -1	
 END

 IF @CD_SALA IS NULL
 BEGIN
	SELECT 'INFORME A SALA'
	RETURN -1
 END
 
 --BALSAS DIGITAL
 IF @CD_SALA = 727
	BEGIN
		IF NOT EXISTS(SELECT TOP 1 1 FROM DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS WHERE CD_SALA = 727 AND DT_DIA = @DT_DIA AND HR_PROVA = ISNULL(@HR_PROVA, HR_PROVA)) 
		BEGIN
			RAISERROR('NÃO HÁ PROVA GERADA PARA A SALA NO PERIODO INFORMADO', 16,1)
			RETURN -1
		END

		EXEC BALSAS.DB_MA_PROVA_DIGITAL.DBO.SP_JOB_BUSCAR_AGENDAMENTOS_OGT 
		@DT_DIA, @HR_PROVA
	END

--IMPERATRIZ
 ELSE IF @CD_SALA = 803
	BEGIN
		IF NOT EXISTS(SELECT TOP 1 1 FROM DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS WHERE CD_SALA = 803 AND DT_DIA = @DT_DIA AND HR_PROVA = ISNULL(@HR_PROVA, HR_PROVA)) 
		BEGIN
			RAISERROR('NÃO HÁ PROVA GERADA PARA A SALA NO PERIODO INFORMADO', 16,1)
			RETURN -1
		END

		EXEC IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.SP_JOB_BUSCAR_AGENDAMENTOS_OGT 
		@DT_DIA, @HR_PROVA
	END
END
GO
PRINT N'Creating [dbo].[SP_JOB_ENVIAR_RESULTADOS]...';


GO
  
CREATE procedure dbo.SP_JOB_ENVIAR_RESULTADOS  
(  
 @DT_DIA smalldatetime  
, @HR_PROVA varchar(5)  
, @CD_SALA int  
, @NU_RENACH bigint  
, @NU_CPF bigint  
)  
  
------------------------------------------------------------------------  
-- SP_JOB_ENVIAR_RESULTADOS  
--  Data: 13/03/2009  
------------------------------------------------------------------------  
--  Objetivo:   
--   Envia os resultas para o Banco de dados do site.  
--  Desenvolvedor: Thiago Y. Yamashiro  
--  
------------------------------------------------------------------------  
--  Histórico de revisões    
------------------------------------------------------------------------  
--  Data:  
--        [data da revisao da procedure]  
--  Desenvolvedor:  
--        [nome do desenvolvedor]  
--  Descricao:  
--        [descricao da alteracao]  
------------------------------------------------------------------------  
as  
begin  
  
 -- ( Início ) - Declara variáveis auxiliares ...  
 declare @DT_EVENTO datetime  
   
 set @DT_EVENTO = getdate()  
 -- ( Fim ) - Declara variáveis auxiliares .   
  
 -- ( Início ) - Declara tabelas temporárias ...  
 declare @TB_HISTORICOS_PROVAS table  
 (  
  CD_PROVA bigint  
 , CD_PERGUNTA int  
 , CD_RESPOSTA_CANDIDATO bigint  
 , DT_EVENTO_CLIQUE datetime  
 )  
   
   
 declare @TB_PROVAS_GERADAS table  
 (  
  CD_PROVA bigint  
 , CD_PERGUNTA int  
 , CD_RESPOSTA_CANDIDATO int  
 , NU_ORDEM int   
 )  
   
 declare @TB_PROVAS table   
 (  
  CD_PROVA bigint  
 , CD_CONFIGURACAO_PROVA int  
 , NU_RENACH bigint  
 , NU_CPF bigint  
 , DT_INICIO datetime  
 , DT_FIM datetime  
 , CD_IDENTIFICADOR_COMPUTADOR int  
 , CD_USUARIO bigint  
 , DT_DIA smalldatetime  
 , HR_PROVA char(5)  
 , CD_SALA int  
 , CD_EXAMINADOR int  
 , CD_EXAMINADOR_SEARCH_01 varchar(11)  
 , CD_EXAMINADOR_SEARCH_02 varchar (11)  
 )  
 -- ( Fim ) - Declara tabelas temporárias .  
   
 -- ( Início ) - Alimenta tabelas temporárias ...   
 INSERT INTO @TB_PROVAS   
 (  
  CD_PROVA   
 , CD_CONFIGURACAO_PROVA   
 , NU_RENACH   
 , NU_CPF   
 , DT_INICIO   
 , DT_FIM   
 , CD_IDENTIFICADOR_COMPUTADOR   
 , CD_USUARIO   
 , DT_DIA   
 , HR_PROVA   
 , CD_SALA   
 , CD_EXAMINADOR   
 , CD_EXAMINADOR_SEARCH_01   
 , CD_EXAMINADOR_SEARCH_02   
 )   
 select  
  CD_PROVA   
 , CD_CONFIGURACAO_PROVA   
 , NU_RENACH   
 , NU_CPF   
 , DT_INICIO   
 , DT_FIM   
 , CD_IDENTIFICADOR_COMPUTADOR   
 , CD_USUARIO   
 , DT_DIA   
 , HR_PROVA   
 , CD_SALA   
 , CD_EXAMINADOR   
 , CD_EXAMINADOR_SEARCH_01   
 , CD_EXAMINADOR_SEARCH_02   
 from  
  IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS   
 where   
  DT_DIA = @DT_DIA  
 and HR_PROVA = @HR_PROVA  
 and CD_SALA = @CD_SALA  
 and NU_RENACH = @NU_RENACH  
 and NU_CPF = @NU_CPF    
   
 insert into @TB_HISTORICOS_PROVAS  
 (  
  CD_PROVA  
 , CD_PERGUNTA  
 , CD_RESPOSTA_CANDIDATO  
 , DT_EVENTO_CLIQUE  
 )  
 select  
  A.CD_PROVA  
 , A.CD_PERGUNTA  
 , A.CD_RESPOSTA_CANDIDATO  
 , A.DT_EVENTO_CLIQUE  
 from  
  IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.TB_HISTORICOS_PROVAS A  
 inner join  
  @TB_PROVAS B  
   on  
    A.CD_PROVA = B.CD_PROVA  
       
 insert into @TB_PROVAS_GERADAS   
 (  
  CD_PROVA   
 , CD_PERGUNTA   
 , CD_RESPOSTA_CANDIDATO   
 , NU_ORDEM   
 )  
 select        
  A.CD_PROVA   
 , A.CD_PERGUNTA   
 , A.CD_RESPOSTA_CANDIDATO   
 , A.NU_ORDEM    
 from  
  IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS_GERADAS A  
 inner join  
  @TB_PROVAS B  
   on  
    A.CD_PROVA = B.CD_PROVA   
 -- ( Fim ) - Alimenta tabelas temporárias .   
   
 begin tran RESULTADO  
  
  -- ( Início ) - Transfere os dados do histórico da prova ...  
  insert into TB_HISTORICOS_PROVAS  
  (  
   CD_PROVA  
  , CD_PERGUNTA  
  , CD_RESPOSTA_CANDIDATO  
  , DT_EVENTO_CLIQUE  
  )  
  select  
   A.CD_PROVA  
  , A.CD_PERGUNTA  
  , A.CD_RESPOSTA_CANDIDATO  
  , A.DT_EVENTO_CLIQUE   
  from  
   @TB_HISTORICOS_PROVAS A   
  inner join  
   TB_PROVAS B  
    on  
     A.CD_PROVA = B.CD_PROVA  
  where   
   B.DT_DIA = @DT_DIA  
  and B.HR_PROVA = @HR_PROVA  
  and B.CD_SALA = @CD_SALA  
  and B.NU_RENACH = @NU_RENACH  
  and B.NU_CPF = @NU_CPF  
  and not exists  
   (select C.CD_PROVA, C.CD_PERGUNTA, C.DT_EVENTO_CLIQUE from TB_HISTORICOS_PROVAS C  
    where   
     A.CD_PROVA = C.CD_PROVA  
    and A.CD_PERGUNTA = C.CD_PERGUNTA  
   )   
  
   if @@error <> 0  
    begin   
     rollback tran RESULTADO  
             
     insert into TB_LOG_REPLICACAO (DT_EVENTO, DS_PROCEDURE, DS_EVENTO)  
     values (@DT_EVENTO, 'SP_JOB_ENVIAR_RESULTADOS', 'Cadastra o histórico da prova.')  
       
     insert into TB_LOG_REPLICACAO_REGISTROS (DT_EVENTO, DT_DIA, HR_PROVA, NU_RENACH, NU_CPF, CD_SALA)  
     select @DT_EVENTO, @DT_DIA, @HR_PROVA, @NU_RENACH, @NU_CPF, @CD_SALA   
  
     return -1  
    end    
  -- ( Fim ) - Transfere os dados do histórico da prova .     
  
  -- ( Início ) - Atualiza as respostas do candidato ...  
  update TB_PROVAS_GERADAS  
  set  
   CD_RESPOSTA_CANDIDATO = B.CD_RESPOSTA_CANDIDATO  
  from  
   TB_PROVAS_GERADAS A  
  inner join  
   @TB_PROVAS_GERADAS B  
   on  
    A.CD_PROVA = B.CD_PROVA  
   and A.CD_PERGUNTA = B.CD_PERGUNTA     
  inner join  
   TB_PROVAS C  
    on  
     A.CD_PROVA = C.CD_PROVA  
  where   
   C.DT_DIA = @DT_DIA  
  and C.HR_PROVA = @HR_PROVA  
  and C.CD_SALA = @CD_SALA  
  and C.NU_RENACH = @NU_RENACH  
  and C.NU_CPF = @NU_CPF    
     
   if @@error <> 0  
    begin         
     rollback tran RESULTADO  
      
     insert into TB_LOG_REPLICACAO (DT_EVENTO, DS_PROCEDURE, DS_EVENTO)  
     values (@DT_EVENTO, 'SP_JOB_ENVIAR_RESULTADOS', 'Atualiza as respostas do candidato.')  
       
     insert into TB_LOG_REPLICACAO_REGISTROS (DT_EVENTO, DT_DIA, HR_PROVA, NU_RENACH, NU_CPF, CD_SALA)  
     select @DT_EVENTO, @DT_DIA, @HR_PROVA, @NU_RENACH, @NU_CPF, @CD_SALA   
  
     return -1  
    end    
  -- ( Fim ) - Atualiza as respostas do candidato .  
   
  -- ( Início ) - Atauliza os dados da prova ...  
  update TB_PROVAS  
  set  
   DT_INICIO = B.DT_INICIO  
  , DT_FIM = B.DT_FIM  
  , CD_IDENTIFICADOR_COMPUTADOR = B.CD_IDENTIFICADOR_COMPUTADOR   
  , CD_USUARIO = B.CD_USUARIO  
  , CD_EXAMINADOR = B.CD_EXAMINADOR  
  , CD_EXAMINADOR_SEARCH_01 = B.CD_EXAMINADOR_SEARCH_01  
  , CD_EXAMINADOR_SEARCH_02 = B.CD_EXAMINADOR_SEARCH_02
  from  
   TB_PROVAS A  
  inner join  
   @TB_PROVAS B  
    on  
     A.DT_DIA = B.DT_DIA  
    and A.HR_PROVA = B.HR_PROVA  
    and A.CD_SALA = B.CD_SALA  
    and A.NU_RENACH = B.NU_RENACH  
    and A.NU_CPF = B.NU_CPF  
  where   
   A.DT_DIA = @DT_DIA  
  and A.HR_PROVA = @HR_PROVA  
  and A.CD_SALA = @CD_SALA  
  and A.NU_RENACH = @NU_RENACH  
  and A.NU_CPF = @NU_CPF   
    
   if @@error <> 0  
    begin         
     rollback tran RESULTADO  
      
     insert into TB_LOG_REPLICACAO (DT_EVENTO, DS_PROCEDURE, DS_EVENTO)  
     values (@DT_EVENTO, 'SP_JOB_ENVIAR_RESULTADOS', 'Atualiza os dados da prova.')  
       
     insert into TB_LOG_REPLICACAO_REGISTROS (DT_EVENTO, DT_DIA, HR_PROVA, NU_RENACH, NU_CPF, CD_SALA)  
     select @DT_EVENTO, @DT_DIA, @HR_PROVA, @NU_RENACH, @NU_CPF, @CD_SALA   
  
     return -1  
    end       
  -- ( Fim ) -Atauliza os dados da prova  .  
  
  -- ( Início ) - Insere na TB_RENACHS_AGENDAS_LOG ...  
  insert into TB_AGENDAS_RENACHS_LOG  
  (  
   DT_DIA  
  , HR_PROVA  
  , CD_SALA  
  , NU_RENACH  
  , NU_CPF  
  )  
  select   
   A.DT_DIA  
  , A.HR_PROVA  
  , A.CD_SALA  
  , A.NU_RENACH  
  , A.NU_CPF  
  from  
   TB_AGENDAS_RENACHS A  
  where   
   A.DT_DIA = @DT_DIA  
  and A.HR_PROVA = @HR_PROVA  
  and A.CD_SALA = @CD_SALA  
  and A.NU_RENACH = @NU_RENACH  
  and A.NU_CPF = @NU_CPF   
  and not exists  
    (select C.DT_DIA, C.HR_PROVA, C.CD_SALA, C.NU_RENACH, C.NU_CPF from TB_AGENDAS_RENACHS_LOG C  
     where   
      A.DT_DIA = C.DT_DIA  
     and A.HR_PROVA = C.HR_PROVA  
     and A.CD_SALA = C.CD_SALA  
     and A.NU_RENACH = C.NU_RENACH  
     and A.NU_CPF = C.NU_CPF  
    )    
  -- ( Fim ) - Insere na TB_RENACHS_AGENDAS_LOG .  
  
 commit tran RESULTADO  
end
GO

PRINT N'Creating [dbo].[SP_JOB_ENVIAR_RESULTADOS_AUXILIAR]...';


GO

CREATE procedure dbo.SP_JOB_ENVIAR_RESULTADOS_AUXILIAR
(
    @DT_DIA smalldatetime
,    @HR_PROVA varchar(5)
,    @CD_SALA int
,    @NU_RENACH bigint
,    @NU_CPF bigint
)

------------------------------------------------------------------------
-- SP_JOB_ENVIAR_RESULTADOS
--  Data: 13/03/2009
------------------------------------------------------------------------
--  Objetivo: 
--            Envia os resultas para o Banco de dados do site.
--  Desenvolvedor: Thiago Y. Yamashiro
--
------------------------------------------------------------------------
--  Histórico de revisões  
------------------------------------------------------------------------
--  Data:
--        [data da revisao da procedure]
--  Desenvolvedor:
--        [nome do desenvolvedor]
--  Descricao:
--        [descricao da alteracao]
------------------------------------------------------------------------
as
begin

    -- ( Início ) - Declara variáveis auxiliares ...
    declare @DT_EVENTO datetime
    
    set @DT_EVENTO = getdate()
    -- ( Fim ) - Declara variáveis auxiliares .    

    -- ( Início ) - Declara tabelas temporárias ...
    declare @TB_HISTORICOS_PROVAS table
    (
        CD_PROVA    bigint
    ,    CD_PERGUNTA    int
    ,    CD_RESPOSTA_CANDIDATO    bigint
    ,    DT_EVENTO_CLIQUE    datetime
    )
    
    
    declare @TB_PROVAS_GERADAS table
    (
        CD_PROVA    bigint
    ,    CD_PERGUNTA    int
    ,    CD_RESPOSTA_CANDIDATO    int
    ,    NU_ORDEM    int    
    )
    
    declare @TB_PROVAS table 
    (
        CD_PROVA    bigint
    ,    CD_CONFIGURACAO_PROVA    int
    ,    NU_RENACH    bigint
    ,    NU_CPF    bigint
    ,    DT_INICIO    datetime
    ,    DT_FIM    datetime
    ,    CD_IDENTIFICADOR_COMPUTADOR    int
    ,    CD_USUARIO    bigint
    ,    DT_DIA    smalldatetime
    ,    HR_PROVA    char(5)
    ,    CD_SALA    int
    ,    CD_EXAMINADOR    int
    ,    CD_EXAMINADOR_SEARCH_01    varchar(11)
    ,    CD_EXAMINADOR_SEARCH_02    varchar    (11)
    )
    -- ( Fim ) - Declara tabelas temporárias .
    
    -- ( Início ) - Alimenta tabelas temporárias ...    
    INSERT INTO @TB_PROVAS 
    (
        CD_PROVA    
    ,    CD_CONFIGURACAO_PROVA    
    ,    NU_RENACH    
    ,    NU_CPF    
    ,    DT_INICIO    
    ,    DT_FIM    
    ,    CD_IDENTIFICADOR_COMPUTADOR    
    ,    CD_USUARIO    
    ,    DT_DIA    
    ,    HR_PROVA    
    ,    CD_SALA    
    ,    CD_EXAMINADOR    
    ,    CD_EXAMINADOR_SEARCH_01    
    ,    CD_EXAMINADOR_SEARCH_02    
    )    
    select
        CD_PROVA    
    ,    CD_CONFIGURACAO_PROVA    
    ,    NU_RENACH    
    ,    NU_CPF    
    ,    DT_INICIO    
    ,    DT_FIM    
    ,    CD_IDENTIFICADOR_COMPUTADOR    
    ,    CD_USUARIO    
    ,    DT_DIA    
    ,    HR_PROVA    
    ,    CD_SALA    
    ,    CD_EXAMINADOR    
    ,    CD_EXAMINADOR_SEARCH_01    
    ,    CD_EXAMINADOR_SEARCH_02    
    from
        IMPERATRIZ.DB_MA_PROVA_DIGITAL_AUXILIAR.DBO.TB_PROVAS    
    where 
        DT_DIA = @DT_DIA
    and HR_PROVA = @HR_PROVA
    and CD_SALA = @CD_SALA
    and NU_RENACH = @NU_RENACH
    and NU_CPF = @NU_CPF        
    
    insert into @TB_HISTORICOS_PROVAS
    (
        CD_PROVA
    ,    CD_PERGUNTA
    ,    CD_RESPOSTA_CANDIDATO
    ,    DT_EVENTO_CLIQUE
    )
    select
        A.CD_PROVA
    ,    A.CD_PERGUNTA
    ,    A.CD_RESPOSTA_CANDIDATO
    ,    A.DT_EVENTO_CLIQUE
    from
        IMPERATRIZ.DB_MA_PROVA_DIGITAL_AUXILIAR.DBO.TB_HISTORICOS_PROVAS A
    inner join
        @TB_PROVAS B
            on
                A.CD_PROVA = B.CD_PROVA
                    
    insert into @TB_PROVAS_GERADAS 
    (
        CD_PROVA    
    ,    CD_PERGUNTA    
    ,    CD_RESPOSTA_CANDIDATO    
    ,    NU_ORDEM    
    )
    select                        
        A.CD_PROVA    
    ,    A.CD_PERGUNTA    
    ,    A.CD_RESPOSTA_CANDIDATO    
    ,    A.NU_ORDEM        
    from
        IMPERATRIZ.DB_MA_PROVA_DIGITAL_AUXILIAR.DBO.TB_PROVAS_GERADAS A
    inner join
        @TB_PROVAS B
            on
                A.CD_PROVA = B.CD_PROVA    
    -- ( Fim ) - Alimenta tabelas temporárias .    
    
    begin tran RESULTADO

        -- ( Início ) - Transfere os dados do histórico da prova ...
        insert into TB_HISTORICOS_PROVAS
        (
            CD_PROVA
        ,    CD_PERGUNTA
        ,    CD_RESPOSTA_CANDIDATO
        ,    DT_EVENTO_CLIQUE
        )
        select
            A.CD_PROVA
        ,    A.CD_PERGUNTA
        ,    A.CD_RESPOSTA_CANDIDATO
        ,    A.DT_EVENTO_CLIQUE    
        from
            @TB_HISTORICOS_PROVAS A    
        inner join
            TB_PROVAS B
                on
                    A.CD_PROVA = B.CD_PROVA
        where 
            B.DT_DIA = @DT_DIA
        and B.HR_PROVA = @HR_PROVA
        and B.CD_SALA = @CD_SALA
        and B.NU_RENACH = @NU_RENACH
        and B.NU_CPF = @NU_CPF
        and not exists
            (select C.CD_PROVA, C.CD_PERGUNTA, C.DT_EVENTO_CLIQUE from TB_HISTORICOS_PROVAS C
                where 
                    A.CD_PROVA = C.CD_PROVA
                and A.CD_PERGUNTA = C.CD_PERGUNTA
            )    

            if @@error <> 0
                begin    
                    rollback tran RESULTADO
                                            
                    insert into TB_LOG_REPLICACAO (DT_EVENTO, DS_PROCEDURE, DS_EVENTO)
                    values (@DT_EVENTO, 'SP_JOB_ENVIAR_RESULTADOS', 'Cadastra o histórico da prova.')
                    
                    insert into TB_LOG_REPLICACAO_REGISTROS (DT_EVENTO, DT_DIA, HR_PROVA, NU_RENACH, NU_CPF, CD_SALA)
                    select @DT_EVENTO, @DT_DIA, @HR_PROVA, @NU_RENACH, @NU_CPF, @CD_SALA 

                    return -1
                end        
        -- ( Fim ) - Transfere os dados do histórico da prova .            

        -- ( Início ) - Atualiza as respostas do candidato ...
        update TB_PROVAS_GERADAS
        set
            CD_RESPOSTA_CANDIDATO = B.CD_RESPOSTA_CANDIDATO
        from
            TB_PROVAS_GERADAS A
        inner join
            @TB_PROVAS_GERADAS B
            on
                A.CD_PROVA = B.CD_PROVA
            and A.CD_PERGUNTA = B.CD_PERGUNTA            
        inner join
            TB_PROVAS C
                on
                    A.CD_PROVA = C.CD_PROVA
        where 
            C.DT_DIA = @DT_DIA
        and C.HR_PROVA = @HR_PROVA
        and C.CD_SALA = @CD_SALA
        and C.NU_RENACH = @NU_RENACH
        and C.NU_CPF = @NU_CPF        
         
            if @@error <> 0
                begin                            
                    rollback tran RESULTADO
                
                    insert into TB_LOG_REPLICACAO (DT_EVENTO, DS_PROCEDURE, DS_EVENTO)
                    values (@DT_EVENTO, 'SP_JOB_ENVIAR_RESULTADOS', 'Atualiza as respostas do candidato.')
                    
                    insert into TB_LOG_REPLICACAO_REGISTROS (DT_EVENTO, DT_DIA, HR_PROVA, NU_RENACH, NU_CPF, CD_SALA)
                    select @DT_EVENTO, @DT_DIA, @HR_PROVA, @NU_RENACH, @NU_CPF, @CD_SALA 

                    return -1
                end        
        -- ( Fim ) - Atualiza as respostas do candidato .
    
        -- ( Início ) - Atauliza os dados da prova ...
        update TB_PROVAS
        set
            DT_INICIO = B.DT_INICIO
        ,    DT_FIM = B.DT_FIM
        ,    CD_IDENTIFICADOR_COMPUTADOR = B.CD_IDENTIFICADOR_COMPUTADOR 
        ,    CD_USUARIO = B.CD_USUARIO
        ,    CD_EXAMINADOR = B.CD_EXAMINADOR
        --,    CD_EXAMINADOR_SEARCH_01 = B.CD_EXAMINADOR_SEARCH_01
        --,    CD_EXAMINADOR_SEARCH_02 = B.CD_EXAMINADOR_SEARCH_02
        from
            TB_PROVAS A
        inner join
            @TB_PROVAS B
                on
                    A.DT_DIA = B.DT_DIA
                and A.HR_PROVA = B.HR_PROVA
                and A.CD_SALA = B.CD_SALA
                and A.NU_RENACH = B.NU_RENACH
                and A.NU_CPF = B.NU_CPF
        where 
            A.DT_DIA = @DT_DIA
        and A.HR_PROVA = @HR_PROVA
        and A.CD_SALA = @CD_SALA
        and A.NU_RENACH = @NU_RENACH
        and A.NU_CPF = @NU_CPF    
        
            if @@error <> 0
                begin                            
                    rollback tran RESULTADO
                
                    insert into TB_LOG_REPLICACAO (DT_EVENTO, DS_PROCEDURE, DS_EVENTO)
                    values (@DT_EVENTO, 'SP_JOB_ENVIAR_RESULTADOS', 'Atualiza os dados da prova.')
                    
                    insert into TB_LOG_REPLICACAO_REGISTROS (DT_EVENTO, DT_DIA, HR_PROVA, NU_RENACH, NU_CPF, CD_SALA)
                    select @DT_EVENTO, @DT_DIA, @HR_PROVA, @NU_RENACH, @NU_CPF, @CD_SALA 

                    return -1
                end                    
        -- ( Fim ) -Atauliza os dados da prova  .

        -- ( Início ) - Insere na TB_RENACHS_AGENDAS_LOG ...
        insert into TB_AGENDAS_RENACHS_LOG
        (
            DT_DIA
        ,    HR_PROVA
        ,    CD_SALA
        ,    NU_RENACH
        ,    NU_CPF
        )
        select 
            A.DT_DIA
        ,    A.HR_PROVA
        ,    A.CD_SALA
        ,    A.NU_RENACH
        ,    A.NU_CPF
        from
            TB_AGENDAS_RENACHS A
        where 
            A.DT_DIA = @DT_DIA
        and A.HR_PROVA = @HR_PROVA
        and A.CD_SALA = @CD_SALA
        and A.NU_RENACH = @NU_RENACH
        and A.NU_CPF = @NU_CPF    
        and not exists
                (select C.DT_DIA, C.HR_PROVA, C.CD_SALA, C.NU_RENACH, C.NU_CPF from TB_AGENDAS_RENACHS_LOG C
                    where 
                        A.DT_DIA = C.DT_DIA
                    and A.HR_PROVA = C.HR_PROVA
                    and A.CD_SALA = C.CD_SALA
                    and A.NU_RENACH = C.NU_RENACH
                    and A.NU_CPF = C.NU_CPF
                )        
        -- ( Fim ) - Insere na TB_RENACHS_AGENDAS_LOG .

    commit tran RESULTADO
end
GO


PRINT N'Creating [dbo].[SP_TOTALIZADOR_PROVAS_RESULTADOS]...';


GO
-- =============================================
-- Author:		<Author, Everton de Sá Batista>
-- Create date: <Create Date, 17/03/2016>
-- Description:	<Description, Procedure que retorna de forma totalizada os dados de provas e resultados>
-- =============================================
CREATE PROCEDURE SP_TOTALIZADOR_PROVAS_RESULTADOS

	-- 0 - SINTÉTICO / 1 - ANALÍTICO
	@TIPO BIT

AS
BEGIN

DECLARE	 @QTD_AGENDAMENTOS INT
		,@QTD_PROVAS_T_CORRIGIDAS INT
		,@QTD_PROVAS_T_AGUARDANDO_CORRECAO INT
		,@QTD_PROVAS_T_FALTOSAS INT
		,@QTD_PROVAS_P_CORRIGIDAS INT
		,@QTD_PROVAS_P_AGUARDANDO_CORRECAO INT
		,@QTD_PROVAS_P_FALTOSAS INT
		,@QTD_RESULTADOS_ACATADOS INT
		,@QTD_RETORNOS INT

SET NOCOUNT ON


-- BUSCA DE TODAS AS AGENDAS

SELECT @QTD_AGENDAMENTOS = COUNT(1) 
FROM TB_AGENDAS_RENACHS (NOLOCK) 
WHERE DT_DIA >= CONVERT(VARCHAR(10), GETDATE() - 7, 112)


-- BUSCA DE TODAS AS PROVAS FINALIZADAS

SELECT @QTD_PROVAS_T_CORRIGIDAS = COUNT(1) 
FROM TB_PROVAS (NOLOCK)
WHERE DT_DIA >= CONVERT(VARCHAR(10), GETDATE() - 7, 112) AND DT_INICIO IS NOT NULL AND DT_FIM IS NOT NULL


-- BUSCA DE TODAS AS PROVAS AGUARDANDO CORREÇÃO

SELECT @QTD_PROVAS_T_AGUARDANDO_CORRECAO = COUNT(1) 
FROM TB_PROVAS (NOLOCK)
WHERE DT_DIA >= CONVERT(VARCHAR(10), GETDATE() - 7, 112)  AND DT_INICIO IS NULL AND DT_FIM IS NULL


-- BUSCA DE TODAS AS PROVAS TEÓRICAS FALTOSAS

SELECT @QTD_PROVAS_T_FALTOSAS = COUNT(1) 
FROM TB_HISTORICOS_PROVAS_EXCLUIDAS (NOLOCK)
WHERE DT_DIA >= CONVERT(VARCHAR(10), GETDATE() - 7, 112) 


-- BUSCA DE TODAS AS PRÁTICAS CORRIGIDAS

SELECT @QTD_PROVAS_P_CORRIGIDAS = COUNT(1) 
FROM TB_PROVAS_PRATICAS (NOLOCK)
WHERE DT_DIA >= CONVERT(VARCHAR(10), GETDATE() - 7, 112)  AND DT_CORRECAO IS NOT NULL


-- BUSCA DE TODAS AS PRÁTICAS AGUARDANDO CORREÇÃO

SELECT @QTD_PROVAS_P_AGUARDANDO_CORRECAO = COUNT(1) 
FROM TB_PROVAS_PRATICAS (NOLOCK)
WHERE DT_DIA >= CONVERT(VARCHAR(10), GETDATE() - 7, 112)  AND DT_CORRECAO IS NULL


-- BUSCA DE TODAS AS PRÁTICAS FALTOSAS

SELECT @QTD_PROVAS_P_FALTOSAS = COUNT(1)  
FROM TB_HISTORICOS_PROVAS_PRATICAS (NOLOCK)
WHERE DT_DIA >= CONVERT(VARCHAR(10), GETDATE() - 7, 112) 


-- BUSCA DE TODOS OS RETORNOS

SELECT DISTINCT @QTD_RETORNOS = COUNT(NuRenach)
FROM ArquivosRetornosE (NOLOCK)
WHERE DataAgenda >= CONVERT(VARCHAR(10), GETDATE() - 7, 112) 



SET NOCOUNT OFF

IF @TIPO = 0 -- SINTÉTICO
	BEGIN
		SELECT	 ISNULL(@QTD_AGENDAMENTOS, 0) AGENDAMENTOS		
				,ISNULL (@QTD_PROVAS_T_AGUARDANDO_CORRECAO, 0) + ISNULL(@QTD_PROVAS_P_AGUARDANDO_CORRECAO, 0) [PROVAS AGUARDANDO CORREÇÃO]
				,ISNULL (@QTD_PROVAS_T_CORRIGIDAS, 0) + ISNULL (@QTD_PROVAS_T_FALTOSAS, 0) + ISNULL (@QTD_PROVAS_P_CORRIGIDAS, 0) + ISNULL (@QTD_PROVAS_P_FALTOSAS, 0)	[PROVAS FINALIZADAS]	
				,ISNULL (@QTD_RETORNOS, 0) RETORNOS
	END
ELSE -- ANALÍTICO
	BEGIN 
		SELECT	 ISNULL (@QTD_AGENDAMENTOS, 0) [AGENDAMENTOS]
				,ISNULL (@QTD_PROVAS_T_CORRIGIDAS, 0) [PROVAS TEORICAS CORRIGIDAS]
				,ISNULL (@QTD_PROVAS_T_AGUARDANDO_CORRECAO, 0) [PROVAS TEORICAS AGUARDANDO CORRECAO]
				,ISNULL (@QTD_PROVAS_T_FALTOSAS, 0) [PROVAS TEORICAS FALTOSAS]
				,ISNULL (@QTD_PROVAS_P_CORRIGIDAS, 0) [PROVAS PRATICAS CORRIGIDAS]
				,ISNULL (@QTD_PROVAS_P_AGUARDANDO_CORRECAO, 0) [PROVAS PRATICAS AGUARDANDO CORRECAO]
				,ISNULL (@QTD_PROVAS_P_FALTOSAS, 0) [PROVAS PRATICAS FALTOSAS]
				,ISNULL (@QTD_RETORNOS, 0) [RETORNOS]
	END


END
GO
PRINT N'Creating [DBO].[SP_TRANSFERIR_PROVAS_SITE_SALA_OFFLINE_QG]...';


GO
CREATE PROCEDURE DBO.SP_TRANSFERIR_PROVAS_SITE_SALA_OFFLINE_QG(
																	 @DT_DIA		DATETIME
																	,@HR_PROVA		CHAR(5)
																	,@CD_SALA		INT
																	,@NU_RENACH		BIGINT
																	,@NU_CPF		BIGINT
																	,@DS_MOTIVO		VARCHAR
																	,@CD_USUARIO	BIGINT
																	,@DESCRICAO		VARCHAR(200)
																	,@OBSERVACAO	VARCHAR(200) = NULL
																	)
--WITH ENCRYPTION 
AS
BEGIN

	--VERIFICANDO SE A SALA INFORMADA É UMA SALA DIGITAL E OFF-LINE
	IF @CD_SALA NOT IN
	(
		803 -- IMPERATRIZ
		,727 --balsas
	)
	BEGIN
		RAISERROR('A SALA INFORMADA NÃO É RECONHECIDA COMO SALA DIGITAL OFFLINE', 16, 1)
		RETURN;
	END
	ELSE
	BEGIN
	
		--SE FOR DE IMPERATRIZ
		IF @CD_SALA = 803
		BEGIN
			EXEC IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.SP_JOB_BUSCAR_AGENDAMENTOS_SALA_OFFLINE_QG @DT_DIA	
																				,@HR_PROVA	
																				,@CD_SALA	
																				,@NU_RENACH	
																				,@NU_CPF	
																				,@DS_MOTIVO	
																				,@CD_USUARIO
																				,@DESCRICAO	
																				,@OBSERVACAO
																				
		END

		--SE FOR DE balsas
		IF @CD_SALA = 727
		BEGIN
			EXEC BALSAS.DB_MA_PROVA_DIGITAL.DBO.SP_JOB_BUSCAR_AGENDAMENTOS_SALA_OFFLINE_QG @DT_DIA	
																				,@HR_PROVA	
																				,@CD_SALA	
																				,@NU_RENACH	
																				,@NU_CPF	
																				,@DS_MOTIVO	
																				,@CD_USUARIO
																				,@DESCRICAO	
																				,@OBSERVACAO
																				
		END
	END
	
	
	

END
GO


PRINT N'Creating [dbo].[SpJobCadastrarCFC]...';


GO

create procedure SpJobCadastrarCFC
as
begin
	insert into imperatriz.db_ma_prova_digital.dbo.tb_cfc
	(
		CD_CNPJ
	,	CD_CATEGORIA_CFC
	,	CD_CFC
	,	NM_RAZAO
	,	CD_IE
	,	NM_CIDADE
	,	DS_ENDERECO
	,	NU_TELEFONE
	,	NU_FAX
	,	CD_CNPJ_PAI
	,	IC_ATIVO
	,	NU_CEP
	,	IC_MATRIZ
	)
	select 
		CD_CNPJ
	,	CD_CATEGORIA_CFC
	,	CD_CFC
	,	NM_RAZAO
	,	CD_IE
	,	NM_CIDADE
	,	DS_ENDERECO
	,	NU_TELEFONE
	,	NU_FAX
	,	CD_CNPJ_PAI
	,	IC_ATIVO
	,	NU_CEP
	,	IC_MATRIZ
	from tb_cfc a
	where not exists (select 1 from imperatriz.db_ma_prova_digital.dbo.tb_cfc b where a.cd_cnpj = b.cd_cnpj)
end
GO
PRINT N'Creating [dbo].[SpJobCadastrarCFC_BALSAS]...';


GO

create procedure SpJobCadastrarCFC_BALSAS
as
begin
	insert into BALSAS.db_ma_prova_digital.dbo.tb_cfc
	(
		CD_CNPJ
	,	CD_CATEGORIA_CFC
	,	CD_CFC
	,	NM_RAZAO
	,	CD_IE
	,	NM_CIDADE
	,	DS_ENDERECO
	,	NU_TELEFONE
	,	NU_FAX
	,	CD_CNPJ_PAI
	,	IC_ATIVO
	,	NU_CEP
	,	IC_MATRIZ
	)
	select 
		CD_CNPJ
	,	CD_CATEGORIA_CFC
	,	CD_CFC
	,	NM_RAZAO
	,	CD_IE
	,	NM_CIDADE
	,	DS_ENDERECO
	,	NU_TELEFONE
	,	NU_FAX
	,	CD_CNPJ_PAI
	,	IC_ATIVO
	,	NU_CEP
	,	IC_MATRIZ
	from tb_cfc a
	where not exists (select 1 from BALSAS.db_ma_prova_digital.dbo.tb_cfc b where a.cd_cnpj = b.cd_cnpj)
end
GO
PRINT N'Creating [dbo].[SpJobCadastrarCFC_SAOLUIS]...';


GO

create procedure SpJobCadastrarCFC_SAOLUIS
as
begin
	insert into SAOLUIZ.db_ma_prova_digital.dbo.tb_cfc
	(
		CD_CNPJ
	,	CD_CATEGORIA_CFC
	,	CD_CFC
	,	NM_RAZAO
	,	CD_IE
	,	NM_CIDADE
	,	DS_ENDERECO
	,	NU_TELEFONE
	,	NU_FAX
	,	CD_CNPJ_PAI
	,	IC_ATIVO
	,	NU_CEP
	,	IC_MATRIZ
	)
	select 
		CD_CNPJ
	,	CD_CATEGORIA_CFC
	,	CD_CFC
	,	NM_RAZAO
	,	CD_IE
	,	NM_CIDADE
	,	DS_ENDERECO
	,	NU_TELEFONE
	,	NU_FAX
	,	CD_CNPJ_PAI
	,	IC_ATIVO
	,	NU_CEP
	,	IC_MATRIZ
	from tb_cfc a
	where not exists (select 1 from SAOLUIZ.db_ma_prova_digital.dbo.tb_cfc b where a.cd_cnpj = b.cd_cnpj)
end
GO


PRINT N'Creating [dbo].[Usp_VerificaBiometriasTransferidasMa]...';


GO


CREATE procedure [dbo].[Usp_VerificaBiometriasTransferidasMa]	
as
BEGIN

declare @Contador INT
declare @RetornoLk int = null 
declare @data datetime  

declare @table table 
(
	NU_CPF BIGINT  
  , ID_DOCUMENTO BIGINT  
  , ID_TIPO_DOCUMENTO VARCHAR(20)  
  , DT_AQUISICAO DATETIME  
  ,	ID_SUBTIPO_BLOB BIGINT
)

	------------------------------------------------------------------------------------------------------------------------------------------------
	EXEC @RetornoLk = [checkLinkedServer]  SAOLUIZ
	
	IF @RetornoLk = 1
	BEGIN
		
		SET @data = convert(varchar,getdate(),112)
		SET @Contador = 1
		
		insert into @table
		select A.* from  SAOLUIZ.DB_SERVIDOR_BLOB_MA_P.dbo.VwBiometriaEnviada  AS A 
		INNER JOIN SAOLUIZ.DB_MA_PROVA_DIGITAL.dbo.VwProvaEnviada AS B ON A.NU_CPF = B.NU_CPF AND A.ID_DOCUMENTO = B.NU_RENACH
		WHERE  DT_DIA between @data  and DATEADD(DAY,5,@data) order by dt_dia, hr_prova
		
		WHILE @CONTADOR <= 5
		BEGIN
		insert into TB_MONITORAMENTO_BLOBS
			select  DISTINCT
				'MA'
			,	'SAO LUIS'
			,	@Data
			,  (select COUNT(1) from DB_MA_PROVA_DIGITAL..TB_AGENDAS_RENACHS  AS A (NOLOCK) WHERE A.DT_DIA = convert(varchar,@data,112) AND A.CD_SALA = 921  AND EXISTS (SELECT TOP 1 1 FROM DB_SERVIDOR_BLOB_MA_P..TB_AQUISICOES AS B (nolock)  WHERE A.NU_RENACH = B.id_documento AND A.NU_CPF = B.nu_cpf)) as BiometriasTotais  
			,  (select COUNT(1) from DB_MA_PROVA_DIGITAL..TB_AGENDAS_RENACHS  AS A (NOLOCK) WHERE A.DT_DIA = convert(varchar,@data,112) AND A.CD_SALA = 921  AND NOT EXISTS (SELECT TOP 1 1 FROM DB_SERVIDOR_BLOB_MA_P..TB_AQUISICOES_BLOBS AS B (nolock)  WHERE A.NU_RENACH =B.id_documento AND A.NU_CPF = B.nu_cpf AND B.ID_SUBTIPO_BLOB BETWEEN 6000 AND 6010)) as BiometriasNaoCapturadas  
			,  (select COUNT(1) from DB_MA_PROVA_DIGITAL..TB_AGENDAS_RENACHS  AS A (NOLOCK) WHERE A.DT_DIA = convert(varchar,@data,112) AND A.CD_SALA = 921  AND NOT EXISTS (SELECT TOP 1 1 FROM @table AS B   WHERE A.NU_RENACH = B.id_documento AND A.NU_CPF = B.nu_cpf AND B.ID_SUBTIPO_BLOB BETWEEN 6000 AND 6010)  AND EXISTS(SELECT TOP 1 1 FROM DB_SERVIDOR_BLOB_MA_P..TB_AQUISICOES AS B (nolock)  WHERE A.NU_RENACH = B.id_documento AND A.NU_CPF = B.nu_cpf)) as BiometriasNaoTransferidas  
			,	GETDATE()
			,	''
			from 
				DB_MA_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS AS A with (nolock)
			where 
				CD_SALA = 921
			--and  DT_DIA between @data  and DATEADD(DAY,5,@data)
			
			SET @DATA = @DATA + 1 
			SET @CONTADOR = @Contador + 1
		END	
			
	END
	
	ELSE
	BEGIN
					insert into TB_MONITORAMENTO_BLOBS
					(
						Site
					,	SalaOffline
					,	DataAgendamento
					,	BiometriasTotais
					,	BiometriasNaoCapturadas
					,	BiometriasNaoTransferidas
					,	Data
					,	Observacao
					)
					values
					(
						'MA'
					,	'SAO LUIS'
					,	DATEADD(DAY,1,@data)
					,  (select COUNT(1) from DB_MA_PROVA_DIGITAL..TB_AGENDAS_RENACHS  AS A (NOLOCK) WHERE A.DT_DIA = convert(varchar,@data,112) AND A.CD_SALA = 921  AND EXISTS (SELECT TOP 1 1 FROM DB_SERVIDOR_BLOB_MA_P..TB_AQUISICOES AS B (nolock)  WHERE A.NU_RENACH = B.id_documento AND A.NU_CPF = B.nu_cpf)) 
					,  (select COUNT(1) from DB_MA_PROVA_DIGITAL..TB_AGENDAS_RENACHS  AS A (NOLOCK) WHERE A.DT_DIA = convert(varchar,@data,112) AND A.CD_SALA = 921  AND NOT EXISTS (SELECT TOP 1 1 FROM DB_SERVIDOR_BLOB_MA_P..TB_AQUISICOES_BLOBS AS B (nolock)  WHERE A.NU_RENACH =B.id_documento AND A.NU_CPF = B.nu_cpf AND B.ID_SUBTIPO_BLOB BETWEEN 6000 AND 6010))
					,	NULL
					,	GETDATE()
					,	'Sem link de Comunicação com SAO LUIS!'
					)
	END
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	EXEC @RetornoLk = [checkLinkedServer]  BALSAS
	
	IF @RetornoLk = 1
	BEGIN
		
		SET @data = convert(varchar,getdate(),112)
		SET @Contador = 1
		
		insert into @table
		select A.* from  BALSAS.DB_SERVIDOR_BLOB_MA_P.dbo.VwBiometriaEnviada  AS A 
		INNER JOIN BALSAS.DB_MA_PROVA_DIGITAL.dbo.VwProvaEnviada AS B ON A.NU_CPF = B.NU_CPF AND A.ID_DOCUMENTO = B.NU_RENACH
		WHERE  DT_DIA between @data  and DATEADD(DAY,5,@data) order by dt_dia, hr_prova
		
		WHILE @CONTADOR <= 5
		BEGIN
		insert into TB_MONITORAMENTO_BLOBS
			select  DISTINCT
				'MA'
			,	'BALSAS'
			,	@Data
			,  (select COUNT(1) from DB_MA_PROVA_DIGITAL..TB_AGENDAS_RENACHS  AS A (NOLOCK) WHERE A.DT_DIA = convert(varchar,@data,112) AND A.CD_SALA = 727  AND EXISTS (SELECT TOP 1 1 FROM DB_SERVIDOR_BLOB_MA_P..TB_AQUISICOES AS B (nolock)  WHERE A.NU_RENACH = B.id_documento AND A.NU_CPF = B.nu_cpf)) as BiometriasTotais  
			,  (select COUNT(1) from DB_MA_PROVA_DIGITAL..TB_AGENDAS_RENACHS  AS A (NOLOCK) WHERE A.DT_DIA = convert(varchar,@data,112) AND A.CD_SALA = 727  AND NOT EXISTS (SELECT TOP 1 1 FROM DB_SERVIDOR_BLOB_MA_P..TB_AQUISICOES_BLOBS AS B (nolock)  WHERE A.NU_RENACH =B.id_documento AND A.NU_CPF = B.nu_cpf AND B.ID_SUBTIPO_BLOB BETWEEN 6000 AND 6010)) as BiometriasNaoCapturadas  
			,  (select COUNT(1) from DB_MA_PROVA_DIGITAL..TB_AGENDAS_RENACHS  AS A (NOLOCK) WHERE A.DT_DIA = convert(varchar,@data,112) AND A.CD_SALA = 727  AND NOT EXISTS (SELECT TOP 1 1 FROM @table AS B   WHERE A.NU_RENACH = B.id_documento AND A.NU_CPF = B.nu_cpf AND B.ID_SUBTIPO_BLOB BETWEEN 6000 AND 6010)  AND EXISTS(SELECT TOP 1 1 FROM DB_SERVIDOR_BLOB_MA_P..TB_AQUISICOES AS B (nolock)  WHERE A.NU_RENACH = B.id_documento AND A.NU_CPF = B.nu_cpf)) as BiometriasNaoTransferidas  
			,	GETDATE()
			,	''
			from 
				DB_MA_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS AS A with (nolock)
			where 
				CD_SALA = 727
			--and  DT_DIA between @data  and DATEADD(DAY,5,@data)
			
			SET @DATA = @DATA + 1 
			SET @CONTADOR = @Contador + 1
		END	
			
	END
	
	ELSE
	BEGIN
					insert into TB_MONITORAMENTO_BLOBS
					(
						Site
					,	SalaOffline
					,	DataAgendamento
					,	BiometriasTotais
					,	BiometriasNaoCapturadas
					,	BiometriasNaoTransferidas
					,	Data
					,	Observacao
					)
					values
					(
						'MA'
					,	'BALSAS'
					,	DATEADD(DAY,1,@data)
					,  (select COUNT(1) from DB_MA_PROVA_DIGITAL..TB_AGENDAS_RENACHS  AS A (NOLOCK) WHERE A.DT_DIA = convert(varchar,@data,112) AND A.CD_SALA = 727  AND EXISTS (SELECT TOP 1 1 FROM DB_SERVIDOR_BLOB_MA_P..TB_AQUISICOES AS B (nolock)  WHERE A.NU_RENACH = B.id_documento AND A.NU_CPF = B.nu_cpf)) 
					,  (select COUNT(1) from DB_MA_PROVA_DIGITAL..TB_AGENDAS_RENACHS  AS A (NOLOCK) WHERE A.DT_DIA = convert(varchar,@data,112) AND A.CD_SALA = 727  AND NOT EXISTS (SELECT TOP 1 1 FROM DB_SERVIDOR_BLOB_MA_P..TB_AQUISICOES_BLOBS AS B (nolock)  WHERE A.NU_RENACH =B.id_documento AND A.NU_CPF = B.nu_cpf AND B.ID_SUBTIPO_BLOB BETWEEN 6000 AND 6010)) 
					,	NULL
					,	GETDATE()
					,	'Sem link de Comunicação com BALSAS!'
					)
	END
	
	EXEC @RetornoLk = [checkLinkedServer]  IMPERATRIZ
	
	IF @RetornoLk = 1
	BEGIN
		
		SET @data = convert(varchar,getdate(),112)
		SET @Contador = 1
		
		insert into @table
		select A.* from  IMPERATRIZ.DB_SERVIDOR_BLOB_MA_P.dbo.VwBiometriaEnviada  AS A 
		INNER JOIN IMPERATRIZ.DB_MA_PROVA_DIGITAL.dbo.VwProvaEnviada AS B ON A.NU_CPF = B.NU_CPF AND A.ID_DOCUMENTO = B.NU_RENACH
		WHERE  DT_DIA between @data  and DATEADD(DAY,5,@data) order by dt_dia, hr_prova
		
		WHILE @CONTADOR <= 5
		BEGIN
		insert into TB_MONITORAMENTO_BLOBS
			select  DISTINCT
				'MA'
			,	'IMPERATRIZ'
			,	@Data
			,  (select COUNT(1) from DB_MA_PROVA_DIGITAL..TB_AGENDAS_RENACHS  AS A (NOLOCK) WHERE A.DT_DIA = convert(varchar,@data,112) AND A.CD_SALA = 803  AND EXISTS (SELECT TOP 1 1 FROM DB_SERVIDOR_BLOB_MA_P..TB_AQUISICOES AS B (nolock)  WHERE A.NU_RENACH = B.id_documento AND A.NU_CPF = B.nu_cpf)) as BiometriasTotais  
			,  (select COUNT(1) from DB_MA_PROVA_DIGITAL..TB_AGENDAS_RENACHS  AS A (NOLOCK) WHERE A.DT_DIA = convert(varchar,@data,112) AND A.CD_SALA = 803  AND NOT EXISTS (SELECT TOP 1 1 FROM DB_SERVIDOR_BLOB_MA_P..TB_AQUISICOES_BLOBS AS B (nolock)  WHERE A.NU_RENACH =B.id_documento AND A.NU_CPF = B.nu_cpf AND B.ID_SUBTIPO_BLOB BETWEEN 6000 AND 6010)) as BiometriasNaoCapturadas  
			,  (select COUNT(1) from DB_MA_PROVA_DIGITAL..TB_AGENDAS_RENACHS  AS A (NOLOCK) WHERE A.DT_DIA = convert(varchar,@data,112) AND A.CD_SALA = 803  AND NOT EXISTS (SELECT TOP 1 1 FROM @table AS B   WHERE A.NU_RENACH = B.id_documento AND A.NU_CPF = B.nu_cpf AND B.ID_SUBTIPO_BLOB BETWEEN 6000 AND 6010)  AND EXISTS(SELECT TOP 1 1 FROM DB_SERVIDOR_BLOB_MA_P..TB_AQUISICOES AS B (nolock)  WHERE A.NU_RENACH = B.id_documento AND A.NU_CPF = B.nu_cpf)) as BiometriasNaoTransferidas  
			,	GETDATE()
			,	''
			from 
				DB_MA_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS AS A with (nolock)
			where 
				CD_SALA = 803
			--and  DT_DIA between @data  and DATEADD(DAY,5,@data)
			
			SET @DATA = @DATA + 1 
			SET @CONTADOR = @Contador + 1
		END	
			
	END
	
	ELSE
	BEGIN
					insert into TB_MONITORAMENTO_BLOBS
					(
						Site
					,	SalaOffline
					,	DataAgendamento
					,	BiometriasTotais
					,	BiometriasNaoCapturadas
					,	BiometriasNaoTransferidas
					,	Data
					,	Observacao
					)
					values
					(
						'MA'
					,	'IMPERATRIZ'
					,	DATEADD(DAY,1,@data)
					,  (select COUNT(1) from DB_MA_PROVA_DIGITAL..TB_AGENDAS_RENACHS  AS A (NOLOCK) WHERE A.DT_DIA = convert(varchar,@data,112) AND A.CD_SALA = 803  AND EXISTS (SELECT TOP 1 1 FROM DB_SERVIDOR_BLOB_MA_P..TB_AQUISICOES AS B (nolock)  WHERE A.NU_RENACH = B.id_documento AND A.NU_CPF = B.nu_cpf))
					,  (select COUNT(1) from DB_MA_PROVA_DIGITAL..TB_AGENDAS_RENACHS  AS A (NOLOCK) WHERE A.DT_DIA = convert(varchar,@data,112) AND A.CD_SALA = 803  AND NOT EXISTS (SELECT TOP 1 1 FROM DB_SERVIDOR_BLOB_MA_P..TB_AQUISICOES_BLOBS AS B (nolock)  WHERE A.NU_RENACH =B.id_documento AND A.NU_CPF = B.nu_cpf AND B.ID_SUBTIPO_BLOB BETWEEN 6000 AND 6010)) 
					,	NULL
					,	GETDATE()
					,	'Sem link de Comunicação com IMPERATRIZ!'
					)
	END

	
END
GO


PRINT N'Creating [dbo].[Usp_VerificaProvasTransferidasMa]...';


GO
        
CREATE procedure [dbo].[Usp_VerificaProvasTransferidasMa]         
as        
BEGIN        
        
declare @Contador int    
declare @data datetime    
declare @RetornoLk int = null         
    
declare @table table         
(        
 CD_PROVA bigint        
, NU_RENACH bigint        
, NU_CPF bigint        
, DT_INICIO datetime        
, DT_FIM  datetime        
, DT_DIA  datetime        
, HR_PROVA varchar(5)        
, CD_SALA   int        
)        
        
 ------------------------------------------------------------------------------------------------------------------------------------------------        
 EXEC @RetornoLk = [checkLinkedServer]  SAOLUIZ        
         
 IF @RetornoLk = 1        
 BEGIN        
  SET @Contador = 1        
  SET @data =  convert(varchar,getdate(),112)      
      
  insert into @table        
  select * from  SAOLUIZ.db_ma_prova_digital.dbo.VwProvaEnviada where DT_DIA between @data  and DATEADD(DAY,5,@data) order by dt_dia, hr_prova        
          
  WHILE @CONTADOR <= 7      
  BEGIN        
  insert into TB_MONITORAMENTO        
   select  DISTINCT        
    'MA'        
   , 'SAO LUIS'        
   , @Data        
   , (select count(1) from DB_MA_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  921)  as [Total Agendas]        
   , (select count(1) from DB_MA_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  921)          
   +         
    (SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a         
    inner join DB_MA_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B        
    ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  921)  as [Total Provas]        
   , (SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.dbo.TB_PROVAS AS A (NOLOCK)  WHERE NOT EXISTS (SELECT  top 1 1         
                          from @table as B        
                          where         
                           A.DT_DIA = B.DT_DIA        
                          and A.HR_PROVA = B.HR_PROVA        
                          and A.CD_SALA = B.CD_SALA        
                          and A.NU_RENACH = B.NU_RENACH        
                          and A.NU_CPF = B.NU_CPF)        
                      AND  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  921)        
   , getdate()        
   , ''        
   from         
    DB_MA_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS AS A with (nolock)        
   where         
    CD_SALA = 921        
  -- and  DT_DIA between @data  and DATEADD(DAY,5,@data)        
           
   SET @DATA = @DATA + 1         
   SET @CONTADOR = @Contador + 1          
  END         
           
 END        
         
 ELSE        
 BEGIN        
     insert into TB_MONITORAMENTO        
     (        
      [Site]        
     , SalaOffline        
     , DataAgendamento        
     ,  AgendasTotais        
     , ProvasTotais          
     , ProvasPendentes         
     , DataVerificacao           
     , Observacao        
     )        
     values        
     (        
      'MA'        
     , 'SAO LUIS'        
     , DATEADD(DAY,1,@data)        
     , (select count(1) from DB_MA_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  921)         
     , (select count(1) from DB_MA_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  921)          
     +         
      (SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a inner join DB_MA_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B        
      ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  921)         
     , NULL        
     , GETDATE()        
     , 'Sem link de Comunicação com SAO LUIS!'        
     )        
 END        
 -------------------------------------------------------------------------------------------------------------------------------------------------------------------        
        
         
 ------------------------------------------------------------------------------------------------------------------------------------------------        
 EXEC @RetornoLk = [checkLinkedServer] BALSAS        
         
 IF @RetornoLk = 1        
 BEGIN        
  SET @Contador = 1        
  SET @data =  convert(varchar,getdate(),112)        
          
  delete @table        
  insert into @table        
  select * from  BALSAS.db_ma_prova_digital.dbo.VwProvaEnviada where DT_DIA between @data  and DATEADD(DAY,5,@data) order by dt_dia, hr_prova        
          
  WHILE @CONTADOR <= 7      
  BEGIN        
  insert into TB_MONITORAMENTO        
   select  DISTINCT        
    'MA'        
   , 'BALSAS'        
   , @Data        
   , (select count(1) from DB_MA_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  727)  as [Total Agendas]        
   , (select count(1) from DB_MA_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  727)          
   +         
    (SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a         
    inner join DB_MA_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B        
    ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  727)  as [Total Provas]        
   , (SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.dbo.TB_PROVAS AS A (NOLOCK)  WHERE NOT EXISTS (SELECT  top 1 1         
                          from @table as B        
                          where         
                           A.DT_DIA = B.DT_DIA        
                          and A.HR_PROVA = B.HR_PROVA        
                          and A.CD_SALA = B.CD_SALA        
                          and A.NU_RENACH = B.NU_RENACH        
                          and A.NU_CPF = B.NU_CPF)        
                      AND  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  727)        
   , getdate()        
   , ''        
   from         
    DB_MA_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS AS A with (nolock)        
   where         
    CD_SALA = 727        
   --and  DT_DIA between @data  and DATEADD(DAY,5,@data)        
           
   SET @DATA = @DATA + 1         
   SET @CONTADOR = @Contador + 1        
  END         
           
 END        
         
 ELSE        
     insert into TB_MONITORAMENTO        
     (        
      [Site]        
     , SalaOffline        
     , DataAgendamento        
     ,   AgendasTotais        
     , ProvasTotais          
     , ProvasPendentes         
     , DataVerificacao           
     , Observacao        
     )        
     values        
     (        
      'MA'        
     , 'BALSAS'        
     , DATEADD(DAY,1,@data)        
     , (select count(1) from DB_MA_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  727)         
     , (select count(1) from DB_MA_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  727)          
     +         
      (SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a inner join DB_MA_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B        
      ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  727)         
     , NULL        
     , GETDATE()        
     , 'Sem link de Comunicação com BALSAS!'        
     )        
 -------------------------------------------------------------------------------------------------------------------------------------------------------------------        
        
 ------------------------------------------------------------------------------------------------------------------------------------------------        
 EXEC @RetornoLk = [checkLinkedServer] IMPERATRIZ        
         
 IF @RetornoLk = 1        
 BEGIN        
  SET @Contador = 1        
  SET @data =  convert(varchar,getdate(),112)        
      
  delete @table        
  insert into @table        
  select * from  IMPERATRIZ.db_ma_prova_digital.dbo.VwProvaEnviada where DT_DIA between @data  and DATEADD(DAY,5,@data) order by dt_dia, hr_prova        
          
  WHILE @CONTADOR <= 7      
  BEGIN        
  insert into TB_MONITORAMENTO        
   select  DISTINCT        
    'MA'        
   , 'IMPERATRIZ'        
   , @Data        
   , (select count(1) from DB_MA_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  803)  as [Total Agendas]        
   , (select count(1) from DB_MA_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  803)          
   +         
    (SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a         
    inner join DB_MA_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B        
    ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  803)  as [Total Provas]        
   , (SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.dbo.TB_PROVAS AS A (NOLOCK)  WHERE NOT EXISTS (SELECT  top 1 1         
                          from @table as B        
                          where         
                           A.DT_DIA = B.DT_DIA        
                          and A.HR_PROVA = B.HR_PROVA        
                          and A.CD_SALA = B.CD_SALA        
                          and A.NU_RENACH = B.NU_RENACH        
                          and A.NU_CPF = B.NU_CPF)        
                      AND  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  803)        
   , getdate()        
   , ''        
   from         
    DB_MA_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS AS A with (nolock)        
   where         
    CD_SALA = 803        
   --and  DT_DIA between @data  and DATEADD(DAY,5,@data)        
           
   SET @DATA = @DATA + 1         
   SET @CONTADOR = @Contador + 1        
  END         
           
 END        
         
 ELSE        
     insert into TB_MONITORAMENTO        
     (        
      [Site]        
     , SalaOffline        
     , DataAgendamento        
     ,   AgendasTotais        
     , ProvasTotais          
     , ProvasPendentes         
     , DataVerificacao           
     , Observacao        
     )        
     values        
     (        
      'MA'        
     , 'IMPERATRIZ'        
     , DATEADD(DAY,1,@data)        
     , (select count(1) from DB_MA_PROVA_DIGITAL.dbo.TB_AGENDAS_RENACHS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  803)         
     , (select count(1) from DB_MA_PROVA_DIGITAL.dbo.TB_PROVAS(nolock) where  DT_DIA = convert(varchar,@Data ,112) and CD_SALA =  803)          
     +         
      (SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.dbo.TB_HISTORICOS_PROVAS_EXCLUIDAS as a inner join DB_MA_PROVA_DIGITAL.DBO.TB_AGENDAS_RENACHS AS B        
      ON A.DT_DIA = B.DT_DIA AND A.NU_RENACH = B.NU_RENACH AND A.NU_CPF = B.NU_CPF AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA WHERE a.DT_DIA = convert(varchar,@Data ,112) and a.CD_SALA =  803)     
     , NULL        
     , GETDATE()        
     , 'Sem link de Comunicação com IMPERATRIZ!'        
     )        
         
        
        
         
END
GO


PRINT N'Creating [dbo].[Usp_VerificaResultadosPendentesEnvioProvaDigitalMa]...';


GO
create procedure [dbo].[Usp_VerificaResultadosPendentesEnvioProvaDigitalMa] 
(
	@Data  date = null
)	
as


/*
	Douglas S. Porto
	03/03/2015
	Verificar as quantidades Provas que ainda não tiveram os resultados transferidos	(seja ele faltoso ou realizado)
	os resultados pendentes são baseados nas transferencias que estão sendo logadas na tabela TB_AGENDAS_RENACHS_LOG, a verificaçaõ é baseadas nas provas de até uma antes da hora atual
*/ 


begin
	if @Data is null
		begin
			select @Data = GETDATE()
		end
	
	declare 	
		@RetornoLk bit = null

	
	declare @TableProvas table
	(
		[Site]						varchar(20)  null
	,	[SalaOffline]				varchar(20)	 null	
	,	[DataAgendamento]			varchar(30)	 null
	,	[TotalProvasAgendadas]		int
	,	[TotalProvasRealizadas]		int
	,	[TotalProvasFaltosos]		int
	,	[TotalResultadosPendentes]	int	null
	,	[Observacao]				varchar(100) null
	)

	--(Inicio) -- Provas Totais e Provas Pendentes de envio de resultado ao Site...
	
	--Insere quantidades de resultados pendentes Balsas...
	BEGIN TRY
	exec @RetornoLk = checkLinkedServer  'BALSAS'
		if @RetornoLk  = 1  
			begin 
				insert into	@TableProvas
				(	
					[Site]						
				,	[SalaOffline]				
				,	[DataAgendamento]			
				,	[TotalProvasAgendadas]				
				,	[TotalProvasRealizadas]		
				,	[TotalProvasFaltosos]
				,	[TotalResultadosPendentes]	
				,	[Observacao]				
				)
				select   
					'MA'as [Site]
				,	'BALSAS' as SalaOffline		
				,	convert(varchar,@Data,103)
				,	(SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS (nolock) WHERE DT_DIA = convert(varchar,@Data,112) AND CD_SALA = 727)  AS [TotalProvasAgendadas]
				,	(SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS (nolock)  WHERE DT_DIA = convert(varchar,@Data,112) AND CD_SALA = 727  AND DT_FIM IS NOT NULL)  AS [ProvasRealizadas]				
				,	COUNT(Z.CD_PROVA)
				,	count(1)				
				,	''
				from  
					BALSAS.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS as A  (nolock)
				LEFT JOIN TB_HISTORICOS_PROVAS_EXCLUIDAS AS Z
					ON A.CD_PROVA = Z.CD_PROVA
				where  
					 A.CD_SALA = 727
				and	 A.DT_DIA = convert(varchar,@Data,112)
				and	 A.DT_FIM IS NOT NULL	
				and	not exists  
				(  
					select top 1 1
					from TB_AGENDAS_RENACHS_LOG as  B   (nolock)
					where 
						A.DT_DIA = B.DT_DIA 
					and A.HR_PROVA = B.HR_PROVA 
					and A.CD_SALA = B.CD_SALA 
					and A.NU_RENACH = B.NU_RENACH 
					and A.NU_CPF = B.NU_CPF  
				)  
			end;
		else
			begin
				insert into	@TableProvas
				(	
					[Site]						
				,	[SalaOffline]				
				,	[DataAgendamento]			
				,	[TotalProvasAgendadas]				
				,	[TotalProvasRealizadas]		
				,	[TotalProvasFaltosos]
				,	[TotalResultadosPendentes]	
				,	[Observacao]				
				)
				values
				(
					'MA'
				,	'BALSAS' 
				,	convert(varchar,@Data,103)
				,	(SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS (nolock) WHERE DT_DIA = convert(varchar,@Data,112) AND CD_SALA = 727)  
				,	(SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS (nolock)  WHERE DT_DIA = convert(varchar,@Data,112) AND CD_SALA = 727  AND DT_FIM IS NOT NULL)  
				,	null
				,	null
				,	'Link Indisponivel'
				)			
			end;
		END TRY
		BEGIN CATCH
			begin
				insert into	@TableProvas
				(	
					[Site]						
				,	[SalaOffline]				
				,	[DataAgendamento]			
				,	[TotalProvasAgendadas]				
				,	[TotalProvasRealizadas]		
				,	[TotalProvasFaltosos]
				,	[TotalResultadosPendentes]	
				,	[Observacao]				
				)
				values
				(
					'MA'
				,	'BALSAS' 
				,	convert(varchar,@Data,103)
				,	(SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS (nolock) WHERE DT_DIA = convert(varchar,@Data,112) AND CD_SALA = 727)  
				,	(SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS (nolock)  WHERE DT_DIA = convert(varchar,@Data,112) AND CD_SALA = 727  AND DT_FIM IS NOT NULL)  
				,	null
				,	null
				,	'Link Indisponivel'
				)						
			end;		
		END CATCH
			

	--Insere quantidades de resultados pendentes Imperatriz...
	
		BEGIN TRY
		exec @RetornoLk = checkLinkedServer  'IMPERATRIZ'
		if @RetornoLk  = 1  
			begin 
				insert into	@TableProvas
				(	
					[Site]						
				,	[SalaOffline]				
				,	[DataAgendamento]			
				,	[TotalProvasAgendadas]				
				,	[TotalProvasRealizadas]		
				,	[TotalProvasFaltosos]
				,	[TotalResultadosPendentes]	
				,	[Observacao]				
				)
				select   
					'MA'as [Site]
				,	'IMPERATRIZ' as SalaOffline		
				,	convert(varchar,@Data,103)
				,	(SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS (nolock) WHERE DT_DIA = convert(varchar,@Data,112) AND CD_SALA = 803)  AS [TotalProvasAgendadas]
				,	(SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS (nolock)  WHERE DT_DIA = convert(varchar,@Data,112) AND CD_SALA = 803  AND DT_FIM IS NOT NULL)  AS [ProvasRealizadas]				
				,	COUNT(Z.CD_PROVA)
				,	count(1)				
				,	''
				from  
					IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS as A  (nolock)
				LEFT JOIN TB_HISTORICOS_PROVAS_EXCLUIDAS AS Z
					ON A.CD_PROVA = Z.CD_PROVA
				where  
					 A.CD_SALA = 803
				and	 A.DT_DIA = convert(varchar,@Data,112)
				and	 A.DT_FIM IS NOT NULL	
				and	not exists  
				(  
					select top 1 1
					from TB_AGENDAS_RENACHS_LOG as  B   (nolock)
					where 
						A.DT_DIA = B.DT_DIA 
					and A.HR_PROVA = B.HR_PROVA 
					and A.CD_SALA = B.CD_SALA 
					and A.NU_RENACH = B.NU_RENACH 
					and A.NU_CPF = B.NU_CPF  
				)  
			end;
		else
			begin
				insert into	@TableProvas
				(	
					[Site]						
				,	[SalaOffline]				
				,	[DataAgendamento]			
				,	[TotalProvasAgendadas]				
				,	[TotalProvasRealizadas]		
				,	[TotalProvasFaltosos]
				,	[TotalResultadosPendentes]	
				,	[Observacao]				
				)
				values
				(
					'MA'
				,	'IMPERATRIZ' 
				,	convert(varchar,@Data,103)
				,	(SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS (nolock) WHERE DT_DIA = convert(varchar,@Data,112) AND CD_SALA = 803)  
				,	(SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS (nolock)  WHERE DT_DIA = convert(varchar,@Data,112) AND CD_SALA = 803 AND DT_FIM IS NOT NULL)  
				,	null
				,	null
				,	'Link Indisponivel'
				)		
			end;	
		END TRY
		
		BEGIN CATCH	
			begin
				insert into	@TableProvas
				(	
					[Site]						
				,	[SalaOffline]				
				,	[DataAgendamento]			
				,	[TotalProvasAgendadas]				
				,	[TotalProvasRealizadas]		
				,	[TotalProvasFaltosos]
				,	[TotalResultadosPendentes]	
				,	[Observacao]				
				)
				values
				(
					'MA'
				,	'IMPERATRIZ' 
				,	convert(varchar,@Data,103)
				,	(SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS (nolock) WHERE DT_DIA = convert(varchar,@Data,112) AND CD_SALA = 803)  
				,	(SELECT COUNT(1) FROM DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS (nolock)  WHERE DT_DIA = convert(varchar,@Data,112) AND CD_SALA = 803 AND DT_FIM IS NOT NULL)  
				,	null
				,	null
				,	'Link Indisponivel'
				)	
			end;	
		END CATCH					   

	select * from @TableProvas order by 2;
end
GO


PRINT N'Creating [DBO].[RN_CANCELAR_AGENDA_RENACH_SALA_OFFLINE]...';


GO
CREATE PROCEDURE DBO.RN_CANCELAR_AGENDA_RENACH_SALA_OFFLINE(
				@DT_DIA			DATETIME
				,@HR_PROVA		CHAR(5)
				,@CD_SALA		INT
				,@NU_RENACH		BIGINT
				,@NU_CPF		BIGINT
				,@DS_MOTIVO		VARCHAR
				,@CD_USUARIO	BIGINT
				,@DESCRICAO		VARCHAR(200)
				,@OBSERVACAO	VARCHAR(200) = null
)  as
begin
	declare @CD_PROVA bigint
	declare @erro int
	set @erro = 0
	

	if not exists(
		select 1 
		from dbo.TB_AGENDAS_RENACHS (nolock)
		where DT_DIA = @DT_DIA
		and HR_PROVA = @HR_PROVA 
		and NU_CPF = @NU_CPF 
		and NU_RENACH = @NU_RENACH 
		and CD_SALA = @CD_SALA 
	)
	begin
		raiserror('Não há agendamento a ser cancelado.', 16, 1)
		return
	end

	--carrega a respectiva prova na vaiável
	select @CD_PROVA  = cd_prova
	from TB_PROVAS (nolock)
	where DT_DIA = @DT_DIA
	and HR_PROVA = @HR_PROVA 
	and NU_CPF = @NU_CPF 
	and NU_RENACH = @NU_RENACH 
	and CD_SALA = @CD_SALA 
		
	BEGIN TRAN A

	-- SE EXISTIR PROVA, e ela ainda não tiver sido cancelada, ELA É CANCELADA
	IF (@CD_PROVA IS NOT NULL)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM DB_MA_PROVA_DIGITAL_AUXILIAR.DBO.TB_PROVAS (NOLOCK) 
						WHERE DT_DIA = @DT_DIA
						AND HR_PROVA = @HR_PROVA 
						AND NU_CPF = @NU_CPF 
						AND NU_RENACH = @NU_RENACH 
						AND CD_SALA = @CD_SALA
						) 
		BEGIN
			--CANCELANDO A PROVA DO CANDIDATO
			INSERT INTO DB_MA_PROVA_DIGITAL_AUXILIAR.DBO.TB_PROVAS(CD_PROVA,CD_CONFIGURACAO_PROVA,NU_RENACH,NU_CPF,DT_INICIO,DT_FIM,CD_IDENTIFICADOR_COMPUTADOR,CD_USUARIO,DT_DIA,HR_PROVA,CD_SALA,CD_EXAMINADOR,CD_EXAMINADOR_SEARCH_01,CD_EXAMINADOR_SEARCH_02)
			SELECT CD_PROVA,CD_CONFIGURACAO_PROVA,NU_RENACH,NU_CPF,DT_INICIO,DT_FIM,CD_IDENTIFICADOR_COMPUTADOR,CD_USUARIO,DT_DIA,HR_PROVA,CD_SALA,CD_EXAMINADOR,CD_EXAMINADOR_SEARCH_01,CD_EXAMINADOR_SEARCH_02
			FROM TB_PROVAS (NOLOCK) 
						WHERE DT_DIA = @DT_DIA
						AND HR_PROVA = @HR_PROVA 
						AND NU_CPF = @NU_CPF 
						AND NU_RENACH = @NU_RENACH 
						AND CD_SALA = @CD_SALA
			set @erro = @erro + @@error
					
			DELETE FROM TB_PROVAS
						WHERE DT_DIA = @DT_DIA
						AND HR_PROVA = @HR_PROVA 
						AND NU_CPF = @NU_CPF 
						AND NU_RENACH = @NU_RENACH 
						AND CD_SALA = @CD_SALA
			set @erro = @erro + @@error
		END
	END
			
	--move a agenda para histórico
	insert into DB_MA_PROVA_DIGITAL_AUXILIAR.DBO.TB_AGENDAS_RENACHS (DT_DIA,HR_PROVA,CD_SALA,NU_RENACH,NU_CPF,CD_CNPJ,CD_CONFIGURACAO_PROVA,CD_ESTADO_AGENDA_RENACH,DT_ESTADO_AGENDA_RENACH,CD_USUARIO,CD_TIPO_PRODAM,CD_CATEGORIA)
		select DT_DIA,HR_PROVA,CD_SALA,NU_RENACH,NU_CPF,CD_CNPJ,CD_CONFIGURACAO_PROVA,CD_ESTADO_AGENDA_RENACH,DT_ESTADO_AGENDA_RENACH,CD_USUARIO,CD_TIPO_PRODAM,CD_CATEGORIA
		from  TB_AGENDAS_RENACHS (nolock)
		where DT_DIA = @DT_DIA
			and HR_PROVA = @HR_PROVA 
			and NU_CPF = @NU_CPF 
			and NU_RENACH = @NU_RENACH 
			and CD_SALA = @CD_SALA
	set @erro = @erro + @@error
			
	--exclui a agenda
	delete from TB_AGENDAS_RENACHS 
	where DT_DIA = @DT_DIA
		and HR_PROVA = @HR_PROVA 
		and NU_CPF = @NU_CPF 
		and NU_RENACH = @NU_RENACH 
		and CD_SALA = @CD_SALA
	set @erro = @erro + @@error

		--loga a ação na tabela de Logs
		exec dbo.SP_LOGAR_ACOES_QGS 1, @DESCRICAO , @OBSERVACAO, @CD_USUARIO ,@DT_DIA,@HR_PROVA,@CD_SALA,@NU_RENACH,@NU_CPF
	set @erro = @erro + @@error


	if @erro <> 0 
	begin
		rollback tran a
		raiserror('Erro ao tentar cancelar agendamento', 16, 1)
		return;
	end 
	else 
	begin
		commit tran a
	end
end
GO
PRINT N'Creating [DBO].[RN_CANCELAR_AGENDA_RENACH_SITE_QG]...';


GO
CREATE PROCEDURE DBO.RN_CANCELAR_AGENDA_RENACH_SITE_QG(
				@DT_DIA			DATETIME
				,@HR_PROVA		CHAR(5)
				,@CD_SALA		INT
				,@NU_RENACH		BIGINT
				,@NU_CPF		BIGINT
				,@DS_MOTIVO		VARCHAR
				,@CD_USUARIO	BIGINT
				,@DESCRICAO		VARCHAR(200)
				,@OBSERVACAO	VARCHAR(200) = NULL
				,@FL_SURDEZ		bit = 0
)  
AS
BEGIN
	DECLARE @CD_PROVA BIGINT
	DECLARE @ERRO VARCHAR(MAX)
	
	IF NOT EXISTS(
		SELECT 1 
		FROM DBO.TB_AGENDAS_RENACHS (NOLOCK)
		WHERE DT_DIA = @DT_DIA
		AND HR_PROVA = @HR_PROVA 
		AND NU_CPF = @NU_CPF 
		AND NU_RENACH = @NU_RENACH 
		AND CD_SALA = @CD_SALA 
	)
	BEGIN
		RAISERROR('NÃO HÁ AGENDAMENTO NO SITE PARA SER CANCELADO.', 16, 1)
		RETURN;
	END

	------------------------------------------	
	--CANCELANDO AGENDAMENTO NA SALA OFFLINE--
	------------------------------------------
	--IF @CD_SALA IN (803) -- SE É SALA OFFLINE
	--BEGIN
		
	--	BEGIN TRY
			
	--		IF @CD_SALA = 803 --SE A SALA DE PROVA FOR A SALA DE IMPERATRIZ
	--		BEGIN
	--			EXEC IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.RN_CANCELAR_AGENDA_RENACH_SALA_OFFLINE_QG @DT_DIA,@HR_PROVA,@CD_SALA,@NU_RENACH,@NU_CPF,@DS_MOTIVO,@CD_USUARIO,@DESCRICAO,@OBSERVACAO
	--		END
			
	--	END TRY
	--	BEGIN CATCH
	--		SET @ERRO = 'OCORREU UM ERRO AO TENTAR CANCELAR O AGENDAMENTO NA SALA OFF-LINE: \N' + ERROR_MESSAGE();
	--		RAISERROR(@ERRO, 16, 1)
	--		RETURN
	--	END CATCH
	--END
	

	BEGIN TRAN A
	
	BEGIN TRY
	
		----------------------------	
		--CANCELANDO PROVA NO SITE--
		----------------------------
		--SE A SALA DESSA PROVA É UMA SALA DIGITAL OU IMPRESSA
		IF EXISTS (SELECT 1 FROM TB_SALAS (NOLOCK) WHERE CD_SALA  = @CD_SALA AND CD_TIPO_PROVA IN (1,2))
		BEGIN 
			--CARREGA A RESPECTIVA PROVA NA VAIÁVEL
			SELECT @CD_PROVA  = CD_PROVA
			FROM TB_PROVAS (NOLOCK)
			WHERE DT_DIA = @DT_DIA
			AND HR_PROVA = @HR_PROVA 
			AND NU_CPF = @NU_CPF 
			AND NU_RENACH = @NU_RENACH 
			AND CD_SALA = @CD_SALA 

		
			-- SE EXISTIR PROVA, E ELA AINDA NÃO TIVER SIDO CANCELADA, ELA É CANCELADA
			IF (@CD_PROVA IS NOT NULL)
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM TB_HISTORICOS_PROVAS_EXCLUIDAS (NOLOCK) WHERE CD_PROVA = @CD_PROVA) 
				BEGIN
					--CANCELANDO A PROVA DO CANDIDATO
					EXEC RN_EXCLUIR_PROVA @CD_PROVA, @DS_MOTIVO, @CD_USUARIO
				END
				ELSE
				BEGIN
					--EXCLUINDO A PROVA (CASO ELA EXISTA NAS DUAS TABELAS [A DE PROVAS E A DE HISTÓRICO])
					DELETE FROM TB_HISTORICOS_PROVAS WHERE CD_PROVA = @CD_PROVA
					DELETE FROM TB_PROVAS_GERADAS WHERE CD_PROVA = @CD_PROVA
					DELETE FROM TB_PROVAS WHERE CD_PROVA = @CD_PROVA
				END
			END
		END
		--SE A SALA DESSA PROVA É UMA SALA PRÁTICA
		ELSE IF EXISTS (SELECT 1 FROM TB_SALAS WHERE CD_SALA  = @CD_SALA AND CD_TIPO_PROVA = 3)
		BEGIN 
			--CARREGA A RESPECTIVA PROVA NA VAIÁVEL
			SELECT TOP 1 @CD_PROVA  = CD_PROVA
			FROM TB_PROVAS_PRATICAS (NOLOCK)
			WHERE DT_DIA = @DT_DIA
			AND HR_PROVA = @HR_PROVA 
			AND NU_CPF = @NU_CPF 
			AND NU_RENACH = @NU_RENACH 
			AND CD_SALA = @CD_SALA 

		
			-- SE EXISTIR PROVA, E ELA AINDA NÃO TIVER SIDO CANCELADA, ELA É CANCELADA
			IF (@CD_PROVA IS NOT NULL)
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM TB_HISTORICOS_PROVAS_PRATICAS (NOLOCK) WHERE CD_PROVA = @CD_PROVA) 
				BEGIN

					--MOVENDO FALTAS DESSA PROVA PARA HISTORICO					
					INSERT INTO TB_HISTORICOS_PROVAS_PRATICAS_FALTAS (	DT_OPERACAO,CD_PROVA,CD_FALTA,CD_CONFIGURACAO_PROVA,CD_TIPO_FALTA,NU_FALTAS)
					SELECT GETDATE(),CD_PROVA,CD_FALTA,CD_CONFIGURACAO_PROVA,CD_TIPO_FALTA,NU_FALTAS 
					FROM TB_PROVAS_PRATICAS_FALTAS WHERE CD_PROVA = @CD_PROVA
					
					--EXCLUINDO FALTAS DESSA PROVA
					DELETE FROM TB_PROVAS_PRATICAS_FALTAS WHERE CD_PROVA = @CD_PROVA

					--MOVENDO ESSA PROVA PARA HISTORICO
					INSERT INTO TB_HISTORICOS_PROVAS_PRATICAS (	DT_OPERACAO,CD_PROVA,DT_DIA,HR_PROVA,CD_SALA,NU_RENACH,NU_CPF,CD_CONFIGURACAO_PROVA,DT_GERACAO,CD_USUARIO,DT_CORRECAO,CD_USUARIO_CORRECAO,CD_EXAMINADOR,CD_EXAMINADOR_02)
					SELECT GETDATE(),CD_PROVA,DT_DIA,HR_PROVA,CD_SALA,NU_RENACH,NU_CPF,CD_CONFIGURACAO_PROVA,DT_GERACAO,CD_USUARIO,DT_CORRECAO,CD_USUARIO_CORRECAO,CD_EXAMINADOR,CD_EXAMINADOR_2 
					FROM TB_PROVAS_PRATICAS WHERE CD_PROVA = @CD_PROVA
					
					--EXCLUINDO ESSA PROVA 
					DELETE FROM TB_PROVAS_PRATICAS WHERE CD_PROVA = @CD_PROVA
				END
				ELSE
				BEGIN
					--EXCLUINDO A PROVA (CASO ELA EXISTA NAS DUAS TABELAS [A DE PROVAS E A DE HISTÓRICO])
					DELETE FROM TB_PROVAS_PRATICAS_FALTAS WHERE CD_PROVA = @CD_PROVA
					DELETE FROM TB_PROVAS_PRATICAS WHERE CD_PROVA = @CD_PROVA
				END
			END
		END
		
		----------------------------------	
		--CANCELANDO AGENDAMENTO NO SITE--
		----------------------------------
		
		--MOVE A AGENDA PARA HISTÓRICO
		INSERT INTO TB_HISTORICOS_AGENDAS_RENACHS (DT_DIA,HR_PROVA,CD_SALA,NU_RENACH,NU_CPF,DT_ESTADO_AGENDA_RENACH,CD_CNPJ,CD_CONFIGURACAO_PROVA,CD_USUARIO,CD_TIPO_PRODAM,DT_HISTORICO, FL_SURDEZ)
		SELECT DT_DIA,HR_PROVA,CD_SALA,NU_RENACH,NU_CPF,DT_ESTADO_AGENDA_RENACH,CD_CNPJ,CD_CONFIGURACAO_PROVA,CD_USUARIO,CD_TIPO_PRODAM,GETDATE(), @FL_SURDEZ	
			FROM  TB_AGENDAS_RENACHS (NOLOCK)
			WHERE DT_DIA = @DT_DIA
			  AND HR_PROVA = @HR_PROVA 
			  AND NU_CPF = @NU_CPF 
			  AND NU_RENACH = @NU_RENACH 
			  AND CD_SALA = @CD_SALA
	  
		
		--EXCLUI A AGENDA
		DELETE FROM TB_AGENDAS_RENACHS 
		WHERE DT_DIA = @DT_DIA
		  AND HR_PROVA = @HR_PROVA 
		  AND NU_CPF = @NU_CPF 
		  AND NU_RENACH = @NU_RENACH 
		  AND CD_SALA = @CD_SALA

		--LOGA A AÇÃO NA TABELA DE LOGS
		EXEC DBO.SP_LOGAR_ACOES_QGS 1, @DESCRICAO , @OBSERVACAO, @CD_USUARIO ,@DT_DIA,@HR_PROVA,@CD_SALA,@NU_RENACH,@NU_CPF

		COMMIT TRAN A
		
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN A
		SET @ERRO = 'ERRO AO TENTAR CANCELAR AGENDAMENTO: /N' + ERROR_MESSAGE();
		RAISERROR(@ERRO, 16, 1)
		RETURN;
	END CATCH	


END
GO
PRINT N'Creating [DBO].[RN_ENCERRAR_PROVA_EM_ABERTO]...';


GO
CREATE procedure DBO.RN_ENCERRAR_PROVA_EM_ABERTO(
				@DT_DIA			DATETIME
				,@HR_PROVA		CHAR(5)
				,@CD_SALA		INT
				,@NU_RENACH		BIGINT
				,@NU_CPF		BIGINT
				,@CD_USUARIO	BIGINT
				,@DESCRICAO		VARCHAR(200)
				,@OBSERVACAO	VARCHAR(200) = null
)  

AS
BEGIN

	IF @CD_SALA IN (727,803,921)
		BEGIN
			IF @CD_SALA = 727
				BEGIN
					EXEC BALSAS.DB_MA_PROVA_DIGITAL.DBO.RN_ENCERRAR_PROVA_EM_ABERTO_SALA_OFFLINE @DT_DIA ,@HR_PROVA	,@CD_SALA ,@NU_RENACH ,@NU_CPF ,@CD_USUARIO ,@DESCRICAO	,@OBSERVACAO
				END
			IF @CD_SALA = 803
				BEGIN
					EXEC IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.RN_ENCERRAR_PROVA_EM_ABERTO_SALA_OFFLINE @DT_DIA ,@HR_PROVA	,@CD_SALA ,@NU_RENACH ,@NU_CPF ,@CD_USUARIO ,@DESCRICAO	,@OBSERVACAO
				END
			IF @CD_SALA = 921
				BEGIN
					EXEC SAOLUIZ.DB_MA_PROVA_DIGITAL.DBO.RN_ENCERRAR_PROVA_EM_ABERTO_SALA_OFFLINE @DT_DIA ,@HR_PROVA	,@CD_SALA ,@NU_RENACH ,@NU_CPF ,@CD_USUARIO ,@DESCRICAO	,@OBSERVACAO
				END

			exec dbo.SP_LOGAR_ACOES_QGS 7, @DESCRICAO , @OBSERVACAO, @CD_USUARIO ,@DT_DIA,@HR_PROVA,@CD_SALA,@NU_RENACH,@NU_CPF
		END	
	
END
GO



PRINT N'Creating [DBO].[SP_DESTROCAR_PROVAS_TROCADAS_ENTRE_CANDIDATOS_QG]...';


GO
CREATE procedure DBO.SP_DESTROCAR_PROVAS_TROCADAS_ENTRE_CANDIDATOS_QG(
	@CD_PROVA1 BIGINT
,	@CD_PROVA2 BIGINT 
,	@DESCRICAO VARCHAR(200)
,	@OBSERVACAO VARCHAR(200)
,	@CD_USUARIO BIGINT
)

AS
---------------------------------------------------------------------------------------------        
-- DOCUMENTO ORIGEM:         
---------------------------------------------------------------------------------------------        
-- SP_DESTROCAR_PROVAS_TROCADAS_ENTRE_CANDIDATOS_QG        
-- Data: 26/04/2013        
---------------------------------------------------------------------------------------------        
-- OBJETIVO: Trocar provas        
--        
-- DESENVOLVEDOR: Reinaldo Fiorentini ( Thomas Greg & Sons Ltda. )        
--        
-- NOTAS:        
--  Retorna:         
--    0 - Procedure executada com sucesso.        
--   -1 - Erro na execução da procedure.        
---------------------------------------------------------------------------------------------        
-- HISTÓRICO DE REVISÕES        
---------------------------------------------------------------------------------------------        
-- Data   Desenvolvedor Descrição        
-- 29/04/13 Cleber Peralta - correção do log da prova, passando de 16 para 15 o cd_acao       
--------------------------------------------------------------------------------------------- 

BEGIN
	DECLARE 
		@MSG				VARCHAR(8000)
	,	@NU_CPF_AUX_1		BIGINT
	,	@NU_CPF_AUX_2		BIGINT
	,	@NU_RENACH_AUX_1	BIGINT
	,	@NU_RENACH_AUX_2	BIGINT
	,	@CD_SALA_AUX_1		INT
	,	@CD_SALA_AUX_2		INT
	,	@DT_DIA_AUX_1		DATETIME
	,	@DT_DIA_AUX_2		DATETIME
	,	@HR_PROVA_AUX_1		CHAR(5)
	,	@HR_PROVA_AUX_2		CHAR(5)

	IF NOT EXISTS ( SELECT 1 
					FROM TB_PROVAS AS A (NOLOCK) 
					WHERE CD_PROVA  = @CD_PROVA1 
					AND EXISTS (SELECT 1 
								FROM TB_SALAS AS B (NOLOCK) 
								WHERE B.CD_SALA = A.CD_SALA AND B.CD_ESTADO_SALA = 1
							    )    
				  )
	BEGIN
		SET @MSG = 'NÃO FOI ENCONTRADA NENHUMA PROVA COM O CÓDIGO ' + CONVERT(VARCHAR, @CD_PROVA1)
		RAISERROR(@MSG, 15, 1)
		RETURN
	END
	
	IF NOT EXISTS ( SELECT 1 
					FROM TB_PROVAS AS A (NOLOCK) 
					WHERE CD_PROVA  = @CD_PROVA2 
					AND EXISTS (	SELECT 1 
									FROM TB_SALAS AS B (NOLOCK) 
									WHERE B.CD_SALA = A.CD_SALA and B.CD_ESTADO_SALA = 1
							    )
				  )
	BEGIN
		SET @MSG = 'NÃO FOI ENCONTRADA NENHUMA PROVA COM O CÓDIGO ' + CONVERT(VARCHAR, @CD_PROVA1)
		RAISERROR(@MSG, 15, 1)
		RETURN
	END
	
	IF EXISTS(SELECT 1 
				FROM TB_PROVAS 
				WHERE CD_PROVA IN (@CD_PROVA1, @CD_PROVA2) 
				AND CONVERT(VARCHAR, DT_DIA, 112) + ' ' + HR_PROVA >= DATEADD(MI, 50, GETDATE())
			 )
	BEGIN
		SET @MSG = 'NÃO É POSSÍVEL DESTROCAR ALGUMA PROVA CUJA DATA PREVISTA PARA A APLICAÇÃO AINDA NÃO TENHA OCORRIDO '
		RAISERROR(@MSG, 15, 1)
		RETURN
	END

	--GRAVANDO VARIÁVEIS
	SELECT	
		@NU_CPF_AUX_1	= NU_CPF
	,	@NU_RENACH_AUX_1= NU_RENACH
	,	@CD_SALA_AUX_1	= CD_SALA
	,	@DT_DIA_AUX_1	= DT_DIA
	,	@HR_PROVA_AUX_1	= HR_PROVA
	FROM		TB_PROVAS	
	WHERE		CD_PROVA = @CD_PROVA1	
	
	SELECT	
		@NU_CPF_AUX_2	= NU_CPF
	,	@NU_RENACH_AUX_2= NU_RENACH
	,	@CD_SALA_AUX_2	= CD_SALA
	,	@DT_DIA_AUX_2	= DT_DIA
	,	@HR_PROVA_AUX_2	= HR_PROVA
	FROM		TB_PROVAS	
	WHERE		CD_PROVA = @CD_PROVA2	
	
	
	
	IF (803 IN (@CD_SALA_AUX_1, @CD_SALA_AUX_2)) -- se a sala de provas é uma sala offline (Imperatriz)
	BEGIN
		
		IF EXISTS (SELECT 1 FROM IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS WITH(NOLOCK) WHERE CD_PROVA = @CD_PROVA1 AND NU_CPF = @NU_CPF_AUX_1 AND DT_FIM IS NULL)
		BEGIN
			SET @MSG = 'A PRIMEIRA PROVA AINDA NÃO FOI FINALIZADA NA SALA OFFLINE'
			RAISERROR(@MSG, 15, 1)
			RETURN
		END

		IF EXISTS (SELECT 1 FROM IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS WITH(NOLOCK) WHERE CD_PROVA = @CD_PROVA2 AND NU_CPF = @NU_CPF_AUX_2 AND DT_FIM IS NULL)
		BEGIN
			SET @MSG = 'A SEGUNDA PROVA AINDA NÃO FOI FINALIZADA NA SALA OFFLINE'
			RAISERROR(@MSG, 15, 1)
			RETURN
		END

	
	END
	
	
	
	
	--GRAVANDO PROVAS
	SELECT		A.* 
	INTO #PROVA_1
	FROM	TB_PROVAS			AS A (NOLOCK) 
	WHERE	A.CD_PROVA = @CD_PROVA1	
	
	SELECT		A.* 
	INTO #PROVA_2
	FROM	TB_PROVAS			AS A (NOLOCK) 
	WHERE	A.CD_PROVA = @CD_PROVA2
	
	--GRAVANDO PROVAS_GERADAS
	SELECT		A.* 
	INTO #PROVA_GERADA_1
	FROM	TB_PROVAS_GERADAS	AS A (NOLOCK) 
	WHERE	A.CD_PROVA = @CD_PROVA1	
	
	SELECT		A.* 
	INTO #PROVA_GERADA_2
	FROM	TB_PROVAS_GERADAS	AS A (NOLOCK) 
	WHERE	A.CD_PROVA = @CD_PROVA2
	
	--GRAVANDO HISTORICO DA PROVA 
	SELECT		A.* 
	INTO #HISTORICO_PROVA_1
	FROM	TB_HISTORICOS_PROVAS AS A (NOLOCK) 
	WHERE	A.CD_PROVA = @CD_PROVA1	
	
	SELECT		A.* 
	INTO #HISTORICO_PROVA_2
	FROM	TB_HISTORICOS_PROVAS AS A (NOLOCK) 
	WHERE	A.CD_PROVA = @CD_PROVA2

	
	--TROCANDO AS PROVAS
	UPDATE #PROVA_1 
	SET
		NU_CPF		= 		@NU_CPF_AUX_2
	,	NU_RENACH	=  		@NU_RENACH_AUX_2
	,	CD_SALA		=  		@CD_SALA_AUX_2
	,	DT_DIA		=  		@DT_DIA_AUX_2	
	,	HR_PROVA	=  		@HR_PROVA_AUX_2
	
	UPDATE #PROVA_2
	SET
		NU_CPF		= 		@NU_CPF_AUX_1
	,	NU_RENACH	=  		@NU_RENACH_AUX_1
	,	CD_SALA		=  		@CD_SALA_AUX_1
	,	DT_DIA		=  		@DT_DIA_AUX_1	
	,	HR_PROVA	=  		@HR_PROVA_AUX_1


	BEGIN TRAN A
	
	BEGIN TRY
	
		SET @DESCRICAO = ISNULL(@DESCRICAO,'')  + ' -->TROCA DA PROVA ' + CONVERT(VARCHAR, @CD_PROVA1) + ' PELA PROVA ' + CONVERT(VARCHAR, @CD_PROVA2)
		SET @OBSERVACAO= ISNULL(@OBSERVACAO,'') + ' -->TROCA DA PROVA ' + CONVERT(VARCHAR, @CD_PROVA1) + ' PELA PROVA ' + CONVERT(VARCHAR, @CD_PROVA2)

		
		--LOGANDO INFORMAÇÕES DA PROVA 1
		EXEC dbo.SP_LOGAR_ACOES_QGS
			15
		,	@DESCRICAO
		,	@OBSERVACAO
		,	@CD_USUARIO
		,	@DT_DIA_AUX_1
		,	@HR_PROVA_AUX_1
		,	@CD_SALA_AUX_1
		,	@NU_RENACH_AUX_1
		,	@NU_CPF_AUX_1
		
		
		
		--LIMPANDO DADOS ANTIGOS
		DELETE FROM TB_HISTORICOS_PROVAS WHERE CD_PROVA = @CD_PROVA1
		DELETE FROM TB_PROVAS_GERADAS	 WHERE CD_PROVA = @CD_PROVA1
		DELETE FROM TB_PROVAS			 WHERE CD_PROVA = @CD_PROVA1
		DELETE FROM TB_HISTORICOS_PROVAS WHERE CD_PROVA = @CD_PROVA2
		DELETE FROM TB_PROVAS_GERADAS	 WHERE CD_PROVA = @CD_PROVA2
		DELETE FROM TB_PROVAS			 WHERE CD_PROVA = @CD_PROVA2

		--COLOCANDO DADOS NOVOS
		INSERT INTO TB_PROVAS				SELECT * FROM #PROVA_1
		INSERT INTO TB_PROVAS_GERADAS		SELECT * FROM #PROVA_GERADA_1
		INSERT INTO TB_HISTORICOS_PROVAS	SELECT * FROM #HISTORICO_PROVA_1
		INSERT INTO TB_PROVAS				SELECT * FROM #PROVA_2
		INSERT INTO TB_PROVAS_GERADAS		SELECT * FROM #PROVA_GERADA_2
		INSERT INTO TB_HISTORICOS_PROVAS	SELECT * FROM #HISTORICO_PROVA_2
		
		

	
		
		--LOGANDO INFORMAÇÕES DA PROVA 2	
		EXEC dbo.SP_LOGAR_ACOES_QGS
			15
		,	@DESCRICAO
		,	@OBSERVACAO
		,	@CD_USUARIO
		,	@DT_DIA_AUX_2
		,	@HR_PROVA_AUX_2
		,	@CD_SALA_AUX_2
		,	@NU_RENACH_AUX_2
		,	@NU_CPF_AUX_2		
				
		COMMIT TRAN A
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN A
		SET @MSG = ERROR_MESSAGE();
		RAISERROR(@MSG, 15, 1)
		RETURN;
	END CATCH
END
GO


PRINT N'Creating [dbo].[SP_JOB_BUSCAR_RESULTADOS]...';


GO

CREATE procedure dbo.SP_JOB_BUSCAR_RESULTADOS

------------------------------------------------------------------------
-- SP_JOB_BUSCAR_RESULTADOS
--  Data: 13/03/2009
------------------------------------------------------------------------
--  Objetivo: 
--			Busca os resultados da sala de prova
--  Desenvolvedor: Thiago Y. Yamashiro
--
------------------------------------------------------------------------
--  Histórico de revisões  
------------------------------------------------------------------------
--  Data:
--        [data da revisao da procedure]
--  Desenvolvedor:
--        [nome do desenvolvedor]
--  Descricao:
--        [descricao da alteracao]
------------------------------------------------------------------------
as
begin

set nocount on
	-- ( Início ) - Declara variáveis auxiliares ...
	declare 
		@COUNT int
	,	@LOOP int
	,	@DT_DIA smalldatetime
	,	@HR_PROVA varchar(5)
	,	@CD_SALA int
	,	@NU_RENACH bigint
	,	@NU_CPF bigint
	,	@CD_PROVA bigint
	,	@RC int
	,	@DT_EVENTO datetime
	
	set @DT_EVENTO = getdate()
	-- ( Fim ) - Declara variáveis auxiliares .	

	-- ( Início ) - Resultados dos presentes ...
		-- ( Início ) - Verifica os resultados disponíveis  ...
		declare	@TB_RESULTADOS_PRESENTES table
		(
			CD_REGISTRO int identity
		,	CD_PROVA bigint
		,	NU_RENACH bigint
		,	NU_CPF bigint
		,	DT_DIA smalldatetime
		,	HR_PROVA varchar(5)
		,	CD_SALA int
		)
		
		insert into @TB_RESULTADOS_PRESENTES
		(
			CD_PROVA
		,	NU_RENACH
		,	NU_CPF
		,	DT_DIA
		,	HR_PROVA
		,	CD_SALA
		)
		select 
			A.CD_PROVA
		,	A.NU_RENACH
		,	A.NU_CPF
		,	A.DT_DIA
		,	A.HR_PROVA
		,	A.CD_SALA
		from
			IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS A
		where
			A.DT_FIM is not null
		and not exists
			(
				select B.DT_DIA, B.HR_PROVA, B.CD_SALA, B.NU_RENACH, B.NU_CPF 
				from TB_AGENDAS_RENACHS_LOG B
				where A.DT_DIA = B.DT_DIA and A.HR_PROVA = B.HR_PROVA and A.CD_SALA = B.CD_SALA and A.NU_RENACH = B.NU_RENACH and A.NU_CPF = B.NU_CPF
			)
		-- ( Fim ) - Verifica os resultados disponíveis .
		
		-- ( Início ) - Transfere os resultados dos presentes para as tabelas ...	
		select
			@COUNT = max(CD_REGISTRO)
		from
			@TB_RESULTADOS_PRESENTES
		
		set @LOOP = 1
		
		while @LOOP <= @COUNT
			begin	
				select 
					@DT_DIA = DT_DIA
				,	@HR_PROVA = HR_PROVA
				,	@CD_SALA = CD_SALA
				,	@NU_RENACH = NU_RENACH
				,	@NU_CPF = NU_CPF
				from
					@TB_RESULTADOS_PRESENTES
				where
					CD_REGISTRO = @LOOP
			
				exec SP_JOB_ENVIAR_RESULTADOS
					@DT_DIA 
				,	@HR_PROVA 
				,	@CD_SALA 
				,	@NU_RENACH 
				,	@NU_CPF 
				
				set @LOOP = @LOOP + 1
			end
		-- ( Fim ) - Transfere os resultados dos presentes para as tabelas .	
	-- ( Fim ) - Resultados dos presentes .		
	
	-- ( Início ) - Resultados dos faltosos ...
		-- ( Início ) - Verifica os resultados disponíveis  ...
		declare	@TB_RESULTADOS_FALTOSOS table
		(
			CD_REGISTRO int identity
		,	CD_PROVA bigint
		,	NU_RENACH bigint
		,	NU_CPF bigint
		,	DT_DIA smalldatetime
		,	HR_PROVA varchar(5)
		,	CD_SALA int
		)
		
		insert into @TB_RESULTADOS_FALTOSOS
		(
			CD_PROVA
		,	NU_RENACH
		,	NU_CPF
		,	DT_DIA
		,	HR_PROVA
		,	CD_SALA
		)
		select 
			A.CD_PROVA
		,	A.NU_RENACH
		,	A.NU_CPF
		,	A.DT_DIA
		,	A.HR_PROVA
		,	A.CD_SALA
		from
			IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS A
		where
			A.DT_INICIO is null
		and	exists
			(
				select B.DT_DIA, B.HR_PROVA, B.CD_SALA from	IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS B
					where A.DT_DIA = B.DT_DIA and A.HR_PROVA = B.HR_PROVA and A.CD_SALA = B.CD_SALA
						and B.DT_FIM is not null
			)
		and not exists
			(
				select C.DT_DIA, C.HR_PROVA, C.CD_SALA, C.NU_RENACH, C.NU_CPF 
				from TB_AGENDAS_RENACHS_LOG C
				where A.DT_DIA = C.DT_DIA and A.HR_PROVA = C.HR_PROVA and A.CD_SALA = C.CD_SALA and A.NU_RENACH = C.NU_RENACH and A.NU_CPF = C.NU_CPF
			)	
			
		insert into @TB_RESULTADOS_FALTOSOS
		(
			CD_PROVA
		,	NU_RENACH
		,	NU_CPF
		,	DT_DIA
		,	HR_PROVA
		,	CD_SALA
		)
		select 
			A.CD_PROVA
		,	A.NU_RENACH
		,	A.NU_CPF
		,	A.DT_DIA
		,	A.HR_PROVA
		,	A.CD_SALA
		from
			IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS A
		where
			A.DT_INICIO is null
		and datediff(dd, A.DT_DIA, getdate()) > 0
		and	not exists
			(
				select B.DT_DIA, B.HR_PROVA, B.CD_SALA from	IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS B
					where A.DT_DIA = B.DT_DIA and A.HR_PROVA = B.HR_PROVA and A.CD_SALA = B.CD_SALA
						and B.DT_INICIO is not null
			)
		and not exists
			(
				select C.DT_DIA, C.HR_PROVA, C.CD_SALA, C.NU_RENACH, C.NU_CPF 
				from TB_AGENDAS_RENACHS_LOG C
				where A.DT_DIA = C.DT_DIA and A.HR_PROVA = C.HR_PROVA and A.CD_SALA = C.CD_SALA and A.NU_RENACH = C.NU_RENACH and A.NU_CPF = C.NU_CPF
			)						
		-- ( Fim ) - Verifica os resultados disponíveis .
		
		-- ( Início ) - Baixa dos faltosos ...	
		select
			@COUNT = max(CD_REGISTRO)
		from
			@TB_RESULTADOS_FALTOSOS
		
		set @LOOP = 1
		
		while @LOOP <= @COUNT
		
			begin	
					
				select 
					@CD_PROVA = CD_PROVA
				,	@DT_DIA = DT_DIA
				,	@HR_PROVA = HR_PROVA
				,	@CD_SALA = CD_SALA
				,	@NU_RENACH = NU_RENACH
				,	@NU_CPF = NU_CPF
				from
					@TB_RESULTADOS_FALTOSOS
				where
					CD_REGISTRO = @LOOP
			

				exec SP_JOB_EXCLUIR_PROVA
						@DT_DIA 
					,	@HR_PROVA 
					,	@CD_SALA 
					,	@NU_RENACH 
					,	@NU_CPF 
					,	@CD_PROVA 
					
				set @LOOP = @LOOP + 1
			end
		-- ( Fim ) - Transfere os resultados dos faltosos para as tabelas .	
	-- ( Fim ) - Baixa dos faltosos .		
	
	
end
GO


PRINT N'Creating [dbo].[SP_JOB_BUSCAR_RESULTADOS_BALSAS]...';


GO
CREATE procedure dbo.SP_JOB_BUSCAR_RESULTADOS_BALSAS

------------------------------------------------------------------------
-- SP_JOB_BUSCAR_RESULTADOS
--  Data: 13/03/2009
------------------------------------------------------------------------
--  Objetivo: 
--			Busca os resultados da sala de prova
--  Desenvolvedor: Thiago Y. Yamashiro
--
------------------------------------------------------------------------
--  Histórico de revisões  
------------------------------------------------------------------------
--  Data:
--        [data da revisao da procedure]
--  Desenvolvedor:
--        [nome do desenvolvedor]
--  Descricao:
--        [descricao da alteracao]
------------------------------------------------------------------------
as
begin

set nocount on
	-- ( Início ) - Declara variáveis auxiliares ...
	declare 
		@COUNT int
	,	@LOOP int
	,	@DT_DIA smalldatetime
	,	@HR_PROVA varchar(5)
	,	@CD_SALA int
	,	@NU_RENACH bigint
	,	@NU_CPF bigint
	,	@CD_PROVA bigint
	,	@RC int
	,	@DT_EVENTO datetime
	
	set @DT_EVENTO = getdate()
	-- ( Fim ) - Declara variáveis auxiliares .	

	-- ( Início ) - Resultados dos presentes ...
		-- ( Início ) - Verifica os resultados disponíveis  ...
		declare	@TB_RESULTADOS_PRESENTES table
		(
			CD_REGISTRO int identity
		,	CD_PROVA bigint
		,	NU_RENACH bigint
		,	NU_CPF bigint
		,	DT_DIA smalldatetime
		,	HR_PROVA varchar(5)
		,	CD_SALA int
		)
		
		insert into @TB_RESULTADOS_PRESENTES
		(
			CD_PROVA
		,	NU_RENACH
		,	NU_CPF
		,	DT_DIA
		,	HR_PROVA
		,	CD_SALA
		)
		select 
			A.CD_PROVA
		,	A.NU_RENACH
		,	A.NU_CPF
		,	A.DT_DIA
		,	A.HR_PROVA
		,	A.CD_SALA
		from
			BALSAS.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS A
		where
			A.DT_FIM is not null
		and not exists
			(
				select B.DT_DIA, B.HR_PROVA, B.CD_SALA, B.NU_RENACH, B.NU_CPF 
				from TB_AGENDAS_RENACHS_LOG B
				where A.DT_DIA = B.DT_DIA and A.HR_PROVA = B.HR_PROVA and A.CD_SALA = B.CD_SALA and A.NU_RENACH = B.NU_RENACH and A.NU_CPF = B.NU_CPF
			)
		-- ( Fim ) - Verifica os resultados disponíveis .
		
		-- ( Início ) - Transfere os resultados dos presentes para as tabelas ...	
		select
			@COUNT = max(CD_REGISTRO)
		from
			@TB_RESULTADOS_PRESENTES
		
		set @LOOP = 1
		
		while @LOOP <= @COUNT
			begin	
				select 
					@DT_DIA = DT_DIA
				,	@HR_PROVA = HR_PROVA
				,	@CD_SALA = CD_SALA
				,	@NU_RENACH = NU_RENACH
				,	@NU_CPF = NU_CPF
				from
					@TB_RESULTADOS_PRESENTES
				where
					CD_REGISTRO = @LOOP
			
				exec SP_JOB_ENVIAR_RESULTADOS_BALSAS
					@DT_DIA 
				,	@HR_PROVA 
				,	@CD_SALA 
				,	@NU_RENACH 
				,	@NU_CPF 
				
				set @LOOP = @LOOP + 1
			end
		-- ( Fim ) - Transfere os resultados dos presentes para as tabelas .	
	-- ( Fim ) - Resultados dos presentes .		
	
	-- ( Início ) - Resultados dos faltosos ...
		-- ( Início ) - Verifica os resultados disponíveis  ...
		declare	@TB_RESULTADOS_FALTOSOS table
		(
			CD_REGISTRO int identity
		,	CD_PROVA bigint
		,	NU_RENACH bigint
		,	NU_CPF bigint
		,	DT_DIA smalldatetime
		,	HR_PROVA varchar(5)
		,	CD_SALA int
		)
		
		insert into @TB_RESULTADOS_FALTOSOS
		(
			CD_PROVA
		,	NU_RENACH
		,	NU_CPF
		,	DT_DIA
		,	HR_PROVA
		,	CD_SALA
		)
		select 
			A.CD_PROVA
		,	A.NU_RENACH
		,	A.NU_CPF
		,	A.DT_DIA
		,	A.HR_PROVA
		,	A.CD_SALA
		from
			BALSAS.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS A
		where
			A.DT_INICIO is null
		and	exists
			(
				select B.DT_DIA, B.HR_PROVA, B.CD_SALA from	BALSAS.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS B
					where A.DT_DIA = B.DT_DIA and A.HR_PROVA = B.HR_PROVA and A.CD_SALA = B.CD_SALA
						and B.DT_FIM is not null
			)
		and not exists
			(
				select C.DT_DIA, C.HR_PROVA, C.CD_SALA, C.NU_RENACH, C.NU_CPF 
				from TB_AGENDAS_RENACHS_LOG C
				where A.DT_DIA = C.DT_DIA and A.HR_PROVA = C.HR_PROVA and A.CD_SALA = C.CD_SALA and A.NU_RENACH = C.NU_RENACH and A.NU_CPF = C.NU_CPF
			)	
			
		insert into @TB_RESULTADOS_FALTOSOS
		(
			CD_PROVA
		,	NU_RENACH
		,	NU_CPF
		,	DT_DIA
		,	HR_PROVA
		,	CD_SALA
		)
		select 
			A.CD_PROVA
		,	A.NU_RENACH
		,	A.NU_CPF
		,	A.DT_DIA
		,	A.HR_PROVA
		,	A.CD_SALA
		from
			BALSAS.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS  A with (nolock)
		where
			A.DT_INICIO is null
		and datediff(dd, A.DT_DIA, getdate()) > 0
		and	not exists
			(
				select B.DT_DIA, B.HR_PROVA, B.CD_SALA from	BALSAS.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS B with (nolock)
					where A.DT_DIA = B.DT_DIA and A.HR_PROVA = B.HR_PROVA and A.CD_SALA = B.CD_SALA
						and B.DT_INICIO is not null
			)
		and not exists
			(
				select C.DT_DIA, C.HR_PROVA, C.CD_SALA, C.NU_RENACH, C.NU_CPF 
				from TB_AGENDAS_RENACHS_LOG C with (nolock)
				where A.DT_DIA = C.DT_DIA and A.HR_PROVA = C.HR_PROVA and A.CD_SALA = C.CD_SALA and A.NU_RENACH = C.NU_RENACH and A.NU_CPF = C.NU_CPF
			)						
		-- ( Fim ) - Verifica os resultados disponíveis .
		
		-- ( Início ) - Baixa dos faltosos ...	
		select
			@COUNT = max(CD_REGISTRO)
		from
			@TB_RESULTADOS_FALTOSOS
		
		set @LOOP = 1
		
		while @LOOP <= @COUNT
		
			begin	
					
				select 
					@CD_PROVA = CD_PROVA
				,	@DT_DIA = DT_DIA
				,	@HR_PROVA = HR_PROVA
				,	@CD_SALA = CD_SALA
				,	@NU_RENACH = NU_RENACH
				,	@NU_CPF = NU_CPF
				from
					@TB_RESULTADOS_FALTOSOS
				where
					CD_REGISTRO = @LOOP
			

				exec SP_JOB_EXCLUIR_PROVA
						@DT_DIA 
					,	@HR_PROVA 
					,	@CD_SALA 
					,	@NU_RENACH 
					,	@NU_CPF 
					,	@CD_PROVA 
					
				set @LOOP = @LOOP + 1
			end
		-- ( Fim ) - Transfere os resultados dos faltosos para as tabelas .	
	-- ( Fim ) - Baixa dos faltosos .		
	
	
end
GO
PRINT N'Creating [dbo].[SP_JOB_BUSCAR_RESULTADOS_SAO_LUIS]...';


GO
CREATE procedure [dbo].[SP_JOB_BUSCAR_RESULTADOS_SAO_LUIS]



------------------------------------------------------------------------

-- SP_JOB_BUSCAR_RESULTADOS

--  Data: 13/03/2009

------------------------------------------------------------------------

--  Objetivo: 

--			Busca os resultados da sala de prova

--  Desenvolvedor: Thiago Y. Yamashiro

--

------------------------------------------------------------------------

--  Histórico de revisões  

------------------------------------------------------------------------

--  Data:

--        [data da revisao da procedure]

--  Desenvolvedor:

--        [nome do desenvolvedor]

--  Descricao:

--        [descricao da alteracao]

------------------------------------------------------------------------

as

begin



set nocount on

	-- ( Início ) - Declara variáveis auxiliares ...

	declare 

		@COUNT int

	,	@LOOP int

	,	@DT_DIA smalldatetime

	,	@HR_PROVA varchar(5)

	,	@CD_SALA int

	,	@NU_RENACH bigint

	,	@NU_CPF bigint

	,	@CD_PROVA bigint

	,	@RC int

	,	@DT_EVENTO datetime

	

	set @DT_EVENTO = getdate()

	-- ( Fim ) - Declara variáveis auxiliares .	



	-- ( Início ) - Resultados dos presentes ...

		-- ( Início ) - Verifica os resultados disponíveis  ...

		declare	@TB_RESULTADOS_PRESENTES table

		(

			CD_REGISTRO int identity

		,	CD_PROVA bigint

		,	NU_RENACH bigint

		,	NU_CPF bigint

		,	DT_DIA smalldatetime

		,	HR_PROVA varchar(5)

		,	CD_SALA int

		)

		

		insert into @TB_RESULTADOS_PRESENTES

		(

			CD_PROVA

		,	NU_RENACH

		,	NU_CPF

		,	DT_DIA

		,	HR_PROVA

		,	CD_SALA

		)

		select 

			A.CD_PROVA

		,	A.NU_RENACH

		,	A.NU_CPF

		,	A.DT_DIA

		,	A.HR_PROVA

		,	A.CD_SALA

		from

			SAOLUIZ.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS A

		where

			A.DT_FIM is not null

		and NOT exists

			(

				select B.DT_DIA, B.HR_PROVA, B.CD_SALA, B.NU_RENACH, B.NU_CPF 

				from TB_AGENDAS_RENACHS_LOG B

				where A.DT_DIA = B.DT_DIA and A.HR_PROVA = B.HR_PROVA and A.CD_SALA = B.CD_SALA and A.NU_RENACH = B.NU_RENACH and A.NU_CPF = B.NU_CPF

			)

		and exists

			(

				select C.CD_PROVA

				from TB_PROVAS C

				where A.CD_PROVA = C.CD_PROVA

				AND DT_INICIO IS NULL

				AND DT_FIM IS  NULL

			)



		-- ( Fim ) - Verifica os resultados disponíveis .

		

		-- ( Início ) - Transfere os resultados dos presentes para as tabelas ...	

		select

			@COUNT = max(CD_REGISTRO)

		from

			@TB_RESULTADOS_PRESENTES

		

		set @LOOP = 1

		

		while @LOOP <= @COUNT

			begin	

				select 

					@DT_DIA = DT_DIA

				,	@HR_PROVA = HR_PROVA

				,	@CD_SALA = CD_SALA

				,	@NU_RENACH = NU_RENACH

				,	@NU_CPF = NU_CPF

				from

					@TB_RESULTADOS_PRESENTES

				where

					CD_REGISTRO = @LOOP

			

				exec SP_JOB_ENVIAR_RESULTADOS_SAO_LUIS

					@DT_DIA 

				,	@HR_PROVA 

				,	@CD_SALA 

				,	@NU_RENACH 

				,	@NU_CPF 

				

				set @LOOP = @LOOP + 1

			end



		-- ( Fim ) - Transfere os resultados dos presentes para as tabelas .	

	-- ( Fim ) - Resultados dos presentes .		

	

	-- ( Início ) - Resultados dos faltosos ...

		-- ( Início ) - Verifica os resultados disponíveis  ...

		declare	@TB_RESULTADOS_FALTOSOS table

		(

			CD_REGISTRO int identity

		,	CD_PROVA bigint

		,	NU_RENACH bigint

		,	NU_CPF bigint

		,	DT_DIA smalldatetime

		,	HR_PROVA varchar(5)

		,	CD_SALA int

		)

		

		insert into @TB_RESULTADOS_FALTOSOS

		(

			CD_PROVA

		,	NU_RENACH

		,	NU_CPF

		,	DT_DIA

		,	HR_PROVA

		,	CD_SALA

		)

		select 

			A.CD_PROVA

		,	A.NU_RENACH

		,	A.NU_CPF

		,	A.DT_DIA

		,	A.HR_PROVA

		,	A.CD_SALA

		from

			SAOLUIZ.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS A

		where

			A.DT_INICIO is null

		and	exists

			(

				select B.DT_DIA, B.HR_PROVA, B.CD_SALA from	SAOLUIZ.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS B

					where A.DT_DIA = B.DT_DIA and A.HR_PROVA = B.HR_PROVA and A.CD_SALA = B.CD_SALA

						and B.DT_FIM is not null

			)

		and not exists

			(

				select C.DT_DIA, C.HR_PROVA, C.CD_SALA, C.NU_RENACH, C.NU_CPF 

				from TB_AGENDAS_RENACHS_LOG C

				where A.DT_DIA = C.DT_DIA and A.HR_PROVA = C.HR_PROVA and A.CD_SALA = C.CD_SALA and A.NU_RENACH = C.NU_RENACH and A.NU_CPF = C.NU_CPF

			)	

			

		insert into @TB_RESULTADOS_FALTOSOS

		(

			CD_PROVA

		,	NU_RENACH

		,	NU_CPF

		,	DT_DIA

		,	HR_PROVA

		,	CD_SALA

		)

		select 

			A.CD_PROVA

		,	A.NU_RENACH

		,	A.NU_CPF

		,	A.DT_DIA

		,	A.HR_PROVA

		,	A.CD_SALA

		from

			SAOLUIZ.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS A

		where

			A.DT_INICIO is null

		and datediff(dd, A.DT_DIA, getdate()) > 0

		and	not exists

			(

				select B.DT_DIA, B.HR_PROVA, B.CD_SALA from	SAOLUIZ.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS B

					where A.DT_DIA = B.DT_DIA and A.HR_PROVA = B.HR_PROVA and A.CD_SALA = B.CD_SALA

						and B.DT_INICIO is not null

			)

		and not exists

			(

				select C.DT_DIA, C.HR_PROVA, C.CD_SALA, C.NU_RENACH, C.NU_CPF 

				from TB_AGENDAS_RENACHS_LOG C

				where A.DT_DIA = C.DT_DIA and A.HR_PROVA = C.HR_PROVA and A.CD_SALA = C.CD_SALA and A.NU_RENACH = C.NU_RENACH and A.NU_CPF = C.NU_CPF

			)						

		-- ( Fim ) - Verifica os resultados disponíveis .

		

		-- ( Início ) - Baixa dos faltosos ...	

		select

			@COUNT = max(CD_REGISTRO)

		from

			@TB_RESULTADOS_FALTOSOS

		

		set @LOOP = 1

		

		while @LOOP <= @COUNT

		

			begin	

					

				select 

					@CD_PROVA = CD_PROVA

				,	@DT_DIA = DT_DIA

				,	@HR_PROVA = HR_PROVA

				,	@CD_SALA = CD_SALA

				,	@NU_RENACH = NU_RENACH

				,	@NU_CPF = NU_CPF

				from

					@TB_RESULTADOS_FALTOSOS

				where

					CD_REGISTRO = @LOOP

			



				exec SP_JOB_EXCLUIR_PROVA

						@DT_DIA 

					,	@HR_PROVA 

					,	@CD_SALA 

					,	@NU_RENACH 

					,	@NU_CPF 

					,	@CD_PROVA 

					

				set @LOOP = @LOOP + 1

			end

		-- ( Fim ) - Transfere os resultados dos faltosos para as tabelas .	

	-- ( Fim ) - Baixa dos faltosos .		

	

	

end
GO



PRINT N'Creating [dbo].[TRANSFERIR_AGENDAMENTOS_BIOMETRIAS_SALA_OFFLINE]...';


GO

CREATE PROCEDURE TRANSFERIR_AGENDAMENTOS_BIOMETRIAS_SALA_OFFLINE (@DT_DIA DATETIME, @HR_PROVA CHAR(5) = NULL, @CD_SALA INT, @CD_USUARIO BIGINT)
AS
BEGIN 
	DECLARE @NU_CPF BIGINT, @NU_RENACH BIGINT, @AUX_HORA CHAR(5), @RETORNO VARCHAR(8000)

	
	SET @RETORNO = 'INICIANDO PROCESSO'+ CHAR(13)+CHAR(13)
	SET @RETORNO = @RETORNO + 'VERIFICANDO DISPONIBILIDADE DE AGENDAS NO SITE...'+ CHAR(13)


	--CARREGA AGENDAS NA TABELA TEMPORÁRIA
	SELECT *, CONVERT(BIT, 0)AS FLAG_PROVA_GERADA
	INTO #TEMP_AGENDAS
	FROM TB_AGENDAS_RENACHS (NOLOCK)
	WHERE  CD_SALA  = @CD_SALA
	AND    DT_DIA   = @DT_DIA
	AND	   HR_PROVA = ISNULL(@HR_PROVA, HR_PROVA)
	

	--VERIFICA SE TEM AGENDAS NO SITE
	IF NOT EXISTS(	SELECT 1 FROM #TEMP_AGENDAS	 )
	BEGIN
		SET @RETORNO = @RETORNO + 'NÃO EXISTEM AGENDAS NO SITE PARA EFETUAR A TRANSFERÊNCIA'+ CHAR(13)
		SET @RETORNO = @RETORNO + '***O PROCESSO NÃO PODE CONTINUAR'+ CHAR(13)
		SET @RETORNO = @RETORNO + CHAR(13)+ 'FIM DO PROCESSO'+ CHAR(13)
		RETURN @RETORNO
	END
	SET @RETORNO = @RETORNO + 'AS AGENDAS NO SITE ESTÃO OK!'+ CHAR(13)

	--ATUALIZA AGENDAS SEM PROVAS
	UPDATE #TEMP_AGENDAS SET FLAG_PROVA_GERADA = CASE WHEN ISNULL(B.CD_PROVA, 0)=0 THEN 0 ELSE 1 END
	FROM #TEMP_AGENDAS	AS A (NOLOCK)
	LEFT JOIN TB_PROVAS AS B (NOLOCK) ON A.NU_CPF = B.NU_CPF AND A.NU_RENACH = B.NU_RENACH AND A.DT_DIA = B.DT_DIA AND A.HR_PROVA = B.HR_PROVA AND A.CD_SALA = B.CD_SALA
	WHERE  A.CD_SALA  = @CD_SALA
	AND    A.DT_DIA   = @DT_DIA
	AND	   A.HR_PROVA = ISNULL(@HR_PROVA, A.HR_PROVA)

	SET @RETORNO = @RETORNO + 'VERIFICANDO SE AS PROVAS ESTÃO GERADAS NO SITE...'+ CHAR(13)

	
	IF not EXISTS (SELECT 1 FROM #TEMP_AGENDAS WHERE FLAG_PROVA_GERADA = 0)
	BEGIN
		SET @RETORNO = @RETORNO + 'TODAS AS PROVAS JÁ ESTÃO GERADAS!'+ CHAR(13)
	END	
	ELSE
	BEGIN
		SET @RETORNO = @RETORNO + 'HÁ PROVAS NÃO GERADAS!'+ CHAR(13)
		
		SET @RETORNO = @RETORNO + 'GERANDO AS PROVAS QUE FALTAM SER GERADAS'+ CHAR(13)

		--SE NÃO TIVER ALGUMA DAS PROVAS PARA ESSAS AGENDAS, ELE CRIA AS PROVAS NO SITE
		DECLARE CURS CURSOR  FOR SELECT NU_RENACH, NU_CPF, HR_PROVA FROM #TEMP_AGENDAS WHERE FLAG_PROVA_GERADA = 0
		OPEN CURS
		FETCH NEXT FROM CURS INTO @NU_RENACH, @NU_CPF, @AUX_HORA
		WHILE @@FETCH_STATUS = 0
		BEGIN 
			SET @RETORNO = @RETORNO + 'GERANDO A PROVA DO CANDIDATO DE CPF '+CONVERT(VARCHAR(11),@NU_CPF)+ '...'
			
			EXEC RN_INSERIR_PROVA_SQL NULL, @NU_RENACH, @NU_CPF, @CD_SALA, @DT_DIA, @AUX_HORA, NULL, @CD_USUARIO
			
			SET @RETORNO = @RETORNO + 'PROVA GERADA!'+ CHAR(13)
			
			FETCH NEXT FROM CURS INTO @NU_RENACH, @NU_CPF, @AUX_HORA
		END	
		CLOSE CURS
		DEALLOCATE CURS
	END



	
	--INICIA A TRANSFERÊNCIA DE PROVAS
	SET @RETORNO = @RETORNO + 'TRANSFERINDO AS PROVAS PARA A SALA OFF-LINE...'+ CHAR(13)
	EXEC IMPERATRIZ.DB_MA_PROVA_DIGITAL.DBO.SP_JOB_BUSCAR_AGENDAMENTOS_MANUAL @DT_DIA, @HR_PROVA
	IF @@ERROR <> 0
	BEGIN
		SET @RETORNO = @RETORNO + '***ERRO NA TRANSFERENCIA DAS PROVAS!'+ CHAR(13)
		PRINT @RETORNO
		RETURN @RETORNO
	END
	ELSE 
	BEGIN
		SET @RETORNO = @RETORNO + 'TRANSFERENCIA DAS PROVAS EXECUTADA COM EXITO!'+ CHAR(13)	
	END
	
	


	--INICIA A TRANSFERÊNCIA DAS BIOMETRIAS
	SET @RETORNO = @RETORNO + 'TRANSFERINDO AS BIOMETRIAS PARA A SALA OFF-LINE...'+ CHAR(13)
	EXEC IMPERATRIZ.DB_SERVIDOR_BLOB_MA_P.DBO.SP_JOB_BUSCAR_BIOMETRIAS_MANUAL @DT_DIA, @HR_PROVA, @CD_SALA
	IF @@ERROR <> 0
	BEGIN
		SET @RETORNO = @RETORNO + '***ERRO NA TRANSFERENCIA DAS BIOMETRIAS!'+ CHAR(13)
		PRINT @RETORNO
		RETURN @RETORNO
	END
	ELSE 
	BEGIN
		SET @RETORNO = @RETORNO + 'TRANSFERENCIA DAS BIOMETRIAS EXECUTADA COM EXITO!'+ CHAR(13)
	END

	
	SET @RETORNO = @RETORNO + CHAR(13)+ 'FIM DO PROCESSO'
	
	print 	@RETORNO	
	--RETURN @RETORNO
END
GO
PRINT N'Creating [dbo].[RN_EXPORTAR_DADOS_PROVA_DIGITAL]...';


GO
CREATE  PROCEDURE [dbo].[RN_EXPORTAR_DADOS_PROVA_DIGITAL]   
(  
    @CD_SALA INT,  
    @DT_DIA SMALLDATETIME,  
    @HR_PROVA CHAR(5)  
)  
AS  
---------------------------------------------------------------------------------------------  
-- DOCUMENTO ORIGEM DA SUB-ROTINA:   
---------------------------------------------------------------------------------------------  
-- RN_EXPORTAR_DADOS_PROVA_IMPRESSA  
-- Data: 27/01/2006  
---------------------------------------------------------------------------------------------  
-- OBJETIVO:   
--  
-- DESENVOLVEDOR: Fábio Famiglietti ( Thomas Greg & Sons Ltda. )  
--  
-- NOTAS:  
--  Retorna:   
--    0 - Procedure executada com sucesso.  
--   -1 - Erro na execução da procedure.  
---------------------------------------------------------------------------------------------  
-- HISTÓRICO DE REVISÕES  
---------------------------------------------------------------------------------------------  
-- Data			Desenvolvedor			Descrição  
--28/05/2013	Reinaldo Fiorentini		Ordenação das provas por código de prova (ascendente) 
---------------------------------------------------------------------------------------------  
  
BEGIN  
  
 SET NOCOUNT ON  
  
 exec RN_RECRIAR_PROVA @CD_SALA,@DT_DIA,@HR_PROVA  
  
-- Table 0  
    SELECT TOP 1 CD_CATEGORIA, DS_CATEGORIA   
    FROM dbo.TB_PC_CATEGORIAS (nolock)   
-- Table 0  
  
-- Table 1  
    SELECT CD_ESTADO_CONFIGURACAO_PROVA, DS_ESTADO_CONFIGURACAO_PROVA   
    FROM dbo.TB_PC_ESTADOS_CONFIGURACOES_PROVAS(nolock)   
 where 1=2  
-- Table 1  
  
-- Table 2  
    SELECT CD_GRUPO_PERGUNTA, DS_GRUPO_PERGUNTA   
    FROM dbo.TB_PC_GRUPOS_PERGUNTAS(nolock)   
 where 1=2  
-- Table 2  
  
-- Table 3  
    SELECT CD_ESTADO_PERGUNTA, DS_ESTADO_PERGUNTA   
    FROM dbo.TB_PC_ESTADOS_PERGUNTAS(nolock)   
 where 1=2  
-- Table 3  
  
-- Table 4  
    SELECT CD_ESTADO_RESPOSTA, DS_ESTADO_RESPOSTA   
    FROM dbo.TB_PC_ESTADOS_RESPOSTAS(nolock)   
 where 1=2  
-- Table 4  
  
-- Table 5  
    SELECT CD_ESTADO_AUTENTICACAO, DS_ESTADO_AUTENTICACAO   
    FROM dbo.TB_PC_ESTADOS_AUTENTICACOES(nolock)   
 where 1=2  
-- Table 5  
  
-- Table 6  
    SELECT CD_CONFIGURACAO_PROVA, DS_CONFIGURACAO_PROVA, HR_TEMPO_PROVA, CD_ESTADO_CONFIGURACAO_PROVA   
    FROM dbo.TB_PC_CONFIGURACOES_PROVAS(nolock)   
 where 1=2  
-- Table 6  
  
-- Table 7  
    SELECT CD_CONFIGURACAO_PROVA, CD_GRUPO_PERGUNTA, NU_PERGUNTAS   
    FROM dbo.TB_CONFIGURACOES_GRUPOS (nolock)   
 where 1=2  
-- Table 7  
  
-- Table 8  
    SELECT DISTINCT  
    A.CD_PERGUNTA, A.DS_PERGUNTA, A.CD_IMAGEM, A.CD_ESTADO_PERGUNTA, A.CD_GRUPO_PERGUNTA  
    FROM TB_PERGUNTAS A (nolock)  
    INNER JOIN TB_PROVAS_GERADAS B (nolock) ON B.CD_PERGUNTA = A.CD_PERGUNTA  
    INNER JOIN TB_PROVAS C (nolock) ON C.CD_PROVA = B.CD_PROVA   
    AND C.CD_SALA = @CD_SALA AND C.DT_DIA = @DT_DIA AND C.HR_PROVA = @HR_PROVA AND C.DT_INICIO IS NULL AND C.DT_FIM IS NULL  
-- Table 8  
  
-- Table 9  
    SELECT CD_RESPOSTA, CD_PERGUNTA, DS_RESPOSTA, CD_IMAGEM, CD_ESTADO_RESPOSTA   
    FROM TB_RESPOSTAS (nolock)  where cd_pergunta in (  
    SELECT A.CD_PERGUNTA  
    FROM TB_PERGUNTAS A (nolock)  
    INNER JOIN TB_PROVAS_GERADAS B (nolock) ON B.CD_PERGUNTA = A.CD_PERGUNTA  
    INNER JOIN TB_PROVAS C (nolock) ON C.CD_PROVA = B.CD_PROVA   
    AND C.CD_SALA = @CD_SALA AND C.DT_DIA = @DT_DIA AND C.HR_PROVA = @HR_PROVA AND C.DT_INICIO IS NULL AND C.DT_FIM IS NULL)  
    ORDER BY CD_RESPOSTA  
-- Table 9  
  
-- Table 10  
    SELECT A.NU_RENACH, A.NU_CPF, A.NM_CANDIDATO, A.DT_NASCIMENTO, A.DT_ESTADO_CANDIDATO,  
    A.DS_CFC_INSTRUTOR, A.NU_IDENTIDADE, A.DS_ORGAO_EXPEDIDOR_UF, A.NM_LOCAL, A.CD_CATEGORIA   
    FROM dbo.TB_CANDIDATOS A (nolock)  
    INNER JOIN TB_AGENDAS_RENACHS B (nolock) ON B.NU_RENACH = A.NU_RENACH AND B.NU_CPF = A.NU_CPF   
    AND B.CD_SALA = @CD_SALA AND B.DT_DIA = @DT_DIA AND B.HR_PROVA = @HR_PROVA  
 WHERE NOT EXISTS (SELECT * FROM TB_PROVAS (NOLOCK) WHERE  DT_INICIO IS NOT NULL AND DT_FIM IS NOT NULL AND NU_RENACH = A.NU_RENACH AND CD_SALA = @CD_SALA AND DT_DIA = @DT_DIA AND HR_PROVA = @HR_PROVA)  
-- Table 10  
  
-- Table 11  
    SELECT A.CD_PROVA, A.NU_RENACH, A.NU_CPF, A.CD_CONFIGURACAO_PROVA, B.DS_CONFIGURACAO_PROVA, dateadd(hour,2, A.DT_DIA) as DT_DIA, A.HR_PROVA, C.DS_SALA  
    FROM dbo.TB_PROVAS A  (nolock)  
    INNER JOIN TB_PC_CONFIGURACOES_PROVAS B (nolock) ON B.CD_CONFIGURACAO_PROVA = A.CD_CONFIGURACAO_PROVA  
    INNER JOIN TB_SALAS C (nolock) ON C.CD_SALA = A.CD_SALA  
    WHERE A.CD_SALA = @CD_SALA AND DT_DIA = @DT_DIA AND HR_PROVA = @HR_PROVA AND DT_INICIO IS NULL AND DT_FIM IS NULL  
--(inicio) 28/05/2013	Reinaldo Fiorentini ordenação das provas por código de prova (ascendente) 
    order by a.CD_PROVA asc
--(fim) 28/05/2013	Reinaldo Fiorentini ordenação das provas por código de prova (ascendente) 
      
    
-- Table 11  
  
-- Table 12  
    SELECT A.CD_PROVA, A.CD_PERGUNTA, A.NU_ORDEM  
    FROM dbo.TB_PROVAS_GERADAS A  (nolock)  
    INNER JOIN TB_PROVAS B (nolock) ON B.CD_PROVA = A.CD_PROVA   
    AND B.CD_SALA = @CD_SALA AND B.DT_DIA = @DT_DIA AND B.HR_PROVA = @HR_PROVA  
    AND A.CD_PROVA IN (SELECT A.CD_PROVA  
    FROM dbo.TB_PROVAS A  (nolock)  
    INNER JOIN TB_PC_CONFIGURACOES_PROVAS B (nolock) ON B.CD_CONFIGURACAO_PROVA = A.CD_CONFIGURACAO_PROVA  
    INNER JOIN TB_SALAS C (nolock) ON C.CD_SALA = A.CD_SALA  
    WHERE A.CD_SALA = @CD_SALA AND DT_DIA = @DT_DIA AND HR_PROVA = @HR_PROVA AND DT_INICIO IS NULL AND DT_FIM IS NULL)  
-- Table 12  
  
-- Table 13  
    SELECT CD_IMAGEM, BLOB_IMAGEM FROM TB_IMAGENS_QUESTOES  (nolock)  
    WHERE CD_IMAGEM IN (  
    SELECT C.CD_IMAGEM FROM TB_PROVAS A  (nolock)  
    INNER JOIN TB_PROVAS_GERADAS B (nolock) ON B.CD_PROVA = A.CD_PROVA  
    INNER JOIN TB_PERGUNTAS C (nolock) ON C.CD_PERGUNTA = B.CD_PERGUNTA  
    WHERE A.CD_SALA = @CD_SALA AND A.DT_DIA = @DT_DIA AND A.HR_PROVA = @HR_PROVA AND A.DT_INICIO IS NULL AND A.DT_FIM IS NULL)  
    OR CD_IMAGEM IN  
    (SELECT D.CD_IMAGEM FROM TB_PROVAS A  (nolock)  
    INNER JOIN TB_PROVAS_GERADAS B (nolock) ON B.CD_PROVA = A.CD_PROVA  
    INNER JOIN TB_PERGUNTAS C (nolock) ON C.CD_PERGUNTA = B.CD_PERGUNTA  
    INNER JOIN TB_RESPOSTAS D (nolock) ON D.CD_PERGUNTA = B.CD_PERGUNTA  
    WHERE A.CD_SALA = @CD_SALA AND A.DT_DIA = @DT_DIA AND A.HR_PROVA = @HR_PROVA AND A.DT_INICIO IS NULL AND A.DT_FIM IS NULL)  
-- Table 13  
  
-- TABLE 14  
 SELECT * FROM TB_AGENDAS_RENACHS (nolock) where 1=2  
-- TABLE 14  
  
END
GO


PRINT N'Creating [dbo].[SP_JOB_ENVIAR_RESULTADOS_BALSAS]...';


GO
CREATE procedure dbo.SP_JOB_ENVIAR_RESULTADOS_BALSAS  
(  
 @DT_DIA smalldatetime  
, @HR_PROVA varchar(5)  
, @CD_SALA int  
, @NU_RENACH bigint  
, @NU_CPF bigint  
)  
  
------------------------------------------------------------------------  
-- SP_JOB_ENVIAR_RESULTADOS  
--  Data: 13/03/2009  
------------------------------------------------------------------------  
--  Objetivo:   
--   Envia os resultas para o Banco de dados do site.  
--  Desenvolvedor: Thiago Y. Yamashiro  
--  
------------------------------------------------------------------------  
--  Histórico de revisões    
------------------------------------------------------------------------  
--  Data:  
--        [data da revisao da procedure]  
--  Desenvolvedor:  
--        [nome do desenvolvedor]  
--  Descricao:  
--        [descricao da alteracao]  
------------------------------------------------------------------------  
as  
begin  
  
 -- ( Início ) - Declara variáveis auxiliares ...  
 declare @DT_EVENTO datetime  
   
 set @DT_EVENTO = getdate()  
 -- ( Fim ) - Declara variáveis auxiliares .   
  
 -- ( Início ) - Declara tabelas temporárias ...  
 declare @TB_HISTORICOS_PROVAS table  
 (  
  CD_PROVA bigint  
 , CD_PERGUNTA int  
 , CD_RESPOSTA_CANDIDATO bigint  
 , DT_EVENTO_CLIQUE datetime  
 )  
   
   
 declare @TB_PROVAS_GERADAS table  
 (  
  CD_PROVA bigint  
 , CD_PERGUNTA int  
 , CD_RESPOSTA_CANDIDATO int  
 , NU_ORDEM int   
 )  
   
 declare @TB_PROVAS table   
 (  
  CD_PROVA bigint  
 , CD_CONFIGURACAO_PROVA int  
 , NU_RENACH bigint  
 , NU_CPF bigint  
 , DT_INICIO datetime  
 , DT_FIM datetime  
 , CD_IDENTIFICADOR_COMPUTADOR int  
 , CD_USUARIO bigint  
 , DT_DIA smalldatetime  
 , HR_PROVA char(5)  
 , CD_SALA int  
 , CD_EXAMINADOR int  
 , CD_EXAMINADOR_SEARCH_01 varchar(11)  
 , CD_EXAMINADOR_SEARCH_02 varchar (11)  
 )  
 -- ( Fim ) - Declara tabelas temporárias .  
   
 -- ( Início ) - Alimenta tabelas temporárias ...   
 INSERT INTO @TB_PROVAS   
 (  
  CD_PROVA   
 , CD_CONFIGURACAO_PROVA   
 , NU_RENACH   
 , NU_CPF   
 , DT_INICIO   
 , DT_FIM   
 , CD_IDENTIFICADOR_COMPUTADOR   
 , CD_USUARIO   
 , DT_DIA   
 , HR_PROVA   
 , CD_SALA   
 , CD_EXAMINADOR   
 , CD_EXAMINADOR_SEARCH_01   
 , CD_EXAMINADOR_SEARCH_02   
 )   
 select  
  CD_PROVA   
 , CD_CONFIGURACAO_PROVA   
 , NU_RENACH   
 , NU_CPF   
 , DT_INICIO   
 , DT_FIM   
 , CD_IDENTIFICADOR_COMPUTADOR   
 , CD_USUARIO   
 , DT_DIA   
 , HR_PROVA   
 , CD_SALA   
 , CD_EXAMINADOR   
 , CD_EXAMINADOR_SEARCH_01   
 , CD_EXAMINADOR_SEARCH_02   
 from  
  BALSAS.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS   
 where   
  DT_DIA = @DT_DIA  
 and HR_PROVA = @HR_PROVA  
 and CD_SALA = @CD_SALA  
 and NU_RENACH = @NU_RENACH  
 and NU_CPF = @NU_CPF    
   
 insert into @TB_HISTORICOS_PROVAS  
 (  
  CD_PROVA  
 , CD_PERGUNTA  
 , CD_RESPOSTA_CANDIDATO  
 , DT_EVENTO_CLIQUE  
 )  
 select  
  A.CD_PROVA  
 , A.CD_PERGUNTA  
 , A.CD_RESPOSTA_CANDIDATO  
 , A.DT_EVENTO_CLIQUE  
 from  
  BALSAS.DB_MA_PROVA_DIGITAL.DBO.TB_HISTORICOS_PROVAS A  
 inner join  
  @TB_PROVAS B  
   on  
    A.CD_PROVA = B.CD_PROVA  
       
 insert into @TB_PROVAS_GERADAS   
 (  
  CD_PROVA   
 , CD_PERGUNTA   
 , CD_RESPOSTA_CANDIDATO   
 , NU_ORDEM   
 )  
 select        
  A.CD_PROVA   
 , A.CD_PERGUNTA   
 , A.CD_RESPOSTA_CANDIDATO   
 , A.NU_ORDEM    
 from  
  BALSAS.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS_GERADAS A  
 inner join  
  @TB_PROVAS B  
   on  
    A.CD_PROVA = B.CD_PROVA   
 -- ( Fim ) - Alimenta tabelas temporárias .   
   
 begin tran RESULTADO  
  
  -- ( Início ) - Transfere os dados do histórico da prova ...  
  insert into TB_HISTORICOS_PROVAS  
  (  
   CD_PROVA  
  , CD_PERGUNTA  
  , CD_RESPOSTA_CANDIDATO  
  , DT_EVENTO_CLIQUE  
  )  
  select  
   A.CD_PROVA  
  , A.CD_PERGUNTA  
  , A.CD_RESPOSTA_CANDIDATO  
  , A.DT_EVENTO_CLIQUE   
  from  
   @TB_HISTORICOS_PROVAS A   
  inner join  
   TB_PROVAS B  
    on  
     A.CD_PROVA = B.CD_PROVA  
  where   
   B.DT_DIA = @DT_DIA  
  and B.HR_PROVA = @HR_PROVA  
  and B.CD_SALA = @CD_SALA  
  and B.NU_RENACH = @NU_RENACH  
  and B.NU_CPF = @NU_CPF  
  and not exists  
   (select C.CD_PROVA, C.CD_PERGUNTA, C.DT_EVENTO_CLIQUE from TB_HISTORICOS_PROVAS C  
    where   
     A.CD_PROVA = C.CD_PROVA  
    and A.CD_PERGUNTA = C.CD_PERGUNTA  
   )   
  
   if @@error <> 0  
    begin   
     rollback tran RESULTADO  
             
     insert into TB_LOG_REPLICACAO (DT_EVENTO, DS_PROCEDURE, DS_EVENTO)  
     values (@DT_EVENTO, 'SP_JOB_ENVIAR_RESULTADOS', 'Cadastra o histórico da prova.')  
       
     insert into TB_LOG_REPLICACAO_REGISTROS (DT_EVENTO, DT_DIA, HR_PROVA, NU_RENACH, NU_CPF, CD_SALA)  
     select @DT_EVENTO, @DT_DIA, @HR_PROVA, @NU_RENACH, @NU_CPF, @CD_SALA   
  
     return -1  
    end    
  -- ( Fim ) - Transfere os dados do histórico da prova .     
  
  -- ( Início ) - Atualiza as respostas do candidato ...  
  update TB_PROVAS_GERADAS  
  set  
   CD_RESPOSTA_CANDIDATO = B.CD_RESPOSTA_CANDIDATO  
  from  
   TB_PROVAS_GERADAS A  
  inner join  
   @TB_PROVAS_GERADAS B  
   on  
    A.CD_PROVA = B.CD_PROVA  
   and A.CD_PERGUNTA = B.CD_PERGUNTA     
  inner join  
   TB_PROVAS C  
    on  
     A.CD_PROVA = C.CD_PROVA  
  where   
   C.DT_DIA = @DT_DIA  
  and C.HR_PROVA = @HR_PROVA  
  and C.CD_SALA = @CD_SALA  
  and C.NU_RENACH = @NU_RENACH  
  and C.NU_CPF = @NU_CPF    
     
   if @@error <> 0  
    begin         
     rollback tran RESULTADO  
      
     insert into TB_LOG_REPLICACAO (DT_EVENTO, DS_PROCEDURE, DS_EVENTO)  
     values (@DT_EVENTO, 'SP_JOB_ENVIAR_RESULTADOS', 'Atualiza as respostas do candidato.')  
       
     insert into TB_LOG_REPLICACAO_REGISTROS (DT_EVENTO, DT_DIA, HR_PROVA, NU_RENACH, NU_CPF, CD_SALA)  
     select @DT_EVENTO, @DT_DIA, @HR_PROVA, @NU_RENACH, @NU_CPF, @CD_SALA   
  
     return -1  
    end    
  -- ( Fim ) - Atualiza as respostas do candidato .  
   
  -- ( Início ) - Atauliza os dados da prova ...  
  update TB_PROVAS  
  set  
   DT_INICIO = B.DT_INICIO  
  , DT_FIM = B.DT_FIM  
  , CD_IDENTIFICADOR_COMPUTADOR = B.CD_IDENTIFICADOR_COMPUTADOR   
  , CD_USUARIO = B.CD_USUARIO  
  , CD_EXAMINADOR = B.CD_EXAMINADOR  
  , CD_EXAMINADOR_SEARCH_01 = B.CD_EXAMINADOR_SEARCH_01  
  , CD_EXAMINADOR_SEARCH_02 = B.CD_EXAMINADOR_SEARCH_02
  from  
   TB_PROVAS A  
  inner join  
   @TB_PROVAS B  
    on  
     A.DT_DIA = B.DT_DIA  
    and A.HR_PROVA = B.HR_PROVA  
    and A.CD_SALA = B.CD_SALA  
    and A.NU_RENACH = B.NU_RENACH  
    and A.NU_CPF = B.NU_CPF  
  where   
   A.DT_DIA = @DT_DIA  
  and A.HR_PROVA = @HR_PROVA  
  and A.CD_SALA = @CD_SALA  
  and A.NU_RENACH = @NU_RENACH  
  and A.NU_CPF = @NU_CPF   
    
   if @@error <> 0  
    begin         
     rollback tran RESULTADO  
      
     insert into TB_LOG_REPLICACAO (DT_EVENTO, DS_PROCEDURE, DS_EVENTO)  
     values (@DT_EVENTO, 'SP_JOB_ENVIAR_RESULTADOS', 'Atualiza os dados da prova.')  
       
     insert into TB_LOG_REPLICACAO_REGISTROS (DT_EVENTO, DT_DIA, HR_PROVA, NU_RENACH, NU_CPF, CD_SALA)  
     select @DT_EVENTO, @DT_DIA, @HR_PROVA, @NU_RENACH, @NU_CPF, @CD_SALA   
  
     return -1  
    end       
  -- ( Fim ) -Atauliza os dados da prova  .  
  
  -- ( Início ) - Insere na TB_RENACHS_AGENDAS_LOG ...  
  insert into TB_AGENDAS_RENACHS_LOG  
  (  
   DT_DIA  
  , HR_PROVA  
  , CD_SALA  
  , NU_RENACH  
  , NU_CPF  
  )  
  select   
   A.DT_DIA  
  , A.HR_PROVA  
  , A.CD_SALA  
  , A.NU_RENACH  
  , A.NU_CPF  
  from  
   TB_AGENDAS_RENACHS A  
  where   
   A.DT_DIA = @DT_DIA  
  and A.HR_PROVA = @HR_PROVA  
  and A.CD_SALA = @CD_SALA  
  and A.NU_RENACH = @NU_RENACH  
  and A.NU_CPF = @NU_CPF   
  and not exists  
    (select C.DT_DIA, C.HR_PROVA, C.CD_SALA, C.NU_RENACH, C.NU_CPF from TB_AGENDAS_RENACHS_LOG C  
     where   
      A.DT_DIA = C.DT_DIA  
     and A.HR_PROVA = C.HR_PROVA  
     and A.CD_SALA = C.CD_SALA  
     and A.NU_RENACH = C.NU_RENACH  
     and A.NU_CPF = C.NU_CPF  
    )    
  -- ( Fim ) - Insere na TB_RENACHS_AGENDAS_LOG .  
  
 commit tran RESULTADO  
end
GO
PRINT N'Creating [dbo].[SP_JOB_ENVIAR_RESULTADOS_SAO_LUIS]...';


GO
  
CREATE procedure dbo.SP_JOB_ENVIAR_RESULTADOS_SAO_LUIS 
(  
 @DT_DIA smalldatetime  
, @HR_PROVA varchar(5)  
, @CD_SALA int  
, @NU_RENACH bigint  
, @NU_CPF bigint  
)  
  
------------------------------------------------------------------------  
-- SP_JOB_ENVIAR_RESULTADOS  
--  Data: 13/03/2009  
------------------------------------------------------------------------  
--  Objetivo:   
--   Envia os resultas para o Banco de dados do site.  
--  Desenvolvedor: Thiago Y. Yamashiro  
--  
------------------------------------------------------------------------  
--  Histórico de revisões    
------------------------------------------------------------------------  
--  Data:  
--        [data da revisao da procedure]  
--  Desenvolvedor:  
--        [nome do desenvolvedor]  
--  Descricao:  
--        [descricao da alteracao]  
------------------------------------------------------------------------  
as  
begin  
  
 -- ( Início ) - Declara variáveis auxiliares ...  
 declare @DT_EVENTO datetime  
   
 set @DT_EVENTO = getdate()  
 -- ( Fim ) - Declara variáveis auxiliares .   
  
 -- ( Início ) - Declara tabelas temporárias ...  
 declare @TB_HISTORICOS_PROVAS table  
 (  
  CD_PROVA bigint  
 , CD_PERGUNTA int  
 , CD_RESPOSTA_CANDIDATO bigint  
 , DT_EVENTO_CLIQUE datetime  
 )  
   
   
 declare @TB_PROVAS_GERADAS table  
 (  
  CD_PROVA bigint  
 , CD_PERGUNTA int  
 , CD_RESPOSTA_CANDIDATO int  
 , NU_ORDEM int   
 )  
   
 declare @TB_PROVAS table   
 (  
  CD_PROVA bigint  
 , CD_CONFIGURACAO_PROVA int  
 , NU_RENACH bigint  
 , NU_CPF bigint  
 , DT_INICIO datetime  
 , DT_FIM datetime  
 , CD_IDENTIFICADOR_COMPUTADOR int  
 , CD_USUARIO bigint  
 , DT_DIA smalldatetime  
 , HR_PROVA char(5)  
 , CD_SALA int  
 , CD_EXAMINADOR int  
 , CD_EXAMINADOR_SEARCH_01 varchar(11)  
 , CD_EXAMINADOR_SEARCH_02 varchar (11)  
 )  
 -- ( Fim ) - Declara tabelas temporárias .  
   
 -- ( Início ) - Alimenta tabelas temporárias ...   
 INSERT INTO @TB_PROVAS   
 (  
  CD_PROVA   
 , CD_CONFIGURACAO_PROVA   
 , NU_RENACH   
 , NU_CPF   
 , DT_INICIO   
 , DT_FIM   
 , CD_IDENTIFICADOR_COMPUTADOR   
 , CD_USUARIO   
 , DT_DIA   
 , HR_PROVA   
 , CD_SALA   
 , CD_EXAMINADOR   
 , CD_EXAMINADOR_SEARCH_01   
 , CD_EXAMINADOR_SEARCH_02   
 )   
 select  
  CD_PROVA   
 , CD_CONFIGURACAO_PROVA   
 , NU_RENACH   
 , NU_CPF   
 , DT_INICIO   
 , DT_FIM   
 , CD_IDENTIFICADOR_COMPUTADOR   
 , CD_USUARIO   
 , DT_DIA   
 , HR_PROVA   
 , CD_SALA   
 , CD_EXAMINADOR   
 , CD_EXAMINADOR_SEARCH_01   
 , CD_EXAMINADOR_SEARCH_02   
 from  
  SAOLUIZ.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS   
 where   
  DT_DIA = @DT_DIA  
 and HR_PROVA = @HR_PROVA  
 and CD_SALA = @CD_SALA  
 and NU_RENACH = @NU_RENACH  
 and NU_CPF = @NU_CPF    
   
 insert into @TB_HISTORICOS_PROVAS  
 (  
  CD_PROVA  
 , CD_PERGUNTA  
 , CD_RESPOSTA_CANDIDATO  
 , DT_EVENTO_CLIQUE  
 )  
 select  
  A.CD_PROVA  
 , A.CD_PERGUNTA  
 , A.CD_RESPOSTA_CANDIDATO  
 , A.DT_EVENTO_CLIQUE  
 from  
  SAOLUIZ.DB_MA_PROVA_DIGITAL.DBO.TB_HISTORICOS_PROVAS A  
 inner join  
  @TB_PROVAS B  
   on  
    A.CD_PROVA = B.CD_PROVA  
       
 insert into @TB_PROVAS_GERADAS   
 (  
  CD_PROVA   
 , CD_PERGUNTA   
 , CD_RESPOSTA_CANDIDATO   
 , NU_ORDEM   
 )  
 select        
  A.CD_PROVA   
 , A.CD_PERGUNTA   
 , A.CD_RESPOSTA_CANDIDATO   
 , A.NU_ORDEM    
 from  
  SAOLUIZ.DB_MA_PROVA_DIGITAL.DBO.TB_PROVAS_GERADAS A  
 inner join  
  @TB_PROVAS B  
   on  
    A.CD_PROVA = B.CD_PROVA   
 -- ( Fim ) - Alimenta tabelas temporárias .   
   
 begin tran RESULTADO  
  
  -- ( Início ) - Transfere os dados do histórico da prova ...  
  insert into TB_HISTORICOS_PROVAS  
  (  
   CD_PROVA  
  , CD_PERGUNTA  
  , CD_RESPOSTA_CANDIDATO  
  , DT_EVENTO_CLIQUE  
  )  
  select  
   A.CD_PROVA  
  , A.CD_PERGUNTA  
  , A.CD_RESPOSTA_CANDIDATO  
  , A.DT_EVENTO_CLIQUE   
  from  
   @TB_HISTORICOS_PROVAS A   
  inner join  
   TB_PROVAS B  
    on  
     A.CD_PROVA = B.CD_PROVA  
  where   
   B.DT_DIA = @DT_DIA  
  and B.HR_PROVA = @HR_PROVA  
  and B.CD_SALA = @CD_SALA  
  and B.NU_RENACH = @NU_RENACH  
  and B.NU_CPF = @NU_CPF  
  and not exists  
   (select C.CD_PROVA, C.CD_PERGUNTA, C.DT_EVENTO_CLIQUE from TB_HISTORICOS_PROVAS C  
    where   
     A.CD_PROVA = C.CD_PROVA  
    and A.CD_PERGUNTA = C.CD_PERGUNTA  
   )   
  
   if @@error <> 0  
    begin   
     rollback tran RESULTADO  
             
     insert into TB_LOG_REPLICACAO (DT_EVENTO, DS_PROCEDURE, DS_EVENTO)  
     values (@DT_EVENTO, 'SP_JOB_ENVIAR_RESULTADOS', 'Cadastra o histórico da prova.')  
       
     insert into TB_LOG_REPLICACAO_REGISTROS (DT_EVENTO, DT_DIA, HR_PROVA, NU_RENACH, NU_CPF, CD_SALA)  
     select @DT_EVENTO, @DT_DIA, @HR_PROVA, @NU_RENACH, @NU_CPF, @CD_SALA   
  
     return -1  
    end    
  -- ( Fim ) - Transfere os dados do histórico da prova .     
  
  -- ( Início ) - Atualiza as respostas do candidato ...  
  update TB_PROVAS_GERADAS  
  set  
   CD_RESPOSTA_CANDIDATO = B.CD_RESPOSTA_CANDIDATO  
  from  
   TB_PROVAS_GERADAS A  
  inner join  
   @TB_PROVAS_GERADAS B  
   on  
    A.CD_PROVA = B.CD_PROVA  
   and A.CD_PERGUNTA = B.CD_PERGUNTA     
  inner join  
   TB_PROVAS C  
    on  
     A.CD_PROVA = C.CD_PROVA  
  where   
   C.DT_DIA = @DT_DIA  
  and C.HR_PROVA = @HR_PROVA  
  and C.CD_SALA = @CD_SALA  
  and C.NU_RENACH = @NU_RENACH  
  and C.NU_CPF = @NU_CPF    
     
   if @@error <> 0  
    begin         
     rollback tran RESULTADO  
      
     insert into TB_LOG_REPLICACAO (DT_EVENTO, DS_PROCEDURE, DS_EVENTO)  
     values (@DT_EVENTO, 'SP_JOB_ENVIAR_RESULTADOS', 'Atualiza as respostas do candidato.')  
       
     insert into TB_LOG_REPLICACAO_REGISTROS (DT_EVENTO, DT_DIA, HR_PROVA, NU_RENACH, NU_CPF, CD_SALA)  
     select @DT_EVENTO, @DT_DIA, @HR_PROVA, @NU_RENACH, @NU_CPF, @CD_SALA   
  
     return -1  
    end    
  -- ( Fim ) - Atualiza as respostas do candidato .  
   
  -- ( Início ) - Atauliza os dados da prova ...  
  update TB_PROVAS  
  set  
   DT_INICIO = B.DT_INICIO  
  , DT_FIM = B.DT_FIM  
  , CD_IDENTIFICADOR_COMPUTADOR = B.CD_IDENTIFICADOR_COMPUTADOR   
  , CD_USUARIO = B.CD_USUARIO  
  , CD_EXAMINADOR = B.CD_EXAMINADOR  
  , CD_EXAMINADOR_SEARCH_01 = B.CD_EXAMINADOR_SEARCH_01  
  , CD_EXAMINADOR_SEARCH_02 = B.CD_EXAMINADOR_SEARCH_02
  from  
   TB_PROVAS A  
  inner join  
   @TB_PROVAS B  
    on  
     A.DT_DIA = B.DT_DIA  
    and A.HR_PROVA = B.HR_PROVA  
    and A.CD_SALA = B.CD_SALA  
    and A.NU_RENACH = B.NU_RENACH  
    and A.NU_CPF = B.NU_CPF  
  where   
   A.DT_DIA = @DT_DIA  
  and A.HR_PROVA = @HR_PROVA  
  and A.CD_SALA = @CD_SALA  
  and A.NU_RENACH = @NU_RENACH  
  and A.NU_CPF = @NU_CPF   
    
   if @@error <> 0  
    begin         
     rollback tran RESULTADO  
      
     insert into TB_LOG_REPLICACAO (DT_EVENTO, DS_PROCEDURE, DS_EVENTO)  
     values (@DT_EVENTO, 'SP_JOB_ENVIAR_RESULTADOS', 'Atualiza os dados da prova.')  
       
     insert into TB_LOG_REPLICACAO_REGISTROS (DT_EVENTO, DT_DIA, HR_PROVA, NU_RENACH, NU_CPF, CD_SALA)  
     select @DT_EVENTO, @DT_DIA, @HR_PROVA, @NU_RENACH, @NU_CPF, @CD_SALA   
  
     return -1  
    end       
  -- ( Fim ) -Atauliza os dados da prova  .  
  
  -- ( Início ) - Insere na TB_RENACHS_AGENDAS_LOG ...  
  insert into TB_AGENDAS_RENACHS_LOG  
  (  
   DT_DIA  
  , HR_PROVA  
  , CD_SALA  
  , NU_RENACH  
  , NU_CPF  
  )  
  select   
   A.DT_DIA  
  , A.HR_PROVA  
  , A.CD_SALA  
  , A.NU_RENACH  
  , A.NU_CPF  
  from  
   TB_AGENDAS_RENACHS A  
  where   
   A.DT_DIA = @DT_DIA  
  and A.HR_PROVA = @HR_PROVA  
  and A.CD_SALA = @CD_SALA  
  and A.NU_RENACH = @NU_RENACH  
  and A.NU_CPF = @NU_CPF   
  and not exists  
    (select C.DT_DIA, C.HR_PROVA, C.CD_SALA, C.NU_RENACH, C.NU_CPF from TB_AGENDAS_RENACHS_LOG C  
     where   
      A.DT_DIA = C.DT_DIA  
     and A.HR_PROVA = C.HR_PROVA  
     and A.CD_SALA = C.CD_SALA  
     and A.NU_RENACH = C.NU_RENACH  
     and A.NU_CPF = C.NU_CPF  
    )    
  -- ( Fim ) - Insere na TB_RENACHS_AGENDAS_LOG .  
  
 commit tran RESULTADO  
end
GO


