SELECT execution_count, 

OBJECT_NAME(objectid, dbid) as ObjName,

min_worker_time,

max_worker_time,

total_worker_time/execution_count as avg_worker_time,

last_worker_time,

min_physical_reads,

max_physical_reads,

total_physical_reads/execution_count as avg_physical_reads,

last_physical_reads,

min_logical_reads,

max_logical_reads,

total_logical_reads/execution_count as avg_logical_reads,

last_logical_reads,

min_logical_writes,

max_logical_writes,

total_logical_writes/execution_count as avg_logical_writes,

last_logical_writes,

min_elapsed_time,

max_elapsed_time,

total_elapsed_time/execution_count as avg_elapsed_time,

last_elapsed_time,

SUBSTRING(text,

-- starting value for substring

CASE WHEN isnull(statement_start_offset, 0) = 0 THEN 1

ELSE statement_start_offset/2 + 1 END,

-- ending value for substring

CASE WHEN isnull(nullif(statement_end_offset, -1), 0) = 0 THEN LEN(text)

ELSE statement_end_offset/2 END -

CASE WHEN isnull(statement_start_offset, 0) = 0 THEN 1

ELSE statement_start_offset/2 END + 1

) AS sql_stmt

FROM sys.dm_exec_query_stats

CROSS APPLY sys.dm_exec_sql_text(sql_handle)

WHERE dbid = db_id()

-- AND OBJECT_NAME(objectid, dbid) = N'StoredProcedureName'

ORDER BY total_elapsed_time/execution_count DESC
