SELECT
DATEADD(yy, DATEDIFF(yy,0,getdate()), 0) AS StartOfYear,
DATEADD(yy, DATEDIFF(yy,0,getdate()) + 1, -1) AS LastDayOfYear,
DATEADD(yy, DATEDIFF(yy,0,getdate()) + 1, 0) AS FirstOfNextYear,
DATEADD(ms, -3, DATEADD(yy, DATEDIFF(yy,0,getdate()) + 1, 0)) AS LastTimeOfYear