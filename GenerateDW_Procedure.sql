USE [SalaryDW];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Description: Generates Data Warehouse tables (DimPeriod, DimEmployee, FactSalary) for Power BI
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_GenerateDW]
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        PRINT 'Starting Data Warehouse Generation...';

        -- 1. Create Dimension: Period (DimPeriod)
        PRINT 'Generating DimPeriod...';
        IF OBJECT_ID('dbo.DimPeriod', 'U') IS NOT NULL 
            DROP TABLE dbo.DimPeriod;

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


        -- 2. Create Dimension: Employee (DimEmployee)
        PRINT 'Generating DimEmployee...';
        IF OBJECT_ID('dbo.DimEmployee', 'U') IS NOT NULL 
            DROP TABLE dbo.DimEmployee;

        SELECT DISTINCT 
            PersonNo
        INTO dbo.DimEmployee
        FROM dbo.stg_SalaryRaw
        WHERE [year] >= '04';


        -- 3. Create Fact Table: Salary (FactSalary)
        PRINT 'Generating FactSalary...';
        IF OBJECT_ID('dbo.FactSalary', 'U') IS NOT NULL 
            DROP TABLE dbo.FactSalary;

        SELECT 
            -- Generate PeriodKey
            CAST((CASE WHEN LEN([year]) = 2 THEN '14' + [year] ELSE [year] END) AS INT) * 100 + [MonthNumber] AS PeriodKey,
            -- Select all columns
            *
        INTO dbo.FactSalary
        FROM dbo.stg_SalaryRaw
        WHERE [year] >= '04'
          AND [MonthNumber] IS NOT NULL;


        -- 4. Cleanup
        PRINT 'Cleaning up FactSalary...';
        -- Remove redundant columns from FactTable
        IF EXISTS(SELECT * FROM sys.columns WHERE Name = N'PeriodName' AND Object_ID = Object_ID(N'dbo.FactSalary'))
        BEGIN
            ALTER TABLE dbo.FactSalary DROP COLUMN [PeriodName];
        END

        PRINT 'DW Generation completed successfully.';
        
        -- Validation output
        SELECT 'FactSalary Count' AS TableName, COUNT(*) AS RowCountVal FROM dbo.FactSalary
        UNION ALL
        SELECT 'DimPeriod Count', COUNT(*) FROM dbo.DimPeriod
        UNION ALL
        SELECT 'DimEmployee Count', COUNT(*) FROM dbo.DimEmployee;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO
