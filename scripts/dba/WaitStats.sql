/*

	Wait stats finder
	=================
	
	This script is taken from the SQL Server 2008 diagnostics queries created by Glenn Berry.
	I have tidied the script up, so that it is more readable for myself. 
	All credits go to Glenn for the script. Thanks.
	
	Author:		Glenn Berry
	Website:	http://sqlserverperformance.wordpress.com
	
	Note:		This is formatted for SSMS, not for web.
*/


WITH Waits AS
(
	SELECT	wait_type										AS 'Wait_type'
	,		wait_time_ms / 1000.0							AS 'Wait_time_seconds'
	,		100.0 * wait_time_ms / SUM(wait_time_ms) OVER()	AS 'Percent_of_results'
	,		ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC)	AS 'Row_number'
	FROM	sys.dm_os_wait_stats WITH (NOLOCK)
	WHERE	wait_type NOT IN ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK','SLEEP_SYSTEMTASK','SQLTRACE_BUFFER_FLUSH','WAITFOR', 'LOGMGR_QUEUE','CHECKPOINT_QUEUE','REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TO_FLUSH','BROKER_TASK_STOP','CLR_MANUAL_EVENT','CLR_AUTO_EVENT','DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT','XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP','ONDEMAND_TASK_QUEUE', 'BROKER_EVENTHANDLER', 'SLEEP_BPOOL_FLUSH')
)
SELECT		W1.wait_type										AS 'Wait_Type'
,			CAST(W1.Wait_time_seconds AS DECIMAL(12, 2))		AS 'Wait_time_seconds'
,			CAST(W1.Percent_of_results AS DECIMAL(12, 2))		AS 'Percent_of_results'
,			CAST(SUM(W2.Percent_of_results) AS DECIMAL(12, 2))	AS 'Running_percentage'
FROM		Waits AS W1
INNER JOIN	Waits AS W2 ON W2.[Row_number] <= W1.[Row_number]
GROUP BY	W1.[Row_number], W1.wait_type, W1.wait_time_seconds, W1.Percent_of_results
HAVING		SUM(W2.percent_of_results) - W1.Percent_of_results < 99 
OPTION (RECOMPILE); 


/*

 Common Significant Wait types with BOL explanations
 ===================================================
 
 *** Network Related Waits ***
 ASYNC_NETWORK_IO		Occurs on network writes when the task is blocked behind the network

 *** Locking Waits ***
 LCK_M_IX				Occurs when a task is waiting to acquire an Intent Exclusive (IX) lock
 LCK_M_IU				Occurs when a task is waiting to acquire an Intent Update (IU) lock
 LCK_M_S				Occurs when a task is waiting to acquire a Shared lock

 *** I/O Related Waits ***
 ASYNC_IO_COMPLETION	Occurs when a task is waiting for I/Os to finish
 IO_COMPLETION			Occurs while waiting for I/O operations to complete. 
							This wait type generally represents non-data page I/Os. Data page I/O completion waits appear 
							as PAGEIOLATCH_* waits
 PAGEIOLATCH_SH			Occurs when a task is waiting on a latch for a buffer that is in an I/O request. 
							The latch request is in Shared mode. Long waits may indicate problems with the disk subsystem.
 PAGEIOLATCH_EX			Occurs when a task is waiting on a latch for a buffer that is in an I/O request. 
							The latch request is in Exclusive mode. Long waits may indicate problems with the disk subsystem.
 WRITELOG				Occurs while waiting for a log flush to complete. 
							Common operations that cause log flushes are checkpoints and transaction commits.
 PAGELATCH_EX			Occurs when a task is waiting on a latch for a buffer that is not in an I/O request. 
							The latch request is in Exclusive mode.
 BACKUPIO				Occurs when a backup task is waiting for data, or is waiting for a buffer in which to store data

 *** CPU Related Waits ***
 SOS_SCHEDULER_YIELD	Occurs when a task voluntarily yields the scheduler for other tasks to execute. 
							During this wait the task is waiting for its quantum to be renewed.

 THREADPOOL				Occurs when a task is waiting for a worker to run on. 
							This can indicate that the maximum worker setting is too low, or that batch executions are taking 
							unusually long, thus reducing the number of workers available to satisfy other batches.
 CX_PACKET				Occurs when trying to synchronize the query processor exchange iterator 
							You may consider lowering the degree of parallelism if contention on this wait type becomes a problem
							Often caused by missing indexes or poorly written queries
*/