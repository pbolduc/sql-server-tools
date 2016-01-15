if object_id('tempdb..#t') is not null
		drop table #t

--Costly Missing Indexes - Nick Duckstein, modified from Bart Duncans
--This gets row counts so we can really tell whether or we care about the missing index
SELECT  TOP 1
		mid.database_id
		,mid.object_id 
        ,[TotalCost]  = ROUND(migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans),0) 
        , migs.avg_user_impact
        , migs.user_seeks
        , migs.unique_compiles
		, 0 AS row_count
        , DB_NAME(mid.database_id) as DatabaseName
        , OBJECT_SCHEMA_NAME(mid.object_id, mid.database_id) as SchemaName
		, OBJECT_NAME(mid.object_id, mid.database_id) as TableName
        , [EqualityUsage] = equality_columns 
        , [InequalityUsage] = inequality_columns
        , [IncludeColumns] = included_columns
        , migs.last_user_seek
INTO #t
FROM        sys.dm_db_missing_index_groups mig
INNER JOIN    sys.dm_db_missing_index_group_stats migs
       ON migs.group_handle = mig.index_group_handle 
INNER JOIN    sys.dm_db_missing_index_details mid 
       ON mid.index_handle = mig.index_handle
WHERE 0=1
 AND	mid.database_id = DB_ID()

-- Loop around all the databases on the server.
EXEC sp_Msforeachdb    'USE [?]; 
-- Table already exists.
INSERT INTO #t
SELECT  
		mid.database_id
		,mid.object_id 
        ,[TotalCost]  = ROUND(migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans),0) 
        , migs.avg_user_impact
        , migs.user_seeks
        , migs.unique_compiles
		, 0 as row_count
        , DB_NAME(mid.database_id) as DatabaseName
        , OBJECT_SCHEMA_NAME(mid.object_id, mid.database_id) as SchemaName
		, OBJECT_NAME(mid.object_id, mid.database_id) as TableName
        , [EqualityUsage] = equality_columns 
        , [InequalityUsage] = inequality_columns
        , [IncludeColumns] = included_columns
        , migs.last_user_seek
FROM        sys.dm_db_missing_index_groups mig
INNER JOIN    sys.dm_db_missing_index_group_stats migs
       ON migs.group_handle = mig.index_group_handle 
INNER JOIN    sys.dm_db_missing_index_details mid 
       ON mid.index_handle = mig.index_handle
WHERE 0=0
 AND	mid.database_id = DB_ID()

UPDATE #t
SET 
	row_count = p.row_count
FROM #t t
INNER JOIN sys.objects o ON t.object_id = o.object_id
--Only join to clustered index or heap to get row count
INNER JOIN sys.dm_db_partition_stats p ON o.object_id = p.object_id 
	AND p.index_id in (0,1) --CLUSTERED or HEAP. Only need row count
WHERE t.database_id = DB_ID()
'

SELECT 
	t.*
	,GETDATE() as DateTimeRecorded
FROM #t t
WHERE	0=0
 AND	t.avg_user_impact >= 90
 AND	t.row_count > 10000
 --AND	t.user_seeks > 5000
ORDER BY 
	TotalCost desc

SELECT 
	DatabaseName
	,COUNT(*) as MissingIndexCount
FROM #t t
WHERE	0=0
 AND	t.avg_user_impact >= 90
 AND	t.row_count > 10000
 --AND	t.user_seeks > 5000
GROUP BY
	DatabaseName
ORDER BY 
	COUNT(*) DESC