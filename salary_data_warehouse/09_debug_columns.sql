USE [SalaryDW];
GO

-- =============================================
-- DIAGNOSTIC SCRIPT: Compare Columns
-- =============================================

PRINT '>>> DROPPING TEMP TABLES...';
IF OBJECT_ID('dbo.debug_Snap', 'U') IS NOT NULL DROP TABLE dbo.debug_Snap;
IF OBJECT_ID('dbo.debug_Zook', 'U') IS NOT NULL DROP TABLE dbo.debug_Zook;

PRINT '>>> DOWNLOADING 1 ROW FROM SNAPMARKET...';
SELECT TOP 1 * INTO dbo.debug_Snap FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalarySnapMarket');

PRINT '>>> DOWNLOADING 1 ROW FROM ZOOKET...';
SELECT TOP 1 * INTO dbo.debug_Zook FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalaryZooket');

PRINT '>>> COMPARING COLUMNS...';
-- This query returns columns that are in Snap but NOT in Zooket, and vice versa.
SELECT 
    ISNULL(s.COLUMN_NAME, z.COLUMN_NAME) AS ColumnName,
    CASE 
        WHEN s.COLUMN_NAME IS NOT NULL AND z.COLUMN_NAME IS NOT NULL THEN 'Both'
        WHEN s.COLUMN_NAME IS NOT NULL THEN 'Only in SnapMarket'
        ELSE 'Only in Zooket' 
    END AS Status
FROM INFORMATION_SCHEMA.COLUMNS s
FULL OUTER JOIN INFORMATION_SCHEMA.COLUMNS z 
    ON s.COLUMN_NAME = z.COLUMN_NAME 
    AND z.TABLE_NAME = 'debug_Zook'
WHERE s.TABLE_NAME = 'debug_Snap'
  AND (s.COLUMN_NAME IS NULL OR z.COLUMN_NAME IS NULL)
ORDER BY Status;
GO
