-- =============================================
-- Data Warehouse Generation Script (Star Schema) - Updated
-- Target: Power BI Dashboard
-- =============================================

-- 1. Create Dimension: Period (DimPeriod)
IF OBJECT_ID('dbo.DimPeriod', 'U') IS NOT NULL DROP TABLE dbo.DimPeriod;

SELECT DISTINCT
    CAST((CASE WHEN LEN([year]) = 2 THEN '14' + [year] ELSE [year] END) AS INT) * 100 + [MonthNumber] AS PeriodKey,
    [year] AS PersianYear,
    [month] AS PersianMonthName,
    [MonthNumber] AS PersianMonthNo,
    PeriodName AS OriginalPeriodName
INTO dbo.DimPeriod
FROM dbo.stg_SalaryRaw
WHERE [year] >= '04' 
  AND [MonthNumber] IS NOT NULL;
GO

-- 2. Create Dimension: Employee (DimEmployee)
-- Kept simple (PersonNo only) to handle historical changes (e.g. Dept changes) in the Fact table.
IF OBJECT_ID('dbo.DimEmployee', 'U') IS NOT NULL DROP TABLE dbo.DimEmployee;

SELECT DISTINCT 
    PersonNo
INTO dbo.DimEmployee
FROM dbo.stg_SalaryRaw
WHERE [year] >= '04';
GO

-- 3. Create Fact Table: Salary (FactSalary)
-- This will now include the renamed columns: Department, Businessline, HRBP, JobTitle
IF OBJECT_ID('dbo.FactSalary', 'U') IS NOT NULL DROP TABLE dbo.FactSalary;

SELECT 
    -- Generate PeriodKey
    CAST((CASE WHEN LEN([year]) = 2 THEN '14' + [year] ELSE [year] END) AS INT) * 100 + [MonthNumber] AS PeriodKey,
    -- Select all columns (includes Department, Businessline, HRBP, JobTitle)
    *
INTO dbo.FactSalary
FROM dbo.stg_SalaryRaw
WHERE [year] >= '04'
  AND [MonthNumber] IS NOT NULL;
GO

-- 4. Cleanup
-- Remove redundant columns from FactTable
ALTER TABLE dbo.FactSalary DROP COLUMN [PeriodName];
-- The following columns are preserved in the Fact table for easy slicing/dicing:
-- Department, Businessline, HRBP, JobTitle, EmployeeStatus, ExitDate, year, month
GO
