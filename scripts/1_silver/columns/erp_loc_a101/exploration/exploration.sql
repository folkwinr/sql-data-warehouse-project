/*============================================================
  STEP 1 - Check Customer ID
  Goal:
  Check ERP Location Customer IDs before cleaning.
============================================================*/

SELECT
    cid
FROM bronze.erp_loc_a101;

SELECT
    cst_key
FROM silver.crm_cust_info;

/*============================================================
  STEP 2 - Clean Customer ID
  Goal:
  Remove "-" from Customer ID.
============================================================*/

SELECT
    cid AS old_cid,

    REPLACE(cid, '-', '') AS cid

FROM bronze.erp_loc_a101;

/*============================================================
  STEP 3 - Validate Customer ID
  Goal:
  Check if cleaned Customer IDs match CRM Customer Keys.
============================================================*/

SELECT
    REPLACE(cid, '-', '') AS cid
FROM bronze.erp_loc_a101
WHERE REPLACE(cid, '-', '') NOT IN
(
    SELECT DISTINCT cst_key
    FROM silver.crm_cust_info
);

/*============================================================
  STEP 4 - Check Country Values
  Goal:
  Show all unique country values.
============================================================*/

SELECT DISTINCT
    cntry
FROM bronze.erp_loc_a101
ORDER BY cntry;

/*============================================================
  STEP 5 - Clean Country Values
  Goal:
  Standardize country values.
============================================================*/

SELECT DISTINCT
    cntry AS old_cntry,

    CASE
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
        ELSE TRIM(cntry)
    END AS cntry

FROM bronze.erp_loc_a101
ORDER BY cntry

/*============================================================
  STEP 6 - Combine All Transformations
  Goal:
  Put cleaned Customer ID and Country in one query.
============================================================*/

SELECT
    REPLACE(cid, '-', '') AS cid,

    CASE
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
        ELSE TRIM(cntry)
    END AS cntry

FROM bronze.erp_loc_a101;

/*============================================================
  STEP 7 - Check Silver DDL
  Goal:
  Check if DDL needs changes.
============================================================*/

-- No changes needed.
-- cid is still NVARCHAR.
-- cntry is still NVARCHAR.

/*============================================================
  STEP 8 - Final Insert Into Silver
  Goal:
  Load cleaned location data into silver.erp_loc_a101.
============================================================*/

INSERT INTO silver.erp_loc_a101
(
    cid,
    cntry
)
SELECT
    REPLACE(cid, '-', '') AS cid,

    CASE
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
        ELSE TRIM(cntry)
    END AS cntry

FROM bronze.erp_loc_a101;

/*============================================================
  STEP 9 - Validate Silver Country Values
  Goal:
  Check cleaned country values in Silver.
============================================================*/

SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101
ORDER BY cntry;

/*============================================================
  STEP 10 - Final Look at Silver Table
  Goal:
  Check final loaded location data.
============================================================*/

SELECT TOP (1000)
    *
FROM silver.erp_loc_a101;
