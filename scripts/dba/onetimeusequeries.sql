USE [master]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FindOneTimeUseQueries] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

select top 100 *
from (
select refcounts, usecounts, size_in_bytes /1024 as sizeInKb, text 
from sys.dm_Exec_cached_plans
cross apply sys.dm_exec_sql_text(plan_handle)
where cacheobjtype = 'Compiled Plan'
and objtype = 'Adhoc' and usecounts = 1 
and text not like 'FETCH API_CURSOR%' ) as qu
order by sizeInKb desc
	
END
