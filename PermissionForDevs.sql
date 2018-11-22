CREATE LOGIN testdev WITH PASSWORD = 'sldkjlkjlkj 987kj//'

CREATE USER testdev

GRANT ALTER ON SCHEMA::dbo TO testdev
GRANT CREATE PROCEDURE TO testdev
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO testdev

CREATE TABLE mysig (a int NOT NULL)
EXECUTE AS USER = 'testdev'
go

CREATE PROCEDURE slaskis AS PRINT 12
go

CREATE TABLE hoppsan(a int NOT NULL) -- FAILS!
go

INSERT mysig (a) VALUES(123)
go

REVERT
go

DROP PROCEDURE slaskis
DROP TABLE mysig
DROP USER testdev
DROP LOGIN testdev