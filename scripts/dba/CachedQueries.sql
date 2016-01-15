/*
		----------------------
		Cached query inspector
		----------------------
		
		Author: Stuart Blackler
		Created: 15/07/2012
		Website: http://sblackler.net/
		
		The purpose of this query is to check the query plan cache for large queries 
		and gives you the execution plan for each query.

*/

SELECT		refcounts				AS	'Reference_Counts'
,			size_in_bytes			AS	'Size_in_bytes'
,			cacheobjtype			AS	'Cache_type'
,			st.encrypted			AS	'Is_encrypted_text'
,			text					AS	'SQL_text'
,			query_plan				AS	'Query_plan'
FROM		sys.dm_exec_cached_plans cp WITH (NOLOCK)
CROSS APPLY	sys.dm_exec_sql_text(cp.plan_handle) st 
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
ORDER BY refcounts DESC, size_in_bytes DESC


/*

Notes:
======

Reference_Counts:	Number of cache objects that are referencing this cache object. Refcounts must be at least 1 for an entry to be in the cache

Cache_Type:			Type of object in the cache. The value can be one of the following:
						Compiled Plan
						Compiled Plan Stub
						Parse Tree
						Extended Proc
						CLR Compiled Func
						CLR Compiled Proc
*/