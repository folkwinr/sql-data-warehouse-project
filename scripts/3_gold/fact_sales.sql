/*============================================================
  STEP 1 - Check Sales Table
  Goal:
  Start from the sales details table in Silver Layer.
============================================================*/

SELECT
    *
FROM silver.crm_sales_details;

/*============================================================
  STEP 2 - Select Needed Sales Columns
  Goal:
  Select sales transaction columns for Gold Layer.
============================================================*/

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
FROM silver.crm_sales_details;


/*============================================================
  STEP 3 - Add Table Alias
  Goal:
  Use alias because we will join dimensions.
============================================================*/

SELECT
    sd.sls_ord_num,
    sd.sls_prd_key,
    sd.sls_cust_id,
    sd.sls_order_dt,
    sd.sls_ship_dt,
    sd.sls_due_dt,
    sd.sls_sales,
    sd.sls_quantity,
    sd.sls_price
FROM silver.crm_sales_details sd;

/*============================================================
  STEP 4 - Lookup Product Surrogate Key
  Goal:
  Join product dimension to get product_key.

  Note:
  We use LEFT JOIN to avoid losing sales transactions.
============================================================*/

SELECT
    sd.sls_ord_num,

    pr.product_key,

    sd.sls_cust_id,
    sd.sls_order_dt,
    sd.sls_ship_dt,
    sd.sls_due_dt,
    sd.sls_sales,
    sd.sls_quantity,
    sd.sls_price

FROM silver.crm_sales_details sd

LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number;


/*============================================================
  STEP 5 - Lookup Customer Surrogate Key
  Goal:
  Join customer dimension to get customer_key.

  Note:
  We use LEFT JOIN to avoid losing sales transactions.
============================================================*/

SELECT
    sd.sls_ord_num,

    pr.product_key,
    cu.customer_key,

    sd.sls_order_dt,
    sd.sls_ship_dt,
    sd.sls_due_dt,
    sd.sls_sales,
    sd.sls_quantity,
    sd.sls_price

FROM silver.crm_sales_details sd

LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number

LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;


/*============================================================
  STEP 6 - Rename Columns for Gold Layer
  Goal:
  Use friendly column names with snake_case.
============================================================*/

SELECT
    sd.sls_ord_num   AS order_number,

    pr.product_key,
    cu.customer_key,

    sd.sls_order_dt  AS order_date,
    sd.sls_ship_dt   AS shipping_date,
    sd.sls_due_dt    AS due_date,

    sd.sls_sales     AS sales_amount,
    sd.sls_quantity  AS quantity,
    sd.sls_price     AS price

FROM silver.crm_sales_details sd

LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number

LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;



/*============================================================
  STEP 7 - Reorder Columns
  Goal:
  Put columns in fact table order.

  Order:
  1. Dimension surrogate keys
  2. Dates
  3. Measures
============================================================*/

SELECT
    sd.sls_ord_num   AS order_number,

    pr.product_key,
    cu.customer_key,

    sd.sls_order_dt  AS order_date,
    sd.sls_ship_dt   AS shipping_date,
    sd.sls_due_dt    AS due_date,

    sd.sls_sales     AS sales_amount,
    sd.sls_quantity  AS quantity,
    sd.sls_price     AS price

FROM silver.crm_sales_details sd

LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number

LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;



/*============================================================
  STEP 8 - Create Gold Sales Fact View
  Goal:
  Create the final sales fact view in Gold Layer.
============================================================*/

CREATE VIEW gold.fact_sales AS

SELECT
    sd.sls_ord_num   AS order_number,

    pr.product_key,
    cu.customer_key,

    sd.sls_order_dt  AS order_date,
    sd.sls_ship_dt   AS shipping_date,
    sd.sls_due_dt    AS due_date,

    sd.sls_sales     AS sales_amount,
    sd.sls_quantity  AS quantity,
    sd.sls_price     AS price

FROM silver.crm_sales_details sd

LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number

LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;



/*============================================================
  STEP 9 - Check Gold Sales Fact View
  Goal:
  Review the final Gold sales fact view.
============================================================*/

SELECT
    *
FROM gold.fact_sales;


/*============================================================
  STEP 10 - Check Customer Dimension Connection
  Goal:
  Find sales records that do not match customer dimension.

  Expected Result:
  No rows.
============================================================*/

SELECT
    f.*
FROM gold.fact_sales f

LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key

WHERE c.customer_key IS NULL;


/*============================================================
  STEP 11 - Check Product Dimension Connection
  Goal:
  Find sales records that do not match product dimension.

  Expected Result:
  No rows.
============================================================*/

SELECT
    f.*
FROM gold.fact_sales f

LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key

WHERE p.product_key IS NULL;

