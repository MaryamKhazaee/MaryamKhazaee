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
    *   *Note: Uses tables with suffix '2' (e.g., FactSalary2) to avoid overwriting existing work.*

3.  **`06_test_verification.sql`**:
    *   Run this to verify the data integrity after running the ETL.

## Usage

To update your data (e.g., weekly), run the following SQL command:

```sql
EXEC [SalaryDW].[dbo].[sp_RunWeeklyETL];
```
