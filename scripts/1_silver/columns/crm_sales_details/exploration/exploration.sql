SELECT
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details

/*============================================================
  STEP 1 - Check Order Number Spaces
  Goal:
  Find order numbers with extra spaces.
============================================================*/

SELECT
    sls_ord_num
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

/*============================================================
  STEP 2 - Check Product Key Integrity
  Goal:
  Find sales product keys that do not exist in Silver product table. To check avaibility for JOINS
============================================================*/

SELECT
    sls_prd_key
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN
(
    SELECT prd_key
    FROM silver.crm_prd_info
);

/*============================================================
  STEP 3 - Check Customer ID Integrity
  Goal:
  Find sales customer IDs that do not exist in Silver customer table.
============================================================*/

SELECT
    sls_cust_id
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN
(
    SELECT cst_id
    FROM silver.crm_cust_info
);

/*============================================================
  STEP 4 - Check Order Date Quality
  Goal:
  Find invalid order dates.
  Dates are stored as numbers, so we check bad values first.
============================================================*/

SELECT
    sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0
   OR LEN(sls_order_dt) != 8;

   /*============================================================
  STEP 5 - Clean Order Date
  Goal:
  Convert valid number date to real DATE.
  Bad values become NULL.
============================================================*/

SELECT
    sls_order_dt AS old_sls_order_dt,

    CASE
        WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
    END AS sls_order_dt

FROM bronze.crm_sales_details;

/*============================================================
  STEP 6 - Check Shipping Date Quality
  Goal:
  Find invalid shipping dates.
  Dates are stored as numbers, so we check bad values first.
============================================================*/

SELECT
    sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0
   OR LEN(sls_ship_dt) != 8;

/*============================================================
  STEP 7 - Clean Shipping Date
  Goal:
  Convert valid number date to real DATE.
  Bad values become NULL.
============================================================*/

SELECT
    sls_ship_dt AS old_sls_ship_dt,

    CASE
        WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
    END AS sls_ship_dt

FROM bronze.crm_sales_details;

/*============================================================
  STEP 8 - Check Due Date Quality
  Goal:
  Find invalid due dates.
  Dates are stored as numbers, so we check bad values first.
============================================================*/

SELECT
    sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0
   OR LEN(sls_due_dt) != 8;

 /*============================================================
  STEP 9 - Clean Due Date
  Goal:
  Convert valid number date to real DATE.
  Bad values become NULL.
============================================================*/

SELECT
    sls_due_dt AS old_sls_due_dt,

    CASE
        WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
    END AS sls_due_dt

FROM bronze.crm_sales_details;

/*============================================================
  STEP 10 - Check Date Order
  Goal:
  Order Date must be before Shipping Date and Due Date.
============================================================*/

SELECT
    *
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;


/*============================================================
  STEP 11 - Check Sales, Quantity, and Price
  Goal:
  Find bad values and wrong calculations.
  Rule:
  Sales = Quantity * Price
============================================================*/

SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0
ORDER BY
    sls_sales,
    sls_quantity,
    sls_price;

/*============================================================
  STEP 11 - Check Sales, Quantity, and Price
  Goal:
  Find bad values and wrong calculations.
  Rule:
  Sales = Quantity * Price
============================================================*/

SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0
ORDER BY
    sls_sales,
    sls_quantity,
    sls_price;

/* =========================================================
   Rule 1 - Fix Sales
   If Sales is NULL, 0, or negative,
   calculate it using:

       Sales = Quantity × Price
 -----

   Rule 2 - Fix Price
   If Price is NULL or 0,
   calculate it using:

       Price = Sales / Quantity
------

   Rule 3 - Fix Negative Price
   If Price is negative,
   convert it to a positive value.

   Example:
       -50  →  50

   Use:
       ABS(price)
   ========================================================= */

/*============================================================
  STEP 12 - Clean Sales and Price Together
  Goal:
  Show old values and cleaned values together.
============================================================*/

SELECT DISTINCT
    sls_sales AS old_sls_sales,
    sls_quantity,
    sls_price AS old_sls_price,

    CASE
        WHEN sls_sales IS NULL 
          OR sls_sales <= 0 
          OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,

    CASE
        WHEN sls_price IS NULL 
          OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price

FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0

ORDER BY
    sls_sales,
    sls_quantity,
    sls_price;

/*============================================================
  STEP 13 - Final Clean Query
  Goal:
  Put all sales details transformations together.
============================================================*/

SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,

    CASE
        WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
    END AS sls_order_dt,

    CASE
        WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
    END AS sls_ship_dt,

    CASE
        WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
    END AS sls_due_dt,

    CASE
        WHEN sls_sales IS NULL 
          OR sls_sales <= 0 
          OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,

    sls_quantity,

    CASE
        WHEN sls_price IS NULL 
          OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price

FROM bronze.crm_sales_details;

/*============================================================
  STEP 14 - Update Silver DDL
  Goal:
  Change date columns from INT to DATE.
============================================================*/

-- Change these columns in silver.crm_sales_details:

sls_order_dt DATE,
sls_ship_dt  DATE,
sls_due_dt   DATE

/*============================================================
  STEP 15 - Insert Clean Data Into Silver
  Goal:
  Load cleaned sales details into silver.crm_sales_details.
============================================================*/

INSERT INTO silver.crm_sales_details (
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,

    CASE
        WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
    END AS sls_order_dt,

    CASE
        WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
    END AS sls_ship_dt,

    CASE
        WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
    END AS sls_due_dt,

    CASE
        WHEN sls_sales IS NULL 
          OR sls_sales <= 0 
          OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,

    sls_quantity,

    CASE
        WHEN sls_price IS NULL 
          OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price

FROM bronze.crm_sales_details;

/*============================================================
  STEP 16 - Check Silver Date Order
  Goal:
  Order Date must be before Shipping Date and Due Date.
============================================================*/

SELECT
    *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

/*============================================================
  STEP 17 - Check Silver Sales Rules
  Goal:
  Check sales, quantity, and price after loading Silver.
============================================================*/

SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0;

/*============================================================
  STEP 18 - Final Look at Silver Table
  Goal:
  Check final loaded data.
============================================================*/

SELECT TOP 1000
    *
FROM silver.crm_sales_details;
