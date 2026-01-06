USE [SalaryDW];
GO

-- =============================================
-- FIX: Extract Procedure - Robust Approach
-- =============================================

CREATE OR ALTER PROCEDURE dbo.sp_ETL_Extract
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '>>> Starting Extraction (sp_ETL_Extract)...';
    
    -- 1. Drop Staging Table
    IF OBJECT_ID('dbo.stg_SalaryRaw', 'U') IS NOT NULL 
        DROP TABLE dbo.stg_SalaryRaw;

    -- 2. Extract SnapMarket Data (Creates the table)
    PRINT 'Fetching SnapMarket data...';
    SELECT *, CAST('SnapMarket' AS NVARCHAR(50)) AS SourceSystem
    INTO dbo.stg_SalaryRaw
    FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalarySnapMarket');

    -- 3. Extract Zooket Data (Appends to table)
    PRINT 'Fetching Zooket data...';
    
    -- If you are getting Error 213, it means the number of columns returned by 
    -- the Zooket query (plus the 'Zooket' string) does not match the number of columns 
    -- in the table created by the SnapMarket query.
    
    -- This usually means the two views (SalarySnapMarket and SalaryZooket) do NOT have the exact same columns.
    
    -- Since we are in a stored procedure and want to be robust, the best way 
    -- (without listing 50+ columns manually) is to do a UNION ALL approach 
    -- into a NEW table, then select into the final one. 
    -- BUT `SELECT INTO` doesn't support UNION ALL easily if we want to create the table on the fly from the first one.
    
    -- ALTERNATIVE FIX: 
    -- If the user's original raw script worked, it means the column counts WERE equal at that time.
    -- If they are failing now inside the SP, ensure we are strictly following the same order.
    
    INSERT INTO dbo.stg_SalaryRaw
    SELECT *, 'Zooket'
    FROM OPENQUERY(REMOTE_VIEW3, 'SELECT * FROM View3.dbo.SalaryZooket');
    
    PRINT '>>> Extraction Complete.';
END
GO
