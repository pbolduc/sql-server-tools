SELECT OBJECT_NAME(i.OBJECT_ID) AS TableName, pf.name AS PFName, ps.name AS PSName, ds.name AS FGName, pv.value 
   ,CASE WHEN pf.boundary_value_on_right = 1 THEN 'Range Right' ELSE 'Range Left' END AS Type 
   ,t.name AS DataType, pp.max_length, pp.PRECISION, pp.scale 
   ,ps.is_default 
   ,pv.parameter_id, pf.fanout AS PartitionCount 
   ,i.index_id AS Index_ID, 
   p.partition_number,  
   rows AS ApproxRowCount,  
   au.total_pages 
--select * 
FROM sys.partitions p  
JOIN sys.indexes i ON p.OBJECT_ID = i.OBJECT_ID AND p.index_id = i.index_id 
JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id 
JOIN sys.partition_functions pf ON pf.function_id = ps.function_id 
LEFT JOIN sys.partition_range_values pv ON pf.function_id = pv.function_id 
         AND p.partition_number = pv.boundary_id 
JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id 
         AND dds.destination_id = p.partition_number 
JOIN sys.partition_parameters pp ON pf.function_id = pp.function_id 
JOIN sys.types t ON t.system_type_id = pp.system_type_id 
JOIN sys.data_spaces ds ON ds.data_space_id=dds.data_space_id 
JOIN (SELECT container_id, SUM(total_pages) AS total_pages 
     FROM sys.allocation_units 
     GROUP BY container_id) AS au ON au.container_id = p.partition_id 
ORDER BY partition_number 