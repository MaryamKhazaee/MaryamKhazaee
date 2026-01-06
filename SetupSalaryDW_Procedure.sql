USE [master];
GO

-- 1. Create the local database if it doesn't exist
-- Note: Database creation cannot be inside a stored procedure.
-- We run this as a setup step before creating the procedure.
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'SalaryDW')
BEGIN
    PRINT 'Creating database SalaryDW...'
    CREATE DATABASE [SalaryDW];
END
GO

USE [SalaryDW];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Description: Loads Salary data from SnapMarket and Zooket (via REMOTE_VIEW3) into stg_SalaryRaw
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_LoadSalaryData]
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        PRINT 'Starting Salary Data Load...';

        -- 2. Drop the table if it exists to start fresh
        IF OBJECT_ID('dbo.stg_SalaryRaw', 'U') IS NOT NULL 
        BEGIN
            PRINT 'Dropping existing table stg_SalaryRaw...';
            DROP TABLE dbo.stg_SalaryRaw;
        END

        -- 3. Extract SnapMarket data (This creates the table)
        PRINT 'Extracting SnapMarket data...';
        -- We use OPENQUERY for better network stability
        -- Note: SELECT INTO creates the table
        SELECT *, CAST('SnapMarket' AS NVARCHAR(50)) AS SourceSystem
        INTO dbo.stg_SalaryRaw
        FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalarySnapMarket');

        -- 4. Extract Zooket data (This adds to the table)
        PRINT 'Extracting Zooket data...';
        INSERT INTO dbo.stg_SalaryRaw
        SELECT *, 'Zooket'
        FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalaryZooket');

        -- 5. Final Check: Show the data and the column names
        PRINT 'Data load completed successfully.';
        SELECT TOP 10 * FROM dbo.stg_SalaryRaw;

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
