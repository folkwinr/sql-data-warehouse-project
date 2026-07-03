/*============================================================
  STEP 1 - Check Customer ID
  Goal:
  Check ERP Customer IDs before cleaning.
============================================================*/

SELECT
    cid,
	bdate,
	gen
FROM bronze.erp_cust_az12;

/*============================================================
  STEP 2 - Clean Customer ID
  Goal:
  Remove "NAS" from the beginning of Customer ID.
============================================================*/

SELECT
    cid AS old_cid,

    CASE
        WHEN cid LIKE 'NAS%'
            THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS cid

FROM bronze.erp_cust_az12;

/*============================================================
  STEP 3 - Validate Customer ID
  Goal:
  Check if cleaned Customer IDs match CRM Customer Keys.
============================================================*/

SELECT
    CASE
        WHEN cid LIKE 'NAS%'
            THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS cid

FROM bronze.erp_cust_az12

WHERE
    CASE
        WHEN cid LIKE 'NAS%'
            THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END NOT IN
(
    SELECT DISTINCT cst_key
    FROM silver.crm_cust_info
);


/*============================================================
  STEP 4 - Check Birth Date Quality
  Goal:
  Find very old birth dates or future birth dates.
============================================================*/

SELECT
    bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01'
   OR bdate > GETDATE();

/*============================================================
  STEP 5 - Clean Birth Date
  Goal:
  Future birth dates are invalid, so make them NULL.
============================================================*/

SELECT
    bdate AS old_bdate,

    CASE
        WHEN bdate > GETDATE() THEN NULL
        ELSE bdate
    END AS bdate

FROM bronze.erp_cust_az12;

/*============================================================
  STEP 6 - Check Gender Values
  Goal:
  Show all unique gender values.
============================================================*/

SELECT DISTINCT
    gen
FROM bronze.erp_cust_az12;


/*============================================================
  STEP 7 - Clean Gender
  Goal:
  Standardize gender values.
============================================================*/

SELECT
    gen AS old_gen,

    CASE
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a'
    END AS gen

FROM bronze.erp_cust_az12;

/*============================================================
  STEP 8 - Combine All Transformations
  Goal:
  Put all cleaned columns into one query.
============================================================*/

SELECT

    -- Clean Customer ID
    CASE
        WHEN cid LIKE 'NAS%'
            THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS cid,

    -- Clean Birth Date
    CASE
        WHEN bdate > GETDATE() THEN NULL
        ELSE bdate
    END AS bdate,

    -- Clean Gender
    CASE
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a'
    END AS gen

FROM bronze.erp_cust_az12;


/*============================================================
  STEP 9 - Check Silver DDL
  Goal:
  Check if DDL needs changes.
============================================================*/

-- No changes needed.
-- No new columns.
-- No data type changes.

/*============================================================
  STEP 10 - Final Insert Into Silver
  Goal:
  Load cleaned ERP customer data into Silver.
============================================================*/

INSERT INTO silver.erp_cust_az12
(
    cid,
    bdate,
    gen
)

SELECT

    CASE
        WHEN cid LIKE 'NAS%'
            THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS cid,

    CASE
        WHEN bdate > GETDATE() THEN NULL
        ELSE bdate
    END AS bdate,

    CASE
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a'
    END AS gen

FROM bronze.erp_cust_az12;


/*============================================================
  STEP 11 - Validate Silver Data
  Goal:
  Check cleaned data in Silver.
============================================================*/

-- Check Birth Dates
SELECT
    bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01'
   OR bdate > GETDATE();

-- Check Gender
SELECT DISTINCT
    gen
FROM silver.erp_cust_az12;

-- Final View
SELECT TOP (1000)
    *
FROM silver.erp_cust_az12;

