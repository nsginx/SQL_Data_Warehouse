/* ============================================================
   SILVER LAYER - DATA QUALITY CHECKS
   ============================================================ */


PRINT '=============================================================';
PRINT 'STARTING SILVER LAYER DATA QUALITY CHECKS';
PRINT '=============================================================';


/* ============================================================
   CRM CUSTOMER INFO
   ============================================================ */

PRINT '';
PRINT '-------------------------------------------------------------';
PRINT 'CHECKING CRM CUSTOMER INFO';
PRINT '-------------------------------------------------------------';

PRINT 'Checking record count...';

SELECT COUNT(*)
FROM silver.crm_cust_info;

PRINT 'Checking for duplicate customer IDs...';

-- CHECKING FOR DUPLICACY
SELECT
    cst_id,
    COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(cst_id) > 1;

PRINT 'Checking customer gender values...';

-- CHECKING FOR DATA TYPES / DISTINCT VALUES
SELECT DISTINCT
    cst_gndr
FROM silver.crm_cust_info;

PRINT 'Checking for whitespace in customer last names...';

-- CHECKING FOR WHITESPACE
SELECT *
FROM silver.crm_cust_info
WHERE TRIM(cst_lastname) != cst_lastname;


/* ============================================================
   CRM PRODUCT INFO
   ============================================================ */

PRINT '';
PRINT '-------------------------------------------------------------';
PRINT 'CHECKING CRM PRODUCT INFO';
PRINT '-------------------------------------------------------------';

PRINT 'Checking for duplicate product IDs...';

-- CHECKING FOR DUPLICACY
SELECT
    prd_id,
    COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(prd_id) > 1;

PRINT 'Checking for whitespace in product names...';

-- CHECKING FOR WHITESPACE
SELECT *
FROM silver.crm_prd_info
WHERE TRIM(prd_nm) != prd_nm;

PRINT 'Checking for NULL values in product cost...';

-- CHECKING FOR NULL VALUE IN COST
SELECT *
FROM silver.crm_prd_info
WHERE prd_cost IS NULL;

PRINT 'Checking product line standardisation...';

-- STANDARDISATION
SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info;

PRINT 'Checking for NULL product start dates...';

-- CHECKING DATES
SELECT *
FROM silver.crm_prd_info
WHERE prd_start_dt IS NULL;

PRINT 'Checking for invalid product date ranges...';

SELECT *
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt;


/* ============================================================
   CRM SALES DETAILS
   ============================================================ */

PRINT '';
PRINT '-------------------------------------------------------------';
PRINT 'CHECKING CRM SALES DETAILS';
PRINT '-------------------------------------------------------------';

PRINT 'Displaying sales details...';

SELECT *
FROM silver.crm_sales_details;

PRINT 'Checking for invalid product keys...';

-- CHECKING PRODUCT REFERENTIAL INTEGRITY
SELECT *
FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN (
    SELECT prd_key
    FROM silver.crm_prd_info
);

PRINT 'Checking for invalid customer IDs...';

-- CHECKING CUSTOMER REFERENTIAL INTEGRITY
SELECT *
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (
    SELECT cst_id
    FROM silver.crm_cust_info
);



PRINT 'Checking due dates...';

-- CHECKING FOR NULL DUE DATES
SELECT *
FROM silver.crm_sales_details
WHERE sls_due_dt IS NULL;

-- CHECKING FOR FUTURE DUE DATES
SELECT *
FROM silver.crm_sales_details
WHERE sls_due_dt > GETDATE();

PRINT 'Checking sales, price and quantity consistency...';

-- CHECKING SALES, PRICE AND QUANTITY CONSISTENCY
SELECT DISTINCT
    sls_price AS old_sls_price,
    sls_sales AS old_sls_sales,
    sls_quantity,

    CASE
        WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price,

    CASE
        WHEN sls_sales IS NULL
          OR sls_sales <= 0
          OR sls_quantity * ABS(sls_price) != sls_sales
            THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales

FROM silver.crm_sales_details
WHERE sls_price * sls_quantity != sls_sales
   OR sls_price <= 0
   OR sls_quantity <= 0
   OR sls_sales <= 0
   OR sls_price IS NULL
   OR sls_quantity IS NULL
   OR sls_sales IS NULL;


/* ============================================================
   ERP CUSTOMER
   ============================================================ */

PRINT '';
PRINT '-------------------------------------------------------------';
PRINT 'CHECKING ERP CUSTOMER';
PRINT '-------------------------------------------------------------';

PRINT 'Checking customer ID referential integrity...';

-- CHECKING REFERENTIAL INTEGRITY
SELECT
    cid
FROM silver.erp_cust_az12
WHERE cid NOT IN (
    SELECT cst_key
    FROM silver.crm_cust_info
);

PRINT 'Checking for future birth dates...';

-- CHECKING BIRTH DATES
SELECT
    bdate
FROM silver.erp_cust_az12
WHERE bdate > GETDATE();

PRINT 'Checking gender standardisation...';

-- CHECKING DATA CONSISTENCY
SELECT DISTINCT
    gen
FROM silver.erp_cust_az12;


/* ============================================================
   ERP LOCATION
   ============================================================ */

PRINT '';
PRINT '-------------------------------------------------------------';
PRINT 'CHECKING ERP LOCATION';
PRINT '-------------------------------------------------------------';

PRINT 'Checking customer ID referential integrity...';

-- CHECKING REFERENTIAL INTEGRITY
SELECT DISTINCT
    cid
FROM silver.erp_loc_a101
WHERE cid NOT IN (
    SELECT cst_key
    FROM silver.crm_cust_info
);

PRINT 'Checking country standardisation...';

-- CHECKING DATA CONSISTENCY
SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101;


/* ============================================================
   ERP PRODUCT CATEGORY
   ============================================================ */

PRINT '';
PRINT '-------------------------------------------------------------';
PRINT 'CHECKING ERP PRODUCT CATEGORY';
PRINT '-------------------------------------------------------------';

PRINT 'Displaying product category data...';

SELECT *
FROM silver.erp_px_cat_g1v2;

PRINT 'Checking for whitespace...';

-- CHECKING FOR WHITESPACE
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat)
   OR subcat != TRIM(subcat)
   OR maintenance != TRIM(maintenance);

PRINT 'Checking category consistency...';

-- CHECKING DATA CONSISTENCY
SELECT DISTINCT
    cat
FROM silver.erp_px_cat_g1v2;

PRINT 'Checking subcategory consistency...';

SELECT DISTINCT
    subcat
FROM silver.erp_px_cat_g1v2;

PRINT 'Checking maintenance consistency...';

SELECT DISTINCT
    maintenance
FROM silver.erp_px_cat_g1v2;


/* ============================================================
   COMPLETION
   ============================================================ */

PRINT '';
PRINT '=============================================================';
PRINT 'SILVER LAYER DATA QUALITY CHECKS COMPLETED';
PRINT '=============================================================';
