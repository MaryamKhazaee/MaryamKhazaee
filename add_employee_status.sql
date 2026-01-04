-- Drop EmployeeStatus column if it already exists to avoid errors
IF EXISTS(SELECT * FROM sys.columns WHERE Name = N'EmployeeStatus' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
BEGIN
    ALTER TABLE dbo.stg_SalaryRaw DROP COLUMN [EmployeeStatus];
END
GO

-- Add the new column EmployeeStatus
ALTER TABLE dbo.stg_SalaryRaw 
ADD [EmployeeStatus] NVARCHAR(20);
GO

-- Update the column based on ExitDate
-- Logic: If ExitDate is NOT NULL -> 'Active', otherwise 'Inactive'
UPDATE dbo.stg_SalaryRaw
SET [EmployeeStatus] = CASE 
                        WHEN [ExitDate] IS NOT NULL THEN 'Active'
                        ELSE 'Inactive'
                       END;
