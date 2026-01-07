-- Check if the table exists, if not, create it
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SalaryDW]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[SalaryDW](
        [SalaryID] [int] IDENTITY(1,1) NOT NULL,
        [EmployeeID] [int] NOT NULL,
        [Amount] [decimal](18, 2) NOT NULL,
        [EffectiveDate] [date] NOT NULL,
        [Department] [nvarchar](50) NULL,
        -- Add other columns as needed
        CONSTRAINT [PK_SalaryDW] PRIMARY KEY CLUSTERED 
        (
            [SalaryID] ASC
        )
    )
END
GO
