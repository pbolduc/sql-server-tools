
--
-- get id, page count and row count of each index in a table
-- 
DECLARE @TableName sysname = N'Transaction'

SELECT
  [Table]    = @TableName,
  [Index_ID] = [ps].[index_id],
  [Index]    = [i].[name],
  [ps].[used_page_count],
  [ps].[row_count]
FROM [sys].[dm_db_partition_stats] AS [ps]
INNER JOIN [sys].[indexes] AS [i] 
  ON [ps].[index_id] = [i].[index_id] 
  AND [ps].[object_id] = [i].[object_id]
WHERE [ps].[object_id] = OBJECT_ID(@TableName);

GO

--
-- get the depth,  page_count and record count of a given index

DECLARE @TableName sysname = N'Transaction'
DECLARE @IndexID int = 4

SELECT
  [ps].[index_id],
  [Index] = [i].[name],
  [ps].[index_type_desc],
  [ps].[index_depth],
  [ps].[index_level],
  [ps].[page_count],
  [ps].[record_count]
FROM [sys].[dm_db_index_physical_stats](DB_ID(), 
  OBJECT_ID(@TableName),@IndexID, NULL, 'DETAILED') AS [ps]
INNER JOIN [sys].[indexes] AS [i] 
  ON [ps].[index_id] = [i].[index_id] 
  AND [ps].[object_id] = [i].[object_id];