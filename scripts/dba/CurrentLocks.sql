/*
		-------------
		Current Locks
		-------------
		
		Author: Stuart Blackler
		Created: 15/07/2012
		Website: http://sblackler.net/
		
		The purpose of this query is to see what queries are currently holding locks
		and gives you the execution plan for the blocking and executing queries.

*/


SELECT	DB_NAME(locks.resource_database_id)		AS	'Database'
,		locks.request_status					AS	'Status'
,		bs.host_name							AS	'Blocking_host'
,		bs.nt_domain + '\' + bs.nt_user_name	AS	'Blocking_user'
,		tasks.wait_duration_ms / 1000.			AS	'Current_wait_duration_seconds'
,		blockText.text							AS	'Blocking_sql_text'
,		blockPlan.query_plan					AS	'Blocking_query_plan'
,		blockText.text							AS	'Executing_sql_text'
,		blockPlan.query_plan					AS	'Executing_query_plan'
,		locks.resource_type						AS	'Resource_type'	
,		locks.resource_subtype					AS	'Resource_sub_type'
,		locks.resource_description				AS	'Resource_description'
,		locks.request_mode						AS	'Request_mode'
,		locks.request_type						AS	'Request_type'
,		tasks.wait_type							AS	'Wait_type'
FROM	sys.dm_tran_locks locks	WITH (NOLOCK)
JOIN	sys.dm_os_waiting_tasks tasks WITH (NOLOCK)	ON	locks.lock_owner_address = tasks.resource_address
JOIN	sys.dm_exec_sessions bs	WITH (NOLOCK)	ON	tasks.blocking_session_id = bs.session_id			-- Blocking session
JOIN	sys.dm_exec_requests br WITH (NOLOCK)	ON	br.session_id = tasks.blocking_session_id			-- Blocking request
JOIN	sys.dm_exec_sessions cs	WITH (NOLOCK)	ON	tasks.session_id = cs.session_id					-- Current session
JOIN	sys.dm_exec_requests cr WITH (NOLOCK)	ON	cr.session_id = tasks.session_id					-- Current request
CROSS APPLY sys.dm_exec_sql_text(br.sql_handle)	blockText
CROSS APPLY sys.dm_exec_query_plan(br.plan_handle) blockPlan
CROSS APPLY sys.dm_exec_sql_text(cr.sql_handle)	currText
CROSS APPLY sys.dm_exec_query_plan(cr.plan_handle) currPlan



/*

Column notes from BOL
---------------------

	Status					Current status of this request. Possible values are GRANTED, CONVERT, or WAIT.
	Resource_type			Can be one of the following values DATABASE, FILE, OBJECT, PAGE, KEY, EXTENT, RID, APPLICATION, METADATA, HOBT, or ALLOCATION_UNIT.
	Resource_sub_type		Represents a subtype of resource_type. Acquiring a subtype lock without holding a nonsubtyped lock of the parent type is technically valid. Different subtypes do not conflict with each other or with the nonsubtyped parent type. Not all resource types have subtypes.
	Resource_description	Description of the resource that contains only information that is not available from other resource columns.
	Request_mode			Mode of the request. For granted requests, this is the granted mode; for waiting requests, this is the mode being requested.
	Wait_type				The name of the wait type.
	
*/	