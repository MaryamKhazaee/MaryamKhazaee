USE [master];
GO

-- =============================================
-- PART 1: INFRASTRUCTURE SETUP
-- Run this ONCE to set up the Linked Server and Database.
-- =============================================

-- 1. Setup Linked Server
IF EXISTS (SELECT * FROM sys.servers WHERE name = N'REMOTE_VIEW3')
BEGIN
    EXEC master.dbo.sp_dropserver @server=N'REMOTE_VIEW3', @droplogins='droplogins'
END
GO

EXEC master.dbo.sp_addlinkedserver 
    @server = N'REMOTE_VIEW3', 
    @srvproduct=N'', 
    @provider=N'MSOLEDBSQL', 
    @datasrc=N'185.105.239.103,2433', 
    @provstr=N'TrustServerCertificate=Yes;'
GO

EXEC master.dbo.sp_addlinkedsrvlogin 
    @rmtsrvname=N'REMOTE_VIEW3', 
    @useself=N'False', 
    @locallogin=NULL, 
    @rmtuser=N'UserView3', 
    @rmtpassword=N'Mkh01234567'
GO

-- 2. Create Database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'SalaryDW')
BEGIN
    CREATE DATABASE [SalaryDW];
END
GO
