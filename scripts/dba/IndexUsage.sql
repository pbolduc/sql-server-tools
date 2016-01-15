SELECT 
	o.name as ObjectName, 
	IsNull(i.name,'(heap)') as IndexName, 
    i.type_desc as Type, 
	IsNull(u.user_seeks,0) as Seeks, 
	IsNull(u.user_scans,0) as Scans,  
	IsNull(u.user_lookups,0) as Lookups,  
	IsNull(u.user_updates,0) as Updates
FROM sys.indexes i
	JOIN sys.objects o ON i.object_id = o.object_id
	LEFT JOIN sys.dm_db_index_usage_stats u ON i.object_id = u.object_id
		AND i.index_id = u.index_id
		AND u.database_id = DB_ID()
WHERE 
	o.type <> 'S' -- No system tables!
ORDER BY 
	o.name, 
	i.name
