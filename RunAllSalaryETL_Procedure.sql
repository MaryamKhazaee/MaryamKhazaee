USE [SalaryDW];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Description: Master ETL Procedure to orchestrate the entire Salary Data Warehouse refresh
-- Executing this single procedure runs all 5 steps in order.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_RunAllSalaryETL]
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartTime DATETIME = GETDATE();

    BEGIN TRY
        PRINT '==================================================';
        PRINT 'STARTING FULL SALARY ETL PROCESS';
        PRINT '==================================================';

        -- Step 1: Setup Linked Server (Runs from master context)
        -- Note: Ensure the user running this has permissions to execute procedures in master
        PRINT '>> STEP 1/5: Setting up Linked Server...';
        EXEC [master].[dbo].[sp_SetupRemoteView3];
        PRINT '>> Step 1 Completed.';
        PRINT '--------------------------------------------------';

        -- Step 2: Load Raw Data
        PRINT '>> STEP 2/5: Loading Raw Data...';
        EXEC [dbo].[sp_LoadSalaryData];
        PRINT '>> Step 2 Completed.';
        PRINT '--------------------------------------------------';

        -- Step 3: Transform Data
        PRINT '>> STEP 3/5: Transforming Data...';
        EXEC [dbo].[sp_TransformSalaryData];
        PRINT '>> Step 3 Completed.';
        PRINT '--------------------------------------------------';

        -- Step 4: Generate DW Tables
        PRINT '>> STEP 4/5: Generating Data Warehouse Tables...';
        EXEC [dbo].[sp_GenerateDW];
        PRINT '>> Step 4 Completed.';
        PRINT '--------------------------------------------------';

        -- Step 5: Create Power BI Views
        PRINT '>> STEP 5/5: Creating Power BI Views...';
        EXEC [dbo].[sp_CreatePowerBIViews];
        PRINT '>> Step 5 Completed.';
        PRINT '--------------------------------------------------';

        DECLARE @Duration INT = DATEDIFF(SECOND, @StartTime, GETDATE());
        PRINT '==================================================';
        PRINT 'ETL PROCESS COMPLETED SUCCESSFULLY';
        PRINT 'Total Duration: ' + CAST(@Duration AS NVARCHAR(20)) + ' seconds.';
        PRINT '==================================================';

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
        PRINT 'ETL FAILED AT STEP: ' + ISNULL(ERROR_PROCEDURE(), 'Unknown');
        PRINT 'Error: ' + @ErrorMessage;
        PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
        
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO
