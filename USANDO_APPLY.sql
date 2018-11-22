use TSQLV4
go

CREATE INDEX idx_poc
ON Sales.Orders(custid, orderdate DESC, orderid DESC)
INCLUDE(empid);

--ERRO
SELECT C.custid, C.companyname,
( 
	SELECT TOP (1) O.orderid, O.orderdate, O.empid
	FROM Sales.Orders AS O
	WHERE O.custid = C.custid
	ORDER BY O.orderdate DESC, O.orderid DESC
)
FROM Sales.Customers AS C;

--acerto
SELECT C.custid, C.companyname,
( SELECT TOP (1) O.orderid
FROM Sales.Orders AS O
WHERE O.custid = C.custid
ORDER BY O.orderdate DESC, O.orderid DESC ) AS orderid,
  ( SELECT TOP (1) O.orderdate
	FROM Sales.Orders AS O
	WHERE O.custid = C.custid
	ORDER BY O.orderdate DESC, O.orderid DESC ) AS orderdate,
	( SELECT TOP (1) O.empid
	FROM Sales.Orders AS O
	WHERE O.custid = C.custid
	ORDER BY O.orderdate DESC, O.orderid DESC ) AS empid
FROM Sales.Customers AS C;
go

--SELECT C.custid, C.companyname, O.orderid, O.orderdate, O.empid
--FROM Sales.Customers AS C
--  CROSS JOIN ( SELECT TOP (3) O.orderid, O.orderdate, O.empid
--			   FROM Sales.Orders AS O
--				 WHERE O.custid = C.custid
--					ORDER BY O.orderdate DESC, O.orderid DESC ) AS O;
-------------------------------------------
SELECT 
	C.custid
,	C.companyname
,	O.orderid
,	O.orderdate
,	O.empid
FROM Sales.Customers AS C
  OUTER  APPLY ( 
				SELECT TOP (3) O.orderid, O.orderdate, O.empid
				FROM Sales.Orders AS O
				WHERE O.custid = C.custid
				ORDER BY O.orderdate DESC, O.orderid DESC 
			  ) AS O;
------------------------------------------------------------
SELECT * FROM  Sales.Orders WHERE CUSTID = 57
-----------------------------------------------------------
SELECT orderyear, ordermonth, COUNT(*) AS numorders
FROM Sales.Orders
  CROSS APPLY 
	( 
		VALUES( YEAR(orderdate), MONTH(orderdate) ) 
	)
AS A	(orderyear, ordermonth)
GROUP BY orderyear, ordermonth;
-----------------------------------------------------------
SELECT orderyear, ordermonth, COUNT(*) AS numorders
FROM Sales.Orders
  CROSS APPLY ( VALUES	( YEAR(orderdate), MONTH(orderdate),  DATEFROMPARTS(orderyear, 12, 31)) )
				AS A	(orderyear	, ordermonth	, endofyear)
WHERE orderdate <> endofyear
GROUP BY orderyear, ordermonth;

SELECT DATEFROMPARTS(GETDATE(), 12, 31)
---------------------------------------------------------------
SELECT orderyear, ordermonth, COUNT(*) AS numorders
FROM Sales.Orders
  CROSS APPLY (		VALUES( YEAR(orderdate), MONTH(orderdate) ) )
AS A1	(orderyear, ordermonth)
  CROSS APPLY (		VALUES( DATEFROMPARTS(orderyear, 12, 31)  ) )
AS A2	(endofyear)
WHERE 
	orderdate <> endofyear
GROUP BY 
	orderyear, ordermonth;



 