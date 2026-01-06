USE [master]
GO

-- 1. CLEANUP: Drop the linked server if it already exists (to start fresh)
IF EXISTS (SELECT * FROM sys.servers WHERE name = N'REMOTE_VIEW3')
BEGIN
    EXEC master.dbo.sp_dropserver @server=N'REMOTE_VIEW3', @droplogins='droplogins'
END
GO

-- 2. CREATE LINKED SERVER: With the SSL Fix (TrustServerCertificate=Yes)
EXEC master.dbo.sp_addlinkedserver 
    @server = N'REMOTE_VIEW3', 
    @srvproduct=N'',             -- MUST BE BLANK to allow custom provider string
    @provider=N'MSOLEDBSQL',     -- Using modern SQL Driver
    @datasrc=N'185.105.239.103,2433', 
    @provstr=N'TrustServerCertificate=Yes;' -- Bypasses the "Authority not trusted" error
GO

-- 3. SETUP SECURITY: Map the user credentials
EXEC master.dbo.sp_addlinkedsrvlogin 
    @rmtsrvname=N'REMOTE_VIEW3', 
    @useself=N'False', 
    @locallogin=NULL, 
    @rmtuser=N'UserView3', 
    @rmtpassword=N'Mkh01234567'
GO

-- 4. TEST CONNECTION: Using the EXACT names from your screenshot
PRINT '--- Testing connection to SalarySnapMarket ---'
SELECT TOP 5 * FROM [REMOTE_VIEW3].[View3].[dbo].[SalarySnapMarket];

PRINT '--- Testing connection to SalaryZooket ---'
SELECT TOP 5 * FROM [REMOTE_VIEW3].[View3].[dbo].[SalaryZooket];
