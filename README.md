[E-Commerce_customer_churn.sql](https://github.com/user-attachments/files/30632366/E-Commerce_customer_churn.sql)# E-Commerce Customer Churn & Revenue Analytics

## Overview
RFM-based customer segmentation and churn analysis on a UK-based online 
retailer's transaction data (Dec 2009 – Dec 2011). Cleaned 1.07M raw 
transaction records down to 805K valid rows, analyzed 5,878 unique customers.

## Tech Stack
- **SQL Server** — data cleaning, RFM modeling, window functions, exploratory analysis
- **Power BI** — interactive dashboard and visualization

## Process
1. **Data Cleaning** — removed rows with missing customer IDs, cancelled orders, 
   and invalid quantity/price values (1,067,371 → 805,549 rows)
2. **RFM Modeling** — calculated Recency, Frequency, and Monetary metrics per 
   customer using `GROUP BY`, `DATEDIFF`, `COUNT DISTINCT`
3. **Scoring & Segmentation** — scored each customer 1–5 on R/F/M using `NTILE()`, 
   classified into Champions / Loyal / At Risk / Lost via `CASE WHEN`
4. **Churn Flagging** — flagged customers inactive 90+ days as churned
5. **Exploratory Analysis** — 13 SQL queries covering revenue trends, retention, 
   segment-level product behavior, and data quality checks (CTEs, `LAG()`, 
   self-joins, `NTILE()` percentile ranking)
6. **Dashboard** — interactive Power BI report: 5 KPIs, 7 visualizations, 
   segment/country slicers, and a dedicated insights summary page

## Key Insights
- **Champions** (22% of customers) generate **~72% of total revenue**
- Churn rate rises consistently across segments: **5.3% → 34.6% → 54.4% → 96.2%**, 
  validating the segmentation model
- Revenue peaks in **Q4 (Sep–Nov)**, consistent with holiday shopping seasonality
- Overall churn rate: **50.85%**
- **$1.27M in revenue is tied to "At Risk" customers** — the highest-priority 
  re-engagement segment

## Dashboard Preview
<img width="913" height="549" alt="Screenshot 2026-08-02 183427" src="https://github.com/user-attachments/assets/eb13e408-dab2-42f0-bfb1-ecf7d9c25f32" />
<img width="906" height="504" alt="Screenshot 2026-08-02 183339" src="https://github.com/user-attachments/assets/960d7f6a-5a9c-4353-81bf-d708f0006ace" />

[Online Retail II — UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/datasets/Online+Retail+II)
