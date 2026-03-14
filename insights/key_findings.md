# 💡 Key Findings & Analytical Decisions
## Online Retail SQL Case Study — 2009-2011

---

## 👥 Customer Behaviour

### Repeat vs One-Time Buyers
- **82% of customers are repeat buyers**
- Only 18% make a single purchase and never return
- **Business Action:** Retention strategy should be prioritised
  over new customer acquisition campaigns

### Cohort Retention
- Sharp drop from Month 0 → Month 1 across all cohorts
- Customers acquired in Dec 2009 show best long-term retention
- **Business Action:** Post-purchase email sequence needed
  within first 30 days to improve early retention

### RFM Segmentation Results
| Segment | Customers | Avg AOV |
|---|---|---|
| Champion | 1,470 | £705 |
| Loyal | 1,470 | £397 |
| At Risk | 1,470 | £297 |
| Churned | 1,471 | £165 |

- **Key Insight:** Even Churned customers average £165 AOV
  → these are dormant high-potential buyers, not lost causes
  → winback campaigns justified across all segments

---

## 🌍 Geography & Revenue

### Country Revenue Analysis
- UK dominates on volume — expected for UK-based retailer
- **Netherlands shows highest AOV** despite fewer orders
  → likely B2B/wholesale buyers
- **Business Action:** Netherlands campaigns should target
  wholesale and gifting segments, not mass discount offers

### Bulk Revenue Concentration Risk
| Country | Top Product | Bulk % of Country Revenue |
|---|---|---|
| Nigeria | 60 TEATIME FAIRY CAKE CASES | 38.6% |
| West Indies | BOX OF 9 PEBBLE CANDLES | 29.0% |
| Saudi Arabia | PLASTERS IN TIN (3 products) | 24.2% |
| Brazil | REGENCY CAKESTAND 3 TIER | 23.2% |

- **Most Actionable:** Brazil — £754 total revenue with 23%
  driven by single product → supply chain risk
- **Business Action:** Diversify Brazil product mix,
  ensure REGENCY CAKESTAND stock continuity

---

## 📈 Revenue Trends

### Monthly Seasonality
- Q4 months (Oct-Dec) show consistent revenue spikes
- November and December are peak trading months
- 3-month rolling average reveals steady underlying growth
  beneath seasonal spikes

### Month-over-Month Analysis
- Largest MoM drops occur in January — post-holiday effect
- **Business Action:** January retention campaign needed
  to smooth post-Q4 revenue dip

---

## 🔬 Analytical Decisions Documented

### HAVING Threshold — 40% → 20%
- **Initial threshold:** 40% bulk revenue concentration
- **Problem:** Zero results returned
- **Diagnostic steps taken:**
  1. Checked `rows_with_qty_over_10` = 250,474 / 805,620 rows
  2. Found `DENSE_RANK` ordering NULLs first by default
  3. Added `NULLS LAST` + pre-filter `WHERE bulk_revenue > 0`
  4. Re-ran with 20% threshold → 6 meaningful results
- **Decision:** 20% chosen based on actual data distribution
- **Learning:** Always run diagnostic queries before
  assuming data has no results

### DENSE_RANK vs RANK — Saudi Arabia Case
- **Problem:** Saudi Arabia showed 3 products at rank 1
- **Why DENSE_RANK was correct:**
  - Three PLASTERS IN TIN variants had identical bulk revenue
  - `RANK()` would create gaps (1, 1, 1, 4) hiding products
  - `DENSE_RANK()` correctly surfaces all tied products
- **Rule:** Use `DENSE_RANK` when ties are meaningful
  and gaps should be avoided

### NULLS LAST — Bulk Revenue Ranking Fix
- **Problem:** Products with NULL bulk revenue
  were ranked first by default
- **Fix:** `ORDER BY bulk_revenue DESC NULLS LAST`
- **Learning:** Always consider NULL behaviour in
  ORDER BY clauses, especially with window functions

---

## 🎓 SQL Lessons Learned

| Lesson | Detail |
|---|---|
| Granularity rule | Always define: one row = one WHAT before writing GROUP BY |
| Window + GROUP BY | Cannot mix in same SELECT — separate into next CTE |
| LAG() granularity | Apply only after data is at correct granularity |
| FILTER(WHERE) | Replaces multiple subqueries — cleaner and faster |
| NULLIF() | Always wrap denominators: `NULLIF(value, 0)` |
| RANK vs ROW_NUMBER | RANK for honest ties,