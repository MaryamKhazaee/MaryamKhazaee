USE [master];
GO

-- 1. Create the local database if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'SalaryDW')
BEGIN
    CREATE DATABASE [SalaryDW];
END
GO

USE [SalaryDW];
GO

-- 2. Drop the table if it exists to start fresh
IF OBJECT_ID('dbo.stg_SalaryRaw', 'U') IS NOT NULL 
    DROP TABLE dbo.stg_SalaryRaw;
GO

-- 3. Extract SnapMarket data (This creates the table)
-- We use OPENQUERY for better network stability
SELECT *, CAST('SnapMarket' AS NVARCHAR(50)) AS SourceSystem
INTO dbo.stg_SalaryRaw
FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalarySnapMarket');
GO

-- 4. Extract Zooket data (This adds to the table)
INSERT INTO dbo.stg_SalaryRaw
SELECT *, 'Zooket'
FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalaryZooket');
GO

-- 5. Final Check: Show the data and the column names
SELECT TOP 10 * FROM dbo.stg_SalaryRaw;
