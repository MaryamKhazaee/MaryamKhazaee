USE [SalaryDW];
GO

PRINT '=======================================================';
PRINT 'TEST REPORT FOR SALARY DATA WAREHOUSE (Suffix 2)';
PRINT '=======================================================';

-- 1. Check Staging Table
PRINT '';
PRINT '>>> 1. Checking Staging Table (stg_SalaryRaw2)';
PRINT '-------------------------------------------------------';
SELECT 'Total Rows' AS Metric, COUNT(*) AS Value FROM dbo.stg_SalaryRaw2;
SELECT TOP 5 
    SourceSystem, 
    PeriodName, 
    [year], 
    [month], 
    EmployeeStatus 
FROM dbo.stg_SalaryRaw2;

-- 2. Check Dimensions
PRINT '';
PRINT '>>> 2. Checking Dimensions';
PRINT '-------------------------------------------------------';
SELECT 'DimPeriod2 Count' AS Metric, COUNT(*) AS Value FROM dbo.DimPeriod2;
SELECT TOP 5 * FROM dbo.DimPeriod2;

SELECT 'DimEmployee2 Count' AS Metric, COUNT(*) AS Value FROM dbo.DimEmployee2;
SELECT TOP 5 * FROM dbo.DimEmployee2;

-- 3. Check Fact Table & Column Renaming
PRINT '';
PRINT '>>> 3. Checking Fact Table (FactSalary2)';
PRINT '-------------------------------------------------------';
SELECT 'FactSalary2 Count' AS Metric, COUNT(*) AS Value FROM dbo.FactSalary2;

-- Check if renaming worked (Department, Businessline, HRBP, JobTitle)
-- We select these specific columns to confirm they exist and have data
SELECT TOP 5 
    PersonNo, 
    PeriodKey, 
    Department, 
    Businessline, 
    HRBP, 
    JobTitle
FROM dbo.FactSalary2;

-- 4. Check Power BI Views
PRINT '';
PRINT '>>> 4. Checking Power BI Views (Year 1404)';
PRINT '-------------------------------------------------------';
SELECT 'View Fact 1404 Count' AS Metric, COUNT(*) AS Value FROM dbo.vw_PBI_FactSalary_1404_2;
