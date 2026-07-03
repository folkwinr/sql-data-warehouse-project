/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'bronze' Tables
===============================================================================
*/


-- =========================================================
-- CRM TABLE 1: Customer Info
-- Silver table for cleaned customer data
-- =========================================================

IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO

CREATE TABLE silver.crm_cust_info (
    cst_id             INT,
    cst_key            NVARCHAR(50),
    cst_firstname      NVARCHAR(50),
    cst_lastname       NVARCHAR(50),
    cst_marital_status NVARCHAR(50),
    cst_gndr           NVARCHAR(50),
    cst_create_date    DATE,

    -- Silver Layer extra column
    -- This shows when the row was created in DWH
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
);
GO


-- =========================================================
-- CRM TABLE 2: Product Info
-- Silver table for cleaned product data
-- =========================================================

IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO

CREATE TABLE silver.crm_prd_info (
    prd_id          INT,
    cat_id          NVARCHAR(50),
    prd_key         NVARCHAR(50),
    prd_nm          NVARCHAR(50),
    prd_cost        INT,
    prd_line        NVARCHAR(50),
    prd_start_dt    DATE,
    prd_end_dt      DATE,

    -- Silver Layer extra column
    -- This shows when the row was created in DWH
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


-- =========================================================
-- CRM TABLE 3: Sales Details
-- Silver table for cleaned sales data
-- =========================================================

IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO

CREATE TABLE silver.crm_sales_details (
    sls_ord_num     NVARCHAR(50),
    sls_prd_key     NVARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    DATE,
    sls_ship_dt     DATE,
    sls_due_dt      DATE,
    sls_sales       INT,
    sls_quantity    INT,
    sls_price       INT,

    -- Silver Layer extra column
    -- This shows when the row was created in DWH
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


-- =========================================================
-- ERP TABLE 1: Location
-- Silver table for cleaned location data
-- =========================================================

IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;
GO

CREATE TABLE silver.erp_loc_a101 (
    cid             NVARCHAR(50),
    cntry           NVARCHAR(50),

    -- Silver Layer extra column
    -- This shows when the row was created in DWH
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


-- =========================================================
-- ERP TABLE 2: Customer Extra Info
-- Silver table for cleaned ERP customer data
-- =========================================================

IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;
GO

CREATE TABLE silver.erp_cust_az12 (
    cid             NVARCHAR(50),
    bdate           DATE,
    gen             NVARCHAR(50),

    -- Silver Layer extra column
    -- This shows when the row was created in DWH
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


-- =========================================================
-- ERP TABLE 3: Product Category
-- Silver table for cleaned category data
-- =========================================================

IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;
GO

CREATE TABLE silver.erp_px_cat_g1v2 (
    id              NVARCHAR(50),
    cat             NVARCHAR(50),
    subcat          NVARCHAR(50),
    maintenance     NVARCHAR(50),

    -- Silver Layer extra column
    -- This shows when the row was created in DWH
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO
