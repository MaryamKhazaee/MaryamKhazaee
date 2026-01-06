USE [SalaryDW];
GO

PRINT '>>> Executing Weekly ETL...';

-- Execute the Master Procedure
EXEC [dbo].[sp_RunWeeklyETL];

PRINT '>>> Execution finished. Please check the "Messages" tab above for any "!!! ERROR OCCURRED !!!" messages.';
