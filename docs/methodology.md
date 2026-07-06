# Methodology

This project follows a layered data warehouse approach based on the **Medallion Architecture (Bronze → Silver → Gold)**. The goal is to move raw operational data into a clean, trusted, and business-ready analytical model.

The development process is divided into six main stages.

---

## 1. Understand the Source Data

The project starts with two operational systems:

- **CRM** – Customer, product, and sales data
- **ERP** – Customer demographics, locations, and product categories

Before building the ETL pipeline, the source data was explored to understand:

- Table structures
- Relationships between datasets
- Data quality issues
- Business meaning of each table
- Integration points between CRM and ERP

This step helps define the transformations needed in the following layers.

---

## 2. Build the Bronze Layer

The Bronze layer acts as the landing zone for all source data.

Its purpose is to preserve the original data exactly as it arrives from the source systems.

### Main activities

- Create Bronze tables
- Load CSV files using `BULK INSERT`
- Apply a full-load strategy
- Truncate tables before each reload
- Track load duration
- Handle loading errors with `TRY...CATCH`

No business logic or transformations are applied at this stage.

---

## 3. Build the Silver Layer

The Silver layer focuses on improving data quality and preparing the data for analytics.

Raw Bronze data is cleaned, standardized, and validated before moving to the final analytical layer.

### Main transformations

- Remove duplicate customer records
- Keep the latest customer information
- Trim unwanted spaces
- Standardize gender, marital status, country, and product line values
- Clean ERP customer IDs
- Split product keys into category IDs and product numbers
- Manage product history using start and end dates
- Convert integer dates into SQL `DATE`
- Correct sales calculations using business rules
- Add `dwh_create_date` for warehouse auditing

The result is a consistent and reliable dataset that can safely be used for reporting.

---

## 4. Validate Data Quality

After the Silver layer is loaded, validation queries are executed to verify the transformed data.

The checks include:

- Duplicate records
- Missing values
- Extra spaces
- Invalid date ranges
- Incorrect date sequences
- Invalid or missing costs
- Sales calculation consistency
- Relationships between related tables

> **Expected result:** Most quality check queries should return **zero rows**, indicating that no data quality issues were found.

---

## 5. Build the Gold Layer

The Gold layer delivers the final analytical model.

Instead of storing additional tables, this layer exposes SQL **Views** built on top of the clean Silver data.

The final model follows a **Star Schema**.

| View | Type | Purpose |
|------|------|---------|
| `gold.dim_customers` | Dimension | Customer profiles and demographics |
| `gold.dim_products` | Dimension | Product and category information |
| `gold.fact_sales` | Fact | Sales transactions and business measures |

### Business Rules

Several business rules are applied while building the Gold layer:

- CRM is the primary source for customer and product data.
- ERP enriches customer and product information.
- CRM gender has priority over ERP gender.
- ERP gender is used only when CRM data is unavailable.
- Only active products are included in the product dimension.
- Surrogate keys are generated in the Gold views using `ROW_NUMBER()` to support dimensional modeling.

---

## 6. Validate the Final Model

After the Gold views are created, the final analytical model is validated.

The validation includes:

- Surrogate key uniqueness
- Dimension key uniqueness
- Fact-to-dimension relationships
- Sales measure consistency

These checks ensure the data warehouse is ready for reporting and Business Intelligence tools.

---

## Workflow Overview

```text
Understand Source Data
        │
        ▼
Build Bronze Layer
        │
        ▼
Build Silver Layer
        │
        ▼
Validate Data Quality
        │
        ▼
Build Gold Views
        │
        ▼
Validate Final Model
        │
        ▼
Reporting & Business Intelligence
```
