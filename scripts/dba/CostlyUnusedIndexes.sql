if object_id('tempdb..#t') is not null
		drop table #t
--Costly unused indexes
-- Create required table structure only.
-- Note: this SQL must be the same as in the Database loop given in the following step.
--SELECT 'Costly unused indexes'
SELECT TOP 1
        DatabaseName = DB_NAME()
        ,OBJECT_SCHEMA_NAME(i.object_id, s.database_id) as [SchemaName]
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
        ,i.type_desc
        ,user_updates
        ,user_seeks
        ,user_scans
        ,user_lookups    
        ,system_updates
        ,case
			when user_seeks > 0 or user_scans > 0 or user_lookups > 0 then 1
			else 0
		end as IndexIsUsed
		--,a.page_count
        -- Useful fields below:
        --, *
INTO #t
--FROM sys.dm_db_index_physical_stats(db_id(db_name()), NULL, NULL, NULL , 'LIMITED') AS a 
--INNER JOIN sys.dm_db_index_usage_stats s on a.database_id = s.database_id
--	AND s.object_id = a.object_id
--	AND s.index_id = a.index_id
FROM sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE  0=0
	AND s.database_id = DB_ID()
    AND OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0
    AND    user_seeks = 0
    AND user_scans = 0 
    AND user_lookups = 0
    AND s.[object_id] = -999  -- Dummy value to get table structure.
;

-- Loop around all the databases on the server.
EXEC sp_Msforeachdb    'USE [?]; 
-- Table already exists.
INSERT INTO #t
SELECT --TOP 10    
        DatabaseName = DB_NAME()
        ,OBJECT_SCHEMA_NAME(i.object_id, s.database_id) as [SchemaName]
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
        ,i.type_desc
        ,user_updates    
        ,user_seeks
        ,user_scans
        ,user_lookups    
        ,system_updates    
        ,case
			when user_seeks > 0 or user_scans > 0 or user_lookups > 0 then 1
			else 0
		end as IndexIsUsed
		--,a.page_count
--FROM sys.dm_db_index_physical_stats(db_id(db_name()), NULL, NULL, NULL , ''LIMITED'') AS a 
--INNER JOIN sys.dm_db_index_usage_stats s on a.database_id = s.database_id
	--AND s.object_id = a.object_id
	--AND s.index_id = a.index_id
FROM sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE  0=0
	AND s.database_id = DB_ID()
    AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
    --AND    user_seeks < 10
    --AND user_scans < 10 
    --AND user_lookups < 10
    AND i.name IS NOT NULL    -- Ignore HEAP indexes.
ORDER BY user_updates DESC
;
'
-- Select records.
SELECT 
	--TOP 100 
	--t.DatabaseName
	--,t.TableName
	--,t.IndexName
	--,t.type_desc
	--,t.user_updates
	--,t.user_seeks
	--,t.user_lookups
	t.*
	,0 as DropIndex
	,GETDATE() as DateTimeRecorded
FROM #t t
WHERE	0=0
--and DatabaseName = 'UODB019'
--AND TableName IN ('t_user_names','t_user_name_deletes')
--and IndexName ='u_t_user_offer_instance_purchases_offer_id'
 --and user_seeks = 0
ORDER BY [user_updates] DESC

