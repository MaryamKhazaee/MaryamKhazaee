-- Rename ContractOrgUnitName to Department
IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractOrgUnitName' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
BEGIN
    EXEC sp_rename 'dbo.stg_SalaryRaw.ContractOrgUnitName', 'Department', 'COLUMN';
END
GO

-- Rename ContractEmployeeType to Businessline
IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractEmployeeType' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
BEGIN
    EXEC sp_rename 'dbo.stg_SalaryRaw.ContractEmployeeType', 'Businessline', 'COLUMN';
END
GO

-- Rename ContractEmployeeStatus to HRBP
IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractEmployeeStatus' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
BEGIN
    EXEC sp_rename 'dbo.stg_SalaryRaw.ContractEmployeeStatus', 'HRBP', 'COLUMN';
END
GO

-- Rename ContractJobTotle to JobTitle
-- Note: Checking for both 'ContractJobTotle' (as requested) and 'ContractJobTitle' (potential typo fix)
IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractJobTotle' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
BEGIN
    EXEC sp_rename 'dbo.stg_SalaryRaw.ContractJobTotle', 'JobTitle', 'COLUMN';
END
ELSE IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractJobTitle' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
BEGIN
    -- Fallback in case the column name in DB is actually spelled correctly
    EXEC sp_rename 'dbo.stg_SalaryRaw.ContractJobTitle', 'JobTitle', 'COLUMN';
END
GO
