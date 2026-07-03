/*============================================================
  STEP - Final Insert Into Silver
  Goal:
  Load cleaned product data into silver.crm_prd_info.
============================================================*/

INSERT INTO silver.crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT
    prd_id,

    -- Create Category ID
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,

    -- Create Product Key
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,

    -- Clean Product Name
    TRIM(prd_nm) AS prd_nm,

    -- Replace NULL cost with 0
    ISNULL(prd_cost, 0) AS prd_cost,

    -- Standardize Product Line
    CASE UPPER(TRIM(prd_line))
        WHEN 'M' THEN 'Mountain'
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,

    -- Keep only date
    CAST(prd_start_dt AS DATE) AS prd_start_dt,

    -- Create clean End Date
    CAST(
        DATEADD(
            DAY,
            -1,
            LEAD(prd_start_dt) OVER (
                PARTITION BY prd_key
                ORDER BY prd_start_dt
            )
        ) AS DATE
    ) AS prd_end_dt

FROM bronze.crm_prd_info;
