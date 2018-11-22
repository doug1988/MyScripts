USE AdventureWorks2016
SELECT 
  BusinessEntityID
  ,PersonType
 ,FirstName + ' ' + MiddleName + ' ' + LastName 
FROM Person.Person
 ORDER BY BusinessEntityID ASC
  OFFSET (2 -1 ) * 5 ROWS 
  FETCH NEXT 5 ROWS ONLY
  


  SELECT 
  BusinessEntityID
  ,PersonType
 ,FirstName + ' ' + MiddleName + ' ' + LastName 
FROM Person.Person
 ORDER BY BusinessEntityID ASC