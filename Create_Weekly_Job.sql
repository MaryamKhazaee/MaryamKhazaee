USE [msdb];
GO

-- =============================================
-- Create SQL Server Agent Job: SalaryDW_Weekly_Refresh
-- Schedule: Weekly on Fridays at 03:00 AM
-- =============================================

-- 1. Cleanup: Delete the job if it already exists
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'SalaryDW_Weekly_Refresh')
BEGIN
    PRINT 'Deleting existing job...';
    EXEC msdb.dbo.sp_delete_job @job_name=N'SalaryDW_Weekly_Refresh', @delete_unused_schedule=1;
END
GO

-- 2. Create the Job
PRINT 'Creating new job: SalaryDW_Weekly_Refresh...';
BEGIN TRANSACTION
DECLARE @ReturnCode INT = 0;

DECLARE @jobId BINARY(16);
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SalaryDW_Weekly_Refresh', 
        @enabled=1, 
        @notify_level_eventlog=0, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N'Refreshes SalaryDW tables (Load, Transform, DW, Views) every Friday at 3 AM.', 
        @category_name=N'[Uncategorized (Local)]', 
        @owner_login_name=N'sa', -- Changed to sa for safety, or use current user
        @job_id = @jobId OUTPUT;

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

-- 3. Add the Job Step (Executes the Master Refresh Procedure)
-- Note: We use the sp_RefreshSalaryData procedure which wraps all 4 steps.
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Execute Full Refresh', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'TSQL', 
        @command=N'EXEC [SalaryDW].[dbo].[sp_RefreshSalaryData];', 
        @database_name=N'SalaryDW', 
        @flags=0;

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

-- 4. Create the Schedule (Weekly, Fridays, 3:00 AM)
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1;

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

DECLARE @schedule_id int
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'WeeklyFriday3AM', 
        @enabled=1, 
        @freq_type=8,               -- 8 = Weekly
        @freq_interval=32,          -- 32 = Friday (1=Sun, 2=Mon, 4=Tue, 8=Wed, 16=Thu, 32=Fri, 64=Sat)
        @freq_subday_type=1,        -- 1 = At the specified time
        @freq_subday_interval=0, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=1,  -- Every 1 week
        @active_start_date=20240101, 
        @active_end_date=99991231, 
        @active_start_time=30000,   -- 03:00:00 (HHMMSS format)
        @active_end_time=235959, 
        @schedule_id = @schedule_id OUTPUT;

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

-- 5. Add Job Server
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)';

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

COMMIT TRANSACTION;
PRINT 'Job created successfully.';
GOTO EndSave;

QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION;
    PRINT 'Error creating job.';

EndSave:
GO
