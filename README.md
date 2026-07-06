# SQL Data Warehouse Project

This project builds a modern **SQL Server Data Warehouse** by combining CRM and ERP data into one trusted data source.

The project uses the **Medallion Architecture (Bronze → Silver → Gold)** to load, clean, and prepare data for reporting. The final result is a **Single Source of Truth** that can be used by Business Intelligence tools such as Power BI and Tableau.

---

##  Business Context

Many companies store customer, product, and sales data in different systems.

This can cause several problems:

- ❌ Inconsistent reports
- ❌ Manual data preparation
- ❌ Poor data quality
- ❌ Different numbers across departments
- ❌ Slow reporting process

This project helps solve these problems by creating one central data warehouse.

---

##  Business Goal

The main goals of this project are:

- Combine CRM and ERP data into one central database
- Improve data quality
- Build a repeatable ETL process
- Provide trusted data for BI tools
- Make reporting and dashboard creation easier

A fully functional data warehouse built with **SQL Server**, implementing the **Medallion Architecture** (Bronze → Silver → Gold) to consolidate, clean, and serve data from two source systems: a CRM platform and an ERP system.

---

## Architecture Overview

```
CRM System          ERP System
(CSV exports)       (CSV exports)
     │                   │
     ▼                   ▼
┌─────────────────────────────┐
│         BRONZE LAYER        │   Raw ingestion, no transformation
│                             │
│  crm_cust_info              │
│  crm_prd_info               │
│  crm_sales_details          │
│  erp_cust_az12              │
│  erp_loc_a101               │
│  erp_px_cat_g1v2            │
└────────────┬────────────────┘
             │
             │ EXEC bronze.load_bronze
             ▼
┌─────────────────────────────┐
│         SILVER LAYER        │   Cleaned, standardized, deduplicated
│                             │
│  crm_cust_info              │
│  crm_prd_info               │
│  crm_sales_details          │
│  erp_cust_az12              │
│  erp_loc_a101               │
│  erp_px_cat_g1v2            │
└────────────┬────────────────┘
             │
             │ EXEC silver.load_silver
             ▼
┌─────────────────────────────┐
│          GOLD LAYER         │   Business-ready Star Schema
│                             │
│  dim_customers              │
│  dim_products               │
│  fact_sales                 │
└─────────────────────────────┘
```

---

## Data Sources

| Source | Table | Description |
|--------|-------|-------------|
| CRM | `crm_cust_info` | Customer master records |
| CRM | `crm_prd_info` | Product catalog with versioning |
| CRM | `crm_sales_details` | Transactional sales orders |
| ERP | `erp_cust_az12` | Customer demographics (birthdate, gender) |
| ERP | `erp_loc_a101` | Customer location data |
| ERP | `erp_px_cat_g1v2` | Product category hierarchy |

---

## ETL Pipeline

### Bronze Layer — Raw Ingestion

The `bronze.load_bronze` stored procedure uses `BULK INSERT` to load CSV files directly into staging tables without any transformation. The procedure:
- Truncates each table before loading (full reload pattern)
- Tracks load duration per table using `DATEDIFF`
- Handles errors with `TRY/CATCH` and prints structured diagnostics

### Silver Layer — Cleansing & Transformation

The `silver.load_silver` stored procedure applies the following transformations:

**Customer deduplication (`crm_cust_info`)**
- Uses `ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC)` to retain only the most recent record per customer
- Filters `NULL` customer IDs at source
- Expands abbreviated codes: `'S' → 'Single'`, `'M' → 'Married'`, `'F' → 'Female'`, `'M' → 'Male'`

**Product versioning (`crm_prd_info`)**
- Parses a composite `prd_key` field to extract `cat_id` (first 5 characters) and a clean product key (from character 7 onward)
- Derives `prd_end_dt` using `LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1` — no end date stored in source; it's calculated from the next version's start date
- Replaces `NULL` costs with `0`; expands product line codes

**Sales data repair (`crm_sales_details`)**
- Converts 8-digit integer dates (stored as `YYYYMMDD`) to proper `DATE` values, nullifying malformed entries
- Enforces the business rule `sales = quantity × price`: recalculates `sls_sales` when it is `NULL`, zero, negative, or inconsistent; similarly derives `sls_price` from sales/quantity when missing

**ERP customer cleanup (`erp_cust_az12`)**
- Strips the `NAS` prefix from customer IDs to align with CRM keys
- Nullifies future birth dates (`bdate > GETDATE()`)
- Normalizes gender variants (`'F'`, `'FEMALE'` → `'Female'`)

**Location standardization (`erp_loc_a101`)**
- Removes dashes from customer IDs to match CRM format
- Maps country codes and abbreviations to full names (`'DE' → 'Germany'`, `'US'/'USA' → 'United States'`)

All Silver tables include a `dwh_create_date DATETIME2 DEFAULT GETDATE()` audit column added at the warehouse layer.

---

## Data Quality Checks

`tests/quality_checks_silver.sql` runs after each Silver load to validate transformation correctness. Checks are organized by table and cover:

| Category | Examples |
|----------|----------|
| **Primary key integrity** | No `NULL` or duplicate customer/product IDs |
| **String hygiene** | No leading/trailing whitespace in key fields |
| **Standardized values** | Gender, marital status, product line, country only contain expected values |
| **Date validity** | No future birth dates; `order_dt` precedes `ship_dt` and `due_dt`; `prd_start_dt` precedes `prd_end_dt` |
| **Business rule enforcement** | `sls_sales = sls_quantity × sls_price` for all rows |
| **Referential integrity** | Sales product keys exist in product table; customer IDs join correctly across CRM and ERP |

Each query is expected to return zero rows after a clean load.

---

## Technologies

- **SQL Server** — database engine, stored procedures, window functions
- **T-SQL** — `BULK INSERT`, `TRY/CATCH`, `ROW_NUMBER()`, `LEAD()`, `NULLIF()`, `ISNULL()`, `DATEDIFF()`
- **Medallion Architecture** — Bronze / Silver / Gold layered design pattern

---

## Setup & Usage

**1. Initialize the database**
```sql
-- WARNING: drops and recreates the DataWarehouse database
-- Run in SQL Server Management Studio (SSMS) against the master database
scripts/2_bronze/init_database/init_database.sql
```

**2. Create Bronze tables and load procedure**
```sql
scripts/2_bronze/ddl_bronze/ddl_bronze.sql
-- Update BULK INSERT file paths in bronze.load_bronze to match your local dataset directory
```

**3. Create Silver tables**
```sql
scripts/1_silver/ddl_silver/ddl_silver.sql
```

**4. Create Silver load procedure**
```sql
scripts/1_silver/silver_procedure/load_silver_procedure.sql
```

**5. Run the pipeline**
```sql
EXEC bronze.load_bronze;
EXEC silver.load_silver;
```

**6. Validate**
```sql
-- Run all checks in:
tests/quality_checks_silver.sql
```

Each column folder under `columns/` contains an `exploration/` script (ad-hoc profiling queries) and a `final_script/` (the transformation logic promoted into the stored procedure).
