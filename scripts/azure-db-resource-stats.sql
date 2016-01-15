-- --------------------------------------------------------------------------------------------------------------------------------------------------
--
-- 
--
SELECT TOP 10 *
  FROM sys.dm_db_resource_stats
-- WHERE end_time >= DATEADD(mi,-15,GETUTCDATE())
 ORDER BY end_time DESC

-- get how well a database fits in the service level
--
-- https://azure.microsoft.com/en-us/blog/azure-sql-database-introduces-new-near-real-time-performance-metrics/

SELECT  (COUNT(end_time) - SUM(CASE WHEN avg_cpu_percent > 80 THEN 1 ELSE 0 END) * 1.0) / COUNT(end_time) AS 'CPU Fit Percent'
       ,(COUNT(end_time) - SUM(CASE WHEN avg_log_write_percent > 80 THEN 1 ELSE 0 END) * 1.0) / COUNT(end_time) AS 'Log Write Fit Percent'
       ,(COUNT(end_time) - SUM(CASE WHEN avg_data_io_percent > 80 THEN 1 ELSE 0 END) * 1.0) / COUNT(end_time) AS 'Physical Data Read Fit Percent'
  FROM sys.dm_db_resource_stats
-- WHERE end_time >= DATEADD(mi,-60,GETUTCDATE())

-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- Returns CPU usage and storage data for an Azure SQL Database. The data is collected and aggregated within five-minute intervals. 
-- For each user database, there is one row for every five-minute reporting window in which there is change in resource consumption. 
-- This includes CPU usage, storage size change or database SKU modification. Idle databases with no changes may not have rows for 
-- every five minute interval. Historical data is retained for approximately 14 days.
--
-- Run in [master] database
--
-- https://msdn.microsoft.com/en-CA/library/dn269979.aspx
-- https://azure.microsoft.com/en-us/blog/azure-sql-database-introduces-new-near-real-time-performance-metrics/
--

DECLARE @database_name sysname = N'database-name'

SELECT  start_time
       ,end_time
	   ,(SELECT MAX(v) FROM (VALUES (avg_cpu_percent), (avg_data_io_percent), (avg_log_write_percent)) AS value(v)) as [avg_DTU_percent] 
  FROM sys.resource_stats
  WHERE database_name = @database_name 
  ORDER BY end_time DESC


