-- Drop MonthNumber column if it already exists
IF EXISTS(SELECT * FROM sys.columns WHERE Name = N'MonthNumber' AND Object_ID = Object_ID(N'dbo.stg_SalaryRaw'))
BEGIN
    ALTER TABLE dbo.stg_SalaryRaw DROP COLUMN [MonthNumber];
END
GO

-- Add the new column MonthNumber
ALTER TABLE dbo.stg_SalaryRaw 
ADD [MonthNumber] INT;
GO

-- Update the column based on Persian month names
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
