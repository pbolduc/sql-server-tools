SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DiskUsageByTable] 
AS
BEGIN
	SET NOCOUNT ON;


	CREATE TABLE #temp 
       (TableName NVARCHAR (128), 
        RowsCnt VARCHAR (11), 
        ReservedSpace VARCHAR(18), 
        DataSpace VARCHAR(18), 
        CombinedIndexSpace VARCHAR(18), 
        UnusedSpace VARCHAR(18));

	EXEC sp_MSforeachtable 'INSERT INTO #temp (TableName, RowsCnt, ReservedSpace, DataSpace, CombinedIndexSpace, UnusedSpace) EXEC sp_spaceused ''?'', FALSE';

	SELECT TableName, 
           cast(RowsCnt as int) RowsCount, 
           cast(SUBSTRING(DataSpace, 0, CHARINDEX(' ', DataSpace)) as int) dSpaceKB,
           cast(SUBSTRING(CombinedIndexSpace, 0, CHARINDEX(' ', CombinedIndexSpace)) as int) indexSpaceKB,
	   cast(SUBSTRING(DataSpace, 0, CHARINDEX(' ', DataSpace)) as int) + 
           cast(SUBSTRING(CombinedIndexSpace, 0, CHARINDEX(' ', CombinedIndexSpace)) as int) totalSpaceKB
      FROM #temp
     order by totalSpaceKB desc;

	DROP TABLE #temp;

END
