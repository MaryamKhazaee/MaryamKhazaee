USE [master]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Description: Sets up the REMOTE_VIEW3 linked server and tests connection
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_SetupRemoteView3]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- 1. CLEANUP: Drop the linked server if it already exists
        IF EXISTS (SELECT * FROM sys.servers WHERE name = N'REMOTE_VIEW3')
        BEGIN
            PRINT 'Dropping existing linked server REMOTE_VIEW3...'
            EXEC master.dbo.sp_dropserver @server=N'REMOTE_VIEW3', @droplogins='droplogins'
        END

        -- 2. CREATE LINKED SERVER
        PRINT 'Creating linked server REMOTE_VIEW3...'
        EXEC master.dbo.sp_addlinkedserver 
            @server = N'REMOTE_VIEW3', 
            @srvproduct=N'',             
            @provider=N'MSOLEDBSQL',     
            @datasrc=N'185.105.239.103,2433', 
            @provstr=N'TrustServerCertificate=Yes;'

        -- 3. SETUP SECURITY
        PRINT 'Setting up security...'
        EXEC master.dbo.sp_addlinkedsrvlogin 
            @rmtsrvname=N'REMOTE_VIEW3', 
            @useself=N'False', 
            @locallogin=NULL, 
            @rmtuser=N'UserView3', 
            @rmtpassword=N'Mkh01234567'

        -- 4. TEST CONNECTION
        -- Using dynamic SQL to avoid compile-time errors if the server doesn't exist yet
        PRINT '--- Testing connection to SalarySnapMarket ---'
        EXEC sp_executesql N'SELECT TOP 5 * FROM [REMOTE_VIEW3].[View3].[dbo].[SalarySnapMarket]'

        PRINT '--- Testing connection to SalaryZooket ---'
        EXEC sp_executesql N'SELECT TOP 5 * FROM [REMOTE_VIEW3].[View3].[dbo].[SalaryZooket]'
        
        PRINT 'Success: Linked server setup and tests completed.'
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO
