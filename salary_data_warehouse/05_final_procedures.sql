USE [SalaryDW];
GO

-- =============================================
-- PART 2: ETL STORED PROCEDURES
-- This script creates the stored procedures that automate your workflow.
-- =============================================

-- 1. EXTRACT PROCEDURE: Pulls data from Linked Server
CREATE OR ALTER PROCEDURE dbo.sp_ETL_Extract
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '>>> Starting Extraction (sp_ETL_Extract)...';
    
    -- Drop Staging Table if exists
    IF OBJECT_ID('dbo.stg_SalaryRaw', 'U') IS NOT NULL 
        DROP TABLE dbo.stg_SalaryRaw;

    -- Extract SnapMarket Data
    PRINT 'Fetching SnapMarket data...';
    SELECT *, CAST('SnapMarket' AS NVARCHAR(50)) AS SourceSystem
    INTO dbo.stg_SalaryRaw
    FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalarySnapMarket');

    -- Extract Zooket Data
    PRINT 'Fetching Zooket data...';
    INSERT INTO dbo.stg_SalaryRaw
    SELECT *, 'Zooket'
    FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalaryZooket');
    
    PRINT '>>> Extraction Complete.';
END
GO

-- 2. TRANSFORM PROCEDURE: Cleans and Prepares Data
CREATE OR ALTER PROCEDURE dbo.sp_ETL_Transform
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '>>> Starting Transformation (sp_ETL_Transform)...';

    -- A. Handle Year/Month Columns
    -- Since we recreated the table in Extract, we need to add these columns
    IF NOT EXISTS(SELECT * FROM sys.columns WHERE Name = N'year' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
        ALTER TABLE dbo.stg_SalaryRaw ADD [year] NVARCHAR(50);

    IF NOT EXISTS(SELECT * FROM sys.columns WHERE Name = N'month' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
        ALTER TABLE dbo.stg_SalaryRaw ADD [month] NVARCHAR(50);
        
    -- Split PeriodName into Year and Month
    UPDATE dbo.stg_SalaryRaw
    SET 
        [year] = CASE 
                    WHEN CHARINDEX(' ', PeriodName) > 0 
                    THEN LTRIM(SUBSTRING(PeriodName, CHARINDEX(' ', PeriodName) + 1, LEN(PeriodName)))
                    ELSE NULL 
                  END,
        [month] = CASE 
                    WHEN CHARINDEX(' ', PeriodName) > 0 
                    THEN LEFT(PeriodName, CHARINDEX(' ', PeriodName) - 1)
                    ELSE PeriodName 
                 END
    WHERE PeriodName IS NOT NULL;

    -- B. Handle Employee Status
    IF NOT EXISTS(SELECT * FROM sys.columns WHERE Name = N'EmployeeStatus' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
        ALTER TABLE dbo.stg_SalaryRaw ADD [EmployeeStatus] NVARCHAR(20);

    -- Logic as requested: ExitDate NOT NULL -> 'Active'
    UPDATE dbo.stg_SalaryRaw
    SET [EmployeeStatus] = CASE 
                            WHEN [ExitDate] IS NOT NULL THEN 'Active'
                            ELSE 'Inactive'
                           END;

    -- C. Handle Month Number
    IF EXISTS(SELECT * FROM sys.columns WHERE Name = N'MonthNumber' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
        ALTER TABLE dbo.stg_SalaryRaw DROP COLUMN [MonthNumber];
    
    ALTER TABLE dbo.stg_SalaryRaw ADD [MonthNumber] INT;

    UPDATE dbo.stg_SalaryRaw
    SET [MonthNumber] = CASE [month]
                            WHEN N'فروردين' THEN 1
                            WHEN N'ارديبهشت' THEN 2
                            WHEN N'خرداد' THEN 3
                            WHEN N'تير' THEN 4
                            WHEN N'مرداد' THEN 5
                            WHEN N'شهريور' THEN 6
                            WHEN N'مهر' THEN 7
                            WHEN N'آبان' THEN 8
                            WHEN N'آذر' THEN 9
                            WHEN N'دي' THEN 10
                            WHEN N'بهمن' THEN 11
                            WHEN N'اسفند' THEN 12
                            ELSE NULL
                        END;

    -- D. Rename Columns
    -- We check existence to avoid errors
    IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractOrgUnitName' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
        EXEC sp_rename 'dbo.stg_SalaryRaw.ContractOrgUnitName', 'Department', 'COLUMN';

    IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractEmployeeType' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
        EXEC sp_rename 'dbo.stg_SalaryRaw.ContractEmployeeType', 'Businessline', 'COLUMN';

    IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractEmployeeStatus' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
        EXEC sp_rename 'dbo.stg_SalaryRaw.ContractEmployeeStatus', 'HRBP', 'COLUMN';

    IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractJobTotle' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
        EXEC sp_rename 'dbo.stg_SalaryRaw.ContractJobTotle', 'JobTitle', 'COLUMN';
    ELSE IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractJobTitle' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
        EXEC sp_rename 'dbo.stg_SalaryRaw.ContractJobTitle', 'JobTitle', 'COLUMN';
        
    PRINT '>>> Transformation Complete.';
END
GO

-- 3. LOAD PROCEDURE: Creates Dimensions and Facts
CREATE OR ALTER PROCEDURE dbo.sp_ETL_Load
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '>>> Starting Load (sp_ETL_Load)...';

    -- DimPeriod
    IF OBJECT_ID('dbo.DimPeriod', 'U') IS NOT NULL DROP TABLE dbo.DimPeriod;
    SELECT DISTINCT
        CAST((CASE WHEN LEN([year]) = 2 THEN '14' + [year] ELSE [year] END) AS INT) * 100 + [MonthNumber] AS PeriodKey,
        [year] AS PersianYear,
        [month] AS PersianMonthName,
        [MonthNumber] AS PersianMonthNo,
        PeriodName AS OriginalPeriodName
    INTO dbo.DimPeriod
    FROM dbo.stg_SalaryRaw
    WHERE [year] >= '04' AND [MonthNumber] IS NOT NULL;

    -- DimEmployee
    IF OBJECT_ID('dbo.DimEmployee', 'U') IS NOT NULL DROP TABLE dbo.DimEmployee;
    SELECT DISTINCT PersonNo
    INTO dbo.DimEmployee
    FROM dbo.stg_SalaryRaw
    WHERE [year] >= '04';

    -- FactSalary
    IF OBJECT_ID('dbo.FactSalary', 'U') IS NOT NULL DROP TABLE dbo.FactSalary;
    SELECT 
        CAST((CASE WHEN LEN([year]) = 2 THEN '14' + [year] ELSE [year] END) AS INT) * 100 + [MonthNumber] AS PeriodKey,
        *
    INTO dbo.FactSalary
    FROM dbo.stg_SalaryRaw
    WHERE [year] >= '04' AND [MonthNumber] IS NOT NULL;

    ALTER TABLE dbo.FactSalary DROP COLUMN [PeriodName];

    PRINT '>>> Load Complete.';
END
GO

-- 4. VIEWS PROCEDURE: Refreshes Power BI Views
CREATE OR ALTER PROCEDURE dbo.sp_ETL_RefreshViews
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '>>> Refreshing Views (sp_ETL_RefreshViews)...';

    -- Fact View
    IF OBJECT_ID('dbo.vw_PBI_FactSalary_1404', 'V') IS NOT NULL DROP VIEW dbo.vw_PBI_FactSalary_1404;
    EXEC('CREATE VIEW dbo.vw_PBI_FactSalary_1404 AS SELECT * FROM dbo.FactSalary WHERE [year] = ''04'';');

    -- Period View
    IF OBJECT_ID('dbo.vw_PBI_DimPeriod_1404', 'V') IS NOT NULL DROP VIEW dbo.vw_PBI_DimPeriod_1404;
    EXEC('CREATE VIEW dbo.vw_PBI_DimPeriod_1404 AS SELECT * FROM dbo.DimPeriod WHERE PersianYear = ''04'';');

    -- Employee View
    IF OBJECT_ID('dbo.vw_PBI_DimEmployee_1404', 'V') IS NOT NULL DROP VIEW dbo.vw_PBI_DimEmployee_1404;
    EXEC('CREATE VIEW dbo.vw_PBI_DimEmployee_1404 AS SELECT DISTINCT e.* FROM dbo.DimEmployee e JOIN dbo.FactSalary f ON e.PersonNo = f.PersonNo WHERE f.[year] = ''04'';');

    PRINT '>>> Views Refreshed.';
END
GO

-- 5. MASTER PROCEDURE: Runs Everything
-- Run this once a week to update your data
CREATE OR ALTER PROCEDURE dbo.sp_RunWeeklyETL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT '=== STARTING WEEKLY ETL ===';
        
        -- Step 1: Extract (Refresh Staging from Remote)
        EXEC dbo.sp_ETL_Extract;
        
        -- Step 2: Transform (Clean and Rename)
        EXEC dbo.sp_ETL_Transform;
        
        -- Step 3: Load (Update DW Tables)
        EXEC dbo.sp_ETL_Load;
        
        -- Step 4: Refresh Views (Ensure Views match new tables)
        EXEC dbo.sp_ETL_RefreshViews;
        
        PRINT '=== ETL COMPLETED SUCCESSFULLY ===';
    END TRY
    BEGIN CATCH
        PRINT '!!! ERROR OCCURRED !!!';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO
