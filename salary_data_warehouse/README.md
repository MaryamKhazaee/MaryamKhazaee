# Salary Data Warehouse Project

This project contains SQL scripts to build a local Data Warehouse from remote salary data.

## Files

1.  **`00_setup_infrastructure.sql`**:
    *   **Run this ONCE.**
    *   Sets up the Linked Server connection.
    *   Creates the `SalaryDW` database.

2.  **`05_final_procedures.sql`**:
    *   **Run this ONCE.**
    *   Creates all the Stored Procedures (`sp_ETL_Extract`, `sp_ETL_Transform`, etc.) needed for automation.

## Usage

To update your data (e.g., weekly), run the following SQL command:

```sql
EXEC [SalaryDW].[dbo].[sp_RunWeeklyETL];
```
