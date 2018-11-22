 CREATE PROCEDURE sp_scripttable ( @TableName SYSNAME,
@IncludeConstraints BIT = 1,
@IncludeIndexes     BIT = 1,
@NewTableName SYSNAME = NULL,
@UseSystemDataTypes BIT = 0 )
AS
  BEGIN
    DECLARE @MAINDEFINITION TABLE
                                  (
                                                                fieldvalue VARCHAR(200)
                                  )
    DECLARE @DBName SYSNAME
    DECLARE @ClusteredPK BIT
    DECLARE @TableSchema NVARCHAR(255)
    SET @DBName = Db_name(Db_id())
    SELECT @TableName = NAME
    FROM   sysobjects
    WHERE  id = Object_id(@TableName)
    DECLARE @SHOWFIELDS TABLE 
                              (
                                                        fieldid            int IDENTITY(1,1) ,
                                                        databasename       varchar(100) ,
                                                        tableowner         varchar(100) ,
                                                        tablename          varchar(100) ,
                                                        fieldname          varchar(100) ,
                                                        columnposition     int ,
                                                        columndefaultvalue varchar(100) ,
                                                        columndefaultname  varchar(100) ,
                                                        isnullable         bit ,
                                                        datatype           varchar(100) ,
                                                        maxlength          int ,
                                                        numericprecision   int ,
                                                        numericscale       int ,
                                                        domainname         varchar(100) ,
                                                        fieldlistingname   varchar(110) ,
                                                        fielddefinition    char(1) ,
                                                        identitycolumn     bit ,
                                                        identityseed       int ,
                                                        identityincrement  int ,
                                                        ischarcolumn       bit
                              )
    DECLARE @HOLDINGAREA TABLE
                               (
                                                          fldid    SMALLINT IDENTITY(1,1),
                                                          flds     VARCHAR(4000),
                                                          fldvalue CHAR(1) DEFAULT(0)
                               )
    DECLARE @PKOBJECTID TABLE
                              (
                                                        objectid INT
                              )
    DECLARE @UNIQUES TABLE
                           (
                                                  objectid INT
                           )
    DECLARE @HOLDINGAREAVALUES TABLE
                                     (
                                                                      fldid    SMALLINT IDENTITY(1,1),
                                                                      flds     VARCHAR(4000),
                                                                      fldvalue CHAR(1) DEFAULT(0)
                                     )
    DECLARE @DEFINITION TABLE
                              (
                                                        definitionid SMALLINT IDENTITY(1,1) ,
                                                        fieldvalue   VARCHAR(200)
                              )
    INSERT INTO @ShowFields
                (
                            databasename,
                            tableowner,
                            tablename,
                            fieldname,
                            columnposition,
                            columndefaultvalue,
                            columndefaultname,
                            isnullable ,
                            datatype,
                            maxlength,
                            numericprecision,
                            numericscale,
                            domainname ,
                            fieldlistingname,
                            fielddefinition,
                            identitycolumn,
                            identityseed,
                            identityincrement,
                            ischarcolumn
                )
    SELECT          Db_name(),
                    table_schema,
                    table_name,
                    column_name,
                    Cast(ordinal_position AS INT),
                    column_default,
                    dobj.NAME AS columndefaultname,
                    CASE
                                    WHEN c.is_nullable = 'YES' THEN 1
                                    ELSE 0
                    END,
                    data_type,
                    Cast(character_maximum_length AS INT),
                    Cast(numeric_precision AS        INT),
                    Cast(numeric_scale AS            INT),
                    domain_name,
                    column_name + ',',
                    '' AS fielddefinition,
                    CASE
                                    WHEN ic.object_id IS NULL THEN 0
                                    ELSE 1
                    END                                  AS identitycolumn,
                    Cast(Isnull(ic.seed_value,0) AS      INT) AS identityseed,
                    Cast(Isnull(ic.increment_value,0) AS INT) AS identityincrement,
                    CASE
                                    WHEN st.collation_name IS NOT NULL THEN 1
                                    ELSE 0
                    END AS ischarcolumn
    FROM            information_schema.columns c
    JOIN            sys.columns sc
    ON              c.table_name = Object_name(sc.object_id)
    AND             c.column_name = sc.NAME
    LEFT JOIN       sys.identity_columns ic
    ON              c.table_name = Object_name(ic.object_id)
    AND             c.column_name = ic.NAME
    JOIN            sys.types st
    ON              COALESCE(c.domain_name,c.data_type) = st.NAME
    LEFT OUTER JOIN sys.objects dobj
    ON              dobj.object_id = sc.default_object_id
    AND             dobj.type = 'D'
    WHERE           c.table_name = @TableName
    ORDER BY        c.table_name,
                    c.ordinal_position
    SELECT TOP 1
           @TableSchema = tableowner
    FROM   @ShowFields
    INSERT INTO @HoldingArea
                (
                            flds
                )
                VALUES
                (
                            '('
                )
    INSERT INTO @Definition
                (
                            fieldvalue
                )
                VALUES
                (
                            'CREATE TABLE ' +
                            CASE
                                        WHEN @NewTableName IS NOT NULL THEN @NewTableName
                                        ELSE @DBName + '.' + @TableSchema + '.' + @TableName
                            END
                )
    INSERT INTO @Definition
                (
                            fieldvalue
                )
                VALUES
                (
                            '('
                )
    INSERT INTO @Definition
                (
                            fieldvalue
                )
    SELECT Char(10) + fieldname + ' ' +
           CASE
                  WHEN domainname IS NOT NULL
                  AND    @UseSystemDataTypes = 0 THEN domainname +
                         CASE
                                WHEN isnullable = 1 THEN ' NULL '
                                ELSE ' NOT NULL '
                         END
                  ELSE Upper(datatype) +
                         CASE
                                WHEN ischarcolumn = 1 THEN '(' + Cast(maxlength AS VARCHAR(10)) + ')'
                                ELSE ''
                         END +
                         CASE
                                WHEN identitycolumn = 1 THEN ' IDENTITY(' + Cast(identityseed AS VARCHAR(5))+ ',' + Cast(identityincrement AS VARCHAR(5)) + ')'
                                ELSE ''
                         END +
                         CASE
                                WHEN isnullable = 1 THEN ' NULL '
                                ELSE ' NOT NULL '
                         END +
                         CASE
                                WHEN columndefaultname IS NOT NULL
                                AND    @IncludeConstraints = 1 THEN 'CONSTRAINT [' + columndefaultname + '] DEFAULT' + Upper(columndefaultvalue)
                                ELSE ''
                         END
           END +
           CASE
                  WHEN fieldid =
                         (
                                SELECT Max(fieldid)
                                FROM   @ShowFields) THEN ''
                  ELSE ','
           END
    FROM   @ShowFields
    IF @IncludeConstraints = 1
    BEGIN
      INSERT INTO @Definition
                  (
                              fieldvalue
                  )
      SELECT ',CONSTRAINT [' + NAME + '] FOREIGN KEY (' + parentcolumns + ') REFERENCES [' + referencedobject + '](' + referencedcolumns + ')'
      FROM   (
                    SELECT referencedobject = object_name(fk.referenced_object_id),
                           parentobject = object_name(parent_object_id),                       fk.NAME,
                           reverse(substring(reverse(
                           (
                                  SELECT cp.NAME + ','
                                  FROM   sys.foreign_key_columns fkc
                                  JOIN   sys.columns cp
                                  ON     fkc.parent_object_id = cp.object_id
                                  AND    fkc.parent_column_id = cp.column_id
                                  WHERE  fkc.constraint_object_id = fk.object_id FOR xml path('') )), 2, 8000)) parentcolumns,
                           reverse(substring (reverse(
                           (
                                  SELECT cr.NAME + ','
                                  FROM   sys.foreign_key_columns fkc
                                  JOIN   sys.columns cr
                                  ON     fkc.referenced_object_id = cr.object_id
                                  AND    fkc.referenced_column_id = cr.column_id 
								  where fkc.constraint_object_id = fk.object_id FOR xml path('') )), 2, 8000)) referencedcolumns
                    FROM   sys.foreign_keys fk ) a
      WHERE  parentobject = @TableName
      INSERT INTO @Definition
                  (
                              fieldvalue
                  )
      SELECT',CONSTRAINT [' + NAME + '] CHECK ' + definition
      FROM   sys.check_constraints
      WHERE  Object_name(parent_object_id) = @TableName
      INSERT INTO @PKObjectID
                  (
                              objectid
                  )
      SELECT DISTINCT pkobject = cco.object_id
      FROM            sys.key_constraints cco
      JOIN            sys.index_columns cc
      ON              cco.parent_object_id = cc.object_id
      AND             cco.unique_index_id = cc.index_id
      JOIN            sys.indexes i
      ON              cc.object_id = i.object_id
      AND             cc.INdex_id = i.index_id
      WHERE           object_name(parent_object_id) = @TableName
      AND             i.type = 1
      AND             is_primary_key = 1
      INSERT INTO @Uniques
                  (
                              objectid
                  )
      SELECT DISTINCT pkobject = cco.object_id
      FROM            sys.key_constraints cco
      JOIN            sys.index_columns cc
      ON              cco.parent_object_id = cc.object_id
      AND             cco.unique_index_id = cc.index_id
      JOIN            sys.indexes i
      ON              cc.object_id = i.object_id
      AND             cc.index_id = i.index_id
      WHERE           Object_name(parent_object_id) = @TableName
      AND             i.type = 2
      AND             is_primary_key = 0
      AND             is_unique_constraint = 1
      SET @ClusteredPK =
      CASE
      WHEN @@ROWCOUNT > 0 THEN
        1
        ELSE 0
      END
      INSERT INTO @Definition
                  (
                              fieldvalue
                  )
      SELECT    ',CONSTRAINT ' + NAME +
                CASE type
                          WHEN 'PK' THEN ' PRIMARY KEY ' +
                                    CASE
                                              WHEN pk.objectid IS NULL THEN ' NONCLUSTERED '
                                              ELSE ' CLUSTERED '
                                    END
                          WHEN 'UQ' THEN ' UNIQUE '
                END +
                CASE
                          WHEN u.objectid IS NOT NULL THEN ' NO NCLUSTERED '
                          ELSE ''
                END + '(' + reverse(substring(reverse(
                (
                          SELECT    c.NAME + +
                                    CASE
                                              WHEN cc.is_descending_key = 1 THEN ' DESC'
                                              ELSE ' ASC'
                                    END + ','
                          FROM      sys.key_constraints ccok
                          LEFT JOIN sys.index_columns cc
                          ON        ccok.parent_object_id = cc.object_id
                          AND       cco.unique_index_id = cc.index_id
                          LEFT JOIN sys.columns c
                          ON        cc.object_id = c.object_id
                          AND       cc.COLUMN_id = c.column_id
                          LEFT JOIN sys.indexes i
                          ON        cc.object_id = i.object_id
                          AND       cc.index_id = i.index_id
                          WHERE     i.object_id = ccok.parent_object_id
                          AND       ccok.object_id = cco.object_id FOR xml path('') )), 2, 8000)) + ')'
      FROM      sys.key_constraints cco
      LEFT JOIN @PKObjectID pk
      ON        cco.object_id = pk.objectid
      LEFT JOIN @Uniques u
      ON        cco.object_id = u.objectid
      WHERE     object_name(cco.parent_object_id) = @TableName
    END
    INSERT INTO @Definition
                (
                            fieldvalue
                )
                VALUES
                (
                            ')'
                )
    IF @IncludeIndexes = 1
    BEGIN
      INSERT INTO @Definition
                  (
                              fieldvalue
                  )
      SELECT 'CREATE ' + type_desc + ' INDEX [' + [name] COLLATE sql_latin1_general_cp1_ci_as + '] ON [' + Object_name(object_id) + '] (' + reverse(substring(reverse(
             (
                      SELECT   NAME +
                               CASE
                                        WHEN sc.is_descending_key = 1 THEN ' DESC'
                                        ELSE ' ASC'
                               END + ','
                      FROM     sys.index_columns sc
                      JOIN     sys.columns c
                      ON       sc.object_id = c.object_id
                      AND      sc.column_id = c.column_id
                      WHERE    object_name(sc.object_id) = @TableName
                      AND      sc.object_id = i.object_id
                      AND      sc.index_id = i.index_id
                      ORDER BY index_column_id ASC FOR xml path('') )), 2, 8000)) + ')'
      FROM   sys.indexes i
      WHERE  object_name(object_id) = @TableName
      AND
             CASE
                    WHEN @ClusteredPK = 1
                    AND    is_primary_key = 1
                    AND    type = 1 THEN 0
                    ELSE 1
             END = 1
      AND    is_unique_constraint = 0
      AND    is_primary_key = 0
    END
    insert INTO @MainDefinition
                (
                            fieldvalue
                )
    SELECT   fieldvalue
    FROM     @Definition
    ORDER BY definitionid ASC
    SELECT *
    FROM   @MainDefinition
  END 