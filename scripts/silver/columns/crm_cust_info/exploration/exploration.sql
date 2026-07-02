/*============================================================
  STEP 1 - Check Primary Key
  Goal:
  Check NULL and duplicate Product IDs.
============================================================*/

SELECT
    prd_id,
    COUNT(*) AS total_records
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1
    OR prd_id IS NULL;

/*============================================================
  STEP 2 - Create Category ID
  Goal:
  Get the first 5 characters from Product Key.
============================================================*/

SELECT
    prd_key,
    SUBSTRING(prd_key, 1, 5) AS cat_id
FROM bronze.crm_prd_info;

/*============================================================
  STEP 3 - Replace "-" with "_"
  Goal:
  Make Category IDs match ERP table.
============================================================*/

SELECT
    REPLACE(
        SUBSTRING(prd_key, 1, 5),
        '-',
        '_'
    ) AS cat_id
FROM bronze.crm_prd_info;

/*============================================================
  STEP 4 - Validate Category IDs
  Goal:
  Find Category IDs that do not exist in ERP.
============================================================*/

/*============================================================
  STEP 4 - Validate Category IDs
  Goal:
  Find category IDs that do not match ERP after transformation.
============================================================*/

SELECT
    prd_id,
    prd_key,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
	prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
FROM bronze.crm_prd_info
WHERE REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') NOT IN (
    SELECT DISTINCT id
    FROM bronze.erp_px_cat_g1v2
);

/*============================================================
  STEP 5 - Create Product Key
  Goal:
  Get the second part from prd_key.
  This key will be used to join with sales details.
============================================================*/

SELECT
    prd_id,
    prd_key,

    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,

    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
FROM bronze.crm_prd_info;

/*============================================================
  STEP 6 - Validate Product Key
  Goal:
  Find products that do not exist in sales details.
============================================================*/

SELECT
    prd_id,
    prd_key,
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key_new,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
FROM bronze.crm_prd_info
WHERE SUBSTRING(prd_key, 7, LEN(prd_key)) NOT IN
(
    SELECT DISTINCT sls_prd_key
    FROM bronze.crm_sales_details
);

/*============================================================
  STEP 7 - Check Product Name Spaces
  Goal:
  Find product names with extra spaces.
============================================================*/

SELECT
    prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);


/*============================================================
  STEP 8 - Clean Product Name
  Goal:
  Remove extra spaces from product name.
============================================================*/

SELECT
    prd_id,
    prd_key,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
    TRIM(prd_nm) AS prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
FROM bronze.crm_prd_info;

/*============================================================
  STEP 9 - Check Product Cost
  Goal:
  Find NULL or negative costs.
============================================================*/

SELECT
    prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0
   OR prd_cost IS NULL;

/*============================================================
  STEP 10 - Clean Product Cost
  Goal:
  Replace NULL values with 0.
============================================================*/

SELECT
    prd_id,
    prd_key,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
    TRIM(prd_nm) AS prd_nm,

    ISNULL(prd_cost, 0) AS prd_cost,

    prd_line,
    prd_start_dt,
    prd_end_dt
FROM bronze.crm_prd_info;

/*============================================================
  STEP 11 - Check Product Line
  Goal:
  Show all unique Product Line values.
============================================================*/

SELECT DISTINCT
    prd_line
FROM bronze.crm_prd_info;

/*============================================================
  STEP 12 - Standardize Product Line
  Goal:
  Replace short codes with friendly names.
============================================================*/

SELECT
    prd_id,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
    prd_nm,
    ISNULL(prd_cost, 0) AS prd_cost,

    CASE UPPER(TRIM(prd_line))
        WHEN 'M' THEN 'Mountain'
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,

    prd_start_dt,
    prd_end_dt
FROM bronze.crm_prd_info;

/*============================================================
  STEP 13 - Check Start Date and End Date
  Goal:
  Find rows where End Date is before Start Date.
  End date must not be earlier ehan the start date
============================================================*/

SELECT
    *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

/*============================================================
  STEP 14 - Test New End Date
  Goal:
  Use the next Start Date as the new End Date.(TEST)
============================================================*/

SELECT
    prd_id,
    prd_key,
    prd_nm,
    prd_start_dt,
    prd_end_dt,

    LEAD(prd_start_dt) OVER (
        PARTITION BY prd_key
        ORDER BY prd_start_dt
    ) AS prd_end_dt_test

FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R' , 'AC-HE-HL-U509')

/*============================================================
  STEP 15 - Fix New End Date
  Goal:
  Use next Start Date minus 1 day.
  This avoids date overlap.
============================================================*/

SELECT
    prd_id,
    prd_key,
    prd_nm,
    prd_start_dt,
    prd_end_dt,

    DATEADD(
        DAY,
        -1,
        LEAD(prd_start_dt) OVER (
            PARTITION BY prd_key
            ORDER BY prd_start_dt
        )
    ) AS new_prd_end_dt

FROM bronze.crm_prd_info;

/*============================================================
  STEP 16 - Cast Dates
  Goal:
  Remove time part and keep only date.
============================================================*/

SELECT
    prd_id,
    prd_key,
    prd_start_dt,
    prd_end_dt,

    CAST(prd_start_dt AS DATE) AS prd_start_dt_new,

    CAST(
        DATEADD(
            DAY,
            -1,
            LEAD(prd_start_dt) OVER (
                PARTITION BY prd_key
                ORDER BY prd_start_dt
            )
        ) AS DATE
    ) AS prd_end_dt_new

FROM bronze.crm_prd_info;

/*============================================================
  STEP 17 - Update Silver DDL
  Goal:
  Add new column and update data types.
============================================================*/

-- Add new column
cat_id NVARCHAR(50),

-- Change data types
prd_start_dt DATE,
prd_end_dt DATE


