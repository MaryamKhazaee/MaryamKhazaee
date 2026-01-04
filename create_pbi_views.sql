-- =============================================
-- Power BI Views (Filtered for Year 04)
-- Use these views in Power BI to get only 1404 data
-- =============================================

-- 1. Fact View: Only 1404 data
IF OBJECT_ID('dbo.vw_PBI_FactSalary_1404', 'V') IS NOT NULL DROP VIEW dbo.vw_PBI_FactSalary_1404;
GO

CREATE VIEW dbo.vw_PBI_FactSalary_1404 AS
SELECT * 
FROM dbo.FactSalary
WHERE [year] = '04';
GO

-- 2. Period Dimension View: Only 1404 months
IF OBJECT_ID('dbo.vw_PBI_DimPeriod_1404', 'V') IS NOT NULL DROP VIEW dbo.vw_PBI_DimPeriod_1404;
GO

CREATE VIEW dbo.vw_PBI_DimPeriod_1404 AS
SELECT * 
FROM dbo.DimPeriod
WHERE PersianYear = '04';
GO

-- 3. Employee Dimension View: Only employees present in 1404
IF OBJECT_ID('dbo.vw_PBI_DimEmployee_1404', 'V') IS NOT NULL DROP VIEW dbo.vw_PBI_DimEmployee_1404;
GO

CREATE VIEW dbo.vw_PBI_DimEmployee_1404 AS
SELECT DISTINCT e.*
FROM dbo.DimEmployee e
JOIN dbo.FactSalary f ON e.PersonNo = f.PersonNo
WHERE f.[year] = '04';
GO
