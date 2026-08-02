-- cleaning the raw data - dropping rows with no customer id, cancelled orders (invoice starts with C), 
-- and bad qty/price values. this brought it down from 1067371 to 805549 rows
/*
SELECT *, (Quantity*Price) AS amount
INTO retail_clean
FROM retail
WHERE Customer_ID IS NOT NULL
AND Quantity>0
AND Price>0
AND Invoice NOT LIKE 'C%'
*/

-- building RFM now. using dataset's last invoice date as "today" since this is old data (2009-2011),
-- cant use actual current date or everyone looks churned
-- recency = days since last order, frequency = distinct orders, monetary = total spend
/*
WITH rfm AS (
    SELECT 
    Customer_ID,
    MAX(InvoiceDate) AS last_order,
    DATEDIFF(DAY, MAX(InvoiceDate), (SELECT MAX(InvoiceDate) From retail_clean)) AS Days_Since_Last_Order,
    COUNT(DISTINCT Invoice) AS Frequency,
    ROUND(SUM(Quantity*Price),2) AS Monetary
    FROM retail_clean
    GROUP BY Customer_ID
),
-- scoring 1-5 using NTILE. recency is reversed bc recent buyer = good = high score
rfm_scored AS (
    SELECT *,
    NTILE(5) OVER (Order by Days_Since_Last_Order DESC) AS r_score,
    NTILE(5) OVER (Order by Frequency ASC) AS f_score,
    NTILE(5) OVER (Order by Monetary ASC) AS m_score
    FROM rfm
)
-- adding up scores + labeling segments. also flagging churn if no order in 90+ days
SELECT *,
    (r_score+f_score+m_score) AS rfm_Score,
    CASE 
        WHEN (r_score+f_score+m_score)>=13 THEN 'Champions'
        WHEN (r_score+f_score+m_score)>=10 THEN 'Loyal'
        WHEN (r_score+f_score+m_score)>=7 THEN 'At Risk'
        ELSE 'Lost'
    END AS Segment,
    CASE WHEN Days_Since_Last_Order > 90 THEN 1 ELSE 0 END AS is_churned
INTO rfm_finall
FROM rfm_scored
*/

-- quick check on segment numbers
SELECT Segment, COUNT(*) AS Customer_count, SUM(Monetary) AS Segment_Revenue
FROM rfm_finall
GROUP BY Segment
Order BY Segment_Revenue DESC;

-- Champions are only ~22% of customers but ~68% of revenue. Loyal segment decent size too.
-- At Risk (1580 people) is the real opportunity - catch them before they become Lost

--Month over Month Revenue Growth
WITH monhly_revenue AS(
Select 
Format(InvoiceDate,'yyyy-MM') AS month,
SUM(amount) AS revenue
From retail_clean
GROUP BY Format(InvoiceDate,'yyyy-MM')
)
SELECT month,revenue,
LAG(revenue)over(Order by month) AS prev_month_revenue,
ROUND((revenue-lag(revenue) over(order by month))*100/Lag(revenue)over(order by month),2) AS growth_perc
FROM monhly_revenue
ORDER BY month


-- 2. year over year, same month diff year
SELECT MONTH(InvoiceDate) AS month_num, YEAR(InvoiceDate) AS year, SUM(amount) AS revenue
FROM retail_clean
GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY month_num, year;

-- 3. cumulative revenue over time
SELECT FORMAT(InvoiceDate,'yyyy-MM') AS month, SUM(amount) AS monthly_revenue,
    SUM(SUM(amount)) OVER (ORDER BY FORMAT(InvoiceDate,'yyyy-MM') ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
FROM retail_clean GROUP BY FORMAT(InvoiceDate,'yyyy-MM');

-- 4. which day of week brings most revenue
SELECT DATENAME(WEEKDAY, InvoiceDate) AS day_of_week, SUM(amount) AS revenue, COUNT(DISTINCT Invoice) AS orders
FROM retail_clean GROUP BY DATENAME(WEEKDAY, InvoiceDate)
ORDER BY revenue DESC;


--CATEGORY B - retention 

-- 5. repeat purchase rate - how many customers ever buy more than once
SELECT COUNT(CASE WHEN Frequency > 1 THEN 1 END) * 100.0 / COUNT(*) AS repeat_purchase_rate_perc
FROM rfm_finall;

-- CATEGORY C - segment deep dives

-- 6. country x segment breakdown
SELECT r.Country, f.Segment, COUNT(*) AS customer_count, SUM(f.Monetary) AS revenue
FROM rfm_finall f
JOIN (SELECT DISTINCT Customer_ID, Country FROM retail_clean) r ON f.Customer_ID = r.Customer_ID
GROUP BY r.Country, f.Segment ORDER BY r.Country, revenue DESC;

-- 7. top products bought by champions
SELECT TOP 10 rc.Description, SUM(rc.amount) AS revenue_from_champions
FROM retail_clean rc JOIN rfm_finall f ON rc.Customer_ID = f.Customer_ID
WHERE f.Segment = 'Champions'
GROUP BY rc.Description ORDER BY revenue_from_champions DESC;

-- 8. avg order value by segment
SELECT Segment, ROUND(AVG(Monetary/Frequency),2) AS avg_order_value
FROM rfm_finall GROUP BY Segment ORDER BY avg_order_value DESC;

-- 9. percentile ranking - splitting customers into 100 buckets by spend
SELECT Customer_ID, Monetary, NTILE(100) OVER (ORDER BY Monetary) AS percentile_rank
FROM rfm_finall;

-- 10. revenue share of top 1% customers
WITH ranked AS (
    SELECT Customer_ID, Monetary, NTILE(100) OVER (ORDER BY Monetary DESC) AS pct_rank FROM rfm_finall
)
SELECT SUM(CASE WHEN pct_rank = 1 THEN Monetary ELSE 0 END) * 100.0 / SUM(Monetary) AS top1pct_revenue_share
FROM ranked;

-- ============================================================
-- CATEGORY D - product & operational
-- ============================================================

-- 11. top 10 best sellers overall
SELECT TOP 10 Description, SUM(Quantity) AS units_sold, SUM(amount) AS revenue
FROM retail_clean GROUP BY Description ORDER BY revenue DESC;

-- 12. revenue per customer by country - efficiency not just total volume
SELECT Country, SUM(amount)/COUNT(DISTINCT Customer_ID) AS revenue_per_customer
FROM retail_clean GROUP BY Country
ORDER BY revenue_per_customer DESC;

-- ============================================================
-- CATEGORY E - data quality check
-- ============================================================

-- 13. biggest single line-item orders - checking for outliers/errors
SELECT TOP 20 Invoice, Customer_ID, Description, Quantity, Price, amount
FROM retail_clean ORDER BY amount DESC;
