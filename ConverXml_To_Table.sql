

SELECT  
       Tbl.Col.value('IdInvernadero[1]', 'smallint'),  
       Tbl.Col.value('IdProducto[1]', 'smallint'),  
       Tbl.Col.value('IdCaracteristica1[1]', 'smallint'),
       Tbl.Col.value('IdCaracteristica2[1]', 'smallint'),
       Tbl.Col.value('Cantidad[1]', 'int'),
       Tbl.Col.value('Folio[1]', 'varchar(7)')
FROM   
    @xml.nodes('//row') Tbl(Col)  




DECLARE @tempTable TABLE 
(
    userId INT,
    userName NVARCHAR(50),
    password NVARCHAR(50)
)
DECLARE @xml XML
SET @xml='
<row userId="67" userName="Kenny1" password="1234" />
<row userId="80" userName="Kenny2" password="5678" />'

INSERT INTO @tempTable
SELECT 
    Tbl.Col.value('@userId', 'INT')
,   Tbl.Col.value('@userName', 'NVARCHAR(50)')
,    Tbl.Col.value('@password', 'NVARCHAR(50)')
FROM 
    @xml.nodes('//row') Tbl(Col)
--See the table
SELECT * FROM @tempTable






select * from [dbo] .[BlobPe_2]



SELECT 
        CAST(ID_DOCUMENTO AS varchar (10))
+      '_'
+      CAST (id_subtipo_blob AS varchar( 10))
+      '.JPG'  
,      blob_conteudo
FROM 
       [BlobPe] WHERE  id_documento = 62706306


SELECT 
        CAST(ID_DOCUMENTO AS varchar (10))
+      '_'
+      CAST (id_subtipo_blob AS varchar( 10))
+      '.JPG'  
,      blob_conteudo
FROM 
       [BlobPe_2]
WHERE 
       id_documento = 62706306

select *    into tb_90001 from recife. db_servidor_blob_pe_p.dbo .tb_aquisicoes_blobs  as A
where EXISTS (SELECT TOP 1 1 FROM  AgendamentosParaProvaApagar AS C
        WHERE A. NU_CPF = C .CPF
        AND A. ID_DOCUMENTO   =      C .RENACH      
        ) and id_subtipo_blob = 90001







CREATE TABLE XML_TESTE
(
       CAMPO XML
)

DELETE XML_TESTE
INSERT INTO XML_TESTE
select (
               select 
                     nu_cpf                                          
               ,      id_documento                             
               ,      ID_TIPO_DOCUMENTO                        
               ,      DT_AQUISICAO                             
               ,      dt_entrada                                      
               ,      id_subtipo_blob
               ,      blob_conteudo    
               from
                     DB_AL_PROVA_PRATICA .dbo. TEMP
                      FOR XML RAW ( 'Aquisicao')
                            ,      ROOT ( 'Aquisicoes' )
                            ,      BINARY BASE64
               ) as X


 SELECT * FROM TEMP



 EXEC master..xp_cmdshell 'BCP DB_AL_PROVA_PRATICA.dbo.TEMP OUT C:\BackupDouglasPorto\@@BAK_S\BiometriasPE.xml -T -c'
 
DECLARE
       @XML AS XML
,      @hDoc AS INT
,      @SQL NVARCHAR ( MAX)
              
SELECT @XML = CAMPO FROM XML_TESTE
EXEC sp_xml_preparedocument @hDoc OUTPUT , @XML
SELECT *
--into BAIXAR 
FROM OPENXML (@hDoc, 'Aquisicoes/Aquisicao')
WITH
(
       nu_cpf                      bigint                      '@nu_cpf'
,      id_documento          bigint                '@id_documento'
,      id_tipo_documento    varchar( 100)   '@ID_TIPO_DOCUMENTO'
,      dt_aquisicao          datetime             '@DT_AQUISICAO'
,      dt_entrada                  datetime             '@dt_entrada'
,      id_subtipo_blob             bigint                '@id_subtipo_blob'
,      blob_conteudo               VARCHAR(max )  '@blob_conteudo'                   
)                                                                          
EXEC sp_xml_removedocument @hDoc



 


 

 drop table tb_xml

 create table tb_xml
(
       XMLData XML
)

delete TB_XML

select * from TB_XML
insert into TB_XML
select (
               select 
                     nu_cpf                                          
               ,      id_documento                             
               ,      ID_TIPO_DOCUMENTO                        
               ,      DT_AQUISICAO                             
               ,      dt_entrada                                      
               ,      id_subtipo_blob
               ,      blob_conteudo
               from
                     DB_AL_PROVA_PRATICA .dbo. [BlobPe_2]
                      FOR XML RAW ( 'Aquisicao')
                            ,      ROOT ( 'Aquisicoes' )
                            ,      BINARY BASE64
               ) as X


EXEC master ..xp_cmdshell 'BCP DB_AL_PROVA_PRATICA.dbo.TB_XML OUT C:\BackupDouglasPorto\@@BAK_S\BiometriasPe2015.xml -T -c'




select cast (N'' as xml ).value( 'xs:base64Binary(sql:column("t.blob"))' , 'varbinary(max)') as sql_handle





create table #tb_xml
(
       XMLData XML
)
--(inicio) - Cria Tabela para guardar o XML que será importado...
                     

--(inicio) - importa XML da Maquina Central...
DECLARE @xmlData XML
SET @xmlData =
(
        SELECT * FROM OPENROWSET ( BULK 'C:\BackupDouglasPorto\@@BAK_S\BiometriasPE2015.xml' , SINGLE_CLOB ) AS xmlData
)
       
insert into #tb_xml
SELECT @xmlData



DECLARE
       @XML AS XML
,      @hDoc AS INT
,      @SQL NVARCHAR ( MAX)
              
SELECT @XML = XMLData FROM #tb_xml
                     

EXEC sp_xml_preparedocument @hDoc OUTPUT , @XML
SELECT *   
into #Aquisicoes
FROM OPENXML (@hDoc, 'Aquisicoes/Aquisicao')
WITH
(
       nu_cpf                      bigint                      '@nu_cpf'
,      id_documento          bigint                '@id_documento'
,      id_tipo_documento    varchar( 100)   '@ID_TIPO_DOCUMENTO'
,      dt_aquisicao          datetime             '@DT_AQUISICAO'
,      dt_entrada                  datetime             '@dt_entrada'
,      id_subtipo_blob             bigint                '@id_subtipo_blob'
,      blob_conteudo               VARCHAR(max )  '@blob_conteudo'                   
)                                                                          
EXEC sp_xml_removedocument @hDoc  



select 

cast(N'' as xml).value ('xs:base64Binary(sql:column("t.blob"))', 'varbinary(max)')
from #Aquisicoes




select
       nu_cpf                     
,      id_documento         
,      id_tipo_documento    
,      dt_aquisicao         
,      dt_entrada                 
,      id_subtipo_blob      
,      cast (N'' as xml ).value( 'xs:base64Binary(sql:column("blob_conteudo"))' , 'varbinary(max)') as sql_handle  
,      null
from
       #Aquisicoes








DECLARE
       @XML AS XML
,      @hDoc AS INT
,      @SQL NVARCHAR ( MAX)
              
SELECT @XML = CAMPO 
FROM XML_TESTE       
EXEC sp_xml_preparedocument @hDoc OUTPUT , @XML
SELECT *
--INTO tEMP
FROM OPENXML (@hDoc, 'Aquisicoes/Aquisicao')
WITH
(
       nu_cpf                      bigint                      '@nu_cpf'
,      id_documento          bigint                '@id_documento'
,      id_tipo_documento    varchar( 100)   '@ID_TIPO_DOCUMENTO'
,      dt_aquisicao          datetime             '@DT_AQUISICAO'
,      dt_entrada                  datetime             '@dt_entrada'
,      id_subtipo_blob             bigint                '@id_subtipo_blob'
,      blob_conteudo               VARCHAR(MAX )  '@blob_conteudo'                   
)                                                                          
EXEC sp_xml_removedocument @hDoc


SELECT * FROM tEMP

select
        cast(N'' as xml).value ('xs:base64Binary(sql:column("t.blob"))', 'varbinary(max)') as sql_handle
from
       tEMP as t;
 