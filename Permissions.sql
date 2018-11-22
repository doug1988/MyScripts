-- Identificando Permissões
USE --$$$Database
GO

Execute AS LOGIN = 'maimpressaoett'   --<------- Digite aqui o nome do usuario !!
SELECT * FROM fn_my_permissions(NULL, 'Database') ORDER BY subentity_name, permission_name ;
REVERT;
GO

-- Exemplo com os direitos na instancia:
EXECUTE AS LOGIN = 'maimpressaoett' ; --<------- Digite aqui o nome do usuario !!
SELECT * FROM fn_my_permissions(NULL, 'SERVER');
GO

-- Exemplo com os direitos nas Tabelas:
SELECT * FROM fn_my_permissions('dbo.Paises' , 'OBJECT' )
ORDER BY subentity_name, permission_name ;
GO