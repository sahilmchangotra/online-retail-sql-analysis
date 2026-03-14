# 📁 Data Dictionary
## Online Retail Dataset — 2009-2011

**Source:** UCI Machine Learning Repository via Kaggle
**Link:** https://www.kaggle.com/code/olgaluzhetska/online-retail-cohort-analysis-and-other-stories
**Combined:** 2009-2010 + 2010-2011 datasets merged into single table

---

## Table: online_retail

| Column | Type | Description | Notes |
|---|---|---|---|
| `invoice` | VARCHAR | Unique invoice number | Prefix 'C' = cancellation |
| `stockcode` | VARCHAR | Unique product code | Use with description for dedup |
| `description` | VARCHAR | Product name | Can vary for same stockcode |
| `quantity` | INTEGER | Units purchased | Negative = return/cancellation |
| `invoice_timestamp` | TIMESTAMP | Date and time of transaction | Used for cohort + trend analysis |
| `price_numeric` | DECIMAL | Unit price in GBP (£) | Multiply by quantity for revenue |
| `customer_id` | VARCHAR | Unique customer identifier | Nullable — exclude NULLs in analysis |
| `country` | VARCHAR | Customer's country | 40+ countries in dataset |

---

## Key Filters Used Consistently
```sql
WHERE customer_id IS NOT NULL   -- exclude guest/anonymous transactions
  AND quantity > 0              -- exclude returns and cancellations
```

---

## Derived Metrics

| Metric | Formula | Used In |
|---|---|---|
| Revenue | `quantity * price_numeric` | All analysis |
| AOV | `total_revenue / COUNT(DISTINCT invoice)` | Segmentation, country analysis |
| Recency | `ref_date - MAX(DATE(invoice_timestamp))` | RFM analysis |
| Frequency | `COUNT(DISTINCT invoice)` | RFM analysis |
| Monetary | `SUM(quantity * price_numeric)` | RFM analysis |
| Month Number | `(YEAR diff * 12) + MONTH diff` | Cohort analysis |
| Cohort Month | `TO_CHAR(MIN(invoice_timestamp), 'YYYY-MM')` | Cohort analysis |