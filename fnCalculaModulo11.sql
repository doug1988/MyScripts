use DbVotosCFM
go
CREATE or alter  FUNCTION fnCalculaModulo11(@VALOR varchar(60))
RETURNS CHAR(1)
AS
---------------------------------------------------------------------------------------------
-- DOCUMENTO ORIGEM DA SUB-ROTINA: 
---------------------------------------------------------------------------------------------
-- CALCULADV
-- Data: 11/06/2007 
---------------------------------------------------------------------------------------------
-- OBJETIVO: Calcula dígito verificador do RENAVAM
--
-- DESENVOLVEDOR: Fabio Famiglietti ( Thomas Greg & Sons Ltda. )
--
-- NOTAS:
---------------------------------------------------------------------------------------------
-- HISTÓRICO DE REVISÕES
---------------------------------------------------------------------------------------------
-- Data                  Desenvolvedor                   Descrição		Documento
---------------------------------------------------------------------------------------------
BEGIN
  DECLARE
     @SOMA     INT,
     @CONTADOR INT,
     @PESO     INT,
     @DIGITO   INT,
     @RETORNO  CHAR(1),
     @BASE     INT

  SET @SOMA  = 0
  SET @PESO  = 2
  SET @BASE  = 9
  SET @CONTADOR = Len(@VALOR)

  LOOP:
    BEGIN
      SET @SOMA = @SOMA + (Convert(int, SubString(@VALOR, @CONTADOR, 1)) * @PESO)
      IF (@PESO < @BASE)
        SET @PESO = @PESO + 1
      ELSE
        SET @PESO = 2
      SET @CONTADOR = @CONTADOR-1
    END
  IF @CONTADOR >= 1 GOTO LOOP

  SET @DIGITO = 11 - (@SOMA % 11)
  IF (@DIGITO > 9) SET @DIGITO = 0
  SET @RETORNO = @DIGITO

  RETURN @RETORNO
END

--GRANT EXECUTE ON fnCalculaModulo11 TO SIMP

