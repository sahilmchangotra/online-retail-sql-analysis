# 🛒 Online Retail SQL Analysis
## SQL Case Study | Business Analytics Portfolio

### 📌 Project Overview
End-to-end SQL analysis of the Online Retail dataset (2009–2011)
covering 500K+ transactions across 40+ countries.
Performed as a structured business case study simulating
real stakeholder questions from Amazon Netherlands and Amazon India.

**Dataset:** Online Retail UCI — Combined 2009-2010 + 2010-2011  
**Tool:** PostgreSQL  
**Skills:** Advanced SQL — Window Functions, CTEs, RFM Analysis, Cohort Analysis

---

### 🛠️ Skills Demonstrated
| Skill | Details |
|---|---|
| Window Functions | RANK, DENSE_RANK, ROW_NUMBER, NTILE, LAG, LEAD |
| Conditional Aggregations | FILTER(WHERE), HAVING, rolling averages |
| CTE Design | Multi-layer CTE chains with granularity control |
| Business Analysis | RFM segmentation, cohort analysis, MoM trends |
| Debugging | Threshold analysis, NULL handling, granularity fixes |

---

### 📂 Repository Structure
| File | Description |
|---|---|
| `sql/01_customer_segmentation.sql` | Repeat vs one-time buyers, VIP identification |
| `sql/02_cohort_analysis.sql` | Monthly cohort retention grid |
| `sql/03_revenue_trends.sql` | MoM revenue, 3-month rolling average |
| `sql/04_window_functions.sql` | RANK, LAG, NTILE, FILTER practice questions |
| `sql/05_product_country_analysis.sql` | Top products per country, bulk revenue concentration |
| `insights/key_findings.md` | Business insights and analytical decisions |
| `data/data_dictionary.md` | Dataset column reference guide |

---

### 💡 Key Business Findings

**Customer Behaviour**
- 82% of customers are repeat buyers → retention over acquisition is the priority
- RFM segmentation revealed 1,470 Champion customers with avg AOV of £705
- Cohort analysis shows sharp drop from Month 0 → Month 1 → post-purchase email sequence needed within 30 days

**Revenue & Geography**
- Netherlands shows highest AOV → likely B2B buyers, wholesale strategy recommended
- UK dominates volume but Netherlands and Germany lead on order value per transaction
- Brazil's bulk revenue 23% dependent on single product (REGENCY CAKESTAND 3 TIER) → supply chain risk flagged

**Analytical Decisions Documented**
- HAVING threshold set at 20% after diagnostic analysis showed no markets exceeded 40% concentration
- DENSE_RANK chosen over RANK for bulk product analysis to correctly handle tied revenues in Saudi Arabia
- NULLS LAST added to DENSE_RANK after NULL bulk_revenue values were incorrectly ranked first

---

### 📊 Tableau Dashboard
🔗 *🔗 [View Interactive Dashboard on Tableau Public](https://public.tableau.com/app/profile/sahil.changotra/viz/shared/SXCXW4NNP)*

---

### 📁 Dataset Source
[Online Retail — Cohort Analysis and Other Stories](https://www.kaggle.com/code/olgaluzhetska/online-retail-cohort-analysis-and-other-stories)  
Period: December 2009 — December 2011