
CREATE TABLE [dbo].[DimTimeOfDay] (
	[Id] INT NOT NULL,
	[Time] TIME(0) NOT NULL,
	CONSTRAINT [PK_DimTimeOfDay] PRIMARY KEY CLUSTERED ([Id] ASC)
)

CREATE TABLE [dbo].[DimDate] (
	[Id] SMALLINT NOT NULL,
	[Date] DATE NOT NULL,
	CONSTRAINT [PK_DimDate] PRIMARY KEY CLUSTERED ([Id] ASC)
)

DECLARE @epoch DATETIME  = '2015-01-01'
DECLARE @years int = 50

--digits gives you a set of 10 numbers 0-9 
;with digits (i) as( 
        select 1 as i union all select 2 as i union all select 3 union all 
        select 4 union all select 5 union all select 6 union all select 7 
        union all select 8 union all select 9 union all select 0) 
--sequence produces a set of integers from 0 - 99999 
,sequence (i) as ( 
        SELECT D1.i + (10*D2.i) + (100*D3.i) + (1000*D4.i) + (10000*D5.i) 
        FROM digits AS D1 CROSS JOIN digits AS D2 CROSS JOIN digits AS D3 CROSS JOIN digits AS D4 CROSS JOIN digits AS D5) 
SELECT i, CONVERT(TIME(0),DATEADD(ss,i,@epoch)) as DateAndTime
  FROM sequence
 WHERE 0 <= i
   AND i < (24*60*60)
 order by i 

 --digits gives you a set of 10 numbers 0-9 
;with digits (i) as( 
        select 1 as i union all select 2 as i union all select 3 union all 
        select 4 union all select 5 union all select 6 union all select 7 
        union all select 8 union all select 9 union all select 0) 
--sequence produces a set of integers from 0 - 99999 
,sequence (i) as ( 
        SELECT D1.i + (10*D2.i) + (100*D3.i) + (1000*D4.i) + (10000*D5.i) 
        FROM digits AS D1 CROSS JOIN digits AS D2 CROSS JOIN digits AS D3 CROSS JOIN digits AS D4 CROSS JOIN digits AS D5) 
SELECT CONVERT(SMALLINT,i), [Date] = convert(date,DATEADD(dd,i,@epoch))
  FROM sequence
 WHERE 0 <= i
   AND DATEADD(dd,i,@epoch) < dateadd(yyyy,@years,@epoch)
 order by i 