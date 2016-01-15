/*
		-----------------------
		Running query inspector
		-----------------------
		
		Author: Stuart Blackler
		Created: 15/07/2012
		Website: http://sblackler.net/
		
		The purpose of this query is to check to see what queries are currently running
		and gives you the execution plan for each query. It ignores any query that is 
		on the current SQL connection.

*/


SELECT		req.session_id									AS 'Session_ID'
,			DB_NAME(req.database_id)						AS 'Database_Name'
,			ses.host_name									AS 'Executing_Host'
,			ses.nt_domain + '\' + ses.nt_user_name			AS 'Executing_User'
,			req.command										AS 'Command_Type'
,			req.status										AS 'Command_Status'
,			ses.deadlock_priority							AS 'Deadlock_Priority'
,			req.cpu_time									AS 'CPU_Time'
,			req.total_elapsed_time							AS 'Elapsed_Time'
,			sqltext.TEXT									AS 'SQL_Text'
,			query_plan										AS 'Query_plan'
FROM		sys.dm_exec_requests req WITH (NOLOCK)
JOIN		sys.dm_exec_sessions ses WITH (NOLOCK) ON req.session_id = ses.session_id
CROSS APPLY sys.dm_exec_sql_text(sql_handle) sqltext
CROSS APPLY sys.dm_exec_query_plan(plan_handle) qp
WHERE		req.session_id <> @@SPID
ORDER BY	req.total_elapsed_time DESC, req.cpu_time DESC