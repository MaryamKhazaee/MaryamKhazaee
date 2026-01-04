CREATE PROCEDURE [dbo].[sp_RefreshSalaryDashboard]
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Empty the Staging Table
    TRUNCATE TABLE dbo.stg_SalaryRaw;

    -- 2. Load Data from Remote Server
    -- IMPORTANT: Replace [REMOTE_SERVER] and [RemoteDB] with your actual names
    -- We map the REMOTE names (e.g. ContractOrgUnitName) to LOCAL names (e.g. Department) here
    -- Note: I've commented this out because I don't have the remote server name. 
    -- UNCOMMENT and UPDATE the section below:
    
    /*
    INSERT INTO dbo.stg_SalaryRaw (
        PersonNo,
        PeriodName,
        ExitDate,
        Department,       -- Maps from ContractOrgUnitName
        Businessline,     -- Maps from ContractEmployeeType
        HRBP,             -- Maps from ContractEmployeeStatus
        JobTitle          -- Maps from ContractJobTitle
        -- Add other columns (BasicSalary, Overtime, etc.) here
    )
    SELECT 
        PersonNo,
        PeriodName,
        ExitDate,
        ContractOrgUnitName,
        ContractEmployeeType,
        ContractEmployeeStatus,
        ContractJobTitle
        -- Add other columns here
    FROM [LINKED_SERVER_NAME].[DATABASE_NAME].[SCHEMA].[VIEW_NAME]; 
    */

    -- 3. Calculate Year, Month, and MonthNumber
    UPDATE dbo.stg_SalaryRaw
    SET 
        [month] = CASE 
                    WHEN CHARINDEX(' ', PeriodName) > 0 
                    THEN LTRIM(SUBSTRING(PeriodName, CHARINDEX(' ', PeriodName) + 1, LEN(PeriodName)))
                    ELSE NULL 
                  END,
        [year] = CASE 
                    WHEN CHARINDEX(' ', PeriodName) > 0 
                    THEN LEFT(PeriodName, CHARINDEX(' ', PeriodName) - 1)
                    ELSE PeriodName 
                 END;

    UPDATE dbo.stg_SalaryRaw
    SET [MonthNumber] = CASE [month]
                            WHEN N'فروردين' THEN 1
                            WHEN N'ارديبهشت' THEN 2
                            WHEN N'خرداد' THEN 3
                            WHEN N'تير' THEN 4
                            WHEN N'مرداد' THEN 5
                            WHEN N'شهريور' THEN 6
                            WHEN N'مهر' THEN 7
                            WHEN N'آبان' THEN 8
                            WHEN N'آذر' THEN 9
                            WHEN N'دي' THEN 10
                            WHEN N'بهمن' THEN 11
                            WHEN N'اسفند' THEN 12
                            ELSE NULL
                        END;

    -- 4. Calculate Employee Status
    UPDATE dbo.stg_SalaryRaw
    SET [EmployeeStatus] = CASE 
                            WHEN [ExitDate] IS NOT NULL THEN 'Active'
                            ELSE 'Inactive'
                           END;

    -- 5. Refresh Dimensions and Facts
    -- Clear existing data
    TRUNCATE TABLE dbo.DimPeriod;
    TRUNCATE TABLE dbo.DimEmployee;
    TRUNCATE TABLE dbo.FactSalary;

    -- Reload DimPeriod
    INSERT INTO dbo.DimPeriod (PeriodKey, PersianYear, PersianMonthName, PersianMonthNo, OriginalPeriodName)
    SELECT DISTINCT
        CAST((CASE WHEN LEN([year]) = 2 THEN '14' + [year] ELSE [year] END) AS INT) * 100 + [MonthNumber],
        [year],
        [month],
        [MonthNumber],
        PeriodName
    FROM dbo.stg_SalaryRaw
    WHERE [year] >= '04' AND [MonthNumber] IS NOT NULL;

    -- Reload DimEmployee
    INSERT INTO dbo.DimEmployee (PersonNo)
    SELECT DISTINCT PersonNo
    FROM dbo.stg_SalaryRaw
    WHERE [year] >= '04';

    -- Reload FactSalary
    INSERT INTO dbo.FactSalary (PeriodKey, PersonNo, EmployeeStatus, ExitDate, Department, Businessline, HRBP, JobTitle, year, month, MonthNumber) -- Add other metric columns here
    SELECT 
        CAST((CASE WHEN LEN([year]) = 2 THEN '14' + [year] ELSE [year] END) AS INT) * 100 + [MonthNumber],
        PersonNo,
        EmployeeStatus,
        ExitDate,
        Department,
        Businessline,
        HRBP,
        JobTitle,
        [year],
        [month],
        [MonthNumber]
        -- Add other metric columns here
    FROM dbo.stg_SalaryRaw
    WHERE [year] >= '04' AND [MonthNumber] IS NOT NULL;
END
GO
