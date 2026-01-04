-- =============================================
-- Data Warehouse Generation Script (Star Schema)
-- Target: Power BI Dashboard
-- =============================================

-- 1. Create Dimension: Period (DimPeriod)
-- This table handles the time dimension. We create a numeric Key (YYYYMM) for sorting and joining.
IF OBJECT_ID('dbo.DimPeriod', 'U') IS NOT NULL DROP TABLE dbo.DimPeriod;

SELECT DISTINCT
    -- Create a surrogate key: 140408 (for year 04 month 08)
    CAST((CASE WHEN LEN([year]) = 2 THEN '14' + [year] ELSE [year] END) AS INT) * 100 + [MonthNumber] AS PeriodKey,
    [year] AS PersianYear,
    [month] AS PersianMonthName,
    [MonthNumber] AS PersianMonthNo,
    PeriodName AS OriginalPeriodName
INTO dbo.DimPeriod
FROM dbo.stg_SalaryRaw
WHERE [year] >= '04' 
  AND [MonthNumber] IS NOT NULL; -- Ensure we don't have bad data
GO

-- 2. Create Dimension: Employee (DimEmployee)
-- Contains unique list of employees.
-- Note: In a real scenario, you would group by PersonNo and take the latest Name/Info.
IF OBJECT_ID('dbo.DimEmployee', 'U') IS NOT NULL DROP TABLE dbo.DimEmployee;

SELECT DISTINCT 
    PersonNo
    -- Add Name or other static employee columns here if they exist in the raw table
    -- , MAX(FirstName) as FirstName
    -- , MAX(LastName) as LastName
INTO dbo.DimEmployee
FROM dbo.stg_SalaryRaw
WHERE [year] >= '04';
GO

-- 3. Create Fact Table: Salary (FactSalary)
-- Contains the transactional data and foreign keys to dimensions.
IF OBJECT_ID('dbo.FactSalary', 'U') IS NOT NULL DROP TABLE dbo.FactSalary;

SELECT 
    -- Foreign Key to DimPeriod
    CAST((CASE WHEN LEN(r.[year]) = 2 THEN '14' + r.[year] ELSE r.[year] END) AS INT) * 100 + r.[MonthNumber] AS PeriodKey,
    
    -- Foreign Key to DimEmployee
    r.PersonNo,
    
    -- Status attributes (Degenerate Dimension or Fact Attribute)
    r.EmployeeStatus,
    r.ExitDate,
    
    -- All other columns (Measures/Amounts)
    -- Ideally, specify columns explicitly: r.BasicSalary, r.Overtime, etc.
    r.*
INTO dbo.FactSalary
FROM dbo.stg_SalaryRaw r
WHERE r.[year] >= '04'
  AND r.[MonthNumber] IS NOT NULL;
GO

-- 4. Clean up columns in FactTable that are now redundant (Optional)
-- We remove the columns that are now handled by the joins or Keys to save space.
ALTER TABLE dbo.FactSalary DROP COLUMN [PeriodName];
-- You might want to keep year/month in Fact for easy debugging, or remove them if strict normalization is desired.
-- ALTER TABLE dbo.FactSalary DROP COLUMN [year];
-- ALTER TABLE dbo.FactSalary DROP COLUMN [month];
-- ALTER TABLE dbo.FactSalary DROP COLUMN [MonthNumber];
GO
