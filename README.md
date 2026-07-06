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

## Data Sources

| Source | Table | Description |
|--------|-------|-------------|
| CRM | `crm_cust_info` | Customer master records |
| CRM | `crm_prd_info` | Product catalog with versioning |
| CRM | `crm_sales_details` | Transactional sales orders |
| ERP | `erp_cust_az12` | Customer demographics (birthdate, gender) |
| ERP | `erp_loc_a101` | Customer location data |
| ERP | `erp_px_cat_g1v2` | Product category hierarchy |
## Architecture Overview

---

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

##  ETL Pipeline Overview

The process starts by loading raw CRM and ERP data into the Bronze layer. The data is then cleaned and standardized in the Silver layer before being transformed into a business-ready **Star Schema** in the Gold layer.

---

##  Bronze Layer — Raw Data

The Bronze layer is the landing area for all source data. Data is loaded exactly as it comes from the CRM and ERP systems without any transformations.

### What happens in this layer?

- CSV files are loaded using **BULK INSERT**
- Tables are truncated before each load
- A full reload strategy is used
- Load duration is recorded
- Errors are handled with **TRY...CATCH**

At this stage, the goal is simply to move the data into the warehouse while keeping it unchanged.

---

##  Silver Layer — Data Cleaning & Transformation

The Silver layer focuses on improving data quality. Here, raw data is cleaned, standardized, and prepared for business use.

### Main transformations

- Removed duplicate customer records
- Kept only the latest customer information
- Removed unwanted spaces
- Standardized gender and marital status values
- Standardized country names
- Cleaned ERP customer IDs
- Split product keys into **Category ID** and **Product Number**
- Managed product history using **Start Date** and **End Date**
- Converted integer dates into SQL `DATE`
- Recalculated sales values using:

```text
Sales = Quantity × Price
```

### Metadata

Each Silver table also includes a warehouse audit column:

- `dwh_create_date`

This column stores the timestamp when the record was loaded into the data warehouse.

---

##  Gold Layer — Business-Ready Model

The Gold layer contains the final business model used for reporting and analytics.

Instead of creating physical tables, this layer uses SQL **Views** built on top of the clean Silver data.

### Business Views

| View | Type | Description |
|------|------|-------------|
| `gold.dim_customers` | Dimension | Customer information |
| `gold.dim_products` | Dimension | Product and category information |
| `gold.fact_sales` | Fact | Sales transactions |

---

## ⭐ Star Schema

```text
              dim_customers
                     │
                     │ customer_key
                     ▼
              fact_sales
                     ▲
                     │ product_key
              dim_products
```

---

#  Business Rules

A few business rules were applied while building the Gold layer.

- CRM is the main source for customer and product information.
- ERP data is used to enrich customer and product details.
- CRM gender has priority over ERP gender.
- ERP gender is only used when CRM data is missing.
- Only active products are included in the product dimension.
- Fact tables use surrogate keys from the dimension tables.

---

#  Data Quality Checks

Several validation checks were performed to make sure the data is reliable.

The checks include:

- Duplicate keys
- Missing values
- Extra spaces
- Invalid date ranges
- Sales calculation validation
- Fact-to-dimension relationship validation

> **Expected result:** Most validation queries should return **zero rows**, meaning no data quality issues were found.

---

#  Final Output

The completed Gold layer can be used for:

- Sales performance analysis
- Product performance reporting
- Customer segmentation
- Dashboard development
- Business intelligence reporting

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
