IF Object_Id('dbo.DatabaseObjects') IS NOT NULL
       DROP function dbo.DatabaseObjects
    GO
    CREATE FUNCTION dbo.DatabaseObjects
    /**
    Summary: >
      lists out the full names, schemas and (where appropriate)
      the owner of the object.
    Author: PhilFactor
    Date: 10/9/2017
    Examples:
       - Select * from dbo.DatabaseObjects('2123154609,960722475,1024722703')
    Returns: >
      A table with the id, name of object and so on.
            **/
      (
      @ListOfObjectIDs varchar(max)
      )
    RETURNS TABLE
     --WITH ENCRYPTION|SCHEMABINDING, ..
    AS
    RETURN
      (
      SELECT 
	    object_id,
        Schema_Name(schema_id) + '.' +
		  Coalesce(Object_Name(parent_object_id) + '.', '') + name AS name
        FROM sys.objects AS ob
          INNER JOIN OpenJson(N'[' + @ListOfObjectIDs + N']')
            ON Convert(INT, Value) = ob.object_id
      )


IF EXISTS (SELECT * FROM sys.types WHERE name LIKE 'Hierarchy')
    SET NOEXEC On
  go
  CREATE TYPE dbo.Hierarchy AS TABLE
  /*Markup languages such as JSON and XML all represent object data as hierarchies. Although it looks very different to the entity-relational model, it isn't. It is rather more a different perspective on the same model. The first trick is to represent it as a Adjacency list hierarchy in a table, and then use the contents of this table to update the database. This Adjacency list is really the Database equivalent of any of the nested data structures that are used for the interchange of serialized information with the application, and can be used to create XML, OSX Property lists, Python nested structures or YAML as easily as JSON.
  Adjacency list tables have the same structure whatever the data in them. This means that you can define a single Table-Valued  Type and pass data structures around between stored procedures. However, they are best held at arms-length from the data, since they are not relational tables, but something more like the dreaded EAV (Entity-Attribute-Value) tables. Converting the data from its Hierarchical table form will be different for each application, but is easy with a CTE. You can, alternatively, convert the hierarchical table into XML and interrogate that with XQuery
  */
  (
     element_id INT primary key, /* internal surrogate primary key gives the order of parsing and the list order */
     sequenceNo [int] NULL, /* the place in the sequence for the element */
     parent_ID INT,/* if the element has a parent then it is in this column. The document is the ultimate parent, so you can get the structure from recursing from the document */
     Object_ID INT,/* each list or object has an object id. This ties all elements to a parent. Lists are treated as objects here */
     NAME NVARCHAR(2000),/* the name of the object, null if it hasn't got one */
     StringValue NVARCHAR(MAX) NOT NULL,/*the string representation of the value of the element. */
     ValueType VARCHAR(10) NOT null /* the declared type of the value represented as a string in StringValue*/
  )
  go
  SET NOEXEC OFF
  GO


  IF  Object_Id('dbo.JSONHierarchy', 'TF') IS NOT NULL 
	DROP FUNCTION dbo.JSONHierarchy
GO
CREATE FUNCTION dbo.JSONHierarchy
  (
  @JSONData VARCHAR(MAX),
  @Parent_object_ID INT = NULL,
  @MaxObject_id INT = 0,
  @type INT = null
  )
RETURNS @ReturnTable TABLE
  (
  Element_ID INT IDENTITY(1, 1) PRIMARY KEY, /* internal surrogate primary key gives the order of parsing and the list order */
  SequenceNo INT NULL, /* the sequence number in a list */
  Parent_ID INT, /* if the element has a parent then it is in this column. The document is the ultimate parent, so you can get the structure from recursing from the document */
  Object_ID INT, /* each list or object has an object id. This ties all elements to a parent. Lists are treated as objects here */
  Name NVARCHAR(2000), /* the name of the object */
  StringValue NVARCHAR(MAX) NOT NULL, /*the string representation of the value of the element. */
  ValueType VARCHAR(10) NOT NULL /* the declared type of the value represented as a string in StringValue*/
  )
AS
  BEGIN
	--the types of JSON
    DECLARE @null INT =
      0, @string INT = 1, @int INT = 2, @boolean INT = 3, @array INT = 4, @object INT = 5;
 
    DECLARE @OpenJSONData TABLE
      (
      sequence INT IDENTITY(1, 1),
      [key] VARCHAR(200),
      Value VARCHAR(MAX),
      type INT
      );
 
    DECLARE @key VARCHAR(200), @Value VARCHAR(MAX), @Thetype INT, @ii INT, @iiMax INT,
      @NewObject INT, @firstchar CHAR(1);
 
    INSERT INTO @OpenJSONData
      ([key], Value, type)
      SELECT [Key], Value, Type FROM OpenJson(@JSONData);
	SELECT @ii = 1, @iiMax = Scope_Identity()
    SELECT  @Firstchar= --the first character to see if it is an object or an array
	  Substring(@JSONData,PatIndex('%[^'+CHAR(0)+'- '+CHAR(160)+']%',' '+@JSONData+'!' collate SQL_Latin1_General_CP850_Bin)-1,1)
    IF @type IS NULL AND @firstchar IN ('[','{')
		begin
	   INSERT INTO @returnTable
	    (SequenceNo,Parent_ID,Object_ID,Name,StringValue,ValueType)
			SELECT 1,NULL,1,'-','', 
			   CASE @firstchar WHEN '[' THEN 'array' ELSE 'object' END
        SELECT @type=CASE @firstchar WHEN '[' THEN @array ELSE @object END,
		@Parent_object_ID  = 1, @MaxObject_id=Coalesce(@MaxObject_id, 1) + 1;
		END       
	WHILE(@ii <= @iiMax)
      BEGIN
	  --OpenJSON renames list items with 0-nn which confuses the consumers of the table
        SELECT @key = CASE WHEN [key] LIKE '[0-9]%' THEN NULL ELSE [key] end , @Value = Value, @Thetype = type
          FROM @OpenJSONData
          WHERE sequence = @ii;
 
        IF @Thetype IN (@array, @object) --if we have been returned an array or object
          BEGIN
            SELECT @MaxObject_id = Coalesce(@MaxObject_id, 1) + 1;
			--just in case we have an object or array returned
            INSERT INTO @ReturnTable --record the object itself
              (SequenceNo, Parent_ID, Object_ID, Name, StringValue, ValueType)
              SELECT @ii, @Parent_object_ID, @MaxObject_id, @key, '',
                CASE @Thetype WHEN @array THEN 'array' ELSE 'object' END;
 
            INSERT INTO @ReturnTable --and return all its children
              (SequenceNo, Parent_ID, Object_ID, [Name],  StringValue, ValueType)
			  SELECT SequenceNo, Parent_ID, Object_ID, 
				[Name],
				StringValue,
				ValueType
              FROM dbo.JSONHierarchy(@Value, @MaxObject_id, @MaxObject_id, @type);
			SELECT @MaxObject_id=Max(Object_id)+1 FROM @ReturnTable
		  END;
        ELSE
          INSERT INTO @ReturnTable
            (SequenceNo, Parent_ID, Object_ID, Name, StringValue, ValueType)
            SELECT @ii, @Parent_object_ID, NULL, @key, @Value,
              CASE @Thetype WHEN @string THEN 'string'
                WHEN @null THEN 'null'
                WHEN @int THEN 'int'
                WHEN @boolean THEN 'boolean' ELSE 'int' END;
 
        SELECT @ii = @ii + 1;
      END;
 
    RETURN;
  END;
GO







SELECT * FROM dbo.HierarchyFromJSON('{"Dia":"2018-08-27T00:00:00","Hora":"13:00","CodSala":727,"ConfiguracaoProva":0,"EstadoAgenda":0,"DataCadastro":"0001-01-01T00:00:00","CodigoUsuario":0,"Candidato":{"CPF":36419783860,"Renach":124,"Nome":"ANDRE LOPES RUSSO","NumeroIdentidade":null,"OrgaoIdentidade":null,"Aquisicao":null},"FlagSurdez":false,"CodExaminador":0,"Prova":{"CodigoProva":1,"CodigoConfiguracaoProva":1,"CodigoIdentificadorComputador":0,"Dia":"2018-08-27T00:00:00","Hora":"13:00","Renach":124,"CPF":36419783860,"CodigoSala":727,"CodigoUsuario":0,"CdExaminador01":null,"CdExaminador02":null,"CdPresidente":null,"DtInicio":"0001-01-01T00:00:00","DtFim":"0001-01-01T00:00:00","ListaPergunta":[{"CodigoPergunta":3780,"Ordem":1},{"CodigoPergunta":4353,"Ordem":2},{"CodigoPergunta":4607,"Ordem":3},{"CodigoPergunta":3786,"Ordem":4},{"CodigoPergunta":4202,"Ordem":5},{"CodigoPergunta":4060,"Ordem":6},{"CodigoPergunta":4427,"Ordem":7},{"CodigoPergunta":3186,"Ordem":8},{"CodigoPergunta":4020,"Ordem":9},{"CodigoPergunta":3025,"Ordem":10},{"CodigoPergunta":4119,"Ordem":11},{"CodigoPergunta":3007,"Ordem":12},{"CodigoPergunta":4671,"Ordem":13},{"CodigoPergunta":4667,"Ordem":14},{"CodigoPergunta":3624,"Ordem":15},{"CodigoPergunta":3303,"Ordem":16},{"CodigoPergunta":3570,"Ordem":17},{"CodigoPergunta":3653,"Ordem":18},{"CodigoPergunta":3321,"Ordem":19},{"CodigoPergunta":4682,"Ordem":20},{"CodigoPergunta":4128,"Ordem":21},{"CodigoPergunta":4111,"Ordem":22},{"CodigoPergunta":3489,"Ordem":23},{"CodigoPergunta":3471,"Ordem":24},{"CodigoPergunta":3587,"Ordem":25},{"CodigoPergunta":3388,"Ordem":26},{"CodigoPergunta":3512,"Ordem":27},{"CodigoPergunta":4661,"Ordem":28},{"CodigoPergunta":3354,"Ordem":29},{"CodigoPergunta":4659,"Ordem":30}]}}'  )


SELECT * FROM OPENJSON(('{"Dia":"2018-08-27T00:00:00","Hora":"13:00","CodSala":727,"ConfiguracaoProva":0,"EstadoAgenda":0,"DataCadastro":"0001-01-01T00:00:00","CodigoUsuario":0,"Candidato":{"CPF":36419783860,"Renach":124,"Nome":"ANDRE LOPES RUSSO","NumeroIdentidade":null,"OrgaoIdentidade":null,"Aquisicao":null},"FlagSurdez":false,"CodExaminador":0,"Prova":{"CodigoProva":1,"CodigoConfiguracaoProva":1,"CodigoIdentificadorComputador":0,"Dia":"2018-08-27T00:00:00","Hora":"13:00","Renach":124,"CPF":36419783860,"CodigoSala":727,"CodigoUsuario":0,"CdExaminador01":null,"CdExaminador02":null,"CdPresidente":null,"DtInicio":"0001-01-01T00:00:00","DtFim":"0001-01-01T00:00:00","ListaPergunta":[{"CodigoPergunta":3780,"Ordem":1},{"CodigoPergunta":4353,"Ordem":2},{"CodigoPergunta":4607,"Ordem":3},{"CodigoPergunta":3786,"Ordem":4},{"CodigoPergunta":4202,"Ordem":5},{"CodigoPergunta":4060,"Ordem":6},{"CodigoPergunta":4427,"Ordem":7},{"CodigoPergunta":3186,"Ordem":8},{"CodigoPergunta":4020,"Ordem":9},{"CodigoPergunta":3025,"Ordem":10},{"CodigoPergunta":4119,"Ordem":11},{"CodigoPergunta":3007,"Ordem":12},{"CodigoPergunta":4671,"Ordem":13},{"CodigoPergunta":4667,"Ordem":14},{"CodigoPergunta":3624,"Ordem":15},{"CodigoPergunta":3303,"Ordem":16},{"CodigoPergunta":3570,"Ordem":17},{"CodigoPergunta":3653,"Ordem":18},{"CodigoPergunta":3321,"Ordem":19},{"CodigoPergunta":4682,"Ordem":20},{"CodigoPergunta":4128,"Ordem":21},{"CodigoPergunta":4111,"Ordem":22},{"CodigoPergunta":3489,"Ordem":23},{"CodigoPergunta":3471,"Ordem":24},{"CodigoPergunta":3587,"Ordem":25},{"CodigoPergunta":3388,"Ordem":26},{"CodigoPergunta":3512,"Ordem":27},{"CodigoPergunta":4661,"Ordem":28},{"CodigoPergunta":3354,"Ordem":29},{"CodigoPergunta":4659,"Ordem":30}]}}'  ))




IF Object_Id('dbo.HierarchyFromJSON', 'TF') IS NOT NULL DROP FUNCTION dbo.HierarchyFromJSON;
GO
 
CREATE FUNCTION dbo.HierarchyFromJSON(@JSONData VARCHAR(MAX))
RETURNS @ReturnTable TABLE
  (
  Element_ID INT, /* internal surrogate primary key gives the order of parsing and the list order */
  SequenceNo INT NULL, /* the sequence number in a list */
  Parent_ID INT, /* if the element has a parent then it is in this column. The document is the ultimate parent, so you can get the structure from recursing from the document */
  Object_ID INT, /* each list or object has an object id. This ties all elements to a parent. Lists are treated as objects here */
  Name NVARCHAR(2000), /* the name of the object */
  StringValue NVARCHAR(MAX) NOT NULL, /*the string representation of the value of the element. */
  ValueType VARCHAR(10) NOT NULL /* the declared type of the value represented as a string in StringValue*/
  )
AS
  BEGIN
    DECLARE @ii INT = 1, @rowcount INT = -1;
    DECLARE @null INT =
      0, @string INT = 1, @int INT = 2, @boolean INT = 3, @array INT = 4, @object INT = 5;
 
    DECLARE @TheHierarchy TABLE
      (
      element_id INT IDENTITY(1, 1) PRIMARY KEY,
      sequenceNo INT NULL,
      Depth INT, /* effectively, the recursion level. =the depth of nesting*/
      parent_ID INT,
      Object_ID INT,
      NAME NVARCHAR(2000),
      StringValue NVARCHAR(MAX) NOT NULL,
      ValueType VARCHAR(10) NOT NULL
      );
 
    INSERT INTO @TheHierarchy
      (sequenceNo, Depth, parent_ID, Object_ID, NAME, StringValue, ValueType)
      SELECT 1, @ii, NULL, 0, 'root', @JSONData, 'object';
 
    WHILE @rowcount <> 0
      BEGIN
        SELECT @ii = @ii + 1;
 
        INSERT INTO @TheHierarchy
          (sequenceNo, Depth, parent_ID, Object_ID, NAME, StringValue, ValueType)
          SELECT Scope_Identity(), @ii, Object_ID,
            Scope_Identity() + Row_Number() OVER (ORDER BY parent_ID), [Key], o.Value,
            CASE o.Type WHEN @string THEN 'string'
              WHEN @null THEN 'null'
              WHEN @int THEN 'int'
              WHEN @boolean THEN 'boolean'
              WHEN @int THEN 'int'
              WHEN @array THEN 'array' ELSE 'object' END
          FROM @TheHierarchy AS m
            CROSS APPLY OpenJson(StringValue) AS o
          WHERE m.ValueType IN
        ('array', 'object') AND Depth = @ii - 1;
 
        SELECT @rowcount = @@RowCount;
      END;
 
    INSERT INTO @ReturnTable
      (Element_ID, SequenceNo, Parent_ID, Object_ID, Name, StringValue, ValueType)
      SELECT element_id, element_id - sequenceNo, parent_ID,
        CASE WHEN ValueType IN ('object', 'array') THEN Object_ID ELSE NULL END,
        CASE WHEN NAME LIKE '[0-9]%' THEN NULL ELSE NAME END,
        CASE WHEN ValueType IN ('object', 'array') THEN '' ELSE StringValue END, ValueType
      FROM @TheHierarchy;
 
    RETURN;
  END;
GO








SELECT * FROM OPENJSON(('{"Dia":"2018-08-27T00:00:00","Hora":"13:00","CodSala":727,"ConfiguracaoProva":0,"EstadoAgenda":0,"DataCadastro":"0001-01-01T00:00:00","CodigoUsuario":0,"Candidato":{"CPF":36419783860,"Renach":124,"Nome":"ANDRE LOPES RUSSO","NumeroIdentidade":null,"OrgaoIdentidade":null,"Aquisicao":null},"FlagSurdez":false,"CodExaminador":0,"Prova":{"CodigoProva":1,"CodigoConfiguracaoProva":1,"CodigoIdentificadorComputador":0,"Dia":"2018-08-27T00:00:00","Hora":"13:00","Renach":124,"CPF":36419783860,"CodigoSala":727,"CodigoUsuario":0,"CdExaminador01":null,"CdExaminador02":null,"CdPresidente":null,"DtInicio":"0001-01-01T00:00:00","DtFim":"0001-01-01T00:00:00","ListaPergunta":[{"CodigoPergunta":3780,"Ordem":1},{"CodigoPergunta":4353,"Ordem":2},{"CodigoPergunta":4607,"Ordem":3},{"CodigoPergunta":3786,"Ordem":4},{"CodigoPergunta":4202,"Ordem":5},{"CodigoPergunta":4060,"Ordem":6},{"CodigoPergunta":4427,"Ordem":7},{"CodigoPergunta":3186,"Ordem":8},{"CodigoPergunta":4020,"Ordem":9},{"CodigoPergunta":3025,"Ordem":10},{"CodigoPergunta":4119,"Ordem":11},{"CodigoPergunta":3007,"Ordem":12},{"CodigoPergunta":4671,"Ordem":13},{"CodigoPergunta":4667,"Ordem":14},{"CodigoPergunta":3624,"Ordem":15},{"CodigoPergunta":3303,"Ordem":16},{"CodigoPergunta":3570,"Ordem":17},{"CodigoPergunta":3653,"Ordem":18},{"CodigoPergunta":3321,"Ordem":19},{"CodigoPergunta":4682,"Ordem":20},{"CodigoPergunta":4128,"Ordem":21},{"CodigoPergunta":4111,"Ordem":22},{"CodigoPergunta":3489,"Ordem":23},{"CodigoPergunta":3471,"Ordem":24},{"CodigoPergunta":3587,"Ordem":25},{"CodigoPergunta":3388,"Ordem":26},{"CodigoPergunta":3512,"Ordem":27},{"CodigoPergunta":4661,"Ordem":28},{"CodigoPergunta":3354,"Ordem":29},{"CodigoPergunta":4659,"Ordem":30}]}}'  ))




 
/****** Object: UserDefinedFunction [dbo].[fnGetTableSchemaSelectInto] Script Date: 09/22/2010 09:57:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: WA
-- Create date: 03/02/2010
-- Description: Retrieve Table Schema for Select Into
-- =============================================
CREATE FUNCTION [dbo].[fnGetTableSchemaSelectInto]
(
@TableName varchar(50)
)
RETURNS varchar(2000)
AS
BEGIN

DECLARE @ResultVar varchar(2000)

DECLARE @i int, @sSql varchar(2000)

SELECT @sSql = '' 

SELECT @i = MIN(ordinal_Position)
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE [TABLE_NAME] = @TableName 
AND Column_Name not in 
(SELECT c.name AS ColumnName
FROM sys.columns AS c INNER JOIN sys.tables AS t ON t.[object_id] = c.[object_id]
WHERE c.is_identity = 1 and t.name = @TableName)
AND data_Type <> 'timestamp' 

WHILE @i is not null
BEGIN 

SELECT @sSql = @sSql + replace(replace(column_name,' ',''),'/','') + ','
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE [TABLE_NAME] = @TableName 
AND ordinal_Position = @i
AND data_Type <> 'timestamp'

SELECT @i = min(ordinal_Position) 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE [TABLE_NAME] = @TableName 
AND Column_Name not in 
(SELECT c.name AS ColumnName
FROM sys.columns AS c INNER JOIN sys.tables AS t ON t.[object_id] = c.[object_id]
WHERE c.is_identity = 1 and t.name = @TableName) 
AND data_Type <> 'timestamp' 
AND ordinal_Position > @i
END

SET @sSql = @sSql + '//'

SET @ResultVar = replace(@sSql, ',//','')

-- Return the result of the function
RETURN @ResultVar

END
GO
/****** Object: UserDefinedFunction [dbo].[fnGetTableSchemaInsert] Script Date: 09/22/2010 09:57:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: WA
-- Create date: 12/28/2009
-- Description: Retrieve Table Schema for Insert
-- =============================================
CREATE FUNCTION [dbo].[fnGetTableSchemaInsert]
(
@TableName varchar(50)
)
RETURNS varchar(2000)
AS
BEGIN

DECLARE @ResultVar varchar(2000)

DECLARE @i int, @sSql varchar(2000)

SELECT @sSql = '' 

SELECT @i = MIN(ordinal_Position)
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE [TABLE_NAME] = @TableName 
AND Column_Name not in 
(SELECT c.name AS ColumnName
FROM sys.columns AS c INNER JOIN sys.tables AS t ON t.[object_id] = c.[object_id]
WHERE c.is_identity = 1 and t.name = @TableName)
AND data_Type <> 'timestamp' 

WHILE @i is not null
BEGIN 

SELECT @sSql = @sSql + CASE data_type
WHEN 'varchar' THEN 
CASE WHEN character_maximum_length = -1 THEN
'[' + replace(replace(column_name,' ',''),'/','') + '] ' + data_type + '(MAX), '
ELSE 
'[' + replace(replace(column_name,' ',''),'/','') + '] ' + data_type + '(' + cast(isnull(character_maximum_length,numeric_precision) as varchar(60)) + '), '
END
WHEN 'nvarchar' THEN '[' + replace(replace(column_name,' ',''),'/','') + '] ' + data_type + '(' + cast(isnull(character_maximum_length,numeric_precision) as varchar(60)) + '), '
WHEN 'char' THEN '[' + replace(replace(column_name,' ',''),'/','') + '] ' + data_type + '(' + cast(isnull(character_maximum_length,numeric_precision) as varchar(60)) + '), '
ELSE '[' + replace(replace(column_name,' ',''),'/','') + '] ' + data_type + ', '
END
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE [TABLE_NAME] = @TableName 
AND ordinal_Position = @i
AND data_Type <> 'timestamp'

SELECT @i = min(ordinal_Position) 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE [TABLE_NAME] = @TableName 
AND Column_Name not in 
(SELECT c.name AS ColumnName
FROM sys.columns AS c INNER JOIN sys.tables AS t ON t.[object_id] = c.[object_id]
WHERE c.is_identity = 1 and t.name = @TableName) 
AND data_Type <> 'timestamp' 
AND ordinal_Position > @i
END

SET @sSql = @sSql + '//'

SET @ResultVar = replace(@sSql, ', //','')

-- Return the result of the function
RETURN @ResultVar

END
GO
/****** Object: UserDefinedFunction [dbo].[fnGetTableSchema] Script Date: 09/22/2010 09:57:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: WA
-- Create date: 12/28/2009
-- Description: Retrieve Table Schema
-- =============================================
CREATE FUNCTION [dbo].[fnGetTableSchema]
(
@TableName varchar(50)
)
RETURNS varchar(2000)
AS
BEGIN

DECLARE @ResultVar varchar(2000)

DECLARE @i int, @sSql varchar(2000)

SELECT @sSql = '' 

SELECT @i = MIN(ordinal_Position)
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE [TABLE_NAME] = @TableName
AND data_Type <> 'timestamp' 

WHILE @i is not null
BEGIN 

SELECT @sSql = @sSql + CASE data_type
WHEN 'varchar' THEN 
CASE WHEN character_maximum_length = -1 THEN
'[' + replace(replace(column_name,' ',''),'/','') + '] ' + data_type + '(MAX), '
ELSE 
'[' + replace(replace(column_name,' ',''),'/','') + '] ' + data_type + '(' + cast(isnull(character_maximum_length,numeric_precision) as varchar(60)) + '), '
END
WHEN 'nvarchar' THEN '[' + replace(replace(column_name,' ',''),'/','') + '] ' + data_type + '(' + cast(isnull(character_maximum_length,numeric_precision) as varchar(60)) + '), '
WHEN 'char' THEN '[' + replace(replace(column_name,' ',''),'/','') + '] ' + data_type + '(' + cast(isnull(character_maximum_length,numeric_precision) as varchar(60)) + '), '
ELSE '[' + replace(replace(column_name,' ',''),'/','') + '] ' + data_type + ', '
END
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE [TABLE_NAME] = @TableName
AND ordinal_Position = @i

SELECT @i = min(ordinal_Position) 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE [TABLE_NAME] = @TableName
AND data_Type <> 'timestamp'
AND ordinal_Position > @i
END

SET @sSql = @sSql + '//'

SET @ResultVar = replace(@sSql, ', //','')

-- Return the result of the function
RETURN @ResultVar

END
GO
/****** Object: UserDefinedFunction [dbo].[fnGetTableKeys] Script Date: 09/22/2010 09:57:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: WA
-- Create date: 12/28/2009
-- Description: Retrieve Table Primary Keys
-- =============================================
CREATE FUNCTION [dbo].[fnGetTableKeys] 
( 
@TableName varchar(50)
)
RETURNS TABLE 
AS
RETURN 
(
SELECT Ordinal_position, Column_Name 
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE table_name = @TableName
)
GO
/****** Object: UserDefinedFunction [dbo].[fnGetPrimaryKeys] Script Date: 09/22/2010 09:57:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: WA
-- Create date: 12/28/2009
-- Description: Retrieve Table Primary Keys
-- =============================================
CREATE FUNCTION [dbo].[fnGetPrimaryKeys]
(
@TableName varchar(50)
)
RETURNS varchar(2000)
AS
BEGIN

DECLARE @ResultVar varchar(2000)

DECLARE @i int, @sSql varchar(2000)

SELECT @i = 1, @sSql = '' 

WHILE @i is not null
BEGIN 

SELECT @sSql = @sSql + @TableName + '.' + Column_Name + '=xm.' + Column_Name + ' AND '
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE table_name = @TableName
AND Ordinal_position = @i

-- MoveNext
SELECT @i = min(Ordinal_position) 
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE table_name = @TableName
AND Ordinal_position > @i
END

SET @sSql = @sSql + '//'

SET @ResultVar = replace(@sSql, 'AND //','')

-- Return the result of the function
RETURN @ResultVar

END
GO
/****** Object: UserDefinedFunction [dbo].[fnSetTableSchemaSelect] Script Date: 09/22/2010 09:57:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: WA
-- Create date: 12/28/2009
-- Description: Retreive Table Schema for Insert
-- =============================================
CREATE FUNCTION [dbo].[fnSetTableSchemaSelect]
(
@TableName varchar(50)
)
RETURNS varchar(2000)
AS
BEGIN

DECLARE @ResultVar varchar(2000)

DECLARE @i int, @sSql varchar(2000)

SELECT @sSql = '' 

SELECT @i = MIN(ordinal_Position)
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE [TABLE_NAME] = @TableName 
AND Column_Name not in 
(SELECT c.name AS ColumnName
FROM sys.columns AS c INNER JOIN sys.tables AS t ON t.[object_id] = c.[object_id]
WHERE c.is_identity = 1 and t.name = @TableName)
AND data_Type <> 'timestamp' 

WHILE @i is not null
BEGIN 

SELECT @sSql = @sSql + CASE data_type
WHEN 'datetime' THEN 
'[' + replace(replace([column_name],' ',''),'/','') + ']= CASE WHEN dbo.fnIsDate([' + replace(replace([column_name],' ',''),'/','') + '])=1 THEN NULL ELSE [' + replace(replace([column_name],' ',''),'/','') + '] END, ' 
ELSE '[' + replace(replace(column_name,' ',''),'/','') + '], '
END
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE [TABLE_NAME] = @TableName
AND ordinal_Position = @i
AND data_Type <> 'timestamp'

SELECT @i = min(ordinal_Position) 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE [TABLE_NAME] = @TableName
AND Column_Name not in 
(SELECT c.name AS ColumnName
FROM sys.columns AS c INNER JOIN sys.tables AS t ON t.[object_id] = c.[object_id]
WHERE c.is_identity = 1 and t.name = @TableName) 
AND data_Type <> 'timestamp' 
AND ordinal_Position > @i
END

SET @sSql = @sSql + '//'

SET @ResultVar = replace(@sSql, ', //','')

-- Return the result of the function
RETURN @ResultVar

END
GO
/****** Object: UserDefinedFunction [dbo].[fnIsDate] Script Date: 09/22/2010 09:57:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: WA
-- Create date: 01/22/2010
-- Description: Validate good Date
-- =============================================
CREATE FUNCTION [dbo].[fnIsDate] 
(
@DateTime datetime
)
RETURNS bit
AS
BEGIN

DECLARE @ResultVar bit
SET @ResultVar = 0

IF @DateTime = '1900-01-01 00:00:00.000'
SET @ResultVar = 1

-- Return the result of the function
RETURN @ResultVar

END
GO
/****** Object: UserDefinedFunction [dbo].[fnGetTableUpdate] Script Date: 09/22/2010 09:57:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: WA
-- Create date: 12/28/2009
-- Description: Retrieve Table Update
-- =============================================
CREATE FUNCTION [dbo].[fnGetTableUpdate]
(
@TableName varchar(50)
)
RETURNS varchar(4000)
AS
BEGIN

DECLARE @ResultVar varchar(4000)

DECLARE @i int, @sSql varchar(4000)

SELECT @sSql = '' 

SELECT @i = MIN(ordinal_Position)
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE [TABLE_NAME] = @TableName
AND ordinal_Position not in (SELECT Ordinal_Position FROM [dbo].[fnGetTableKeys](@TableName)) 
AND [Column_Name]<> 'SysTimeStamp' 

WHILE @i is not null
BEGIN 

SELECT @sSql = @sSql + CASE data_type
WHEN 'datetime' THEN 
'[' + replace(replace([column_name],' ',''),'/','') + ']= CASE WHEN dbo.fnIsDate(xm.[' + replace(replace([column_name],' ',''),'/','') + '])=1 THEN NULL ELSE xm.[' + replace(replace([column_name],' ',''),'/','') + '] END, ' 
ELSE '[' + replace(replace(column_name,' ',''),'/','') + '] = xm.' + replace(replace(column_name,' ',''),'/','') + ', '
END
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE [TABLE_NAME] = @TableName
AND [Column_Name]<> 'SysTimeStamp' 
AND ordinal_Position = @i

SELECT @i = min(ordinal_Position) 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE [TABLE_NAME] = @TableName
AND ordinal_Position not in (SELECT Ordinal_Position FROM [dbo].[fnGetTableKeys](@TableName))
AND [Column_Name]<> 'SysTimeStamp' 
AND ordinal_Position > @i
END

SET @sSql = @sSql + '//'

SET @ResultVar = replace(@sSql, ', //','')

-- Return the result of the function
RETURN @ResultVar

END
GO
/****** Object: StoredProcedure [dbo].[prXMLDataInsert] Script Date: 09/22/2010 09:57:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: WA
-- Create date: 12/24/2009
-- Description: Translate XML to SQL RecordSet for Insert
-- =============================================
CREATE PROCEDURE [dbo].[prXMLDataInsert] 
(
@XmlData xml
)
AS
BEGIN

SET NOCOUNT ON
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

DECLARE @hdoc int

-- Prepare XML document
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xmlData

-- Set Raw XML Schema
SELECT *
INTO #xmlDoc 
FROM OPENXML( @hdoc, '//*',2)

-- Set Primary Table to use
SELECT DISTINCT Identity(int,1,1) id, rt.localname + '/' + tbl.localname + '/' + col.localname as NodePath, tbl.localname as NodeRow
INTO #xml
FROM #xmlDoc rt 
INNER JOIN #xmlDoc tbl
ON rt.id = tbl.parentID and rt.parentID is null
INNER JOIN #xmlDoc col
ON tbl.id = col.parentID

DECLARE @i int, @NodePath varchar(255), @NodeRow varchar(50), 
@NodeKeys varchar(255), @NodeCol varchar(2000), @UpdateNodes varchar(2000), 
@sSql nvarchar(4000), @SetSchemaSelect varchar(4000), @iVars varchar(2000)

-- Set id of first row
SELECT @i = min(id) from #xml 

-- Begin looping through xml recordset
WHILE @i is not null
BEGIN 
SELECT @NodePath = NodePath, @NodeRow = NodeRow FROM #xml WHERE id = @i 

-- Get Table Schema for XML data columns
SELECT @NodeCol =[dbo].[fnGetTableSchemaInsert](@NodeRow)
SELECT @SetSchemaSelect = [dbo].[fnSetTableSchemaSelect](@NodeRow)
SELECT @ivars = [dbo].[fnGetTableSchemaSelectInto](@NodeRow)

DECLARE @param NVARCHAR(50), @pkID int, @pkIDOUT int

SET @param = N'@hdoc INT, @pkIDOUT INT OUTPUT'

/******* This updates xml Recordset on primary keys of a given table *******/

SET @sSql = 'INSERT INTO ' + @NodeRow + '(' + @iVars + ') SELECT ' + @SetSchemaSelect + ' FROM OPENXML( @hdoc, ''' + @NodePath + ''',2) WITH (' + @NodeCol + ') as xm SELECT @pkIDOUT = SCOPE_IDENTITY()'

/******* Execute the query and pass in the @hdoc for update *******/
EXEC sp_executesql @sSql, @param, @hdoc, @pkIDOUT=@pkID OUTPUT

/***** Movenext *****/
SELECT @i = min(id) FROM #xml WHERE id > @i
END

-- Release @hdoc
EXEC sp_xml_removedocument @hdoc
DROP TABLE #xmlDoc
DROP TABLE #xml

END
GO
/****** Object: StoredProcedure [dbo].[prXMLDataUpdate] Script Date: 09/22/2010 09:57:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: WA
-- Create date: 12/24/2009
-- Description: Translate XML to SQL RecordSet for Update
-- =============================================
CREATE PROCEDURE [dbo].[prXMLDataUpdate] 
(
@XmlData xml
)
AS
BEGIN

SET NOCOUNT ON
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

DECLARE @hdoc int

-- Prepare XML document
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xmlData

-- Set Raw XML Schema
SELECT *
INTO #xmlDoc 
FROM OPENXML( @hdoc, '//*',2)

-- Set Primary Table to use
SELECT DISTINCT Identity(int,1,1) id, rt.localname + '/' + tbl.localname + '/' + col.localname as NodePath, tbl.localname as NodeRow
INTO #xml
FROM #xmlDoc rt 
INNER JOIN #xmlDoc tbl
ON rt.id = tbl.parentID and rt.parentID is null
INNER JOIN #xmlDoc col
ON tbl.id = col.parentID

DECLARE @i int, @NodePath varchar(255), @NodeRow varchar(50), @NodeKeys varchar(255), @NodeCol varchar(4000), @UpdateNodes varchar(4000), @sSql nvarchar(4000)

-- Set id of first row
SELECT @i = min(id) from #xml 

-- Begin looping through xml recordset
WHILE @i is not null
BEGIN 
SELECT @NodePath = NodePath, @NodeRow = NodeRow FROM #xml WHERE id = @i 

-- Get Table Schema for XML data columns
SELECT @NodeCol = [dbo].[fnGetTableSchema](@NodeRow)--:00
SELECT @UpdateNodes =[dbo].[fnGetTableUpdate](@NodeRow)--:00
SELECT @NodeKeys = [dbo].[fnGetPrimaryKeys](@NodeRow)--:00

DECLARE @param NVARCHAR(50)
SET @param = N'@hdoc INT'

/******* This updates xml Recordset on primary keys of a given table *******/
SET @sSql = 'UPDATE ' + @NodeRow + ' SET ' + @UpdateNodes + ' FROM OPENXML( @hdoc, ''' + @NodePath + ''',2) WITH (' + @NodeCol + ') as xm INNER JOIN ' + @NodeRow + ' ON ' + @NodeKeys

/******* Execute the query and pass in the @hdoc for update *******/
EXEC sp_executesql @sSql, @param, @hdoc

/***** Movenext *****/
SELECT @i = min(id) FROM #xml WHERE id > @i
END

-- Release @hdoc
EXEC sp_xml_removedocument @hdoc
DROP TABLE #xmlDoc
DROP TABLE #xml

END
GO



CREATE FUNCTION dbo.parseJSON( @JSON NVARCHAR(MAX))
RETURNS @hierarchy TABLE
  (
   element_id INT IDENTITY(1, 1) NOT NULL, /* internal surrogate primary key gives the order of parsing and the list order */
   sequenceNo [int] NULL, /* the place in the sequence for the element */
   parent_ID INT,/* if the element has a parent then it is in this column. The document is the ultimate parent, so you can get the structure from recursing from the document */
   Object_ID INT,/* each list or object has an object id. This ties all elements to a parent. Lists are treated as objects here */
   NAME NVARCHAR(2000),/* the name of the object */
   StringValue NVARCHAR(MAX) NOT NULL,/*the string representation of the value of the element. */
   ValueType VARCHAR(10) NOT null /* the declared type of the value represented as a string in StringValue*/
  )
AS
BEGIN
  DECLARE
    @FirstObject INT, --the index of the first open bracket found in the JSON string
    @OpenDelimiter INT,--the index of the next open bracket found in the JSON string
    @NextOpenDelimiter INT,--the index of subsequent open bracket found in the JSON string
    @NextCloseDelimiter INT,--the index of subsequent close bracket found in the JSON string
    @Type NVARCHAR(10),--whether it denotes an object or an array
    @NextCloseDelimiterChar CHAR(1),--either a '}' or a ']'
    @Contents NVARCHAR(MAX), --the unparsed contents of the bracketed expression
    @Start INT, --index of the start of the token that you are parsing
    @end INT,--index of the end of the token that you are parsing
    @param INT,--the parameter at the end of the next Object/Array token
    @EndOfName INT,--the index of the start of the parameter at end of Object/Array token
    @token NVARCHAR(200),--either a string or object
    @value NVARCHAR(MAX), -- the value as a string
    @SequenceNo int, -- the sequence number within a list
    @name NVARCHAR(200), --the name as a string
    @parent_ID INT,--the next parent ID to allocate
    @lenJSON INT,--the current length of the JSON String
    @characters NCHAR(36),--used to convert hex to decimal
    @result BIGINT,--the value of the hex symbol being parsed
    @index SMALLINT,--used for parsing the hex value
    @Escape INT --the index of the next escape character


  DECLARE @Strings TABLE /* in this temporary table we keep all strings, even the names of the elements, since they are 'escaped' in a different way, and may contain, unescaped, brackets denoting objects or lists. These are replaced in the JSON string by tokens representing the string */
    (
     String_ID INT IDENTITY(1, 1),
     StringValue NVARCHAR(MAX)
    )
  SELECT--initialise the characters to convert hex to ascii
    @characters='0123456789abcdefghijklmnopqrstuvwxyz',
    @SequenceNo=0, --set the sequence no. to something sensible.
  /* firstly we process all strings. This is done because [{} and ] aren't escaped in strings, which complicates an iterative parse. */
    @parent_ID=0;
  WHILE 1=1 --forever until there is nothing more to do
    BEGIN
      SELECT
        @start=PATINDEX('%[^a-zA-Z]["]%', @json collate SQL_Latin1_General_CP850_Bin);--next delimited string
      IF @start=0 BREAK --no more so drop through the WHILE loop
      IF SUBSTRING(@json, @start+1, 1)='"'
        BEGIN --Delimited Name
          SET @start=@Start+1;
          SET @end=PATINDEX('%[^\]["]%', RIGHT(@json, LEN(@json+'|')-@start) collate SQL_Latin1_General_CP850_Bin);
        END
      IF @end=0 --no end delimiter to last string
        BREAK --no more
      SELECT @token=SUBSTRING(@json, @start+1, @end-1)
      --now put in the escaped control characters
      SELECT @token=REPLACE(@token, FROMString, TOString)
      FROM
        (SELECT
          '\"' AS FromString, '"' AS ToString
         UNION ALL SELECT '\\', '\'
         UNION ALL SELECT '\/', '/'
         UNION ALL SELECT '\b', CHAR(08)
         UNION ALL SELECT '\f', CHAR(12)
         UNION ALL SELECT '\n', CHAR(10)
         UNION ALL SELECT '\r', CHAR(13)
         UNION ALL SELECT '\t', CHAR(09)
        ) substitutions
      SELECT @result=0, @escape=1
  --Begin to take out any hex escape codes
      WHILE @escape>0
        BEGIN
          SELECT @index=0,
          --find the next hex escape sequence
          @escape=PATINDEX('%\x[0-9a-f][0-9a-f][0-9a-f][0-9a-f]%', @token collate SQL_Latin1_General_CP850_Bin)
          IF @escape>0 --if there is one
            BEGIN
              WHILE @index<4 --there are always four digits to a \x sequence  
                BEGIN
                  SELECT --determine its value
                    @result=@result+POWER(16, @index)
                    *(CHARINDEX(SUBSTRING(@token, @escape+2+3-@index, 1),
                                @characters)-1), @index=@index+1 ;

                END
                -- and replace the hex sequence by its unicode value
              SELECT @token=STUFF(@token, @escape, 6, NCHAR(@result))
            END
        END
      --now store the string away
      INSERT INTO @Strings (StringValue) SELECT @token
      -- and replace the string with a token
      SELECT @JSON=STUFF(@json, @start, @end+1,
                    '@string'+CONVERT(NVARCHAR(5), @@identity))
    END
  -- all strings are now removed. Now we find the first leaf.
  WHILE 1=1  --forever until there is nothing more to do
  BEGIN

  SELECT @parent_ID=@parent_ID+1
  --find the first object or list by looking for the open bracket
  SELECT @FirstObject=PATINDEX('%[{[[]%', @json collate SQL_Latin1_General_CP850_Bin)--object or array
  IF @FirstObject = 0 BREAK
  IF (SUBSTRING(@json, @FirstObject, 1)='{')
    SELECT @NextCloseDelimiterChar='}', @type='object'
  ELSE
    SELECT @NextCloseDelimiterChar=']', @type='array'
  SELECT @OpenDelimiter=@firstObject

  WHILE 1=1 --find the innermost object or list...
    BEGIN
      SELECT
        @lenJSON=LEN(@JSON+'|')-1
  --find the matching close-delimiter proceeding after the open-delimiter
      SELECT
        @NextCloseDelimiter=CHARINDEX(@NextCloseDelimiterChar, @json,
                                      @OpenDelimiter+1)
  --is there an intervening open-delimiter of either type
      SELECT @NextOpenDelimiter=PATINDEX('%[{[[]%',
             RIGHT(@json, @lenJSON-@OpenDelimiter)collate SQL_Latin1_General_CP850_Bin)--object
      IF @NextOpenDelimiter=0
        BREAK
      SELECT @NextOpenDelimiter=@NextOpenDelimiter+@OpenDelimiter
      IF @NextCloseDelimiter<@NextOpenDelimiter
        BREAK
      IF SUBSTRING(@json, @NextOpenDelimiter, 1)='{'
        SELECT @NextCloseDelimiterChar='}', @type='object'
      ELSE
        SELECT @NextCloseDelimiterChar=']', @type='array'
      SELECT @OpenDelimiter=@NextOpenDelimiter
    END
  ---and parse out the list or name/value pairs
  SELECT
    @contents=SUBSTRING(@json, @OpenDelimiter+1,
                        @NextCloseDelimiter-@OpenDelimiter-1)
  SELECT
    @JSON=STUFF(@json, @OpenDelimiter,
                @NextCloseDelimiter-@OpenDelimiter+1,
                '@'+@type+CONVERT(NVARCHAR(5), @parent_ID))
  WHILE (PATINDEX('%[A-Za-z0-9@+.e]%', @contents collate SQL_Latin1_General_CP850_Bin))<>0
    BEGIN
      IF @Type='Object' --it will be a 0-n list containing a string followed by a string, number,boolean, or null
        BEGIN
          SELECT
            @SequenceNo=0,@end=CHARINDEX(':', ' '+@contents)--if there is anything, it will be a string-based name.
          SELECT  @start=PATINDEX('%[^A-Za-z@][@]%', ' '+@contents collate SQL_Latin1_General_CP850_Bin)--AAAAAAAA
          SELECT @token=SUBSTRING(' '+@contents, @start+1, @End-@Start-1),
            @endofname=PATINDEX('%[0-9]%', @token collate SQL_Latin1_General_CP850_Bin),
            @param=RIGHT(@token, LEN(@token)-@endofname+1)
          SELECT
            @token=LEFT(@token, @endofname-1),
            @Contents=RIGHT(' '+@contents, LEN(' '+@contents+'|')-@end-1)
          SELECT  @name=stringvalue FROM @strings
            WHERE string_id=@param --fetch the name
        END
      ELSE
        SELECT @Name=null,@SequenceNo=@SequenceNo+1
      SELECT
        @end=CHARINDEX(',', @contents)-- a string-token, object-token, list-token, number,boolean, or null
      IF @end=0
        SELECT  @end=PATINDEX('%[A-Za-z0-9@+.e][^A-Za-z0-9@+.e]%', @Contents+' ' collate SQL_Latin1_General_CP850_Bin)
          +1
       SELECT
        @start=PATINDEX('%[^A-Za-z0-9@+.e][A-Za-z0-9@+.e]%', ' '+@contents collate SQL_Latin1_General_CP850_Bin)
      --select @start,@end, LEN(@contents+'|'), @contents
      SELECT
        @Value=RTRIM(SUBSTRING(@contents, @start, @End-@Start)),
        @Contents=RIGHT(@contents+' ', LEN(@contents+'|')-@end)
      IF SUBSTRING(@value, 1, 7)='@object'
        INSERT INTO @hierarchy
          (NAME, SequenceNo, parent_ID, StringValue, Object_ID, ValueType)
          SELECT @name, @SequenceNo, @parent_ID, SUBSTRING(@value, 8, 5),
            SUBSTRING(@value, 8, 5), 'object'
      ELSE
        IF SUBSTRING(@value, 1, 6)='@array'
          INSERT INTO @hierarchy
            (NAME, SequenceNo, parent_ID, StringValue, Object_ID, ValueType)
            SELECT @name, @SequenceNo, @parent_ID, SUBSTRING(@value, 7, 5),
              SUBSTRING(@value, 7, 5), 'array'
        ELSE
          IF SUBSTRING(@value, 1, 7)='@string'
            INSERT INTO @hierarchy
              (NAME, SequenceNo, parent_ID, StringValue, ValueType)
              SELECT @name, @SequenceNo, @parent_ID, stringvalue, 'string'
              FROM @strings
              WHERE string_id=SUBSTRING(@value, 8, 5)
          ELSE
            IF @value IN ('true', 'false')
              INSERT INTO @hierarchy
                (NAME, SequenceNo, parent_ID, StringValue, ValueType)
                SELECT @name, @SequenceNo, @parent_ID, @value, 'boolean'
            ELSE
              IF @value='null'
                INSERT INTO @hierarchy
                  (NAME, SequenceNo, parent_ID, StringValue, ValueType)
                  SELECT @name, @SequenceNo, @parent_ID, @value, 'null'
              ELSE
                IF PATINDEX('%[^0-9]%', @value collate SQL_Latin1_General_CP850_Bin)>0
                  INSERT INTO @hierarchy
                    (NAME, SequenceNo, parent_ID, StringValue, ValueType)
                    SELECT @name, @SequenceNo, @parent_ID, @value, 'real'
                ELSE
                  INSERT INTO @hierarchy
                    (NAME, SequenceNo, parent_ID, StringValue, ValueType)
                    SELECT @name, @SequenceNo, @parent_ID, @value, 'int'
      if @Contents=' ' Select @SequenceNo=0
    END
  END
INSERT INTO @hierarchy (NAME, SequenceNo, parent_ID, StringValue, Object_ID, ValueType)
  SELECT '-',1, NULL, '', @parent_id-1, @type
--
   RETURN
END
GO




DECLARE @JSON NVARCHAR(MAX) 

SET @JSON = '{"Dia":"2018-08-27T00:00:00","Hora":"13:00","CodSala":727,"ConfiguracaoProva":0,"EstadoAgenda":0,"DataCadastro":"0001-01-01T00:00:00","CodigoUsuario":0,"Candidato":{"CPF":36419783860,"Renach":124,"Nome":"ANDRE LOPES RUSSO","NumeroIdentidade":null,"OrgaoIdentidade":null,"Aquisicao":null},"FlagSurdez":false,"CodExaminador":0,"Prova":{"CodigoProva":1,"CodigoConfiguracaoProva":1,"CodigoIdentificadorComputador":0,"Dia":"2018-08-27T00:00:00","Hora":"13:00","Renach":124,"CPF":36419783860,"CodigoSala":727,"CodigoUsuario":0,"CdExaminador01":null,"CdExaminador02":null,"CdPresidente":null,"DtInicio":"0001-01-01T00:00:00","DtFim":"0001-01-01T00:00:00","ListaPergunta":[{"CodigoPergunta":3780,"Ordem":1},{"CodigoPergunta":4353,"Ordem":2},{"CodigoPergunta":4607,"Ordem":3},{"CodigoPergunta":3786,"Ordem":4},{"CodigoPergunta":4202,"Ordem":5},{"CodigoPergunta":4060,"Ordem":6},{"CodigoPergunta":4427,"Ordem":7},{"CodigoPergunta":3186,"Ordem":8},{"CodigoPergunta":4020,"Ordem":9},{"CodigoPergunta":3025,"Ordem":10},{"CodigoPergunta":4119,"Ordem":11},{"CodigoPergunta":3007,"Ordem":12},{"CodigoPergunta":4671,"Ordem":13},{"CodigoPergunta":4667,"Ordem":14},{"CodigoPergunta":3624,"Ordem":15},{"CodigoPergunta":3303,"Ordem":16},{"CodigoPergunta":3570,"Ordem":17},{"CodigoPergunta":3653,"Ordem":18},{"CodigoPergunta":3321,"Ordem":19},{"CodigoPergunta":4682,"Ordem":20},{"CodigoPergunta":4128,"Ordem":21},{"CodigoPergunta":4111,"Ordem":22},{"CodigoPergunta":3489,"Ordem":23},{"CodigoPergunta":3471,"Ordem":24},{"CodigoPergunta":3587,"Ordem":25},{"CodigoPergunta":3388,"Ordem":26},{"CodigoPergunta":3512,"Ordem":27},{"CodigoPergunta":4661,"Ordem":28},{"CodigoPergunta":3354,"Ordem":29},{"CodigoPergunta":4659,"Ordem":30}]}}'
SELECT * FROM DBO.parseJSON(@JSON)
 
select     
            Renach ,  
            Cpf ,    
            NomeCandidato ,  
            NumeroIdentidade,  
            OrgaoIdentidade ,  
            NULL--@DS_UF_RENACH  
        FROM 
            OPENJSON(@JSON)  
        WITH(  
            Renach			BIGINT,  
            Cpf			BIGINT,    
            NomeCandidato varchar(50),  
            NumeroIdentidade varchar(12),  
            OrgaoIdentidade varchar(10)  
        )  
		/*
        WHERE   
            Renach IS NOT NULL 
        AND cpf IS NOT NULL  
		*/


		use master
go
DECLARE @MyHierarchy Hierarchy 
DECLARE @JSON VARCHAR(MAX)

 -- to pass the hierarchy table around
insert into @MyHierarchy 
SELECT * from dbo.ParseXML(
---your SQL Goes here --->
  (select  top 1 
	id
,	Banco
,	NomeArquivo
,	SizeMB
,	type
,	DataOperacao
from DbEnviaDados..Dados
---You add this magic spell, making it XML, and giving a name for the 'list' of rows and the root      
  for XML path ('dados'), root('dados')
-- end of SQL
  )
)


create TABLE #hierarchy
          (
           element_id INT IDENTITY(1, 1) NOT NULL, /* internal surrogate primary key gives the order of parsing and the list order */
           parent_ID INT,/* if the element has a parent then it is in this column. The document is the ultimate parent, so you can get the structure from recursing from the document */
           Object_ID INT,/* each list or object has an object id. This ties all elements to a parent. Lists are treated as objects here */
           NAME NVARCHAR(2000),/* the name of the object */
           StringValue NVARCHAR(MAX) NOT NULL,/*the string representation of the value of the element. */
           ValueType VARCHAR(10) NOT null /* the declared type of the value represented as a string in StringValue*/
          )
        
    
     ;With loc 
		(
			Roworder
		,	id
		,	Banco
		,	NomeArquivo
		,	SizeMB
		,	type
		,	DataOperacao
		)
        as
        (
						Select  top 10
							ROW_NUMBER() OVER ( ORDER BY id) as RowOrder
						,	id
						,	Banco
						,	NomeArquivo
						,	SizeMB
						,	type
						,	DataOperacao
						from DbEnviaDados..Dados
				 
					
        )
        
        --INSERT INTO #Hierarchy (parent_ID,Object_ID,NAME,StringValue,ValueType)
		Select 
						 Roworder,null,'id', convert(varchar(5),id),'int'  from loc
        union all Select Roworder,null,'Banco', Banco ,'string'  from  loc
        union all Select Roworder,null,'NomeArquivo', convert(varchar(100),NomeArquivo) ,'real'  from  loc
        union all Select Roworder,null,'SizeMB', convert(varchar(100),SizeMB) ,'real'  from  loc
        union all Select Roworder,null,'type', Convert(varchar(100),type,126) ,'string'  from  loc
		union all Select Roworder,null,'DataOperacao', Convert(varchar(100),DataOperacao,126) ,'string'  from  loc
        union all Select (Select count(*) from loc)+1, ROW_NUMBER() OVER ( ORDER BY id ), NULL,'1','object' from  loc
        union all Select null, (Select count(*) from loc)+1,'-','','array'

SELECT @JSON  = dbo.ToJSON(@MyHierarchy)
SELECT * FROM DBO.parseJSON(@JSON)






select * from master..sysdatabases 
select * from DB_MA_PROVA_DIGITAL_off.dbo.TB_AGENDAS_RENACHS


use DbEnviaDados



select  top 1 
	id
,	Banco
,	NomeArquivo
,	SizeMB
,	type
,	DataOperacao
from DbEnviaDados..Dados



CREATE TYPE dbo.Hierarchy AS TABLE
/*Markup languages such as JSON and XML all represent object data as hierarchies. Although it looks very different to the entity-relational model, it isn't. It is rather more a different perspective on the same model. The first trick is to represent it as a Adjacency list hierarchy in a table, and then use the contents of this table to update the database. This Adjacency list is really the Database equivalent of any of the nested data structures that are used for the interchange of serialized information with the application, and can be used to create XML, OSX Property lists, Python nested structures or YAML as easily as JSON.
	
Adjacency list tables have the same structure whatever the data in them. This means that you can define a single Table-Valued  Type and pass data structures around between stored procedures. However, they are best held at arms-length from the data, since they are not relational tables, but something more like the dreaded EAV (Entity-Attribute-Value) tables. Converting the data from its Hierarchical table form will be different for each application, but is easy with a CTE. You can, alternatively, convert the hierarchical table into XML and interrogate that with XQuery
*/
(
	element_id INT primary key, /* internal surrogate primary key gives the order of parsing and the list order */
	sequenceNo int NULL, /* the place in the sequence for the element */
	parent_ID INT,/* if the element has a parent then it is in this column. The document is the ultimate parent, so you can get the structure from recursing from the document */
	[Object_ID] INT,/* each list or object has an object id. This ties all elements to a parent. Lists are treated as objects here */
	NAME NVARCHAR(2000),/* the name of the object, null if it hasn't got one */
	StringValue NVARCHAR(MAX) NOT NULL,/*the string representation of the value of the element. */
	ValueType VARCHAR(10) NOT null /* the declared type of the value represented as a string in StringValue*/
)
IF OBJECT_ID (N'dbo.JSONEscaped') IS NOT NULL     DROP FUNCTION dbo.JSONEscaped
GO 
CREATE FUNCTION [dbo].[JSONEscaped] ( /* this is a simple utility function that takes a SQL String with all its clobber and outputs it as a sting with all the JSON escape sequences in it.*/
 @Unescaped NVARCHAR(MAX) --a string with maybe characters that will break json
 )
RETURNS NVARCHAR(MAX)
AS
BEGIN
  SELECT @Unescaped = REPLACE(@Unescaped, FROMString, TOString)
  FROM (SELECT '' AS FromString, '\' AS ToString 
        UNION ALL SELECT '"', '"' 
        UNION ALL SELECT '/', '/'
        UNION ALL SELECT CHAR(08),'b'
        UNION ALL SELECT CHAR(12),'f'
        UNION ALL SELECT CHAR(10),'n'
        UNION ALL SELECT CHAR(13),'r'
        UNION ALL SELECT CHAR(09),'t'
 ) substitutions
RETURN @Unescaped
END
GO
IF OBJECT_ID (N'dbo.ParseXML') IS NOT NULL
   DROP FUNCTION dbo.ParseXML
GO
CREATE FUNCTION dbo.ParseXML( @XML_Result XML)
/* 
Returns a hierarchy table from an XML document.
Author: Phil Factor
Revision: 1.2
date: 1 May 2014
example:
 
DECLARE @MyHierarchy Hierarchy
INSERT INTO @myHierarchy
SELECT* from dbo.ParseXML((SELECT* from adventureworks.person.contact where contactID in (123,124,125) FOR XML path('contact'), root('contacts')))
SELECTdbo.ToJSON(@MyHierarchy)
 
DECLARE @MyHierarchy Hierarchy
INSERT INTO @myHierarchy
SELECT* from dbo.ParseXML('<root><CSV><item Year="1997" Make="Ford" Model="E350" Description="ac, abs, moon" Price="3000.00" /><item Year="1999" Make="Chevy" Model="Venture &quot;Extended Edition&quot;" Description="" Price="4900.00" /><item Year="1999" Make="Chevy" Model="Venture &quot;Extended Edition, Very Large&quot;" Description="" Price="5000.00" /><item Year="1996" Make="Jeep" Model="Grand Cherokee" Description="MUST SELL!
air, moon roof, loaded" Price="4799.00" /></CSV></root>')
SELECTdbo.ToJSON(@MyHierarchy)
 
*/
RETURNS @Hierarchy TABLE
 (
    Element_ID INT PRIMARY KEY, /* internal surrogate primary key gives the order of parsing and the list order */
    SequenceNo INT NULL, /* the sequence number in a list */
    Parent_ID INT,/* if the element has a parent then it is in this column. The document is the ultimate parent, so you can get the structure from recursing from the document */
    [Object_ID] INT,/* each list or object has an object id. This ties all elements to a parent. Lists are treated as objects here */
    [Name] NVARCHAR(2000),/* the name of the object */
    StringValue NVARCHAR(MAX) NOT NULL,/*the string representation of the value of the element. */
    ValueType VARCHAR(10) NOT NULL /* the declared type of the value represented as a string in StringValue*/
 )
   AS 
 BEGIN
 DECLARE  @Insertions TABLE(
     Element_ID INT IDENTITY PRIMARY KEY,
     SequenceNo INT,
     TheLevel INT,
     Parent_ID INT,
     [Object_ID] INT,
     [Name] VARCHAR(50),
     StringValue VARCHAR(MAX),
     ValueType VARCHAR(10),
     TheNextLevel XML,
     ThisLevel XML)
     
 DECLARE @RowCount INT, @ii INT
 --get the base-level nodes into the table
 INSERT INTO @Insertions (TheLevel, Parent_ID, [Object_ID], [Name], StringValue, SequenceNo, TheNextLevel, ThisLevel)
  SELECT   1 AS TheLevel, NULL AS Parent_ID, NULL AS [Object_ID], 
    FirstLevel.value('local-name(.)', 'varchar(255)') AS [Name], --the name of the element
    FirstLevel.value('text()[1]','varchar(max)') AS StringValue,-- its value as a string
    ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS SequenceNo,--the 'child number' (simple number sequence here)
    FirstLevel.query('*'), --The 'inner XML' of the current child  
    FirstLevel.query('.')  --the XML of the parent
  FROM @XML_Result.nodes('/*') a(FirstLevel) --get all nodes from the XML
 SELECT @RowCount=@@RowCount --we need this to work out if we are rendering an object or a list.
 SELECT @ii=2
 WHILE @RowCount>0 --while loop to avoid recursion.
  BEGIN
  INSERT INTO @Insertions (TheLevel, Parent_ID, [Object_ID], [Name], StringValue, SequenceNo, TheNextLevel, ThisLevel)
   SELECT --all the elements first
   @ii AS TheLevel, --(2 to the final level)
     a.Element_ID, --the parent node
     NULL, --we do this later. The object ID is merely a surrogate key to distinguish each node
     [then].value('local-name(.)', 'varchar(255)') AS [name], --the name
     [then].value('text()[1]','varchar(max)') AS [value], --the value
     ROW_NUMBER() OVER(PARTITION BY a.Element_ID ORDER BY (SELECT 1)),--the order in the sequence
     [then].query('*'), --the 'inner' XML for the node
     [then].query('.') --the XML from which this node was extracted
   FROM   @Insertions a
     CROSS apply a.TheNextLevel.nodes('*') whatsNext([then])
   WHERE a.TheLevel = @ii - 1 --only look at the previous level
  UNION ALL -- to pick out the attributes of the preceding level
  SELECT @ii AS TheLevel,
     a.Element_ID,--the parent node
     NULL,--we do this later. The object ID is merely a surrogate key to distinguish each node
     [then].value('local-name(.)', 'varchar(255)') AS [name], --the name
     [then].value('.','varchar(max)') AS [value],--the value
     ROW_NUMBER() OVER(PARTITION BY a.Element_ID ORDER BY (SELECT 1)),--the order in the sequence
   '' , ''--no nodes 
   FROM   @Insertions a  
     CROSS apply a.ThisLevel.nodes('/*/@*') whatsNext([then])--just find the attributes
   WHERE a.TheLevel = @ii - 1 OPTION (RECOMPILE)
  SELECT @RowCount=@@ROWCOUNT
  SELECT @ii=@ii+1
  END;
  --roughly type the DataTypes (no XSD available here) 
 UPDATE @Insertions SET
    [Object_ID]=CASE WHEN StringValue IS NULL THEN Element_ID 
  ELSE NULL END,
    ValueType = CASE
     WHEN StringValue IS NULL THEN 'object'
     WHEN  LEN(StringValue)=0 THEN 'string'
     WHEN StringValue LIKE '%[^0-9.-]%' THEN 'string'
     WHEN StringValue LIKE '[0-9]' THEN 'int'
     WHEN RIGHT(StringValue, LEN(StringValue)-1) LIKE'%[^0-9.]%' THEN 'string'
     WHEN  StringValue LIKE'%[0-9][.][0-9]%' THEN 'real'
     WHEN StringValue LIKE '%[^0-9]%' THEN 'string'
  ELSE 'int' END--and find the arrays
 UPDATE @Insertions SET
    ValueType='array'
  WHERE Element_ID IN(
  SELECT candidates.Parent_ID 
   FROM
   (
   SELECT Parent_ID, COUNT(*) AS SameName 
    FROM @Insertions --where they all have the same name (a sure sign)
    GROUP BY [Name],Parent_ID --no lists in XML
    HAVING COUNT(*)>1) candidates
     INNER JOIN  @Insertions insertions
     ON candidates.Parent_ID= insertions.Parent_ID
   GROUP BY candidates.Parent_ID 
   HAVING COUNT(*)=MIN(SameName))-- 
 INSERT INTO @Hierarchy (Element_ID,SequenceNo, Parent_ID, [Object_ID], [Name], StringValue,ValueType)
  SELECT Element_ID, SequenceNo, Parent_ID, [Object_ID], [Name], COALESCE(StringValue,''), ValueType
  FROM @Insertions--and insert them into the hierarchy.
 RETURN
 END
 
 go 
CREATE FUNCTION ToJSON
	(
	      @Hierarchy Hierarchy READONLY
	)
	 
	/*
	the function that takes a Hierarchy table and converts it to a JSON string
	 
	Author: Phil Factor
	Revision: 1.5
	date: 1 May 2014
	why: Added a fix to add a name for a list.
	example:
	 
	Declare @XMLSample XML
	Select @XMLSample='
	  <glossary><title>example glossary</title>
	  <GlossDiv><title>S</title>
	   <GlossList>
	    <GlossEntry id="SGML"" SortAs="SGML">
	     <GlossTerm>Standard Generalized Markup Language</GlossTerm>
	     <Acronym>SGML</Acronym>
	     <Abbrev>ISO 8879:1986</Abbrev>
	     <GlossDef>
	      <para>A meta-markup language, used to create markup languages such as DocBook.</para>
	      <GlossSeeAlso OtherTerm="GML" />
	      <GlossSeeAlso OtherTerm="XML" />
	     </GlossDef>
	     <GlossSee OtherTerm="markup" />
	    </GlossEntry>
	   </GlossList>
	  </GlossDiv>
	 </glossary>'
	 
	DECLARE @MyHierarchy Hierarchy -- to pass the hierarchy table around
	insert into @MyHierarchy select * from dbo.ParseXML(@XMLSample)
	SELECT dbo.ToJSON(@MyHierarchy)
	 
	       */
	RETURNS NVARCHAR(MAX)--JSON documents are always unicode.
	AS
	BEGIN
	  DECLARE
	    @JSON NVARCHAR(MAX),
	    @NewJSON NVARCHAR(MAX),
	    @Where INT,
	    @ANumber INT,
	    @notNumber INT,
	    @indent INT,
	    @ii int,
	    @CrLf CHAR(2)--just a simple utility to save typing!
	      
	  --firstly get the root token into place 
	  SELECT @CrLf=CHAR(13)+CHAR(10),--just CHAR(10) in UNIX
	         @JSON = CASE ValueType WHEN 'array' THEN 
	         +COALESCE('{'+@CrLf+'  "'+NAME+'" : ','')+'[' 
	         ELSE '{' END
	            +@CrLf
	            + case when ValueType='array' and NAME is not null then '  ' else '' end
	            + '@Object'+CONVERT(VARCHAR(5),OBJECT_ID)
	            +@CrLf+CASE ValueType WHEN 'array' THEN
	            case when NAME is null then ']' else '  ]'+@CrLf+'}'+@CrLf end
	                ELSE '}' END
	  FROM @Hierarchy 
	    WHERE parent_id IS NULL AND valueType IN ('object','document','array') --get the root element
	/* now we simply iterat from the root token growing each branch and leaf in each iteration. This won't be enormously quick, but it is simple to do. All values, or name/value pairs withing a structure can be created in one SQL Statement*/
	  Select @ii=1000
	  WHILE @ii>0
	    begin
	    SELECT @where= PATINDEX('%[^[a-zA-Z0-9]@Object%',@json)--find NEXT token
	    if @where=0 BREAK
	    /* this is slightly painful. we get the indent of the object we've found by looking backwards up the string */ 
	    SET @indent=CHARINDEX(char(10)+char(13),Reverse(LEFT(@json,@where))+char(10)+char(13))-1
	    SET @NotNumber= PATINDEX('%[^0-9]%', RIGHT(@json,LEN(@JSON+'|')-@Where-8)+' ')--find NEXT token
	    SET @NewJSON=NULL --this contains the structure in its JSON form
	    SELECT  
	        @NewJSON=COALESCE(@NewJSON+','+@CrLf+SPACE(@indent),'')
	        +case when parent.ValueType='array' then '' else COALESCE('"'+TheRow.NAME+'" : ','') end
	        +CASE TheRow.valuetype
	        WHEN 'array' THEN '  ['+@CrLf+SPACE(@indent+2)
	           +'@Object'+CONVERT(VARCHAR(5),TheRow.[OBJECT_ID])+@CrLf+SPACE(@indent+2)+']' 
	        WHEN 'object' then '  {'+@CrLf+SPACE(@indent+2)
	           +'@Object'+CONVERT(VARCHAR(5),TheRow.[OBJECT_ID])+@CrLf+SPACE(@indent+2)+'}'
	        WHEN 'string' THEN '"'+dbo.JSONEscaped(TheRow.StringValue)+'"'
	        ELSE TheRow.StringValue
	       END 
	     FROM @Hierarchy TheRow 
	     inner join @hierarchy Parent
	     on parent.element_ID=TheRow.parent_ID
	      WHERE TheRow.parent_id= SUBSTRING(@JSON,@where+8, @Notnumber-1)
	     /* basically, we just lookup the structure based on the ID that is appended to the @Object token. Simple eh? */
	    --now we replace the token with the structure, maybe with more tokens in it.
	    Select @JSON=STUFF (@JSON, @where+1, 8+@NotNumber-1, @NewJSON),@ii=@ii-1
	    end
	  return @JSON
	end
	go
GO


CREATE FUNCTION dbo.parseJSON( @JSON NVARCHAR(MAX))
	RETURNS @hierarchy TABLE
	  (
	   element_id INT IDENTITY(1, 1) NOT NULL, /* internal surrogate primary key gives the order of parsing and the list order */
	   sequenceNo [int] NULL, /* the place in the sequence for the element */
	   parent_ID INT,/* if the element has a parent then it is in this column. The document is the ultimate parent, so you can get the structure from recursing from the document */
	   Object_ID INT,/* each list or object has an object id. This ties all elements to a parent. Lists are treated as objects here */
	   NAME NVARCHAR(2000),/* the name of the object */
	   StringValue NVARCHAR(MAX) NOT NULL,/*the string representation of the value of the element. */
	   ValueType VARCHAR(10) NOT null /* the declared type of the value represented as a string in StringValue*/
	  )
	AS
	BEGIN
	  DECLARE
	    @FirstObject INT, --the index of the first open bracket found in the JSON string
	    @OpenDelimiter INT,--the index of the next open bracket found in the JSON string
	    @NextOpenDelimiter INT,--the index of subsequent open bracket found in the JSON string
	    @NextCloseDelimiter INT,--the index of subsequent close bracket found in the JSON string
	    @Type NVARCHAR(10),--whether it denotes an object or an array
	    @NextCloseDelimiterChar CHAR(1),--either a '}' or a ']'
	    @Contents NVARCHAR(MAX), --the unparsed contents of the bracketed expression
	    @Start INT, --index of the start of the token that you are parsing
	    @end INT,--index of the end of the token that you are parsing
	    @param INT,--the parameter at the end of the next Object/Array token
	    @EndOfName INT,--the index of the start of the parameter at end of Object/Array token
	    @token NVARCHAR(200),--either a string or object
	    @value NVARCHAR(MAX), -- the value as a string
	    @SequenceNo int, -- the sequence number within a list
	    @name NVARCHAR(200), --the name as a string
	    @parent_ID INT,--the next parent ID to allocate
	    @lenJSON INT,--the current length of the JSON String
	    @characters NCHAR(36),--used to convert hex to decimal
	    @result BIGINT,--the value of the hex symbol being parsed
	    @index SMALLINT,--used for parsing the hex value
	    @Escape INT --the index of the next escape character
	    
	  DECLARE @Strings TABLE /* in this temporary table we keep all strings, even the names of the elements, since they are 'escaped' in a different way, and may contain, unescaped, brackets denoting objects or lists. These are replaced in the JSON string by tokens representing the string */
	    (
	     String_ID INT IDENTITY(1, 1),
	     StringValue NVARCHAR(MAX)
	    )
	  SELECT--initialise the characters to convert hex to ascii
	    @characters='0123456789abcdefghijklmnopqrstuvwxyz',
	    @SequenceNo=0, --set the sequence no. to something sensible.
	  /* firstly we process all strings. This is done because [{} and ] aren't escaped in strings, which complicates an iterative parse. */
	    @parent_ID=0;
	  WHILE 1=1 --forever until there is nothing more to do
	    BEGIN
	      SELECT
	        @start=PATINDEX('%[^a-zA-Z]["]%', @json collate SQL_Latin1_General_CP850_Bin);--next delimited string
	      IF @start=0 BREAK --no more so drop through the WHILE loop
	      IF SUBSTRING(@json, @start+1, 1)='"' 
	        BEGIN --Delimited Name
	          SET @start=@Start+1;
	          SET @end=PATINDEX('%[^\]["]%', RIGHT(@json, LEN(@json+'|')-@start) collate SQL_Latin1_General_CP850_Bin);
	        END
	      IF @end=0 --no end delimiter to last string
	        BREAK --no more
	      SELECT @token=SUBSTRING(@json, @start+1, @end-1)
	      --now put in the escaped control characters
	      SELECT @token=REPLACE(@token, FROMString, TOString)
	      FROM
	        (SELECT
	          '\"' AS FromString, '"' AS ToString
	         UNION ALL SELECT '\\', '\'
	         UNION ALL SELECT '\/', '/'
	         UNION ALL SELECT '\b', CHAR(08)
	         UNION ALL SELECT '\f', CHAR(12)
	         UNION ALL SELECT '\n', CHAR(10)
	         UNION ALL SELECT '\r', CHAR(13)
	         UNION ALL SELECT '\t', CHAR(09)
	        ) substitutions
	      SELECT @result=0, @escape=1
	  --Begin to take out any hex escape codes
	      WHILE @escape>0
	        BEGIN
	          SELECT @index=0,
	          --find the next hex escape sequence
	          @escape=PATINDEX('%\x[0-9a-f][0-9a-f][0-9a-f][0-9a-f]%', @token collate SQL_Latin1_General_CP850_Bin)
	          IF @escape>0 --if there is one
	            BEGIN
	              WHILE @index<4 --there are always four digits to a \x sequence   
	                BEGIN
	                  SELECT --determine its value
	                    @result=@result+POWER(16, @index)
	                    *(CHARINDEX(SUBSTRING(@token, @escape+2+3-@index, 1),
	                                @characters)-1), @index=@index+1 ;
	         
	                END
	                -- and replace the hex sequence by its unicode value
	              SELECT @token=STUFF(@token, @escape, 6, NCHAR(@result))
	            END
	        END
	      --now store the string away 
	      INSERT INTO @Strings (StringValue) SELECT @token
	      -- and replace the string with a token
	      SELECT @JSON=STUFF(@json, @start, @end+1,
	                    '@string'+CONVERT(NVARCHAR(5), @@identity))
	    END
	  -- all strings are now removed. Now we find the first leaf.  
	  WHILE 1=1  --forever until there is nothing more to do
	  BEGIN
	 
	  SELECT @parent_ID=@parent_ID+1
	  --find the first object or list by looking for the open bracket
	  SELECT @FirstObject=PATINDEX('%[{[[]%', @json collate SQL_Latin1_General_CP850_Bin)--object or array
	  IF @FirstObject = 0 BREAK
	  IF (SUBSTRING(@json, @FirstObject, 1)='{') 
	    SELECT @NextCloseDelimiterChar='}', @type='object'
	  ELSE 
	    SELECT @NextCloseDelimiterChar=']', @type='array'
	  SELECT @OpenDelimiter=@firstObject
	  WHILE 1=1 --find the innermost object or list...
	    BEGIN
	      SELECT
	        @lenJSON=LEN(@JSON+'|')-1
	  --find the matching close-delimiter proceeding after the open-delimiter
	      SELECT
	        @NextCloseDelimiter=CHARINDEX(@NextCloseDelimiterChar, @json,
	                                      @OpenDelimiter+1)
	  --is there an intervening open-delimiter of either type
	      SELECT @NextOpenDelimiter=PATINDEX('%[{[[]%',
	             RIGHT(@json, @lenJSON-@OpenDelimiter)collate SQL_Latin1_General_CP850_Bin)--object
	      IF @NextOpenDelimiter=0 
	        BREAK
	      SELECT @NextOpenDelimiter=@NextOpenDelimiter+@OpenDelimiter
	      IF @NextCloseDelimiter<@NextOpenDelimiter 
	        BREAK
	      IF SUBSTRING(@json, @NextOpenDelimiter, 1)='{' 
	        SELECT @NextCloseDelimiterChar='}', @type='object'
	      ELSE 
	        SELECT @NextCloseDelimiterChar=']', @type='array'
	      SELECT @OpenDelimiter=@NextOpenDelimiter
	    END
	  ---and parse out the list or name/value pairs
	  SELECT
	    @contents=SUBSTRING(@json, @OpenDelimiter+1,
	                        @NextCloseDelimiter-@OpenDelimiter-1)
	  SELECT
	    @JSON=STUFF(@json, @OpenDelimiter,
	                @NextCloseDelimiter-@OpenDelimiter+1,
	                '@'+@type+CONVERT(NVARCHAR(5), @parent_ID))
	  WHILE (PATINDEX('%[A-Za-z0-9@+.e]%', @contents collate SQL_Latin1_General_CP850_Bin))<>0 
	    BEGIN
	      IF @Type='Object' --it will be a 0-n list containing a string followed by a string, number,boolean, or null
	        BEGIN
	          SELECT
	            @SequenceNo=0,@end=CHARINDEX(':', ' '+@contents)--if there is anything, it will be a string-based name.
	          SELECT  @start=PATINDEX('%[^A-Za-z@][@]%', ' '+@contents collate SQL_Latin1_General_CP850_Bin)--AAAAAAAA
	          SELECT @token=SUBSTRING(' '+@contents, @start+1, @End-@Start-1),
	            @endofname=PATINDEX('%[0-9]%', @token collate SQL_Latin1_General_CP850_Bin),
	            @param=RIGHT(@token, LEN(@token)-@endofname+1)
	          SELECT
	            @token=LEFT(@token, @endofname-1),
	            @Contents=RIGHT(' '+@contents, LEN(' '+@contents+'|')-@end-1)
	          SELECT  @name=stringvalue FROM @strings
	            WHERE string_id=@param --fetch the name
	        END
	      ELSE 
	        SELECT @Name=null,@SequenceNo=@SequenceNo+1 
	      SELECT
	        @end=CHARINDEX(',', @contents)-- a string-token, object-token, list-token, number,boolean, or null
                IF @end=0
	        --HR Engineering notation bugfix start
	          IF ISNUMERIC(@contents) = 1
		    SELECT @end = LEN(@contents)
	          Else
	        --HR Engineering notation bugfix end 
		  SELECT  @end=PATINDEX('%[A-Za-z0-9@+.e][^A-Za-z0-9@+.e]%', @contents+' ' collate SQL_Latin1_General_CP850_Bin) + 1
	       SELECT
	        @start=PATINDEX('%[^A-Za-z0-9@+.e][A-Za-z0-9@+.e]%', ' '+@contents collate SQL_Latin1_General_CP850_Bin)
	      --select @start,@end, LEN(@contents+'|'), @contents  
	      SELECT
	        @Value=RTRIM(SUBSTRING(@contents, @start, @End-@Start)),
	        @Contents=RIGHT(@contents+' ', LEN(@contents+'|')-@end)
	      IF SUBSTRING(@value, 1, 7)='@object' 
	        INSERT INTO @hierarchy
	          (NAME, SequenceNo, parent_ID, StringValue, Object_ID, ValueType)
	          SELECT @name, @SequenceNo, @parent_ID, SUBSTRING(@value, 8, 5),
	            SUBSTRING(@value, 8, 5), 'object' 
	      ELSE 
	        IF SUBSTRING(@value, 1, 6)='@array' 
	          INSERT INTO @hierarchy
	            (NAME, SequenceNo, parent_ID, StringValue, Object_ID, ValueType)
	            SELECT @name, @SequenceNo, @parent_ID, SUBSTRING(@value, 7, 5),
	              SUBSTRING(@value, 7, 5), 'array' 
	        ELSE 
	          IF SUBSTRING(@value, 1, 7)='@string' 
	            INSERT INTO @hierarchy
	              (NAME, SequenceNo, parent_ID, StringValue, ValueType)
	              SELECT @name, @SequenceNo, @parent_ID, stringvalue, 'string'
	              FROM @strings
	              WHERE string_id=SUBSTRING(@value, 8, 5)
	          ELSE 
	            IF @value IN ('true', 'false') 
	              INSERT INTO @hierarchy
	                (NAME, SequenceNo, parent_ID, StringValue, ValueType)
	                SELECT @name, @SequenceNo, @parent_ID, @value, 'boolean'
	            ELSE
	              IF @value='null' 
	                INSERT INTO @hierarchy
	                  (NAME, SequenceNo, parent_ID, StringValue, ValueType)
	                  SELECT @name, @SequenceNo, @parent_ID, @value, 'null'
	              ELSE
	                IF PATINDEX('%[^0-9]%', @value collate SQL_Latin1_General_CP850_Bin)>0 
	                  INSERT INTO @hierarchy
	                    (NAME, SequenceNo, parent_ID, StringValue, ValueType)
	                    SELECT @name, @SequenceNo, @parent_ID, @value, 'real'
	                ELSE
	                  INSERT INTO @hierarchy
	                    (NAME, SequenceNo, parent_ID, StringValue, ValueType)
	                    SELECT @name, @SequenceNo, @parent_ID, @value, 'int'
	      if @Contents=' ' Select @SequenceNo=0
	    END
	  END
	INSERT INTO @hierarchy (NAME, SequenceNo, parent_ID, StringValue, Object_ID, ValueType)
	  SELECT '-',1, NULL, '', @parent_id-1, @type
	--
	   RETURN
	END
GO

CREATE TYPE dbo.Hierarchy AS TABLE
	/*Markup languages such as JSON and XML all represent object data as hierarchies. Although it looks very different to the entity-relational model, it isn't. It is rather more a different perspective on the same model. The first trick is to represent it as a Adjacency list hierarchy in a table, and then use the contents of this table to update the database. This Adjacency list is really the Database equivalent of any of the nested data structures that are used for the interchange of serialized information with the application, and can be used to create XML, OSX Property lists, Python nested structures or YAML as easily as JSON.
	
	Adjacency list tables have the same structure whatever the data in them. This means that you can define a single Table-Valued  Type and pass data structures around between stored procedures. However, they are best held at arms-length from the data, since they are not relational tables, but something more like the dreaded EAV (Entity-Attribute-Value) tables. Converting the data from its Hierarchical table form will be different for each application, but is easy with a CTE. You can, alternatively, convert the hierarchical table into XML and interrogate that with XQuery
	*/
	(
	   element_id INT primary key, /* internal surrogate primary key gives the order of parsing and the list order */
	   sequenceNo int NULL, /* the place in the sequence for the element */
	   parent_ID INT,/* if the element has a parent then it is in this column. The document is the ultimate parent, so you can get the structure from recursing from the document */
	   [Object_ID] INT,/* each list or object has an object id. This ties all elements to a parent. Lists are treated as objects here */
	   NAME NVARCHAR(2000),/* the name of the object, null if it hasn't got one */
	   StringValue NVARCHAR(MAX) NOT NULL,/*the string representation of the value of the element. */
	   ValueType VARCHAR(10) NOT null /* the declared type of the value represented as a string in StringValue*/
	)
GO
IF OBJECT_ID (N'dbo.ParseXML') IS NOT NULL
   DROP FUNCTION dbo.ParseXML
GO
CREATE FUNCTION dbo.ParseXML( @XML_Result XML)
/* 
Returns a hierarchy table from an XML document.
Author: Phil Factor
Revision: 1.2
date: 1 May 2014
example:
 
DECLARE @MyHierarchy Hierarchy
INSERT INTO @myHierarchy
SELECT* from dbo.ParseXML((SELECT* from adventureworks.person.contact where contactID in (123,124,125) FOR XML path('contact'), root('contacts')))
SELECTdbo.ToJSON(@MyHierarchy)
 
DECLARE @MyHierarchy Hierarchy
INSERT INTO @myHierarchy
SELECT* from dbo.ParseXML('<root><CSV><item Year="1997" Make="Ford" Model="E350" Description="ac, abs, moon" Price="3000.00" /><item Year="1999" Make="Chevy" Model="Venture &quot;Extended Edition&quot;" Description="" Price="4900.00" /><item Year="1999" Make="Chevy" Model="Venture &quot;Extended Edition, Very Large&quot;" Description="" Price="5000.00" /><item Year="1996" Make="Jeep" Model="Grand Cherokee" Description="MUST SELL!
air, moon roof, loaded" Price="4799.00" /></CSV></root>')
SELECTdbo.ToJSON(@MyHierarchy)
 
*/
RETURNS @Hierarchy TABLE
 (
    Element_ID INT PRIMARY KEY, /* internal surrogate primary key gives the order of parsing and the list order */
    SequenceNo INT NULL, /* the sequence number in a list */
    Parent_ID INT,/* if the element has a parent then it is in this column. The document is the ultimate parent, so you can get the structure from recursing from the document */
    [Object_ID] INT,/* each list or object has an object id. This ties all elements to a parent. Lists are treated as objects here */
    [Name] NVARCHAR(2000),/* the name of the object */
    StringValue NVARCHAR(MAX) NOT NULL,/*the string representation of the value of the element. */
    ValueType VARCHAR(10) NOT NULL /* the declared type of the value represented as a string in StringValue*/
 )
   AS 
 BEGIN
 DECLARE  @Insertions TABLE(
     Element_ID INT IDENTITY PRIMARY KEY,
     SequenceNo INT,
     TheLevel INT,
     Parent_ID INT,
     [Object_ID] INT,
     [Name] VARCHAR(50),
     StringValue VARCHAR(MAX),
     ValueType VARCHAR(10),
     TheNextLevel XML,
     ThisLevel XML)
     
 DECLARE @RowCount INT, @ii INT
 --get the base-level nodes into the table
 INSERT INTO @Insertions (TheLevel, Parent_ID, [Object_ID], [Name], StringValue, SequenceNo, TheNextLevel, ThisLevel)
  SELECT   1 AS TheLevel, NULL AS Parent_ID, NULL AS [Object_ID], 
    FirstLevel.value('local-name(.)', 'varchar(255)') AS [Name], --the name of the element
    FirstLevel.value('text()[1]','varchar(max)') AS StringValue,-- its value as a string
    ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS SequenceNo,--the 'child number' (simple number sequence here)
    FirstLevel.query('*'), --The 'inner XML' of the current child  
    FirstLevel.query('.')  --the XML of the parent
  FROM @XML_Result.nodes('/*') a(FirstLevel) --get all nodes from the XML
 SELECT @RowCount=@@RowCount --we need this to work out if we are rendering an object or a list.
 SELECT @ii=2
 WHILE @RowCount>0 --while loop to avoid recursion.
  BEGIN
  INSERT INTO @Insertions (TheLevel, Parent_ID, [Object_ID], [Name], StringValue, SequenceNo, TheNextLevel, ThisLevel)
   SELECT --all the elements first
   @ii AS TheLevel, --(2 to the final level)
     a.Element_ID, --the parent node
     NULL, --we do this later. The object ID is merely a surrogate key to distinguish each node
     [then].value('local-name(.)', 'varchar(255)') AS [name], --the name
     [then].value('text()[1]','varchar(max)') AS [value], --the value
     ROW_NUMBER() OVER(PARTITION BY a.Element_ID ORDER BY (SELECT 1)),--the order in the sequence
     [then].query('*'), --the 'inner' XML for the node
     [then].query('.') --the XML from which this node was extracted
   FROM   @Insertions a
     CROSS apply a.TheNextLevel.nodes('*') whatsNext([then])
   WHERE a.TheLevel = @ii - 1 --only look at the previous level
  UNION ALL -- to pick out the attributes of the preceding level
  SELECT @ii AS TheLevel,
     a.Element_ID,--the parent node
     NULL,--we do this later. The object ID is merely a surrogate key to distinguish each node
     [then].value('local-name(.)', 'varchar(255)') AS [name], --the name
     [then].value('.','varchar(max)') AS [value],--the value
     ROW_NUMBER() OVER(PARTITION BY a.Element_ID ORDER BY (SELECT 1)),--the order in the sequence
   '' , ''--no nodes 
   FROM   @Insertions a  
     CROSS apply a.ThisLevel.nodes('/*/@*') whatsNext([then])--just find the attributes
   WHERE a.TheLevel = @ii - 1 OPTION (RECOMPILE)
  SELECT @RowCount=@@ROWCOUNT
  SELECT @ii=@ii+1
  END;
  --roughly type the DataTypes (no XSD available here) 
 UPDATE @Insertions SET
    [Object_ID]=CASE WHEN StringValue IS NULL THEN Element_ID 
  ELSE NULL END,
    ValueType = CASE
     WHEN StringValue IS NULL THEN 'object'
     WHEN  LEN(StringValue)=0 THEN 'string'
     WHEN StringValue LIKE '%[^0-9.-]%' THEN 'string'
     WHEN StringValue LIKE '[0-9]' THEN 'int'
     WHEN RIGHT(StringValue, LEN(StringValue)-1) LIKE'%[^0-9.]%' THEN 'string'
     WHEN  StringValue LIKE'%[0-9][.][0-9]%' THEN 'real'
     WHEN StringValue LIKE '%[^0-9]%' THEN 'string'
  ELSE 'int' END--and find the arrays
 UPDATE @Insertions SET
    ValueType='array'
  WHERE Element_ID IN(
  SELECT candidates.Parent_ID 
   FROM
   (
   SELECT Parent_ID, COUNT(*) AS SameName 
    FROM @Insertions --where they all have the same name (a sure sign)
    GROUP BY [Name],Parent_ID --no lists in XML
    HAVING COUNT(*)>1) candidates
     INNER JOIN  @Insertions insertions
     ON candidates.Parent_ID= insertions.Parent_ID
   GROUP BY candidates.Parent_ID 
   HAVING COUNT(*)=MIN(SameName))-- 
 INSERT INTO @Hierarchy (Element_ID,SequenceNo, Parent_ID, [Object_ID], [Name], StringValue,ValueType)
  SELECT Element_ID, SequenceNo, Parent_ID, [Object_ID], [Name], COALESCE(StringValue,''), ValueType
  FROM @Insertions--and insert them into the hierarchy.
 RETURN
 END
 GO
 
GO
CREATE FUNCTION ToJSON
	(
	      @Hierarchy Hierarchy READONLY
	)
	 
	/*
	the function that takes a Hierarchy table and converts it to a JSON string
	 
	Author: Phil Factor
	Revision: 1.5
	date: 1 May 2014
	why: Added a fix to add a name for a list.
	example:
	 
	Declare @XMLSample XML
	Select @XMLSample='
	  <glossary><title>example glossary</title>
	  <GlossDiv><title>S</title>
	   <GlossList>
	    <GlossEntry id="SGML"" SortAs="SGML">
	     <GlossTerm>Standard Generalized Markup Language</GlossTerm>
	     <Acronym>SGML</Acronym>
	     <Abbrev>ISO 8879:1986</Abbrev>
	     <GlossDef>
	      <para>A meta-markup language, used to create markup languages such as DocBook.</para>
	      <GlossSeeAlso OtherTerm="GML" />
	      <GlossSeeAlso OtherTerm="XML" />
	     </GlossDef>
	     <GlossSee OtherTerm="markup" />
	    </GlossEntry>
	   </GlossList>
	  </GlossDiv>
	 </glossary>'
	 
	DECLARE @MyHierarchy Hierarchy -- to pass the hierarchy table around
	insert into @MyHierarchy select * from dbo.ParseXML(@XMLSample)
	SELECT dbo.ToJSON(@MyHierarchy)
	 
	       */
	RETURNS NVARCHAR(MAX)--JSON documents are always unicode.
	AS
	BEGIN
	  DECLARE
	    @JSON NVARCHAR(MAX),
	    @NewJSON NVARCHAR(MAX),
	    @Where INT,
	    @ANumber INT,
	    @notNumber INT,
	    @indent INT,
	    @ii int,
	    @CrLf CHAR(2)--just a simple utility to save typing!
	      
	  --firstly get the root token into place 
	  SELECT @CrLf=CHAR(13)+CHAR(10),--just CHAR(10) in UNIX
	         @JSON = CASE ValueType WHEN 'array' THEN 
	         +COALESCE('{'+@CrLf+'  "'+NAME+'" : ','')+'[' 
	         ELSE '{' END
	            +@CrLf
	            + case when ValueType='array' and NAME is not null then '  ' else '' end
	            + '@Object'+CONVERT(VARCHAR(5),OBJECT_ID)
	            +@CrLf+CASE ValueType WHEN 'array' THEN
	            case when NAME is null then ']' else '  ]'+@CrLf+'}'+@CrLf end
	                ELSE '}' END
	  FROM @Hierarchy 
	    WHERE parent_id IS NULL AND valueType IN ('object','document','array') --get the root element
	/* now we simply iterat from the root token growing each branch and leaf in each iteration. This won't be enormously quick, but it is simple to do. All values, or name/value pairs withing a structure can be created in one SQL Statement*/
	  Select @ii=1000
	  WHILE @ii>0
	    begin
	    SELECT @where= PATINDEX('%[^[a-zA-Z0-9]@Object%',@json)--find NEXT token
	    if @where=0 BREAK
	    /* this is slightly painful. we get the indent of the object we've found by looking backwards up the string */ 
	    SET @indent=CHARINDEX(char(10)+char(13),Reverse(LEFT(@json,@where))+char(10)+char(13))-1
	    SET @NotNumber= PATINDEX('%[^0-9]%', RIGHT(@json,LEN(@JSON+'|')-@Where-8)+' ')--find NEXT token
	    SET @NewJSON=NULL --this contains the structure in its JSON form
	    SELECT  
	        @NewJSON=COALESCE(@NewJSON+','+@CrLf+SPACE(@indent),'')
	        +case when parent.ValueType='array' then '' else COALESCE('"'+TheRow.NAME+'" : ','') end
	        +CASE TheRow.valuetype
	        WHEN 'array' THEN '  ['+@CrLf+SPACE(@indent+2)
	           +'@Object'+CONVERT(VARCHAR(5),TheRow.[OBJECT_ID])+@CrLf+SPACE(@indent+2)+']' 
	        WHEN 'object' then '  {'+@CrLf+SPACE(@indent+2)
	           +'@Object'+CONVERT(VARCHAR(5),TheRow.[OBJECT_ID])+@CrLf+SPACE(@indent+2)+'}'
	        WHEN 'string' THEN '"'+dbo.JSONEscaped(TheRow.StringValue)+'"'
	        ELSE TheRow.StringValue
	       END 
	     FROM @Hierarchy TheRow 
	     inner join @hierarchy Parent
	     on parent.element_ID=TheRow.parent_ID
	      WHERE TheRow.parent_id= SUBSTRING(@JSON,@where+8, @Notnumber-1)
	     /* basically, we just lookup the structure based on the ID that is appended to the @Object token. Simple eh? */
	    --now we replace the token with the structure, maybe with more tokens in it.
	    Select @JSON=STUFF (@JSON, @where+1, 8+@NotNumber-1, @NewJSON),@ii=@ii-1
	    end
	  return @JSON
	end
	go



	

	CREATE FUNCTION dbo.parseJSON( @JSON NVARCHAR(MAX))
	RETURNS @hierarchy TABLE
	  (
	   element_id INT IDENTITY(1, 1) NOT NULL, /* internal surrogate primary key gives the order of parsing and the list order */
	   sequenceNo [int] NULL, /* the place in the sequence for the element */
	   parent_ID INT,/* if the element has a parent then it is in this column. The document is the ultimate parent, so you can get the structure from recursing from the document */
	   Object_ID INT,/* each list or object has an object id. This ties all elements to a parent. Lists are treated as objects here */
	   NAME NVARCHAR(2000),/* the name of the object */
	   StringValue NVARCHAR(MAX) NOT NULL,/*the string representation of the value of the element. */
	   ValueType VARCHAR(10) NOT null /* the declared type of the value represented as a string in StringValue*/
	  )
	AS
	BEGIN
	  DECLARE
	    @FirstObject INT, --the index of the first open bracket found in the JSON string
	    @OpenDelimiter INT,--the index of the next open bracket found in the JSON string
	    @NextOpenDelimiter INT,--the index of subsequent open bracket found in the JSON string
	    @NextCloseDelimiter INT,--the index of subsequent close bracket found in the JSON string
	    @Type NVARCHAR(10),--whether it denotes an object or an array
	    @NextCloseDelimiterChar CHAR(1),--either a '}' or a ']'
	    @Contents NVARCHAR(MAX), --the unparsed contents of the bracketed expression
	    @Start INT, --index of the start of the token that you are parsing
	    @end INT,--index of the end of the token that you are parsing
	    @param INT,--the parameter at the end of the next Object/Array token
	    @EndOfName INT,--the index of the start of the parameter at end of Object/Array token
	    @token NVARCHAR(200),--either a string or object
	    @value NVARCHAR(MAX), -- the value as a string
	    @SequenceNo int, -- the sequence number within a list
	    @name NVARCHAR(200), --the name as a string
	    @parent_ID INT,--the next parent ID to allocate
	    @lenJSON INT,--the current length of the JSON String
	    @characters NCHAR(36),--used to convert hex to decimal
	    @result BIGINT,--the value of the hex symbol being parsed
	    @index SMALLINT,--used for parsing the hex value
	    @Escape INT --the index of the next escape character
	    
	  DECLARE @Strings TABLE /* in this temporary table we keep all strings, even the names of the elements, since they are 'escaped' in a different way, and may contain, unescaped, brackets denoting objects or lists. These are replaced in the JSON string by tokens representing the string */
	    (
	     String_ID INT IDENTITY(1, 1),
	     StringValue NVARCHAR(MAX)
	    )
	  SELECT--initialise the characters to convert hex to ascii
	    @characters='0123456789abcdefghijklmnopqrstuvwxyz',
	    @SequenceNo=0, --set the sequence no. to something sensible.
	  /* firstly we process all strings. This is done because [{} and ] aren't escaped in strings, which complicates an iterative parse. */
	    @parent_ID=0;
	  WHILE 1=1 --forever until there is nothing more to do
	    BEGIN
	      SELECT
	        @start=PATINDEX('%[^a-zA-Z]["]%', @json collate SQL_Latin1_General_CP850_Bin);--next delimited string
	      IF @start=0 BREAK --no more so drop through the WHILE loop
	      IF SUBSTRING(@json, @start+1, 1)='"' 
	        BEGIN --Delimited Name
	          SET @start=@Start+1;
	          SET @end=PATINDEX('%[^\]["]%', RIGHT(@json, LEN(@json+'|')-@start) collate SQL_Latin1_General_CP850_Bin);
	        END
	      IF @end=0 --no end delimiter to last string
	        BREAK --no more
	      SELECT @token=SUBSTRING(@json, @start+1, @end-1)
	      --now put in the escaped control characters
	      SELECT @token=REPLACE(@token, FROMString, TOString)
	      FROM
	        (SELECT
	          '\"' AS FromString, '"' AS ToString
	         UNION ALL SELECT '\\', '\'
	         UNION ALL SELECT '\/', '/'
	         UNION ALL SELECT '\b', CHAR(08)
	         UNION ALL SELECT '\f', CHAR(12)
	         UNION ALL SELECT '\n', CHAR(10)
	         UNION ALL SELECT '\r', CHAR(13)
	         UNION ALL SELECT '\t', CHAR(09)
	        ) substitutions
	      SELECT @result=0, @escape=1
	  --Begin to take out any hex escape codes
	      WHILE @escape>0
	        BEGIN
	          SELECT @index=0,
	          --find the next hex escape sequence
	          @escape=PATINDEX('%\x[0-9a-f][0-9a-f][0-9a-f][0-9a-f]%', @token collate SQL_Latin1_General_CP850_Bin)
	          IF @escape>0 --if there is one
	            BEGIN
	              WHILE @index<4 --there are always four digits to a \x sequence   
	                BEGIN
	                  SELECT --determine its value
	                    @result=@result+POWER(16, @index)
	                    *(CHARINDEX(SUBSTRING(@token, @escape+2+3-@index, 1),
	                                @characters)-1), @index=@index+1 ;
	         
	                END
	                -- and replace the hex sequence by its unicode value
	              SELECT @token=STUFF(@token, @escape, 6, NCHAR(@result))
	            END
	        END
	      --now store the string away 
	      INSERT INTO @Strings (StringValue) SELECT @token
	      -- and replace the string with a token
	      SELECT @JSON=STUFF(@json, @start, @end+1,
	                    '@string'+CONVERT(NVARCHAR(5), @@identity))
	    END
	  -- all strings are now removed. Now we find the first leaf.  
	  WHILE 1=1  --forever until there is nothing more to do
	  BEGIN
	 
	  SELECT @parent_ID=@parent_ID+1
	  --find the first object or list by looking for the open bracket
	  SELECT @FirstObject=PATINDEX('%[{[[]%', @json collate SQL_Latin1_General_CP850_Bin)--object or array
	  IF @FirstObject = 0 BREAK
	  IF (SUBSTRING(@json, @FirstObject, 1)='{') 
	    SELECT @NextCloseDelimiterChar='}', @type='object'
	  ELSE 
	    SELECT @NextCloseDelimiterChar=']', @type='array'
	  SELECT @OpenDelimiter=@firstObject
	  WHILE 1=1 --find the innermost object or list...
	    BEGIN
	      SELECT
	        @lenJSON=LEN(@JSON+'|')-1
	  --find the matching close-delimiter proceeding after the open-delimiter
	      SELECT
	        @NextCloseDelimiter=CHARINDEX(@NextCloseDelimiterChar, @json,
	                                      @OpenDelimiter+1)
	  --is there an intervening open-delimiter of either type
	      SELECT @NextOpenDelimiter=PATINDEX('%[{[[]%',
	             RIGHT(@json, @lenJSON-@OpenDelimiter)collate SQL_Latin1_General_CP850_Bin)--object
	      IF @NextOpenDelimiter=0 
	        BREAK
	      SELECT @NextOpenDelimiter=@NextOpenDelimiter+@OpenDelimiter
	      IF @NextCloseDelimiter<@NextOpenDelimiter 
	        BREAK
	      IF SUBSTRING(@json, @NextOpenDelimiter, 1)='{' 
	        SELECT @NextCloseDelimiterChar='}', @type='object'
	      ELSE 
	        SELECT @NextCloseDelimiterChar=']', @type='array'
	      SELECT @OpenDelimiter=@NextOpenDelimiter
	    END
	  ---and parse out the list or name/value pairs
	  SELECT
	    @contents=SUBSTRING(@json, @OpenDelimiter+1,
	                        @NextCloseDelimiter-@OpenDelimiter-1)
	  SELECT
	    @JSON=STUFF(@json, @OpenDelimiter,
	                @NextCloseDelimiter-@OpenDelimiter+1,
	                '@'+@type+CONVERT(NVARCHAR(5), @parent_ID))
	  WHILE (PATINDEX('%[A-Za-z0-9@+.e]%', @contents collate SQL_Latin1_General_CP850_Bin))<>0 
	    BEGIN
	      IF @Type='Object' --it will be a 0-n list containing a string followed by a string, number,boolean, or null
	        BEGIN
	          SELECT
	            @SequenceNo=0,@end=CHARINDEX(':', ' '+@contents)--if there is anything, it will be a string-based name.
	          SELECT  @start=PATINDEX('%[^A-Za-z@][@]%', ' '+@contents collate SQL_Latin1_General_CP850_Bin)--AAAAAAAA
	          SELECT @token=SUBSTRING(' '+@contents, @start+1, @End-@Start-1),
	            @endofname=PATINDEX('%[0-9]%', @token collate SQL_Latin1_General_CP850_Bin),
	            @param=RIGHT(@token, LEN(@token)-@endofname+1)
	          SELECT
	            @token=LEFT(@token, @endofname-1),
	            @Contents=RIGHT(' '+@contents, LEN(' '+@contents+'|')-@end-1)
	          SELECT  @name=stringvalue FROM @strings
	            WHERE string_id=@param --fetch the name
	        END
	      ELSE 
	        SELECT @Name=null,@SequenceNo=@SequenceNo+1 
	      SELECT
	        @end=CHARINDEX(',', @contents)-- a string-token, object-token, list-token, number,boolean, or null
                IF @end=0
	        --HR Engineering notation bugfix start
	          IF ISNUMERIC(@contents) = 1
		    SELECT @end = LEN(@contents)
	          Else
	        --HR Engineering notation bugfix end 
		  SELECT  @end=PATINDEX('%[A-Za-z0-9@+.e][^A-Za-z0-9@+.e]%', @contents+' ' collate SQL_Latin1_General_CP850_Bin) + 1
	       SELECT
	        @start=PATINDEX('%[^A-Za-z0-9@+.e][A-Za-z0-9@+.e]%', ' '+@contents collate SQL_Latin1_General_CP850_Bin)
	      --select @start,@end, LEN(@contents+'|'), @contents  
	      SELECT
	        @Value=RTRIM(SUBSTRING(@contents, @start, @End-@Start)),
	        @Contents=RIGHT(@contents+' ', LEN(@contents+'|')-@end)
	      IF SUBSTRING(@value, 1, 7)='@object' 
	        INSERT INTO @hierarchy
	          (NAME, SequenceNo, parent_ID, StringValue, Object_ID, ValueType)
	          SELECT @name, @SequenceNo, @parent_ID, SUBSTRING(@value, 8, 5),
	            SUBSTRING(@value, 8, 5), 'object' 
	      ELSE 
	        IF SUBSTRING(@value, 1, 6)='@array' 
	          INSERT INTO @hierarchy
	            (NAME, SequenceNo, parent_ID, StringValue, Object_ID, ValueType)
	            SELECT @name, @SequenceNo, @parent_ID, SUBSTRING(@value, 7, 5),
	              SUBSTRING(@value, 7, 5), 'array' 
	        ELSE 
	          IF SUBSTRING(@value, 1, 7)='@string' 
	            INSERT INTO @hierarchy
	              (NAME, SequenceNo, parent_ID, StringValue, ValueType)
	              SELECT @name, @SequenceNo, @parent_ID, stringvalue, 'string'
	              FROM @strings
	              WHERE string_id=SUBSTRING(@value, 8, 5)
	          ELSE 
	            IF @value IN ('true', 'false') 
	              INSERT INTO @hierarchy
	                (NAME, SequenceNo, parent_ID, StringValue, ValueType)
	                SELECT @name, @SequenceNo, @parent_ID, @value, 'boolean'
	            ELSE
	              IF @value='null' 
	                INSERT INTO @hierarchy
	                  (NAME, SequenceNo, parent_ID, StringValue, ValueType)
	                  SELECT @name, @SequenceNo, @parent_ID, @value, 'null'
	              ELSE
	                IF PATINDEX('%[^0-9]%', @value collate SQL_Latin1_General_CP850_Bin)>0 
	                  INSERT INTO @hierarchy
	                    (NAME, SequenceNo, parent_ID, StringValue, ValueType)
	                    SELECT @name, @SequenceNo, @parent_ID, @value, 'real'
	                ELSE
	                  INSERT INTO @hierarchy
	                    (NAME, SequenceNo, parent_ID, StringValue, ValueType)
	                    SELECT @name, @SequenceNo, @parent_ID, @value, 'int'
	      if @Contents=' ' Select @SequenceNo=0
	    END
	  END
	INSERT INTO @hierarchy (NAME, SequenceNo, parent_ID, StringValue, Object_ID, ValueType)
	  SELECT '-',1, NULL, '', @parent_id-1, @type
	--
	   RETURN
	END
GO

 


SELECT  
	max(case when name='CodigoProva'			 then convert(int	,StringValue) else 0 end								)as CodigoProva
,	max(case when name='Renach'					 then convert(bigint,StringValue)			else 0 end						)as Renach
,	max(case when name='Cpf'					 then convert(bigint,StringValue)			else 0 end						)as Cpf
--,	max(case when name='CodigoConfiguracaoProva' then convert(int	,StringValue)			else 0 end						)as CodigoConfiguracaoProva
--,	max(case when name='CodigoExaminador01'		 then convert(VARCHAR(20),StringValue)	else 0 end							)as CodigoExaminador01
FROM 
	dbo.parseJSON('[{"CodigoConfiguracaoProva":1,"CodigoExaminador01":"12765","CodigoExaminador02":null,"CodigoIdentificadorComputador":107,"CodigoPresidente":"12765","CodigoProva":"51967","CodigoResultado":1,"CodigoSala":1,"CodigoUsuario":0,"Cpf":"9734792482","Dia":"2018\/05\/18","DtFim":"2018\/05\/18 09:31:55.093","DtInicio":"2018\/05\/18 08:38:01.197","Hora":"08:00","ListFotosProva":null,"ListProvasGeradas":[{"CodigoPergunta":3014,"CodigoProva":"51967","CodigoRespostaCandidato":19166,"Ordem":9},{"CodigoPergunta":3169,"CodigoProva":51967,"CodigoRespostaCandidato":19941,"Ordem":6},{"CodigoPergunta":3207,"CodigoProva":51967,"CodigoRespostaCandidato":20131,"Ordem":8},{"CodigoPergunta":3214,"CodigoProva":51967,"CodigoRespostaCandidato":20162,"Ordem":3},{"CodigoPergunta":3226,"CodigoProva":51967,"CodigoRespostaCandidato":20226,"Ordem":1},{"CodigoPergunta":3336,"CodigoProva":51967,"CodigoRespostaCandidato":20773,"Ordem":19},{"CodigoPergunta":3364,"CodigoProva":51967,"CodigoRespostaCandidato":20913,"Ordem":26},{"CodigoPergunta":3423,"CodigoProva":51967,"CodigoRespostaCandidato":21211,"Ordem":17},{"CodigoPergunta":3426,"CodigoProva":51967,"CodigoRespostaCandidato":21224,"Ordem":21},{"CodigoPergunta":3502,"CodigoProva":51967,"CodigoRespostaCandidato":21604,"Ordem":23},{"CodigoPergunta":3505,"CodigoProva":51967,"CodigoRespostaCandidato":21619,"Ordem":15},{"CodigoPergunta":3516,"CodigoProva":51967,"CodigoRespostaCandidato":21676,"Ordem":24},{"CodigoPergunta":3527,"CodigoProva":51967,"CodigoRespostaCandidato":21731,"Ordem":30},{"CodigoPergunta":3559,"CodigoProva":51967,"CodigoRespostaCandidato":21888,"Ordem":16},{"CodigoPergunta":3572,"CodigoProva":51967,"CodigoRespostaCandidato":21956,"Ordem":25},{"CodigoPergunta":3610,"CodigoProva":51967,"CodigoRespostaCandidato":22145,"Ordem":29},{"CodigoPergunta":3639,"CodigoProva":51967,"CodigoRespostaCandidato":22287,"Ordem":14},{"CodigoPergunta":3778,"CodigoProva":51967,"CodigoRespostaCandidato":22983,"Ordem":7},{"CodigoPergunta":3976,"CodigoProva":51967,"CodigoRespostaCandidato":23972,"Ordem":20},{"CodigoPergunta":3997,"CodigoProva":51967,"CodigoRespostaCandidato":24081,"Ordem":22},{"CodigoPergunta":4088,"CodigoProva":51967,"CodigoRespostaCandidato":24536,"Ordem":13},{"CodigoPergunta":4094,"CodigoProva":51967,"CodigoRespostaCandidato":24565,"Ordem":28},{"CodigoPergunta":4096,"CodigoProva":51967,"CodigoRespostaCandidato":24573,"Ordem":27},{"CodigoPergunta":4139,"CodigoProva":51967,"CodigoRespostaCandidato":24787,"Ordem":11},{"CodigoPergunta":4183,"CodigoProva":51967,"CodigoRespostaCandidato":25007,"Ordem":5},{"CodigoPergunta":4187,"CodigoProva":51967,"CodigoRespostaCandidato":25030,"Ordem":12},{"CodigoPergunta":4340,"CodigoProva":51967,"CodigoRespostaCandidato":25794,"Ordem":2},{"CodigoPergunta":4374,"CodigoProva":51967,"CodigoRespostaCandidato":25965,"Ordem":4},{"CodigoPergunta":4576,"CodigoProva":51967,"CodigoRespostaCandidato":26974,"Ordem":10},{"CodigoPergunta":4705,"CodigoProva":51967,"CodigoRespostaCandidato":27617,"Ordem":18}],"Renach":"702738557"},{"CodigoConfiguracaoProva":1,"CodigoExaminador01":"12765","CodigoExaminador02":null,"CodigoIdentificadorComputador":103,"CodigoPresidente":"12765","CodigoProva":"51959","CodigoResultado":1,"CodigoSala":1,"CodigoUsuario":0,"Cpf":"8101502475","Dia":"2018\/05\/18","DtFim":"2018\/05\/18 09:31:42.993","DtInicio":"2018\/05\/18 08:31:40.600","Hora":"08:00","ListFotosProva":null,"ListProvasGeradas":[{"CodigoPergunta":2938,"CodigoProva":51959,"CodigoRespostaCandidato":18782,"Ordem":5},{"CodigoPergunta":2940,"CodigoProva":51959,"CodigoRespostaCandidato":18792,"Ordem":1},{"CodigoPergunta":3149,"CodigoProva":51959,"CodigoRespostaCandidato":19841,"Ordem":4},{"CodigoPergunta":3186,"CodigoProva":51959,"CodigoRespostaCandidato":20025,"Ordem":3},{"CodigoPergunta":3222,"CodigoProva":51959,"CodigoRespostaCandidato":20203,"Ordem":6},{"CodigoPergunta":3277,"CodigoProva":51959,"CodigoRespostaCandidato":20481,"Ordem":17},{"CodigoPergunta":3339,"CodigoProva":51959,"CodigoRespostaCandidato":20788,"Ordem":20},{"CodigoPergunta":3366,"CodigoProva":51959,"CodigoRespostaCandidato":20926,"Ordem":25},{"CodigoPergunta":3368,"CodigoProva":51959,"CodigoRespostaCandidato":20933,"Ordem":24},{"CodigoPergunta":3373,"CodigoProva":51959,"CodigoRespostaCandidato":20960,"Ordem":23},{"CodigoPergunta":3414,"CodigoProva":51959,"CodigoRespostaCandidato":21164,"Ordem":22},{"CodigoPergunta":3471,"CodigoProva":51959,"CodigoRespostaCandidato":0,"Ordem":26},{"CodigoPergunta":3486,"CodigoProva":51959,"CodigoRespostaCandidato":21524,"Ordem":18},{"CodigoPergunta":3492,"CodigoProva":51959,"CodigoRespostaCandidato":21555,"Ordem":19},{"CodigoPergunta":3498,"CodigoProva":51959,"CodigoRespostaCandidato":21583,"Ordem":16},{"CodigoPergunta":3560,"CodigoProva":51959,"CodigoRespostaCandidato":21896,"Ordem":29},{"CodigoPergunta":3788,"CodigoProva":51959,"CodigoRespostaCandidato":23035,"Ordem":2},{"CodigoPergunta":3955,"CodigoProva":51959,"CodigoRespostaCandidato":23871,"Ordem":14},{"CodigoPergunta":4052,"CodigoProva":51959,"CodigoRespostaCandidato":24353,"Ordem":27},{"CodigoPergunta":4096,"CodigoProva":51959,"CodigoRespostaCandidato":24573,"Ordem":28},{"CodigoPergunta":4111,"CodigoProva":51959,"CodigoRespostaCandidato":24651,"Ordem":21},{"CodigoPergunta":4160,"CodigoProva":51959,"CodigoRespostaCandidato":24892,"Ordem":13},{"CodigoPergunta":4225,"CodigoProva":51959,"CodigoRespostaCandidato":25217,"Ordem":10},{"CodigoPergunta":4289,"CodigoProva":51959,"CodigoRespostaCandidato":25538,"Ordem":11},{"CodigoPergunta":4337,"CodigoProva":51959,"CodigoRespostaCandidato":25777,"Ordem":7},{"CodigoPergunta":4635,"CodigoProva":51959,"CodigoRespostaCandidato":27267,"Ordem":12},{"CodigoPergunta":4656,"CodigoProva":51959,"CodigoRespostaCandidato":27376,"Ordem":30},{"CodigoPergunta":4698,"CodigoProva":51959,"CodigoRespostaCandidato":27586,"Ordem":15},{"CodigoPergunta":4814,"CodigoProva":51959,"CodigoRespostaCandidato":28165,"Ordem":8},{"CodigoPergunta":4899,"CodigoProva":"51959","CodigoRespostaCandidato":28589,"Ordem":9}],"Renach":"703363042"}]')
where 
	ValueType in ( 'string') 
group by 
	parent_ID

	 