USE [SalaryDW];
GO

-- =============================================
-- CRITICAL FIX V3: COMPILER SATISFACTION
-- The previous errors (Msg 207) happened because SQL Server checks if columns exist 
-- when creating the procedure. Since the table existed from a previous run but 
-- didn't have the new columns yet, it failed.
--
-- We will now create a "Dummy" version of the table with ALL columns first.
-- This tricks SQL Server into compiling the procedures successfully.
-- =============================================

IF OBJECT_ID('dbo.stg_SalaryRaw2', 'U') IS NOT NULL 
    DROP TABLE dbo.stg_SalaryRaw2;
GO

-- Create a dummy table with ALL potential columns so procedures can compile
CREATE TABLE dbo.stg_SalaryRaw2 (
    -- Core columns from source (just examples, strict types don't matter for compilation)
    PeriodName NVARCHAR(255),
    PersonNo NVARCHAR(50),
    ExitDate DATETIME,
    ContractOrgUnitName NVARCHAR(255),
    ContractEmployeeType NVARCHAR(255),
    ContractEmployeeStatus NVARCHAR(255),
    ContractJobTotle NVARCHAR(255),
    ContractJobTitle NVARCHAR(255),
    
    -- New columns we create in Transform
    [year] NVARCHAR(50),
    [month] NVARCHAR(50),
    [MonthNumber] INT,
    [EmployeeStatus] NVARCHAR(20),
    
    -- Renamed columns referenced in Load
    Department NVARCHAR(255),
    Businessline NVARCHAR(255),
    HRBP NVARCHAR(255),
    JobTitle NVARCHAR(255)
);
GO

-- =============================================
-- PROCEDURES (Now they will compile safely)
-- =============================================

-- 1. EXTRACT
CREATE OR ALTER PROCEDURE dbo.sp_ETL_Extract
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '>>> Starting Extraction (sp_ETL_Extract)...';
    
    -- Drop Staging Table if exists
    IF OBJECT_ID('dbo.stg_SalaryRaw2', 'U') IS NOT NULL 
        DROP TABLE dbo.stg_SalaryRaw2;

    -- Extract SnapMarket Data (Year 04 only)
    PRINT 'Fetching SnapMarket data (Year 04 only)...';
    SELECT *, CAST('SnapMarket' AS NVARCHAR(50)) AS SourceSystem
    INTO dbo.stg_SalaryRaw2
    FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalarySnapMarket WHERE PeriodName LIKE ''% 04''');

    -- Extract Zooket Data (Year 04 only)
    PRINT 'Fetching Zooket data (Year 04 only)...';
    INSERT INTO dbo.stg_SalaryRaw2
    SELECT *, 'Zooket'
    FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalaryZooket WHERE PeriodName LIKE ''% 04''');
    
    PRINT '>>> Extraction Complete.';
END
GO

-- 2. TRANSFORM
CREATE OR ALTER PROCEDURE dbo.sp_ETL_Transform
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '>>> Starting Transformation (sp_ETL_Transform)...';

    -- A. Handle Year/Month Columns (Add if missing, which they will be after Extract)
    IF NOT EXISTS(SELECT * FROM sys.columns WHERE Name = N'year' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw2'))
        ALTER TABLE dbo.stg_SalaryRaw2 ADD [year] NVARCHAR(50);

    IF NOT EXISTS(SELECT * FROM sys.columns WHERE Name = N'month' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw2'))
        ALTER TABLE dbo.stg_SalaryRaw2 ADD [month] NVARCHAR(50);
        
    -- Split PeriodName
    UPDATE dbo.stg_SalaryRaw2
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
    IF NOT EXISTS(SELECT * FROM sys.columns WHERE Name = N'EmployeeStatus' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw2'))
        ALTER TABLE dbo.stg_SalaryRaw2 ADD [EmployeeStatus] NVARCHAR(20);

    UPDATE dbo.stg_SalaryRaw2
    SET [EmployeeStatus] = CASE 
                            WHEN [ExitDate] IS NOT NULL THEN 'Active'
                            ELSE 'Inactive'
                           END;

    -- C. Handle Month Number
    IF EXISTS(SELECT * FROM sys.columns WHERE Name = N'MonthNumber' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw2'))
        ALTER TABLE dbo.stg_SalaryRaw2 DROP COLUMN [MonthNumber];
    
    ALTER TABLE dbo.stg_SalaryRaw2 ADD [MonthNumber] INT;

    UPDATE dbo.stg_SalaryRaw2
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
    IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractOrgUnitName' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw2'))
        EXEC sp_rename 'dbo.stg_SalaryRaw2.ContractOrgUnitName', 'Department', 'COLUMN';

    IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractEmployeeType' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw2'))
        EXEC sp_rename 'dbo.stg_SalaryRaw2.ContractEmployeeType', 'Businessline', 'COLUMN';

    IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractEmployeeStatus' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw2'))
        EXEC sp_rename 'dbo.stg_SalaryRaw2.ContractEmployeeStatus', 'HRBP', 'COLUMN';

    IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractJobTotle' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw2'))
        EXEC sp_rename 'dbo.stg_SalaryRaw2.ContractJobTotle', 'JobTitle', 'COLUMN';
    ELSE IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractJobTitle' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw2'))
        EXEC sp_rename 'dbo.stg_SalaryRaw2.ContractJobTitle', 'JobTitle', 'COLUMN';
        
    PRINT '>>> Transformation Complete.';
END
GO

-- 3. LOAD
CREATE OR ALTER PROCEDURE dbo.sp_ETL_Load
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '>>> Starting Load (sp_ETL_Load)...';

    -- DimPeriod2
    IF OBJECT_ID('dbo.DimPeriod2', 'U') IS NOT NULL DROP TABLE dbo.DimPeriod2;
    SELECT DISTINCT
        CAST((CASE WHEN LEN([year]) = 2 THEN '14' + [year] ELSE [year] END) AS INT) * 100 + [MonthNumber] AS PeriodKey,
        [year] AS PersianYear,
        [month] AS PersianMonthName,
        [MonthNumber] AS PersianMonthNo,
        PeriodName AS OriginalPeriodName
    INTO dbo.DimPeriod2
    FROM dbo.stg_SalaryRaw2
    WHERE [year] >= '04' AND [MonthNumber] IS NOT NULL;

    -- DimEmployee2
    IF OBJECT_ID('dbo.DimEmployee2', 'U') IS NOT NULL DROP TABLE dbo.DimEmployee2;
    SELECT DISTINCT PersonNo
    INTO dbo.DimEmployee2
    FROM dbo.stg_SalaryRaw2
    WHERE [year] >= '04';

    -- FactSalary2
    IF OBJECT_ID('dbo.FactSalary2', 'U') IS NOT NULL DROP TABLE dbo.FactSalary2;
    SELECT 
        CAST((CASE WHEN LEN([year]) = 2 THEN '14' + [year] ELSE [year] END) AS INT) * 100 + [MonthNumber] AS PeriodKey,
        *
    INTO dbo.FactSalary2
    FROM dbo.stg_SalaryRaw2
    WHERE [year] >= '04' AND [MonthNumber] IS NOT NULL;

    ALTER TABLE dbo.FactSalary2 DROP COLUMN [PeriodName];

    PRINT '>>> Load Complete.';
END
GO

-- 4. VIEWS
CREATE OR ALTER PROCEDURE dbo.sp_ETL_RefreshViews
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '>>> Refreshing Views (sp_ETL_RefreshViews)...';

    -- Fact View
    IF OBJECT_ID('dbo.vw_PBI_FactSalary_1404_2', 'V') IS NOT NULL DROP VIEW dbo.vw_PBI_FactSalary_1404_2;
    EXEC('CREATE VIEW dbo.vw_PBI_FactSalary_1404_2 AS SELECT * FROM dbo.FactSalary2 WHERE [year] = ''04'';');

    -- Period View
    IF OBJECT_ID('dbo.vw_PBI_DimPeriod_1404_2', 'V') IS NOT NULL DROP VIEW dbo.vw_PBI_DimPeriod_1404_2;
    EXEC('CREATE VIEW dbo.vw_PBI_DimPeriod_1404_2 AS SELECT * FROM dbo.DimPeriod2 WHERE PersianYear = ''04'';');

    -- Employee View
    IF OBJECT_ID('dbo.vw_PBI_DimEmployee_1404_2', 'V') IS NOT NULL DROP VIEW dbo.vw_PBI_DimEmployee_1404_2;
    EXEC('CREATE VIEW dbo.vw_PBI_DimEmployee_1404_2 AS SELECT DISTINCT e.* FROM dbo.DimEmployee2 e JOIN dbo.FactSalary2 f ON e.PersonNo = f.PersonNo WHERE f.[year] = ''04'';');

    PRINT '>>> Views Refreshed.';
END
GO

-- 5. MASTER
CREATE OR ALTER PROCEDURE dbo.sp_RunWeeklyETL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT '=== STARTING WEEKLY ETL (Tables with suffix 2) ===';
        
        EXEC dbo.sp_ETL_Extract;
        EXEC dbo.sp_ETL_Transform;
        EXEC dbo.sp_ETL_Load;
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
