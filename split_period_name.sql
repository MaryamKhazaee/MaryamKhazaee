-- Add new columns for year and month
ALTER TABLE dbo.stg_SalaryRaw 
ADD [year] NVARCHAR(10), 
    [month] NVARCHAR(50);
GO

-- Update the new columns by splitting the PeriodName column
-- Assuming the format is always "Number String" (e.g., "02 Shahrivar")
UPDATE dbo.stg_SalaryRaw
SET 
    -- Take the left part before the first space as the year
    [year] = CASE 
                WHEN CHARINDEX(' ', PeriodName) > 0 
                THEN LEFT(PeriodName, CHARINDEX(' ', PeriodName) - 1)
                ELSE PeriodName -- Fallback if no space
             END,
    -- Take the right part after the first space as the month
    [month] = CASE 
                WHEN CHARINDEX(' ', PeriodName) > 0 
                THEN LTRIM(SUBSTRING(PeriodName, CHARINDEX(' ', PeriodName) + 1, LEN(PeriodName)))
                ELSE NULL 
              END
WHERE PeriodName IS NOT NULL;
