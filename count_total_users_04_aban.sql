SELECT COUNT(PersonNo) AS TotalPersonCount
FROM dbo.stg_SalaryRaw
WHERE [year] = '04'
  AND [month] = N'آبان';
