USE [SalaryDW];
GO

-- =============================================
-- 1. Stored Procedure: Refresh Staging Area
-- Description: Truncates staging table and re-fetches data from Remote Server
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_RefreshStaging
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '--- Starting Staging Refresh ---';

    -- Drop/Recreate or Truncate Staging Table
    IF OBJECT_ID('dbo.stg_SalaryRaw', 'U') IS NOT NULL 
        DROP TABLE dbo.stg_SalaryRaw;

    PRINT 'Extracting SnapMarket data...';
    -- Extract SnapMarket
    -- Note: Using Dynamic SQL or just standard SQL if Linked Server is static. 
    -- Since Linked Server name is constant, standard SQL is fine.
    SELECT *, CAST('SnapMarket' AS NVARCHAR(50)) AS SourceSystem
    INTO dbo.stg_SalaryRaw
    FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalarySnapMarket');

    PRINT 'Extracting Zooket data...';
    -- Extract Zooket
    INSERT INTO dbo.stg_SalaryRaw
    SELECT *, 'Zooket'
    FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalaryZooket');

    PRINT '--- Staging Refresh Completed ---';
END
GO

-- =============================================
-- 2. Stored Procedure: Update Data Warehouse (Dimensions & Facts)
-- Description: Transforms staging data and loads into Star Schema tables
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_UpdateDW
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '--- Starting DW Update ---';

    -- -------------------------
    -- Update DimPeriod
    -- -------------------------
    PRINT 'Updating DimPeriod...';
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

    -- -------------------------
    -- Update DimEmployee
    -- -------------------------
    PRINT 'Updating DimEmployee...';
    IF OBJECT_ID('dbo.DimEmployee', 'U') IS NOT NULL DROP TABLE dbo.DimEmployee;

    SELECT DISTINCT 
        PersonNo
    INTO dbo.DimEmployee
    FROM dbo.stg_SalaryRaw
    WHERE [year] >= '04';

    -- -------------------------
    -- Update FactSalary
    -- -------------------------
    PRINT 'Updating FactSalary...';
    IF OBJECT_ID('dbo.FactSalary', 'U') IS NOT NULL DROP TABLE dbo.FactSalary;

    SELECT 
        CAST((CASE WHEN LEN([year]) = 2 THEN '14' + [year] ELSE [year] END) AS INT) * 100 + [MonthNumber] AS PeriodKey,
        *
    INTO dbo.FactSalary
    FROM dbo.stg_SalaryRaw
    WHERE [year] >= '04'
      AND [MonthNumber] IS NOT NULL;

    -- Cleanup Fact Table
    ALTER TABLE dbo.FactSalary DROP COLUMN [PeriodName];

    PRINT '--- DW Update Completed ---';
END
GO

-- =============================================
-- 3. Master Stored Procedure: Run Full ETL
-- Description: Orchestrates the entire flow
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_RunFullETL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT '=== STARTING WEEKLY ETL PROCESS ===';
        
        -- Step 1: Refresh Staging
        EXEC dbo.sp_RefreshStaging;
        
        -- Step 2: Update DW
        EXEC dbo.sp_UpdateDW;
        
        PRINT '=== ETL PROCESS COMPLETED SUCCESSFULLY ===';
    END TRY
    BEGIN CATCH
        PRINT '!!! ERROR DURING ETL PROCESS !!!';
        PRINT ERROR_MESSAGE();
        -- You could add error logging to a table here
    END CATCH
END
GO
