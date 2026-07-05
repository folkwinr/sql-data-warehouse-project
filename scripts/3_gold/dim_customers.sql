/*============================================================
  STEP 1 - Check Main Customer Table
  Goal:
  Start from the main customer table in Silver Layer.
============================================================*/

SELECT
    *
FROM silver.crm_cust_info;

/*============================================================
  STEP 2 - Select Needed Customer Columns
  Goal:
  Select only business columns.
  Metadata column is not needed in Gold Layer.
============================================================*/

SELECT
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
FROM silver.crm_cust_info;

/*============================================================
  STEP 3 - Add Table Alias
  Goal:
  Use alias because we will join more tables.
============================================================*/

SELECT
    ci.cst_id,
    ci.cst_key,
    ci.cst_firstname,
    ci.cst_lastname,
    ci.cst_marital_status,
    ci.cst_gndr,
    ci.cst_create_date
FROM silver.crm_cust_info ci;

/*============================================================
  STEP 4 - Join ERP Customer Table
  Goal:
  Add birth date and ERP gender information.

  Note:
  We use LEFT JOIN to avoid losing customers
  from the main CRM customer table.
============================================================*/

SELECT
    ci.cst_id,
    ci.cst_key,
    ci.cst_firstname,
    ci.cst_lastname,
    ci.cst_marital_status,
    ci.cst_gndr,
    ci.cst_create_date,

    ca.bdate,
    ca.gen

FROM silver.crm_cust_info ci

LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid;

/*============================================================
  STEP 5 - Join ERP Location Table
  Goal:
  Add country information.
============================================================*/

SELECT
    ci.cst_id,
    ci.cst_key,
    ci.cst_firstname,
    ci.cst_lastname,
    ci.cst_marital_status,
    ci.cst_gndr,
    ci.cst_create_date,

    ca.bdate,
    ca.gen,

    la.cntry

FROM silver.crm_cust_info ci

LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid

LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;


/*============================================================
  STEP 6 - Check Duplicate Customers After Joins
  Goal:
  Make sure joins did not create duplicate customers.

  Expected Result:
  No rows.
============================================================*/

SELECT
    cst_id,
    COUNT(*) AS total_records
FROM
(
    SELECT
        ci.cst_id,
        ci.cst_key,
        ci.cst_firstname,
        ci.cst_lastname,
        ci.cst_marital_status,
        ci.cst_gndr,
        ci.cst_create_date,

        ca.bdate,
        ca.gen,

        la.cntry

    FROM silver.crm_cust_info ci

    LEFT JOIN silver.erp_cust_az12 ca
        ON ci.cst_key = ca.cid

    LEFT JOIN silver.erp_loc_a101 la
        ON ci.cst_key = la.cid
) t
GROUP BY cst_id
HAVING COUNT(*) > 1;

/*============================================================
  STEP 7 - Check Gender Integration Scenarios
  Goal:
  Compare gender values from CRM and ERP.
============================================================*/

SELECT DISTINCT
    ci.cst_gndr AS crm_gender,
    ca.gen      AS erp_gender
FROM silver.crm_cust_info ci

LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid

ORDER BY
    ci.cst_gndr,
    ca.gen;

/*============================================================
  STEP 8 - Create Integrated Gender
  Goal:
  Use CRM gender first because CRM is the master source.
  If CRM gender is not available, use ERP gender.
============================================================*/

SELECT DISTINCT
    ci.cst_gndr AS crm_gender,
    ca.gen      AS erp_gender,

    CASE
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender

FROM silver.crm_cust_info ci

LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid

ORDER BY
    ci.cst_gndr,
    ca.gen;

/*============================================================
  STEP 9 - Add Integrated Gender to Main Query
  Goal:
  Replace old CRM/ERP gender columns with one clean gender column.
============================================================*/

SELECT
    ci.cst_id,
    ci.cst_key,
    ci.cst_firstname,
    ci.cst_lastname,
    ci.cst_marital_status,

    CASE
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,

    ci.cst_create_date,
    ca.bdate,
    la.cntry

FROM silver.crm_cust_info ci

LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid

LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;


/*============================================================
  STEP 10 - Rename Columns for Gold Layer
  Goal:
  Use friendly column names with snake_case.
============================================================*/

SELECT
    ci.cst_id             AS customer_id,
    ci.cst_key            AS customer_number,
    ci.cst_firstname      AS first_name,
    ci.cst_lastname       AS last_name,
    ci.cst_marital_status AS marital_status,

    CASE
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,

    ci.cst_create_date    AS create_date,
    ca.bdate              AS birth_date,
    la.cntry              AS country

FROM silver.crm_cust_info ci

LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid

LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;


/*============================================================
  STEP 11 - Reorder Columns
  Goal:
  Put related columns together.
============================================================*/

SELECT
    ci.cst_id             AS customer_id,
    ci.cst_key            AS customer_number,
    ci.cst_firstname      AS first_name,
    ci.cst_lastname       AS last_name,
    la.cntry              AS country,
    ci.cst_marital_status AS marital_status,

    CASE
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,

    ca.bdate              AS birth_date,
    ci.cst_create_date    AS create_date

FROM silver.crm_cust_info ci

LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid

LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;

/*============================================================
  STEP 11 - Reorder Columns
  Goal:
  Put related columns together.
============================================================*/

SELECT
    ci.cst_id             AS customer_id,
    ci.cst_key            AS customer_number,
    ci.cst_firstname      AS first_name,
    ci.cst_lastname       AS last_name,
    la.cntry              AS country,
    ci.cst_marital_status AS marital_status,

    CASE
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,

    ca.bdate              AS birth_date,
    ci.cst_create_date    AS create_date

FROM silver.crm_cust_info ci

LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid

LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;


/*============================================================
  STEP 12 - Create Surrogate Key
  Goal:
  Create a new unique key for the customer dimension.
============================================================*/

SELECT
    ROW_NUMBER() OVER (
        ORDER BY ci.cst_id
    ) AS customer_key,

    ci.cst_id             AS customer_id,
    ci.cst_key            AS customer_number,
    ci.cst_firstname      AS first_name,
    ci.cst_lastname       AS last_name,
    la.cntry              AS country,
    ci.cst_marital_status AS marital_status,

    CASE
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,

    ca.bdate              AS birth_date,
    ci.cst_create_date    AS create_date

FROM silver.crm_cust_info ci

LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid

LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;


/*============================================================
  STEP 13 - Create Gold Customer Dimension View
  Goal:
  Create the final customer dimension view in Gold Layer.
============================================================*/

CREATE VIEW gold.dim_customers AS

SELECT
    ROW_NUMBER() OVER (
        ORDER BY ci.cst_id
    ) AS customer_key,

    ci.cst_id             AS customer_id,
    ci.cst_key            AS customer_number,
    ci.cst_firstname      AS first_name,
    ci.cst_lastname       AS last_name,
    la.cntry              AS country,
    ci.cst_marital_status AS marital_status,

    CASE
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,

    ca.bdate              AS birth_date,
    ci.cst_create_date    AS create_date

FROM silver.crm_cust_info ci

LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid

LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;

/*============================================================
  STEP 14 - Check Gold Customer Dimension
  Goal:
  Review the final Gold customer dimension view.
============================================================*/

SELECT
    *
FROM gold.dim_customers;

/*============================================================
  STEP 15 - Check Gender Values
  Goal:
  Make sure gender is standardized.
============================================================*/

SELECT DISTINCT
    gender
FROM gold.dim_customers;

