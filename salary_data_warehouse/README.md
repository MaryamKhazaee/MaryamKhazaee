# Salary Data Warehouse Project

این پروژه شامل اسکریپت‌های SQL برای ایجاد یک Data Warehouse محلی از داده‌های حقوق و دستمزد است که از یک سرور ریموت استخراج می‌شوند.

## ساختار فایل‌ها

1.  **`01_setup_linked_server.sql`**:
    *   تنظیم Linked Server برای اتصال به دیتابیس ریموت (`REMOTE_VIEW3`).
    *   مدیریت امنیت و لاگین‌ها.

2.  **`02_extract_to_staging.sql`**:
    *   ایجاد دیتابیس `SalaryDW`.
    *   استخراج داده‌های خام از ویوهای `SalarySnapMarket` و `SalaryZooket`.
    *   ذخیره داده‌ها در جدول Staging (`stg_SalaryRaw`).

3.  **`03_create_star_schema.sql`**:
    *   ایجاد جداول Dimension (`DimPeriod`, `DimEmployee`).
    *   ایجاد جدول Fact (`FactSalary`).
    *   پاکسازی و آماده‌سازی داده‌ها برای استفاده در داشبورد Power BI.

## نحوه استفاده

اسکریپت‌ها را به ترتیب شماره اجرا کنید تا محیط Data Warehouse به طور کامل ایجاد شود.
