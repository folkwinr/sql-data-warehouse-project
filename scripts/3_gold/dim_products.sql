/*============================================================
silver.crm_prd_info
        +
silver.erp_px_cat_g1v2
        ↓
gold.dim_products
============================================================*/

/*============================================================
  STEP 1 - Check Product Table
  Goal:
  Start from the main product table in Silver Layer.
============================================================*/

SELECT
    *
FROM silver.crm_prd_info;

/*============================================================
  STEP 2 - Select Needed Product Columns
  Goal:
  Select product columns needed for Gold Layer.
  Metadata column is not needed.
============================================================*/

SELECT
    prd_id,
    prd_key,
    prd_nm,
    cat_id,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
FROM silver.crm_prd_info;

/*============================================================
  STEP 3 - Filter Current Products
  Goal:
  Keep only current product records.

  Rule:
  If prd_end_dt is NULL, this product record is current.
============================================================*/

SELECT
    prd_id,
    prd_key,
    prd_nm,
    cat_id,
    prd_cost,
    prd_line,
    prd_start_dt
FROM silver.crm_prd_info
WHERE prd_end_dt IS NULL;

/*============================================================
  STEP 4 - Add Table Alias
  Goal:
  Use alias because we will join another table.
============================================================*/

SELECT
    pn.prd_id,
    pn.prd_key,
    pn.prd_nm,
    pn.cat_id,
    pn.prd_cost,
    pn.prd_line,
    pn.prd_start_dt
FROM silver.crm_prd_info pn
WHERE pn.prd_end_dt IS NULL;

/*============================================================
  STEP 5 - Join Product Category Table
  Goal:
  Add category, subcategory, and maintenance information.

  Note:
  We use LEFT JOIN to avoid losing products
  from the main CRM product table.
============================================================*/

SELECT
    pn.prd_id,
    pn.prd_key,
    pn.prd_nm,
    pn.cat_id,

    pc.cat,
    pc.subcat,
    pc.maintenance,

    pn.prd_cost,
    pn.prd_line,
    pn.prd_start_dt

FROM silver.crm_prd_info pn

LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id

WHERE pn.prd_end_dt IS NULL;


/*============================================================
  STEP 6 - Check Duplicate Product Keys After Join
  Goal:
  Make sure joins did not create duplicate products.

  Product key will be used later to connect with sales.

  Expected Result:
  No rows.
============================================================*/

SELECT
    prd_key,
    COUNT(*) AS total_records
FROM
(
    SELECT
        pn.prd_id,
        pn.prd_key,
        pn.prd_nm,
        pn.cat_id,

        pc.cat,
        pc.subcat,
        pc.maintenance,

        pn.prd_cost,
        pn.prd_line,
        pn.prd_start_dt

    FROM silver.crm_prd_info pn

    LEFT JOIN silver.erp_px_cat_g1v2 pc
        ON pn.cat_id = pc.id

    WHERE pn.prd_end_dt IS NULL
) t
GROUP BY prd_key
HAVING COUNT(*) > 1;


/*============================================================
  STEP 7 - Reorder Columns
  Goal:
  Put related columns together.
============================================================*/

SELECT
    pn.prd_id,
    pn.prd_key,
    pn.prd_nm,

    pn.cat_id,
    pc.cat,
    pc.subcat,
    pc.maintenance,

    pn.prd_cost,
    pn.prd_line,
    pn.prd_start_dt

FROM silver.crm_prd_info pn

LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id

WHERE pn.prd_end_dt IS NULL;


/*============================================================
  STEP 8 - Rename Columns for Gold Layer
  Goal:
  Use friendly column names with snake_case.
============================================================*/

SELECT
    pn.prd_id       AS product_id,
    pn.prd_key      AS product_number,
    pn.prd_nm       AS product_name,

    pn.cat_id       AS category_id,
    pc.cat          AS category,
    pc.subcat       AS subcategory,
    pc.maintenance  AS maintenance,

    pn.prd_cost     AS cost,
    pn.prd_line     AS product_line,
    pn.prd_start_dt AS start_date

FROM silver.crm_prd_info pn

LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id

WHERE pn.prd_end_dt IS NULL;


/*============================================================
  STEP 9 - Create Surrogate Key
  Goal:
  Create a new unique key for the product dimension.
============================================================*/

SELECT
    ROW_NUMBER() OVER (
        ORDER BY pn.prd_start_dt, pn.prd_key
    ) AS product_key,

    pn.prd_id       AS product_id,
    pn.prd_key      AS product_number,
    pn.prd_nm       AS product_name,

    pn.cat_id       AS category_id,
    pc.cat          AS category,
    pc.subcat       AS subcategory,
    pc.maintenance  AS maintenance,

    pn.prd_cost     AS cost,
    pn.prd_line     AS product_line,
    pn.prd_start_dt AS start_date

FROM silver.crm_prd_info pn

LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id

WHERE pn.prd_end_dt IS NULL;


/*============================================================
  STEP 10 - Create Gold Product Dimension View
  Goal:
  Create the final product dimension view in Gold Layer.
============================================================*/

CREATE VIEW gold.dim_products AS

SELECT
    ROW_NUMBER() OVER (
        ORDER BY pn.prd_start_dt, pn.prd_key
    ) AS product_key,

    pn.prd_id       AS product_id,
    pn.prd_key      AS product_number,
    pn.prd_nm       AS product_name,

    pn.cat_id       AS category_id,
    pc.cat          AS category,
    pc.subcat       AS subcategory,
    pc.maintenance  AS maintenance,

    pn.prd_cost     AS cost,
    pn.prd_line     AS product_line,
    pn.prd_start_dt AS start_date

FROM silver.crm_prd_info pn

LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id

WHERE pn.prd_end_dt IS NULL;


/*============================================================
  STEP 11 - Check Gold Product Dimension
  Goal:
  Review the final Gold product dimension view.
============================================================*/

SELECT
    *
FROM gold.dim_products;

/*============================================================
  STEP 12 - Check Product Key Uniqueness
  Goal:
  Product number should be unique in Gold dimension.

  Expected Result:
  No rows.
============================================================*/

SELECT
    product_number,
    COUNT(*) AS total_records
FROM gold.dim_products
GROUP BY product_number
HAVING COUNT(*) > 1;
