USE [SalaryDW];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Description: Transforms Salary data in stg_SalaryRaw (Split periods, add status, rename columns)
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_TransformSalaryData]
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        PRINT 'Starting Salary Data Transformation...';

        -- 1. MONTH AND YEAR
        PRINT 'Processing Month and Year columns...';
        
        -- Drop existing columns
        IF EXISTS(SELECT * FROM sys.columns WHERE Name = N'year' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
            ALTER TABLE dbo.stg_SalaryRaw DROP COLUMN [year];

        IF EXISTS(SELECT * FROM sys.columns WHERE Name = N'month' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
            ALTER TABLE dbo.stg_SalaryRaw DROP COLUMN [month];

        -- Add new columns
        ALTER TABLE dbo.stg_SalaryRaw ADD [month] NVARCHAR(50), [year] NVARCHAR(50);

        -- Update columns (Using dynamic SQL to avoid compile errors if columns don't exist yet)
        DECLARE @SqlUpdateMonthYear NVARCHAR(MAX);
        SET @SqlUpdateMonthYear = N'
            UPDATE dbo.stg_SalaryRaw
            SET 
                [year] = CASE 
                            WHEN CHARINDEX('' '', PeriodName) > 0 
                            THEN LTRIM(SUBSTRING(PeriodName, CHARINDEX('' '', PeriodName) + 1, LEN(PeriodName)))
                            ELSE NULL 
                          END,
                [month] = CASE 
                            WHEN CHARINDEX('' '', PeriodName) > 0 
                            THEN LEFT(PeriodName, CHARINDEX('' '', PeriodName) - 1)
                            ELSE PeriodName 
                         END
            WHERE PeriodName IS NOT NULL;
        ';
        EXEC sp_executesql @SqlUpdateMonthYear;


        -- 2. EMPLOYEE STATUS
        PRINT 'Processing Employee Status...';
        
        IF EXISTS(SELECT * FROM sys.columns WHERE Name = N'EmployeeStatus' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
            ALTER TABLE dbo.stg_SalaryRaw DROP COLUMN [EmployeeStatus];
            
        ALTER TABLE dbo.stg_SalaryRaw ADD [EmployeeStatus] NVARCHAR(20);

        -- Logic: If ExitDate is NOT NULL -> ''Active'', otherwise ''Inactive'' (As per original script)
        DECLARE @SqlUpdateStatus NVARCHAR(MAX);
        SET @SqlUpdateStatus = N'
            UPDATE dbo.stg_SalaryRaw
            SET [EmployeeStatus] = CASE 
                                    WHEN [ExitDate] IS NOT NULL THEN ''Active''
                                    ELSE ''Inactive''
                                   END;
        ';
        EXEC sp_executesql @SqlUpdateStatus;


        -- 3. MONTH NUMBER
        PRINT 'Processing Month Number...';
        
        IF EXISTS(SELECT * FROM sys.columns WHERE Name = N'MonthNumber' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
            ALTER TABLE dbo.stg_SalaryRaw DROP COLUMN [MonthNumber];

        ALTER TABLE dbo.stg_SalaryRaw ADD [MonthNumber] INT;

        DECLARE @SqlUpdateMonthNum NVARCHAR(MAX);
        SET @SqlUpdateMonthNum = N'
            UPDATE dbo.stg_SalaryRaw
            SET [MonthNumber] = CASE [month]
                                    WHEN N''فروردين'' THEN 1
                                    WHEN N''ارديبهشت'' THEN 2
                                    WHEN N''خرداد'' THEN 3
                                    WHEN N''تير'' THEN 4
                                    WHEN N''مرداد'' THEN 5
                                    WHEN N''شهريور'' THEN 6
                                    WHEN N''مهر'' THEN 7
                                    WHEN N''آبان'' THEN 8
                                    WHEN N''آذر'' THEN 9
                                    WHEN N''دي'' THEN 10
                                    WHEN N''بهمن'' THEN 11
                                    WHEN N''اسفند'' THEN 12
                                    ELSE NULL
                                END;
        ';
        EXEC sp_executesql @SqlUpdateMonthNum;


        -- 4. RENAME COLUMNS
        PRINT 'Renaming columns...';
        
        IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractOrgUnitName' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
            EXEC sp_rename 'dbo.stg_SalaryRaw.ContractOrgUnitName', 'Department', 'COLUMN';

        IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractEmployeeType' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
            EXEC sp_rename 'dbo.stg_SalaryRaw.ContractEmployeeType', 'Businessline', 'COLUMN';

        IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractEmployeeStatus' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
            EXEC sp_rename 'dbo.stg_SalaryRaw.ContractEmployeeStatus', 'HRBP', 'COLUMN';

        IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractJobTotle' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
            EXEC sp_rename 'dbo.stg_SalaryRaw.ContractJobTotle', 'JobTitle', 'COLUMN';
        ELSE IF EXISTS (SELECT 1 FROM sys.columns WHERE Name = N'ContractJobTitle' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
            EXEC sp_rename 'dbo.stg_SalaryRaw.ContractJobTitle', 'JobTitle', 'COLUMN';


        -- 5. FINAL CHECK
        PRINT 'Transformation completed.';
        SELECT TOP 100 * FROM dbo.stg_SalaryRaw;

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
