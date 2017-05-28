-- from Pluralsight course:

-- SQL Server: Optimizing Ad Hoc Statement Performance
-- https://app.pluralsight.com/library/courses/sqlserver-optimizing-adhoc-statement-performance/table-of-contents

-- Kimberly L. Tripp 
-- Kimberly@SQLskills.com 
-- http://www.SQLskills.com/blogs/Kimberly

SELECT [qh].*, [qp].query_plan
FROM (SELECT [cp].[objtype]
		, [Query Hash] = [qs2].[query_hash] 
		, [Query Plan Hash] = [qs2].[query_plan_hash] 
		, [Total MB] = SUM ([cp].[size_in_bytes]) /
			1024.00 / 1024.00
		, [Avg CPU Time]
			= SUM ([qs2].[total_worker_time]) /
				SUM ([qs2].[execution_count])	
		, [Execution Total]
			= SUM ([qs2].[execution_count]) 
		, [Total Cost]
			= SUM ([qs2].[total_worker_time]) 
		, [Example Statement Text] 
			= MIN ([qs2].[statement_text]) 
		, [plan_handle] = MIN ([qs2].[plan_handle])
		, [statement_start_offset] =
			MIN ([qs2].[statement_start_offset]) 
	FROM (SELECT [qs].*,  
			SUBSTRING ([st].[text], 
				([qs].[statement_start_offset] / 2) + 1, 
			((CASE [statement_end_offset] WHEN -1 THEN
				DATALENGTH ([st].[text]) 
				ELSE [qs].[statement_end_offset] END - 
					[qs].[statement_start_offset]) / 2) + 1) 
					AS [statement_text]
			FROM [sys].[dm_exec_query_stats] AS [qs] 
				CROSS APPLY [sys].[dm_exec_sql_text] 
					([qs].[sql_handle]) AS [st]
			WHERE [st].[text] LIKE '%member%'
				AND [st].[text] NOT LIKE '%dm_exec%') AS [qs2]
			INNER JOIN [sys].[dm_exec_cached_plans] AS [cp]
				ON [qs2].[plan_handle] = [cp].[plan_handle]
			GROUP BY [cp].[objtype], [qs2].[query_hash],
				[qs2].[query_plan_hash]) AS [qh]
CROSS APPLY [sys].[dm_exec_query_plan] 
					([qh].[plan_handle]) AS [qp]
-- For the demo, use the ORDER BY [Example Statement Text]
ORDER BY [Example Statement Text]
-- For the real-world, use the following order by:
-- ORDER BY [qh].[Total Cost] DESC
