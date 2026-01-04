SELECT COUNT(DISTINCT PersonNo) AS ActiveUniquePersonCount
FROM dbo.stg_SalaryRaw
WHERE EmployeeStatus = 'Active'
  AND [year] = '04'
  AND [month] = N'آبان';
