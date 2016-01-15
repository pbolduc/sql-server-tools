--dbcc dropcleanbuffers
--dbcc freeproccache
-------------------------
--***********************
-------------------------
--Cause of server waits
SELECT 'Cause of server waits'
SELECT TOP 10
 [Wait type] = wait_type,
 [Wait time (s)] = wait_time_ms / 1000,
 [% waiting] = CONVERT(DECIMAL(12,2), wait_time_ms * 100.0 
               / SUM(wait_time_ms) OVER())
FROM sys.dm_os_wait_stats
WHERE wait_type NOT LIKE '%SLEEP%' 
ORDER BY wait_time_ms DESC;

WITH Waits AS
(SELECT wait_type, wait_time_ms / 1000. AS wait_time_s,
100. * wait_time_ms / SUM(wait_time_ms) OVER() AS pct,
ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rn
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK'
,'SLEEP_SYSTEMTASK','SQLTRACE_BUFFER_FLUSH','WAITFOR', 'LOGMGR_QUEUE','CHECKPOINT_QUEUE'
,'REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TO_FLUSH','BROKER_TASK_STOP','CLR_MANUAL_EVENT'
,'CLR_AUTO_EVENT','DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT'
,'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN'))
SELECT W1.wait_type, 
CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s,
CAST(W1.pct AS DECIMAL(12, 2)) AS pct,
CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
FROM Waits AS W1
INNER JOIN Waits AS W2
ON W2.rn <= W1.rn
GROUP BY W1.rn, W1.wait_type, W1.wait_time_s, W1.pct
HAVING SUM(W2.pct) - W1.pct < 95; -- percentage threshold
-------------------------
--***********************
-------------------------
--Reads and writes by db
SELECT 'Reads and writes by db'
SELECT TOP 10 
        [Total Reads] = SUM(total_logical_reads)
        ,[Execution count] = SUM(qs.execution_count)
        ,DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
GROUP BY DB_NAME(qt.dbid)
ORDER BY [Total Reads] DESC;

SELECT TOP 10 
        [Total Writes] = SUM(total_logical_writes)
        ,[Execution count] = SUM(qs.execution_count)
        ,DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
GROUP BY DB_NAME(qt.dbid)
ORDER BY [Total Writes] DESC;
-------------------------
--***********************
-------------------------
--Costly Queries by I/O
SELECT 'Costly Queries by I/O'
SELECT TOP 100 
 [Average IO] = (total_logical_reads + total_logical_writes) / qs.execution_count
,[Total IO] = (total_logical_reads + total_logical_writes)
,[Total Reads] = total_logical_reads
,[Total Writes] = total_logical_writes
,[Execution count] = qs.execution_count
,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) 
        ,[Parent Query] = qt.text
,DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
ORDER BY [Average IO] DESC;

-------------------------
--***********************
-------------------------
--Costly Queries by CPU
SELECT 'Costly Queries by CPU'
SELECT TOP 50
 [Average CPU used] = total_worker_time / qs.execution_count
,[Total CPU used] = total_worker_time
,[Execution count] = qs.execution_count
,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2)
,[Parent Query] = qt.text
,DatabaseName = DB_NAME(qt.dbid)
--INTO DBAPerfTuning.dbo.TopCPU
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
--ORDER BY [Average CPU used] DESC;
ORDER BY [Total CPU used]  DESC;

-------------------------
--***********************
-------------------------
--Most costly CLR queries
SELECT 'Most costly CLR queries'
SELECT TOP 100 
 [Average CLR Time] = total_clr_time / execution_count 
,[Total CLR Time] = total_clr_time 
,[Execution count] = qs.execution_count
,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2)
,[Parent Query] = qt.text
,DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats as qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
WHERE total_clr_time <> 0
ORDER BY [Average CLR Time] DESC;


-------------------------
--***********************
-------------------------
--Most executed queries
SELECT 'Most executed queries'
SELECT TOP 10
 qt.dbid
 ,[Execution count] = execution_count
,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2)
,[Parent Query] = qt.text
,DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
WHERE isnull(DB_NAME(qt.dbid),'') not in ('', 'msdb')
ORDER BY [Execution count] DESC;


-------------------------
--***********************
-------------------------
--Queries suffering from blocking
SELECT 'Queries suffering from blocking'
SELECT TOP 100 
 [Average Time Blocked] = (total_elapsed_time - total_worker_time) / qs.execution_count
,[Total Time Blocked] = total_elapsed_time - total_worker_time 
,[Execution count] = qs.execution_count
,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) 
,[Parent Query] = qt.text
,DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
--WHERE qt.dbid = DB_ID('ims_master')
ORDER BY [Average Time Blocked] DESC;

-------------------------
--***********************
-------------------------
--Queries with lowest plan reuse
SELECT 'Queries with lowest plan reuse'
SELECT TOP 100
 [Plan usage] = cp.usecounts
,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), 
qt.text)) * 2 ELSE qs.statement_end_offset END - 
qs.statement_start_offset)/2)
,[Parent Query] = qt.text
,DatabaseName = DB_NAME(qt.dbid)
,cp.cacheobjtype
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
INNER JOIN sys.dm_exec_cached_plans as cp on qs.plan_handle=cp.plan_handle
WHERE cp.plan_handle=qs.plan_handle
ORDER BY [Plan usage] ASC;

-------------------------
--***********************
-------------------------
--Missing Indexes by db
SELECT 'Missing Indexes by db'
SELECT 
    DatabaseName = CAST(DB_NAME(database_id) AS VARCHAR(30))
    ,[Number Indexes Missing] = count(*) 
FROM sys.dm_db_missing_index_details
GROUP BY CAST(DB_NAME(database_id) AS VARCHAR(30))
ORDER BY 2 DESC;
-------------------------
--***********************
-------------------------
-------------------------
--***********************
-------------------------
--Costly used indexes
-- Create required table structure only.
-- Note: this SQL must be the same as in the Database loop given in the following step.
if object_id('tempdb..#TempMaintenanceCost') is not null
		drop table #TempMaintenanceCost

SELECT 'Costly used indexes'
SELECT TOP 1
        [Maintenance cost]  = (user_updates + system_updates)
        ,[Retrieval usage] = (user_seeks + user_scans + user_lookups)
        ,user_updates
        ,system_updates
        ,user_seeks
        ,user_scans
        ,user_lookups
        ,DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
INTO #TempMaintenanceCost
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id
WHERE s.database_id = DB_ID() 
    AND OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0
    AND (user_updates + system_updates) > 0 -- Only report on active rows.
    AND s.[object_id] = -999  -- Dummy value to get table structure.
;

-- Loop around all the databases on the server.
EXEC sp_MSForEachDB    'USE [?]; 
-- Table already exists.
INSERT INTO #TempMaintenanceCost 
SELECT --TOP 10
        [Maintenance cost]  = (user_updates + system_updates)
        ,[Retrieval usage] = (user_seeks + user_scans + user_lookups)
        ,user_updates
        ,system_updates
        ,user_seeks
        ,user_scans
        ,user_lookups
        ,DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id
WHERE s.database_id = DB_ID() 
    AND i.name IS NOT NULL    -- Ignore HEAP indexes.
    AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
    AND (user_updates + system_updates) > 0 -- Only report on active rows.
ORDER BY [Maintenance cost]  DESC
;
'

-- Select records.
SELECT 
	TOP 10 
* FROM #TempMaintenanceCost 
ORDER BY [Maintenance cost]  DESC
-- Tidy up.
--DROP TABLE #TempMaintenanceCost

-------------------------
--***********************
-------------------------
--Most often used indexes
-- Create required table structure only.
-- Note: this SQL must be the same as in the Database loop given in the -- following step.
SELECT 'Most often used indexes'
SELECT TOP 1
        [Usage] = (user_seeks + user_scans + user_lookups)
        ,DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
INTO #TempUsage
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE   s.database_id = DB_ID() 
    AND OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0
    AND (user_seeks + user_scans + user_lookups) > 0 
-- Only report on active rows.
    AND s.[object_id] = -999  -- Dummy value to get table structure.
;

-- Loop around all the databases on the server.
EXEC sp_MSForEachDB    'USE [?]; 
-- Table already exists.
INSERT INTO #TempUsage 
SELECT TOP 10
        [Usage] = (user_seeks + user_scans + user_lookups)
        ,DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE   s.database_id = DB_ID() 
    AND i.name IS NOT NULL    -- Ignore HEAP indexes.
    AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
    AND (user_seeks + user_scans + user_lookups) > 0 -- Only report on active rows.
ORDER BY [Usage]  DESC
;
'

-- Select records.
SELECT TOP 10 * FROM #TempUsage ORDER BY [Usage] DESC
-- Tidy up.
DROP TABLE #TempUsage
-------------------------
--***********************
-------------------------
--Logically fragmented indexes
-- Create required table structure only.
-- Note: this SQL must be the same as in the Database loop given in the -- following step.
SELECT 'Logically fragmented indexes'
SELECT TOP 1 
        DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
		,i.fill_factor
		,i.is_padded
		,i.type_desc
        ,[Fragmentation %] = ROUND(avg_fragmentation_in_percent,2)
INTO #TempFragmentation
FROM sys.dm_db_index_physical_stats(db_id(),null, null, null, null) s
INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE s.[object_id] = -999  -- Dummy value just to get table structure.
;

-- Loop around all the databases on the server.
EXEC sp_MSForEachDB    '
USE [?]; 
-- Table already exists.
INSERT INTO #TempFragmentation 
SELECT TOP 10
        DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
		,i.fill_factor
		,i.is_padded
		,i.type_desc
        ,[Fragmentation %] = ROUND(avg_fragmentation_in_percent,2)
FROM sys.dm_db_index_physical_stats(db_id(),null, null, null, null) s
INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id]
    AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
      AND i.name IS NOT NULL    -- Ignore HEAP indexes.
    AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
ORDER BY [Fragmentation %] DESC
;
'
GO
-- Select records.
SELECT TOP 100 * FROM #TempFragmentation 
WHERE DatabaseName = 'DBAPerfTuning'
ORDER BY DatabaseName, [Fragmentation %] DESC
-- Tidy up.
DROP TABLE #TempFragmentation

/*
SELECT TOP 100
        DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
		,i.fill_factor
		,i.is_padded
		,i.type_desc
        ,[Fragmentation %] = ROUND(avg_fragmentation_in_percent,2)
FROM sys.dm_db_index_physical_stats(db_id(),null, null, null, null) s
INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id]
    AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
      AND i.name IS NOT NULL    -- Ignore HEAP indexes.
    AND OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0
ORDER BY [Fragmentation %] DESC
*/

go
---------------------------------
--Memory consumption by database
SELECT LEFT(CASE database_id 
			WHEN 32767 THEN 'ResourceDb' 
			ELSE db_name(database_id) 
        END, 20) AS Database_Name,
	count_big(*) AS Buffered_Page_Count, 
	count_big(*) * 8192 / (1024 * 1024) as Buffer_Pool_MB
FROM sys.dm_os_buffer_descriptors
GROUP BY db_name(database_id) ,database_id
ORDER BY Buffered_Page_Count DESC


--Memory consumption by object within a database
SELECT TOP 100 
	obj.[name],
	i.[name],
	i.[type_desc],
	count_big(*)AS Buffered_Page_Count ,
	count_big(*) * 8192 / (1024 * 1024) as Buffer_MB
    -- ,obj.name ,obj.index_id, i.[name]
FROM sys.dm_os_buffer_descriptors AS bd 
    INNER JOIN 
    (
        SELECT object_name(object_id) AS name 
            ,index_id ,allocation_unit_id, object_id
        FROM sys.allocation_units AS au
            INNER JOIN sys.partitions AS p 
                ON au.container_id = p.hobt_id 
                    AND (au.type = 1 OR au.type = 3)
        UNION ALL
        SELECT object_name(object_id) AS name   
            ,index_id, allocation_unit_id, object_id
        FROM sys.allocation_units AS au
            INNER JOIN sys.partitions AS p 
                ON au.container_id = p.hobt_id 
                    AND au.type = 2
    ) AS obj 
        ON bd.allocation_unit_id = obj.allocation_unit_id
LEFT JOIN sys.indexes i on i.object_id = obj.object_id AND i.index_id = obj.index_id
WHERE database_id = db_id()
GROUP BY obj.name, obj.index_id , i.[name],i.[type_desc]
ORDER BY Buffered_Page_Count DESC

--------------------------------
--Examine Locks
SELECT 
	DB_NAME(l.resource_database_id) as DatabaseName
	,l.*
	--l.resource_type
	--,l.resource_subtype
	--,l.request_mode 
	--,l.resource_description
	--,l.resource_database_id
FROM   sys.dm_tran_locks l
--WHERE  resource_type <> 'DATABASE'
