-- =============================================
-- Data Warehouse Generation Script (Star Schema) - FIXED
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
IF OBJECT_ID('dbo.DimEmployee', 'U') IS NOT NULL DROP TABLE dbo.DimEmployee;

SELECT DISTINCT 
    PersonNo
INTO dbo.DimEmployee
FROM dbo.stg_SalaryRaw
WHERE [year] >= '04';
GO

-- 3. Create Fact Table: Salary (FactSalary)
-- Fixed: Removed explicit selection of columns that are already included in *
IF OBJECT_ID('dbo.FactSalary', 'U') IS NOT NULL DROP TABLE dbo.FactSalary;

SELECT 
    -- Generate PeriodKey to join with DimPeriod
    CAST((CASE WHEN LEN([year]) = 2 THEN '14' + [year] ELSE [year] END) AS INT) * 100 + [MonthNumber] AS PeriodKey,
    -- Select all other columns from the source table
    *
INTO dbo.FactSalary
FROM dbo.stg_SalaryRaw
WHERE [year] >= '04'
  AND [MonthNumber] IS NOT NULL;
GO

-- 4. Clean up columns in FactTable (Optional)
-- Removing redundant columns from Fact table after creation
ALTER TABLE dbo.FactSalary DROP COLUMN [PeriodName];
-- You can uncomment these if you want to save more space, but keeping them is often harmless:
-- ALTER TABLE dbo.FactSalary DROP COLUMN [year];
-- ALTER TABLE dbo.FactSalary DROP COLUMN [month];
-- ALTER TABLE dbo.FactSalary DROP COLUMN [MonthNumber];
GO
