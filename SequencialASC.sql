CREATE or alter  FUNCTION dbo.GetNums(@low AS BIGINT, @high AS BIGINT) RETURNS TABLE
AS
RETURN
  WITH
    L0   AS (SELECT c FROM (VALUES(1),(1)) AS D(c)),
    L1   AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
    L2   AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
    L3   AS (SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
    L4   AS (SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
    L5   AS (SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
    Nums AS (SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS rownum
            FROM L5)
  SELECT TOP(@high - @low + 1) @low + rownum - 1 AS n
  FROM Nums
  ORDER BY rownum;
GO
CREATE OR ALTER  FUNCTION fnCalculaModulo11(@VALOR varchar(60))  
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
-- Data                  Desenvolvedor                   Descrição  Documento  
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
      SET @SOMA = @SOMA +  dbo.fnCalculaModulo11(  (Convert(int, SubString(@VALOR, @CONTADOR, 1)) * @PESO)  )
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
GO
 CREATE TABLE #Valores 
(
	ValorDecimal int
,	ValorString char(1)
)
/******tabela ASC ************/
INSERT INTO #vALORES SELECT 	32 		,	' '
INSERT INTO #vALORES SELECT  	33 		,	'!'
INSERT INTO #vALORES SELECT  	34 		,	'"'
INSERT INTO #vALORES SELECT  	35 		,	'#'
INSERT INTO #vALORES SELECT  	36 		,	'$'
INSERT INTO #vALORES SELECT  	37 		,	'%'
INSERT INTO #vALORES SELECT  	38 		,	'&'
INSERT INTO #vALORES SELECT  	39 		,	char(39)
INSERT INTO #vALORES SELECT  	40 		,	'('
INSERT INTO #vALORES SELECT  	41 		,	')'
INSERT INTO #vALORES SELECT  	42 		,	'*'
INSERT INTO #vALORES SELECT  	43 		,	'+'
INSERT INTO #vALORES SELECT  	44 		,	','
INSERT INTO #vALORES SELECT  	45 		,	'-'
INSERT INTO #vALORES SELECT  	46 		,	'.'
INSERT INTO #vALORES SELECT  	47 		,	'/'
INSERT INTO #vALORES SELECT  	48 		,	'0'
INSERT INTO #vALORES SELECT  	49 		,	'1'
INSERT INTO #vALORES SELECT  	50 		,	'2'
INSERT INTO #vALORES SELECT  	51 		,	'3'
INSERT INTO #vALORES SELECT  	52 		,	'4'
INSERT INTO #vALORES SELECT  	53 		,	'5'
INSERT INTO #vALORES SELECT  	54 		,	'6'
INSERT INTO #vALORES SELECT  	55 		,	'7'
INSERT INTO #vALORES SELECT  	56 		,	'8'
INSERT INTO #vALORES SELECT  	57 		,	'9'
INSERT INTO #vALORES SELECT  	58 		,	':'
INSERT INTO #vALORES SELECT  	59 		,	';'
INSERT INTO #vALORES SELECT  	60 		,	'<'
INSERT INTO #vALORES SELECT  	61 		,	'='
INSERT INTO #vALORES SELECT  	62 		,	'>'
INSERT INTO #vALORES SELECT  	63 		,	'?'
INSERT INTO #vALORES SELECT  	64 		,	'@'
INSERT INTO #vALORES SELECT  	65 		,	'A'
INSERT INTO #vALORES SELECT  	66 		,	'B'
INSERT INTO #vALORES SELECT  	67 		,	'C'
INSERT INTO #vALORES SELECT  	68 		,	'D'
INSERT INTO #vALORES SELECT  	69 		,	'E'
INSERT INTO #vALORES SELECT  	70 		,	'F'
INSERT INTO #vALORES SELECT  	71 		,	'G'
INSERT INTO #vALORES SELECT  	72 		,	'H'
INSERT INTO #vALORES SELECT  	73 		,	'I'
INSERT INTO #vALORES SELECT  	74 		,	'J'
INSERT INTO #vALORES SELECT  	75 		,	'K'
INSERT INTO #vALORES SELECT  	76 		,	'L'
INSERT INTO #vALORES SELECT  	77 		,	'M'
INSERT INTO #vALORES SELECT  	78 		,	'N'
INSERT INTO #vALORES SELECT  	79 		,	'O'
INSERT INTO #vALORES SELECT  	80 		,	'P'
INSERT INTO #vALORES SELECT  	81 		,	'Q'
INSERT INTO #vALORES SELECT  	82 		,	'R'
INSERT INTO #vALORES SELECT  	83 		,	'S'
INSERT INTO #vALORES SELECT  	84 		,	'T'
INSERT INTO #vALORES SELECT  	85 		,	'U'
INSERT INTO #vALORES SELECT  	86 		,	'V'
INSERT INTO #vALORES SELECT  	87 		,	'W'
INSERT INTO #vALORES SELECT  	88 		,	'X'
INSERT INTO #vALORES SELECT  	89 		,	'Y'
INSERT INTO #vALORES SELECT  	90 		,	'Z'
INSERT INTO #vALORES SELECT  	91 		,	'['
INSERT INTO #vALORES SELECT  	92 		,	'\'
INSERT INTO #vALORES SELECT  	93 		,	']'
INSERT INTO #vALORES SELECT  	94 		,	'^'
INSERT INTO #vALORES SELECT  	95 		,	'_'
INSERT INTO #vALORES SELECT  	96 		,	'`'
INSERT INTO #vALORES SELECT  	97 		,	'a'
INSERT INTO #vALORES SELECT  	98 		,	'b'
INSERT INTO #vALORES SELECT  	99 		,	'c'
INSERT INTO #vALORES SELECT  	100 	,	'd'
INSERT INTO #vALORES SELECT  	101 	,	'e'
INSERT INTO #vALORES SELECT  	102 	,	'f'
INSERT INTO #vALORES SELECT  	103 	,	'g'
INSERT INTO #vALORES SELECT  	104 	,	'h'
INSERT INTO #vALORES SELECT  	105 	,	'i'
INSERT INTO #vALORES SELECT  	106 	,	'j'
INSERT INTO #vALORES SELECT  	107 	,	'k'
INSERT INTO #vALORES SELECT  	108 	,	'l'
INSERT INTO #vALORES SELECT  	109 	,	'm'
INSERT INTO #vALORES SELECT  	110 	,	'n'
INSERT INTO #vALORES SELECT  	111 	,	'o'
INSERT INTO #vALORES SELECT  	112 	,	'p'
INSERT INTO #vALORES SELECT  	113 	,	'q'
INSERT INTO #vALORES SELECT  	114 	,	'r'
INSERT INTO #vALORES SELECT  	115 	,	's'
INSERT INTO #vALORES SELECT  	116 	,	't'
INSERT INTO #vALORES SELECT  	117 	,	'u'
INSERT INTO #vALORES SELECT  	118 	,	'v'
INSERT INTO #vALORES SELECT  	119 	,	'w'
INSERT INTO #vALORES SELECT  	120 	,	'x'
INSERT INTO #vALORES SELECT  	121 	,	'y'
INSERT INTO #vALORES SELECT  	122 	,	'z'
INSERT INTO #vALORES SELECT  	123 	,	'{'
INSERT INTO #vALORES SELECT  	124 	,	'|'
INSERT INTO #vALORES SELECT  	125 	,	'}'
INSERT INTO #vALORES SELECT  	126 	,	'~' 
DECLARE @EspelhoInicial int = 352100
DECLARE @EspelhoFinal	int = 450000
;with NumerosEspelhos
AS
(
	select  
		n as NumeroInteiro  
	from 
		dbo.GetNums (@EspelhoInicial ,@EspelhoFinal - 1)
)
select
	ROW_NUMBER()  over (order by NumeroInteiro) as Id
,	cast(NumeroInteiro as varchar(50))   AS 	ValorEspelho
INTO #Espelhos
from
	NumerosEspelhos
alter table #Espelhos alter column  id int not null
create clustered index Id_pk on #Espelhos (id)
declare @table  table
 (
	Id  int  identity(1,1) not null  primary key 
,	ValorEspelhoRg varchar(50)
 )
 declare @i int = 1 
DECLARE @ULTIMALETRA INT = ASCII('O')
while @i <= 20000--(select max(id) from #Espelhos)
begin
	insert into @table (ValorEspelhoRg)
	select 
		ValorEspelho  
	+  (select ValorString  from  #vALORES where ValorDecimal = @ULTIMALETRA) + '*'
	from 
		#Espelhos
	where
		Id = @i
	
	SELECT @ULTIMALETRA = IIF(@ULTIMALETRA = (SELECT MAX(ValorDecimal) FROM #vALORES), (SELECT MIN(ValorDecimal) FROM #vALORES), @ULTIMALETRA + 1   )
	set @i = @i + 1 
end
select ValorEspelhoRg from  @table order by Id