USE [SalaryDW];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Description: Creates or updates Power BI Views filtered for Year 1404
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_CreatePowerBIViews]
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        PRINT 'Creating Power BI Views for Year 1404...';

        -- 1. Fact View: Only 1404 data
        PRINT 'Creating view vw_PBI_FactSalary_1404...';
        
        -- Check if view exists and drop it (using dynamic SQL for create view)
        IF OBJECT_ID('dbo.vw_PBI_FactSalary_1404', 'V') IS NOT NULL 
            DROP VIEW dbo.vw_PBI_FactSalary_1404;

        EXEC sp_executesql N'
            CREATE VIEW dbo.vw_PBI_FactSalary_1404 AS
            SELECT * 
            FROM dbo.FactSalary
            WHERE [year] = ''04'';
        ';


        -- 2. Period Dimension View: Only 1404 months
        PRINT 'Creating view vw_PBI_DimPeriod_1404...';

        IF OBJECT_ID('dbo.vw_PBI_DimPeriod_1404', 'V') IS NOT NULL 
            DROP VIEW dbo.vw_PBI_DimPeriod_1404;

        EXEC sp_executesql N'
            CREATE VIEW dbo.vw_PBI_DimPeriod_1404 AS
            SELECT * 
            FROM dbo.DimPeriod
            WHERE PersianYear = ''04'';
        ';


        -- 3. Employee Dimension View: Only employees present in 1404
        PRINT 'Creating view vw_PBI_DimEmployee_1404...';

        IF OBJECT_ID('dbo.vw_PBI_DimEmployee_1404', 'V') IS NOT NULL 
            DROP VIEW dbo.vw_PBI_DimEmployee_1404;

        EXEC sp_executesql N'
            CREATE VIEW dbo.vw_PBI_DimEmployee_1404 AS
            SELECT DISTINCT e.*
            FROM dbo.DimEmployee e
            JOIN dbo.FactSalary f ON e.PersonNo = f.PersonNo
            WHERE f.[year] = ''04'';
        ';

        PRINT 'Views created successfully.';

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
