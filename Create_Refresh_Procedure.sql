USE [SalaryDW];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Description: Refreshes the Data Warehouse (Load -> Transform -> Generate -> View)
--              SKIPS the Linked Server setup (Step 1), as requested.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_RefreshSalaryData]
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartTime DATETIME = GETDATE();

    BEGIN TRY
        PRINT '==================================================';
        PRINT 'STARTING DATA REFRESH (Skipping Linked Server Setup)';
        PRINT '==================================================';

        -- Step 1: Load Raw Data
        -- (Ensures we fetch the latest data from Source)
        PRINT '>> STEP 1/4: Loading Raw Data...';
        EXEC [dbo].[sp_LoadSalaryData];
        PRINT '>> Step 1 Completed.';
        PRINT '--------------------------------------------------';

        -- Step 2: Transform Data
        PRINT '>> STEP 2/4: Transforming Data...';
        EXEC [dbo].[sp_TransformSalaryData];
        PRINT '>> Step 2 Completed.';
        PRINT '--------------------------------------------------';

        -- Step 3: Generate DW Tables
        PRINT '>> STEP 3/4: Generating Data Warehouse Tables...';
        EXEC [dbo].[sp_GenerateDW];
        PRINT '>> Step 3 Completed.';
        PRINT '--------------------------------------------------';

        -- Step 4: Create Power BI Views
        PRINT '>> STEP 4/4: Creating Power BI Views...';
        EXEC [dbo].[sp_CreatePowerBIViews];
        PRINT '>> Step 4 Completed.';
        PRINT '--------------------------------------------------';

        DECLARE @Duration INT = DATEDIFF(SECOND, @StartTime, GETDATE());
        PRINT '==================================================';
        PRINT 'DATA REFRESH COMPLETED SUCCESSFULLY';
        PRINT 'Total Duration: ' + CAST(@Duration AS NVARCHAR(20)) + ' seconds.';
        PRINT '==================================================';

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
        PRINT 'REFRESH FAILED AT STEP: ' + ISNULL(ERROR_PROCEDURE(), 'Unknown');
        PRINT 'Error: ' + @ErrorMessage;
        PRINT '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
        
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO
