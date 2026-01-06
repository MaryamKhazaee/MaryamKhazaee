USE [SalaryDW];
GO

PRINT '=== TEST 1: Basic Connectivity (Should be instant) ===';
-- Just get 1 row to see if the server responds at all
SELECT TOP 1 * 
FROM OPENQUERY(REMOTE_VIEW3, 'SELECT TOP 1 * FROM View3.dbo.SalarySnapMarket');
GO

PRINT '=== TEST 2: Filter Performance (Check timing) ===';
-- This checks how long it takes for the REMOTE server to process the filter
-- If this takes 5 minutes, the problem is the REMOTE VIEW itself is slow.
DECLARE @StartTime DATETIME = GETDATE();

SELECT * 
FROM OPENQUERY(REMOTE_VIEW3, 'SELECT COUNT(*) as CountRows FROM View3.dbo.SalarySnapMarket WHERE PeriodName LIKE ''% 04''');

PRINT 'Test 2 Duration (Seconds): ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS NVARCHAR(50));
GO
