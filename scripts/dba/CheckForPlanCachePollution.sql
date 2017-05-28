
-- from Pluralsight course:

-- SQL Server: Optimizing Ad Hoc Statement Performance
-- https://app.pluralsight.com/library/courses/sqlserver-optimizing-adhoc-statement-performance/table-of-contents

-- Kimberly L. Tripp 
-- Kimberly@SQLskills.com 
-- http://www.SQLskills.com/blogs/Kimberly

SELECT [Cache Type] = [cp].[objtype] 
	, [Total Plans] = COUNT_BIG (*) 
	, [Total MBs]
		= SUM (CAST ([cp].[size_in_bytes] 
			AS DECIMAL (18, 2))) / 1024.0 / 1024.0 
	, [Avg Use Count] 
		= AVG ([cp].[usecounts]) 
	, [Total MBs - USE Count 1]
		= SUM (CAST ((CASE WHEN [cp].[usecounts] = 1 
		THEN [cp].[size_in_bytes] ELSE 0 END) 
			AS DECIMAL (18, 2))) / 1024.0 / 1024.0
	, [Total Plans - USE Count 1]
		= SUM (CASE WHEN [cp].[usecounts] = 1 
				THEN 1 ELSE 0 END) 
	, [Percent Wasted]
		= (SUM (CAST ((CASE WHEN [cp].[usecounts] = 1 
			THEN [cp].[size_in_bytes] ELSE 0 END) 
			AS DECIMAL (18, 2))) 
		 / SUM ([cp].[size_in_bytes])) * 100
FROM [sys].[dm_exec_cached_plans] AS [cp]
GROUP BY [cp].[objtype]
ORDER BY [Total MBs - USE Count 1] DESC;
