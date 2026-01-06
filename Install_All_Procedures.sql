/*
===========================================================================
   MASTER INSTALLATION SCRIPT
   
   This script installs ALL necessary Stored Procedures for the SalaryDW project.
   Run this script ONCE to set everything up.
===========================================================================
*/

USE [master];
GO

-- 0. SETUP DATABASE
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'SalaryDW')
BEGIN
    PRINT 'Creating database SalaryDW...'
    CREATE DATABASE [SalaryDW];
END
GO

-- 1. SETUP REMOTE SERVER PROCEDURE (in master)
USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_SetupRemoteView3]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Cleanup
        IF EXISTS (SELECT * FROM sys.servers WHERE name = N'REMOTE_VIEW3')
        BEGIN
            EXEC master.dbo.sp_dropserver @server=N'REMOTE_VIEW3', @droplogins='droplogins'
        END
        -- Create
        EXEC master.dbo.sp_addlinkedserver 
            @server = N'REMOTE_VIEW3', 
            @srvproduct=N'',             
            @provider=N'MSOLEDBSQL',     
            @datasrc=N'185.105.239.103,2433', 
            @provstr=N'TrustServerCertificate=Yes;'
        -- Security
        EXEC master.dbo.sp_addlinkedsrvlogin 
            @rmtsrvname=N'REMOTE_VIEW3', 
            @useself=N'False', 
            @locallogin=NULL, 
            @rmtuser=N'UserView3', 
            @rmtpassword=N'Mkh01234567'
        
        PRINT 'Linked Server Setup Completed.';
    END TRY
    BEGIN CATCH
        PRINT 'Error in Linked Server Setup: ' + ERROR_MESSAGE();
        RAISERROR (50000, -1, -1, 'Setup Failed');
    END CATCH
END
GO

-- 2. SETUP LOAD PROCEDURE (in SalaryDW)
USE [SalaryDW];
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_LoadSalaryData]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF OBJECT_ID('dbo.stg_SalaryRaw', 'U') IS NOT NULL DROP TABLE dbo.stg_SalaryRaw;

        SELECT *, CAST('SnapMarket' AS NVARCHAR(50)) AS SourceSystem
        INTO dbo.stg_SalaryRaw
        FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalarySnapMarket');

        INSERT INTO dbo.stg_SalaryRaw
        SELECT *, 'Zooket'
        FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalaryZooket');
        
        PRINT 'Data Load Completed.';
    END TRY
    BEGIN CATCH
        PRINT 'Error in Data Load: ' + ERROR_MESSAGE();
        RAISERROR (50000, -1, -1, 'Load Failed');
    END CATCH
END
GO

-- 3. SETUP TRANSFORM PROCEDURE
USE [SalaryDW];
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_TransformSalaryData]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Month/Year
        IF EXISTS(SELECT * FROM sys.columns WHERE Name = N'year' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
            ALTER TABLE dbo.stg_SalaryRaw DROP COLUMN [year];
        IF EXISTS(SELECT * FROM sys.columns WHERE Name = N'month' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
            ALTER TABLE dbo.stg_SalaryRaw DROP COLUMN [month];
        ALTER TABLE dbo.stg_SalaryRaw ADD [month] NVARCHAR(50), [year] NVARCHAR(50);
        
        DECLARE @Sql1 NVARCHAR(MAX) = N'UPDATE dbo.stg_SalaryRaw SET [year] = CASE WHEN CHARINDEX('' '', PeriodName) > 0 THEN LTRIM(SUBSTRING(PeriodName, CHARINDEX('' '', PeriodName) + 1, LEN(PeriodName))) ELSE NULL END, [month] = CASE WHEN CHARINDEX('' '', PeriodName) > 0 THEN LEFT(PeriodName, CHARINDEX('' '', PeriodName) - 1) ELSE PeriodName END WHERE PeriodName IS NOT NULL;';
        EXEC sp_executesql @Sql1;

        -- Status
        IF EXISTS(SELECT * FROM sys.columns WHERE Name = N'EmployeeStatus' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
            ALTER TABLE dbo.stg_SalaryRaw DROP COLUMN [EmployeeStatus];
        ALTER TABLE dbo.stg_SalaryRaw ADD [EmployeeStatus] NVARCHAR(20);
        DECLARE @Sql2 NVARCHAR(MAX) = N'UPDATE dbo.stg_SalaryRaw SET [EmployeeStatus] = CASE WHEN [ExitDate] IS NOT NULL THEN ''Active'' ELSE ''Inactive'' END;';
        EXEC sp_executesql @Sql2;

        -- MonthNum
        IF EXISTS(SELECT * FROM sys.columns WHERE Name = N'MonthNumber' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
            ALTER TABLE dbo.stg_SalaryRaw DROP COLUMN [MonthNumber];
        ALTER TABLE dbo.stg_SalaryRaw ADD [MonthNumber] INT;
        DECLARE @Sql3 NVARCHAR(MAX) = N'UPDATE dbo.stg_SalaryRaw SET [MonthNumber] = CASE [month] WHEN N''فروردين'' THEN 1 WHEN N''ارديبهشت'' THEN 2 WHEN N''خرداد'' THEN 3 WHEN N''تير'' THEN 4 WHEN N''مرداد'' THEN 5 WHEN N''شهريور'' THEN 6 WHEN N''مهر'' THEN 7 WHEN N''آبان'' THEN 8 WHEN N''آذر'' THEN 9 WHEN N''دي'' THEN 10 WHEN N''بهمن'' THEN 11 WHEN N''اسفند'' THEN 12 ELSE NULL END;';
        EXEC sp_executesql @Sql3;

        -- Rename
        IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractOrgUnitName' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw')) EXEC sp_rename 'dbo.stg_SalaryRaw.ContractOrgUnitName', 'Department', 'COLUMN';
        IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractEmployeeType' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw')) EXEC sp_rename 'dbo.stg_SalaryRaw.ContractEmployeeType', 'Businessline', 'COLUMN';
        IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractEmployeeStatus' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw')) EXEC sp_rename 'dbo.stg_SalaryRaw.ContractEmployeeStatus', 'HRBP', 'COLUMN';
        IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractJobTotle' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw')) EXEC sp_rename 'dbo.stg_SalaryRaw.ContractJobTotle', 'JobTitle', 'COLUMN';
        ELSE IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractJobTitle' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw')) EXEC sp_rename 'dbo.stg_SalaryRaw.ContractJobTitle', 'JobTitle', 'COLUMN';

        PRINT 'Transformation Completed.';
    END TRY
    BEGIN CATCH
        PRINT 'Error in Transformation: ' + ERROR_MESSAGE();
        RAISERROR (50000, -1, -1, 'Transform Failed');
    END CATCH
END
GO

-- 4. SETUP GENERATE DW PROCEDURE
USE [SalaryDW];
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_GenerateDW]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF OBJECT_ID('dbo.DimPeriod', 'U') IS NOT NULL DROP TABLE dbo.DimPeriod;
        SELECT DISTINCT CAST((CASE WHEN LEN([year]) = 2 THEN '14' + [year] ELSE [year] END) AS INT) * 100 + [MonthNumber] AS PeriodKey, [year] AS PersianYear, [month] AS PersianMonthName, [MonthNumber] AS PersianMonthNo, PeriodName AS OriginalPeriodName INTO dbo.DimPeriod FROM dbo.stg_SalaryRaw WHERE [year] >= '04' AND [MonthNumber] IS NOT NULL;

        IF OBJECT_ID('dbo.DimEmployee', 'U') IS NOT NULL DROP TABLE dbo.DimEmployee;
        SELECT DISTINCT PersonNo INTO dbo.DimEmployee FROM dbo.stg_SalaryRaw WHERE [year] >= '04';

        IF OBJECT_ID('dbo.FactSalary', 'U') IS NOT NULL DROP TABLE dbo.FactSalary;
        SELECT CAST((CASE WHEN LEN([year]) = 2 THEN '14' + [year] ELSE [year] END) AS INT) * 100 + [MonthNumber] AS PeriodKey, * INTO dbo.FactSalary FROM dbo.stg_SalaryRaw WHERE [year] >= '04' AND [MonthNumber] IS NOT NULL;

        IF EXISTS(SELECT * FROM sys.columns WHERE Name = N'PeriodName' AND Object_ID = Object_ID(N'dbo.FactSalary')) ALTER TABLE dbo.FactSalary DROP COLUMN [PeriodName];
        
        PRINT 'DW Generation Completed.';
    END TRY
    BEGIN CATCH
        PRINT 'Error in DW Generation: ' + ERROR_MESSAGE();
        RAISERROR (50000, -1, -1, 'DW Gen Failed');
    END CATCH
END
GO

-- 5. SETUP VIEWS PROCEDURE
USE [SalaryDW];
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_CreatePowerBIViews]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF OBJECT_ID('dbo.vw_PBI_FactSalary_1404', 'V') IS NOT NULL DROP VIEW dbo.vw_PBI_FactSalary_1404;
        EXEC sp_executesql N'CREATE VIEW dbo.vw_PBI_FactSalary_1404 AS SELECT * FROM dbo.FactSalary WHERE [year] = ''04'';';

        IF OBJECT_ID('dbo.vw_PBI_DimPeriod_1404', 'V') IS NOT NULL DROP VIEW dbo.vw_PBI_DimPeriod_1404;
        EXEC sp_executesql N'CREATE VIEW dbo.vw_PBI_DimPeriod_1404 AS SELECT * FROM dbo.DimPeriod WHERE PersianYear = ''04'';';

        IF OBJECT_ID('dbo.vw_PBI_DimEmployee_1404', 'V') IS NOT NULL DROP VIEW dbo.vw_PBI_DimEmployee_1404;
        EXEC sp_executesql N'CREATE VIEW dbo.vw_PBI_DimEmployee_1404 AS SELECT DISTINCT e.* FROM dbo.DimEmployee e JOIN dbo.FactSalary f ON e.PersonNo = f.PersonNo WHERE f.[year] = ''04'';';

        PRINT 'Views Created.';
    END TRY
    BEGIN CATCH
        PRINT 'Error in View Creation: ' + ERROR_MESSAGE();
        RAISERROR (50000, -1, -1, 'View Create Failed');
    END CATCH
END
GO

-- 6. SETUP MASTER ETL PROCEDURE
USE [SalaryDW];
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_RunAllSalaryETL]
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartTime DATETIME = GETDATE();
    BEGIN TRY
        PRINT '>> STEP 1/5: Setup Linked Server';
        EXEC [master].[dbo].[sp_SetupRemoteView3];
        PRINT '>> STEP 2/5: Load Raw Data';
        EXEC [dbo].[sp_LoadSalaryData];
        PRINT '>> STEP 3/5: Transform Data';
        EXEC [dbo].[sp_TransformSalaryData];
        PRINT '>> STEP 4/5: Generate DW Tables';
        EXEC [dbo].[sp_GenerateDW];
        PRINT '>> STEP 5/5: Create Power BI Views';
        EXEC [dbo].[sp_CreatePowerBIViews];
        
        PRINT 'SUCCESS: ETL Process Completed in ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS NVARCHAR(20)) + ' seconds.';
    END TRY
    BEGIN CATCH
        PRINT 'FAILED: ' + ERROR_MESSAGE();
        RAISERROR (50000, -1, -1, 'ETL Process Failed');
    END CATCH
END
GO
