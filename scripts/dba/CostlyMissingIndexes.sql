-------------------------
--***********************
-------------------------
--Costly Missing Indexes - Bart Duncans
SELECT  --TOP 100 
        [TotalCost]  = ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0) 
        , avg_user_impact
        --, avg_total_user_cost
        --, user_scans
        , user_seeks
        , unique_compiles
        , last_user_seek
        , last_user_scan
        --, TableName = statement
        , DatabaseName = substring(statement,1,charindex('.',statement)-1)
		, TableName = substring(statement,charindex('.',statement)+1,len(statement))
        , [EqualityUsage] = equality_columns 
        , [InequalityUsage] = inequality_columns
        , [IncludeColumns] = included_columns
	  ,'CREATE INDEX [missing_index_' + CONVERT (varchar, mig.index_group_handle) + '_' + CONVERT (varchar, mid.index_handle)
	  + '_' + LEFT (PARSENAME(mid.statement, 1), 32) + ']'
	  + ' ON ' + mid.statement
	  + ' (' + ISNULL (mid.equality_columns,'')
		+ CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END
		+ ISNULL (mid.inequality_columns, '')
	  + ')'
	  + ISNULL (' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement
FROM        sys.dm_db_missing_index_groups mig
INNER JOIN    sys.dm_db_missing_index_group_stats migs
       ON migs.group_handle = mig.index_group_handle 
INNER JOIN    sys.dm_db_missing_index_details mid 
       ON mid.index_handle = mig.index_handle
--where substring(statement,1,charindex('.',statement)-1) = '[azAEID]'
--ORDER BY [TotalCost] DESC;
order by avg_user_impact desc

--SELECT  TOP 100 
--        [TotalCost]  = ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0) 
--        , avg_user_impact
--        , user_scans
--        , user_seeks
--        --, TableName = statement
--        , DatabaseName = substring(statement,1,charindex('.',statement)-1)
--		, TableName = substring(statement,charindex('.',statement)+1,len(statement))
--        , [EqualityUsage] = equality_columns 
--        , [InequalityUsage] = inequality_columns
--        , [IncludeColumns] = included_columns
--FROM        sys.dm_db_missing_index_groups g 
--INNER JOIN    sys.dm_db_missing_index_group_stats s 
--       ON s.group_handle = g.index_group_handle 
--INNER JOIN    sys.dm_db_missing_index_details d 
--       ON d.index_handle = g.index_handle
--ORDER BY [TotalCost] DESC;

