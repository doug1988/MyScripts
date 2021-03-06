USE Northwind
GO
SET NOCOUNT ON;

DECLARE @default_ff INT,
        @statusMsg  VARCHAR(MAX) = '',
        @tableCount INT,
        @i          INT = 0;

SELECT @default_ff = CASE
                         WHEN value_in_use = 0 THEN
                             100
                         ELSE
                             CONVERT(INT, value_in_use)
                     END
FROM sys.configurations WITH (NOLOCK)
WHERE name = 'fill factor (%)';

IF OBJECT_ID('tempdb..#ObjEst') IS NOT NULL
    DROP TABLE #ObjEst;

CREATE TABLE #ObjEst
(
    PK INT IDENTITY NOT NULL PRIMARY KEY,
    object_name VARCHAR(250),
    schema_name VARCHAR(250),
    index_id INT,
    partition_number INT,
    size_with_current_compression_setting BIGINT,
    size_with_requested_compression_setting BIGINT,
    sample_size_with_current_compression_setting BIGINT,
    sample_size_with_requested_compresison_setting BIGINT
);

IF OBJECT_ID('tempdb..#dbEstimate') IS NOT NULL
    DROP TABLE #dbEstimate;

CREATE TABLE #dbEstimate
(
    PK INT IDENTITY NOT NULL PRIMARY KEY,
    objectid INT,
    schema_name VARCHAR(250),
    object_name VARCHAR(250),
    index_id INT,
    index_fill_factor INT,
    ixName VARCHAR(255),
    ixType VARCHAR(50),
    partition_number INT,
    data_compression_desc VARCHAR(50),
    None_Size INT,
    Row_Size INT,
    Page_Size INT
);

INSERT INTO #dbEstimate
(
    objectid,
    schema_name,
    object_name,
    index_id,
    ixName,
    index_fill_factor,
    ixType,
    partition_number,
    data_compression_desc
)
SELECT o.object_id,
       S.name,
       O.name,
       I.index_id,
       I.name,
       CASE
           WHEN I.fill_factor = 0 THEN
               @default_ff
           ELSE
               I.fill_factor
       END,
       I.type_desc,
       P.partition_number,
       P.data_compression_desc
FROM sys.schemas AS S
    INNER JOIN sys.objects AS O
        ON S.schema_id = O.schema_id
    INNER JOIN sys.indexes AS I
        ON O.object_id = I.object_id
    INNER JOIN sys.partitions AS P
        ON I.object_id = P.object_id
           AND I.index_id = P.index_id
WHERE O.type = 'U';

SELECT @tableCount = COUNT(*) FROM #dbEstimate;

-- Determine Compression Estimates
DECLARE @PK INT,
        @ObjectID INT,
        @Schema VARCHAR(150),
        @object VARCHAR(250),
        @DAD VARCHAR(25),
        @partNO INT,
        @indexID INT,
        @SQL NVARCHAR(MAX),
        @ixName VARCHAR(250);

DECLARE cCompress CURSOR FAST_FORWARD FOR
SELECT schema_name,
       object_name,
       index_id,
       ixName,
       partition_number,
       data_compression_desc
FROM #dbEstimate;

OPEN cCompress;

FETCH cCompress
INTO @Schema,
     @object,
     @indexID,
     @ixName,
     @partNO,
     @DAD; -- prime the cursor

WHILE @@Fetch_Status = 0
BEGIN
    SET @i = @i + 1;

    SET @statusMsg = 'Working on ' + CAST(@i AS VARCHAR(10)) 
        + ' of ' + CAST(@tableCount AS VARCHAR(10)) + ' obj = ' + @object + '.' + ISNULL(@ixName,'HEAP')

    IF @DAD = 'COLUMNSTORE'
    BEGIN
      SET @statusMsg = 'Working on ' + CAST(@i AS VARCHAR(10)) 
          + ' of ' + CAST(@tableCount AS VARCHAR(10)) + ' Skipping obj as it is set to ColumnStore = ' + @object + '.' + ISNULL(@ixName,'HEAP')
    END

    SET @statusMsg = REPLACE(REPLACE(@statusMsg, CHAR(13), ''), CHAR(10), '')
    RAISERROR(@statusMsg, 0, 42) WITH NOWAIT;

    IF @DAD = 'none'
    BEGIN
        -- estimate Page compression
        INSERT #ObjEst
        (
            object_name,
            schema_name,
            index_id,
            partition_number,
            size_with_current_compression_setting,
            size_with_requested_compression_setting,
            sample_size_with_current_compression_setting,
            sample_size_with_requested_compresison_setting
        )
        EXEC sp_estimate_data_compression_savings @schema_name = @Schema,
                                                  @object_name = @object,
                                                  @index_id = @indexID,
                                                  @partition_number = @partNO,
                                                  @data_compression = 'page';

        UPDATE #dbEstimate
        SET None_Size = O.size_with_current_compression_setting,
            Page_Size = O.size_with_requested_compression_setting
        FROM #dbEstimate D
            INNER JOIN #ObjEst O
                ON D.schema_name = O.schema_name
                   AND D.object_name = O.object_name
                   AND D.index_id = O.index_id
                   AND D.partition_number = O.partition_number;

        DELETE #ObjEst;

        -- estimate Row compression
        INSERT #ObjEst
        (
            object_name,
            schema_name,
            index_id,
            partition_number,
            size_with_current_compression_setting,
            size_with_requested_compression_setting,
            sample_size_with_current_compression_setting,
            sample_size_with_requested_compresison_setting
        )
        EXEC sp_estimate_data_compression_savings @schema_name = @Schema,
                                                  @object_name = @object,
                                                  @index_id = @indexID,
                                                  @partition_number = @partNO,
                                                  @data_compression = 'row';

        UPDATE #dbEstimate
        SET Row_Size = O.size_with_requested_compression_setting
        FROM #dbEstimate D
            INNER JOIN #ObjEst O
                ON D.schema_name = O.schema_name
                   AND D.object_name = O.object_name
                   AND D.index_id = O.index_id
                   AND D.partition_number = O.partition_number;

        DELETE #ObjEst;
    END; -- none compression estimate     

    IF @DAD = 'row'
    BEGIN
        -- estimate Page compression
        INSERT #ObjEst
        (
            object_name,
            schema_name,
            index_id,
            partition_number,
            size_with_current_compression_setting,
            size_with_requested_compression_setting,
            sample_size_with_current_compression_setting,
            sample_size_with_requested_compresison_setting
        )
        EXEC sp_estimate_data_compression_savings @schema_name = @Schema,
                                                  @object_name = @object,
                                                  @index_id = @indexID,
                                                  @partition_number = @partNO,
                                                  @data_compression = 'page';

        UPDATE #dbEstimate
        SET Row_Size = O.size_with_current_compression_setting,
            Page_Size = O.size_with_requested_compression_setting
        FROM #dbEstimate D
            INNER JOIN #ObjEst O
                ON D.schema_name = O.schema_name
                   AND D.object_name = O.object_name
                   AND D.index_id = O.index_id
                   AND D.partition_number = O.partition_number;

        DELETE #ObjEst;

        -- estimate None compression
        INSERT #ObjEst
        (
            object_name,
            schema_name,
            index_id,
            partition_number,
            size_with_current_compression_setting,
            size_with_requested_compression_setting,
            sample_size_with_current_compression_setting,
            sample_size_with_requested_compresison_setting
        )
        EXEC sp_estimate_data_compression_savings @schema_name = @Schema,
                                                  @object_name = @object,
                                                  @index_id = @indexID,
                                                  @partition_number = @partNO,
                                                  @data_compression = 'none';

        UPDATE #dbEstimate
        SET None_Size = O.size_with_requested_compression_setting
        FROM #dbEstimate D
            INNER JOIN #ObjEst O
                ON D.schema_name = O.schema_name
                   AND D.object_name = O.object_name
                   AND D.index_id = O.index_id
                   AND D.partition_number = O.partition_number;

        DELETE #ObjEst;
    END; -- row compression estimate    

    IF @DAD = 'page'
    BEGIN
        -- estimate Row compression
        INSERT #ObjEst
        (
            object_name,
            schema_name,
            index_id,
            partition_number,
            size_with_current_compression_setting,
            size_with_requested_compression_setting,
            sample_size_with_current_compression_setting,
            sample_size_with_requested_compresison_setting
        )
        EXEC sp_estimate_data_compression_savings @schema_name = @Schema,
                                                  @object_name = @object,
                                                  @index_id = @indexID,
                                                  @partition_number = @partNO,
                                                  @data_compression = 'row';

        UPDATE #dbEstimate
        SET Page_Size = O.size_with_current_compression_setting,
            Row_Size = O.size_with_requested_compression_setting
        FROM #dbEstimate D
            INNER JOIN #ObjEst O
                ON D.schema_name = O.schema_name
                   AND D.object_name = O.object_name
                   AND D.index_id = O.index_id
                   AND D.partition_number = O.partition_number;

        DELETE #ObjEst;

        -- estimate None compression
        INSERT #ObjEst
        (
            object_name,
            schema_name,
            index_id,
            partition_number,
            size_with_current_compression_setting,
            size_with_requested_compression_setting,
            sample_size_with_current_compression_setting,
            sample_size_with_requested_compresison_setting
        )
        EXEC sp_estimate_data_compression_savings @schema_name = @Schema,
                                                  @object_name = @object,
                                                  @index_id = @indexID,
                                                  @partition_number = @partNO,
                                                  @data_compression = 'none';

        UPDATE #dbEstimate
        SET None_Size = O.size_with_requested_compression_setting
        FROM #dbEstimate D
            INNER JOIN #ObjEst O
                ON D.schema_name = O.schema_name
                   AND D.object_name = O.object_name
                   AND D.index_id = O.index_id
                   AND D.partition_number = O.partition_number;

        DELETE #ObjEst;
    END; -- page compression estimate

    FETCH cCompress
    INTO @Schema,
         @object,
         @indexID,
         @ixName,
         @partNO,
         @DAD;
END;

CLOSE cCompress;

DEALLOCATE cCompress;


SET @statusMsg = 'Collecting index fragmentation info...'
RAISERROR(@statusMsg, 0, 42) WITH NOWAIT;

IF OBJECT_ID('tempdb.dbo.#tmp1') IS NOT NULL 
  DROP TABLE #tmp1

SELECT * 
  INTO #tmp1 
  FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED')


-- report findings
SELECT schema_name + '.' + object_name AS Objeto,
       #dbEstimate.index_id AS ID_Indice,
       ixName AS NM_Indice,
       ixType AS TP_Indice,
       #dbEstimate.partition_number AS Particao_Indice,
       data_compression_desc AS Compressao_Atual,
       ROUND((CAST(None_Size AS FLOAT) / 1024), 2) AS 'Tamanho_Sem_Compressao(MB)',
       ROUND((CAST(Row_Size AS FLOAT) / 1024), 2) AS 'Estimado_Compressao_Linha(MB)',
       ROUND(CAST(Page_Size AS FLOAT) / 1024, 2) AS 'Estimado_Compressao_Pagina(MB)',
       index_fill_factor AS 'Fill Factor Atual',
       indexstats.avg_fragmentation_in_percent AS '% Framentação',
       ROUND((1 - (CAST(Row_Size AS FLOAT) / None_Size)) * 100, 2) AS 'Ganho_Estimado_Linha(%)',
       ROUND((1 - (CAST(Page_Size AS FLOAT) / None_Size)) * 100, 2) AS 'Ganho_Estimado_Pagina(%)',
       CASE
           WHEN (1 - (CAST(Row_Size AS FLOAT) / None_Size)) >= .10
                AND (Row_Size <= Page_Size) THEN
               'Row'
           WHEN (1 - (CAST(Page_Size AS FLOAT) / None_Size)) >= .10
                AND (Page_Size <= Row_Size) THEN
               'Page'
           ELSE
               'None'
       END AS Compressao_Recomendada,
       ISNULL(bp.CacheSizeMB,0) AS 'Espaco_Utilizado_BP',
       ISNULL(bp.FreeSpaceMB,0) AS 'Espaco_Livre_BP'  
  FROM #dbEstimate
 INNER JOIN (SELECT object_id as objectid,
                    object_name(object_id) as name,
                    allocation_unit_id
               FROM sys.allocation_units as au
              INNER JOIN sys.partitions as p
                 ON au.container_id = p.hobt_id) as obj
    ON #dbEstimate.objectid = obj.objectid
  LEFT OUTER JOIN (SELECT allocation_unit_id, 
                          (count(*) * 8) / 1024. as CacheSizeMB, 
                          (SUM(CONVERT(float, free_space_in_bytes)) / 1024.) / 1024. AS FreeSpaceMB
                     FROM sys.dm_os_buffer_descriptors
                     WHERE dm_os_buffer_descriptors.database_id = db_id()
                       AND dm_os_buffer_descriptors.page_type in ('data_page', 'index_page')
                    GROUP BY allocation_unit_id) as bp
    ON bp.allocation_unit_id = obj.allocation_unit_id
  LEFT OUTER JOIN #tmp1 indexstats
    ON #dbEstimate.objectid = indexstats.object_id
   AND #dbEstimate.index_id = indexstats.index_id
WHERE None_Size > 0;