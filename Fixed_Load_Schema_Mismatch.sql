USE [SalaryDW];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- FIXED sp_LoadSalaryData (Handles Schema Mismatch)
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_LoadSalaryData]
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        PRINT 'Starting Salary Data Load (Auto-Schema-Match Mode)...';

        -- 1. Clean up
        IF OBJECT_ID('dbo.stg_SalaryRaw', 'U') IS NOT NULL DROP TABLE dbo.stg_SalaryRaw;
        IF OBJECT_ID('dbo.stg_SalaryZooket_Temp', 'U') IS NOT NULL DROP TABLE dbo.stg_SalaryZooket_Temp;

        -- 2. Load SnapMarket (Defines the Target Structure)
        PRINT 'Extracting SnapMarket data (Primary Schema)...';
        SELECT *, CAST('SnapMarket' AS NVARCHAR(50)) AS SourceSystem
        INTO dbo.stg_SalaryRaw
        FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalarySnapMarket');

        -- 3. Load Zooket (Temporary Table)
        PRINT 'Extracting Zooket data (Temp)...';
        SELECT *, CAST('Zooket' AS NVARCHAR(50)) AS SourceSystem
        INTO dbo.stg_SalaryZooket_Temp
        FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalaryZooket');

        -- 4. Dynamic Insert for Common Columns (Fixes Schema Mismatch)
        PRINT 'Merging datasets based on common columns...';
        
        DECLARE @CommonCols NVARCHAR(MAX);
        
        -- Get intersection of columns
        SELECT @CommonCols = STUFF((
            SELECT ',' + QUOTENAME(c1.name)
            FROM sys.columns c1
            JOIN sys.columns c2 
              ON c1.name = c2.name
            WHERE c1.object_id = OBJECT_ID('dbo.stg_SalaryRaw')
              AND c2.object_id = OBJECT_ID('dbo.stg_SalaryZooket_Temp')
            FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '');

        IF @CommonCols IS NULL
        BEGIN
            RAISERROR('No common columns found between SnapMarket and Zooket tables!', 16, 1);
        END

        PRINT 'Mapping: ' + LEFT(@CommonCols, 150) + '...';

        DECLARE @Sql NVARCHAR(MAX);
        SET @Sql = 'INSERT INTO dbo.stg_SalaryRaw (' + @CommonCols + ') SELECT ' + @CommonCols + ' FROM dbo.stg_SalaryZooket_Temp';
        
        EXEC sp_executesql @Sql;

        -- 5. Cleanup Temp
        DROP TABLE dbo.stg_SalaryZooket_Temp;

        -- 6. Final Check
        PRINT 'Data load completed successfully.';
        DECLARE @Cnt INT = (SELECT COUNT(*) FROM dbo.stg_SalaryRaw);
        PRINT 'Total Rows Loaded: ' + CAST(@Cnt AS NVARCHAR(20));
        
        SELECT TOP 5 * FROM dbo.stg_SalaryRaw;

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
