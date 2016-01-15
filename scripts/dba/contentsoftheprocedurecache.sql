SELECT  qs.execution_count,
             st.text, total_elapsed_time
FROM    sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
WHERE st.encrypted = 0
