SELECT COUNT(DISTINCT PersonNo) AS PersonCount
FROM dbo.stg_SalaryRaw
WHERE [year] = '04'
  AND [MonthNumber] = 8 -- Assuming "08" refers to the 8th month (Aban in your previous context)
  AND Businessline = N'HQ';
