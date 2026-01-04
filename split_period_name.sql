-- Add new columns for year and month (swapped definition order)
ALTER TABLE dbo.stg_SalaryRaw 
ADD [month] NVARCHAR(50), 
    [year] NVARCHAR(10);
GO

-- Update the new columns by splitting the PeriodName column
-- Logic: The number part (e.g. "02") is the Year, the text part (e.g. "Shahrivar") is the Month.
UPDATE dbo.stg_SalaryRaw
SET 
    -- Take the right part after the first space as the month (Text)
    [month] = CASE 
                WHEN CHARINDEX(' ', PeriodName) > 0 
                THEN LTRIM(SUBSTRING(PeriodName, CHARINDEX(' ', PeriodName) + 1, LEN(PeriodName)))
                ELSE NULL 
              END,
    -- Take the left part before the first space as the year (Number)
    [year] = CASE 
                WHEN CHARINDEX(' ', PeriodName) > 0 
                THEN LEFT(PeriodName, CHARINDEX(' ', PeriodName) - 1)
                ELSE PeriodName -- Fallback
             END
WHERE PeriodName IS NOT NULL;
