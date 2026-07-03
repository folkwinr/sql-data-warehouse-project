SELECT
id,cat,subcat,maintenance
FROM bronze.erp_px_cat_g1v2

/*============================================================
  STEP 1 - Check Category Spaces
  Goal:
  Find category values with extra spaces.
============================================================*/
SELECT
    *
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat);

/*============================================================
  STEP 2 - Check Subcategory Spaces
  Goal:
  Find subcategory values with extra spaces.
============================================================*/

SELECT
    *
FROM bronze.erp_px_cat_g1v2
WHERE subcat != TRIM(subcat);

/*============================================================
  STEP 3 - Check Maintenance Spaces
  Goal:
  Find maintenance values with extra spaces.
============================================================*/

SELECT
    *
FROM bronze.erp_px_cat_g1v2
WHERE maintenance != TRIM(maintenance);

/*============================================================
  STEP 4 - Check Category Values
  Goal:
  Show all unique category values.
============================================================*/

SELECT DISTINCT
    cat
FROM bronze.erp_px_cat_g1v2;

/*============================================================
  STEP 5 - Check Subcategory Values
  Goal:
  Show all unique subcategory values.
============================================================*/

SELECT DISTINCT
    subcat
FROM bronze.erp_px_cat_g1v2;

/*============================================================
  STEP 6 - Check Maintenance Values
  Goal:
  Show all unique maintenance values.
============================================================*/

SELECT DISTINCT
    maintenance
FROM bronze.erp_px_cat_g1v2;

/*============================================================
  STEP 7 - Final Insert Into Silver
  Goal:
  Load category data into Silver.
  No transformation is needed.
============================================================*/

INSERT INTO silver.erp_px_cat_g1v2
(
    id,
    cat,
    subcat,
    maintenance
)
SELECT
    id,
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2;

/*============================================================
  STEP 8 - Final Look at Silver Table
  Goal:
  Check final loaded category data.
============================================================*/

SELECT TOP (1000)
    *
FROM silver.erp_px_cat_g1v2;
