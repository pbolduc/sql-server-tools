--Memory consumption by object within a database

SELECT TOP 100 

            obj.[name],

            i.[name],

            i.[type_desc],

            count_big(*)AS Buffered_Page_Count ,

            count_big(*) * 8192 / (1024 * 1024) as Buffer_MB

    -- ,obj.name ,obj.index_id, i.[name]

FROM sys.dm_os_buffer_descriptors AS bd 

    INNER JOIN 

    (

        SELECT object_name(object_id) AS name 

            ,index_id ,allocation_unit_id, object_id

        FROM sys.allocation_units AS au

            INNER JOIN sys.partitions AS p 

                ON au.container_id = p.hobt_id 

                    AND (au.type = 1 OR au.type = 3)

        UNION ALL

        SELECT object_name(object_id) AS name   

            ,index_id, allocation_unit_id, object_id

        FROM sys.allocation_units AS au

            INNER JOIN sys.partitions AS p 

                ON au.container_id = p.hobt_id 

                    AND au.type = 2

    ) AS obj 

        ON bd.allocation_unit_id = obj.allocation_unit_id

LEFT JOIN sys.indexes i on i.object_id = obj.object_id AND i.index_id = obj.index_id

WHERE database_id = db_id()

GROUP BY obj.name, obj.index_id , i.[name],i.[type_desc]

ORDER BY Buffered_Page_Count DESC

 

 

---------------------------------

--Memory consumption by database

SELECT LEFT(CASE database_id 

                                    WHEN 32767 THEN 'ResourceDb' 

                                    ELSE db_name(database_id) 

        END, 20) AS Database_Name,

            count_big(*) AS Buffered_Page_Count, 

            count_big(*) * 8192 / (1024 * 1024) as Buffer_Pool_MB

FROM sys.dm_os_buffer_descriptors

GROUP BY db_name(database_id) ,database_id

ORDER BY Buffered_Page_Count DESC

