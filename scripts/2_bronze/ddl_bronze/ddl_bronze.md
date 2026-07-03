# 🥉 Bronze Layer - `load_bronze` Procedure Structure

```text
📦 Stored Procedure
(bronze.load_bronze)
│
├── 🟦 BEGIN
│
├── 📋 DECLARE
│     │
│     ├── ⏱️ @start_time
│     ├── ⏱️ @end_time
│     ├── ⏳ @batch_start_time
│     └── ⏳ @batch_end_time
│
├── 🟢 BEGIN TRY
│     │
│     ├── ⏰ Batch Start Time
│     │      └── SET @batch_start_time
│     │
│     ├── 🖨️ PRINT
│     │      └── Loading Bronze Layer
│     │
│     ├── 🥉 CRM TABLES
│     │      │
│     │      ├── 👥 crm_cust_info
│     │      │      ├── ⏰ Start Time
│     │      │      ├── 🗑️ TRUNCATE
│     │      │      ├── 📥 BULK INSERT
│     │      │      ├── ⏰ End Time
│     │      │      └── 🖨️ Print Duration
│     │      │
│     │      ├── 📦 crm_prd_info
│     │      │      ├── ⏰ Start Time
│     │      │      ├── 🗑️ TRUNCATE
│     │      │      ├── 📥 BULK INSERT
│     │      │      ├── ⏰ End Time
│     │      │      └── 🖨️ Print Duration
│     │      │
│     │      └── 💰 crm_sales_details
│     │             ├── ⏰ Start Time
│     │             ├── 🗑️ TRUNCATE
│     │             ├── 📥 BULK INSERT
│     │             ├── ⏰ End Time
│     │             └── 🖨️ Print Duration
│     │
│     ├── 🥉 ERP TABLES
│     │      │
│     │      ├── 🌍 erp_loc_a101
│     │      │      ├── ⏰ Start Time
│     │      │      ├── 🗑️ TRUNCATE
│     │      │      ├── 📥 BULK INSERT
│     │      │      ├── ⏰ End Time
│     │      │      └── 🖨️ Print Duration
│     │      │
│     │      ├── 👤 erp_cust_az12
│     │      │      ├── ⏰ Start Time
│     │      │      ├── 🗑️ TRUNCATE
│     │      │      ├── 📥 BULK INSERT
│     │      │      ├── ⏰ End Time
│     │      │      └── 🖨️ Print Duration
│     │      │
│     │      └── 🏷️ erp_px_cat_g1v2
│     │             ├── ⏰ Start Time
│     │             ├── 🗑️ TRUNCATE
│     │             ├── 📥 BULK INSERT
│     │             ├── ⏰ End Time
│     │             └── 🖨️ Print Duration
│     │
│     ├── ⏰ Batch End Time
│     │      └── SET @batch_end_time
│     │
│     └── 🖨️ Success Message
│            └── Total Load Duration
│
├── 🔴 BEGIN CATCH
│     │
│     ├── ❌ ERROR_MESSAGE()
│     ├── 🔢 ERROR_NUMBER()
│     ├── 📍 ERROR_STATE()
│     └── 🖨️ Print Error
│
└── 🟦 END
```
