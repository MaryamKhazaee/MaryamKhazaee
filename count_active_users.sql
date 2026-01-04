SELECT COUNT(DISTINCT PersonNo) AS ActiveUniquePersonCount
FROM dbo.stg_SalaryRaw
WHERE EmployeeStatus = 'Active';
