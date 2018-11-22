





INSERT INTO TB_AQUISICOES        
 (        
  NU_CPF        
 ,  ID_DOCUMENTO        
 ,  ID_TIPO_DOCUMENTO        
 ,  DT_AQUISICAO        
 ,  CD_UNIDADE_CAV        
 , NM_UNIDADE_CAV        
 ,  LOGIN        
 ,  ID_OPERADOR        
 ,  NM_OPERADOR        
 ,  CD_GRUPO        
 ,  CD_STATUS_OPERADOR        
 ,  DT_ENTRADA        
 )          
 SELECT        
  NU_CPF        
 ,  ID_DOCUMENTO        
 ,  ID_TIPO_DOCUMENTO        
 ,  DT_AQUISICAO        
 ,  CD_UNIDADE_CAV        
 , NM_UNIDADE_CAV        
 ,  LOGIN        
 ,  ID_OPERADOR        
 ,  NM_OPERADOR        
 ,  CD_GRUPO        
 ,  CD_STATUS_OPERADOR        
 ,  DT_ENTRADA          
 FROM        
  ESPIRITOSANTO.DB_SERVIDOR_BLOB_ES_P.DBO.TB_AQUISICOES AS A        
 WHERE EXISTS         
 (        
  SELECT TOP 1 1         
  FROM #t AS C         
  WHERE         
   A.ID_DOCUMENTO = C.ID_DOCUMENTO        
  AND A.NU_CPF = C.NU_CPF         
  AND A.ID_TIPO_DOCUMENTO = C.ID_TIPO_DOCUMENTO        
  AND A.DT_AQUISICAO = C.DT_AQUISICAO     
  and C.Id = @count    
 )    
 and not exists   
 (        
  SELECT TOP 1 1         
  FROM DB_SERVIDOR_BLOB_ES_P.DBO.TB_AQUISICOES  AS C         
  WHERE         
   A.ID_DOCUMENTO = C.ID_DOCUMENTO        
  AND A.NU_CPF = C.NU_CPF         
  AND A.ID_TIPO_DOCUMENTO = C.ID_TIPO_DOCUMENTO        
  AND A.DT_AQUISICAO = C.DT_AQUISICAO         
 )    

INSERT INTO TB_AQUISICOES_BLOBS
(
    NU_CPF        
 ,  ID_DOCUMENTO        
 ,  ID_TIPO_DOCUMENTO        
 ,  DT_AQUISICAO        
 ,  ID_SUBTIPO_BLOB 
 ,  BLOB_CONTEUDO    
)
 SELECT         
  NU_CPF        
 ,  ID_DOCUMENTO        
 ,  ID_TIPO_DOCUMENTO        
 ,  DT_AQUISICAO        
 ,  ID_SUBTIPO_BLOB 
 ,  BLOB_CONTEUDO        
   FROM           
  ESPIRITOSANTO.DB_SERVIDOR_BLOB_ES_P.DBO.TB_AQUISICOES_BLOBS AS A        
 WHERE EXISTS         
 (        
  SELECT TOP 1 1         
  FROM #t  AS C         
  WHERE         
   A.ID_DOCUMENTO = C.ID_DOCUMENTO        
  AND A.NU_CPF = C.NU_CPF         
  AND A.ID_TIPO_DOCUMENTO = C.ID_TIPO_DOCUMENTO        
  AND A.DT_AQUISICAO = C.DT_AQUISICAO     
  AND  C.Id = @count       
 )      
 AND NOT EXISTS  
 (  
  SELECT TOP 1 1   
  FROM DB_SERVIDOR_BLOB_ES_P.DBO.TB_AQUISICOES_BLOBS  AS D  
  WHERE  
   A.ID_DOCUMENTO = D.ID_DOCUMENTO        
  AND A.NU_CPF = D.NU_CPF         
  AND A.ID_TIPO_DOCUMENTO = D.ID_TIPO_DOCUMENTO        
  AND A.DT_AQUISICAO = D.DT_AQUISICAO  
  AND A.ID_SUBTIPO_BLOB = D.ID_SUBTIPO_BLOB  
 )     
 and (id_subtipo_blob between 2001 and 2002 or id_subtipo_blob between 6001 and 6010)  
 
  