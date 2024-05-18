-- Q1 - Provide the list of markets in which customer "Atliq Exclusive" 
	-- operates its business in the APAC region.
SELECT 
    market
FROM
    dim_customer
WHERE
    customer = 'AtliQ Exclusive'
        AND region = 'APAC'
GROUP BY market;
        
-- ===================================================================================================================
-- Q2 - What is the percentage of unique product increase in 2021 vs. 2020? The
		-- final output contains these fields, unique_products_2020, unique_products_2021,
		-- percentage_chg

WITH cte1 AS(
SELECT COUNT(DISTINCT product_code)  AS unique_products_2020
FROM fact_sales_monthly
WHERE fiscal_year = "2020"),
cte2 AS (SELECT *,
(SELECT COUNT(DISTINCT product_code)
FROM fact_sales_monthly
WHERE fiscal_year = "2021") AS unique_products_2021
FROM cte1)
SELECT  
*, ROUND(((unique_products_2021 - unique_products_2020)/unique_products_2020)*100, 2) AS pct_change
FROM cte2;

-- =========================================================================================================================
-- Q3 - Provide a report with all the unique product counts for each segment and
		-- sort them in descending order of product counts. The final output contains
        -- 2 fields,
        -- segment, product_count

SELECT DISTINCT
    segment, COUNT(product) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- ==========================================================================================================================
-- Q4 - Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
		-- The final output contains these fields
        -- segment, product_count_2020, product_count_2021, difference

WITH cte1 AS (
SELECT
	 p.segment, COUNT(DISTINCT product_code) AS unique_product2020
FROM fact_sales_monthly s
JOIN dim_product p
USING ( product_code)
WHERE fiscal_year = "2020"
GROUP BY segment),
cte2 AS (
SELECT
	p.segment, COUNT(DISTINCT product_code) AS unique_product2021
FROM fact_sales_monthly s
JOIN dim_product p
USING ( product_code)
WHERE fiscal_year = "2021"
GROUP BY segment),
cte3 AS (
SELECT
	p20.segment, p20.unique_product2020 AS product_cnt_2020, p21.unique_product2021 AS product_cnt2021
FROM cte1 p20
JOIN cte2 p21
USING (segment))
SELECT *, (product_cnt2021 - product_cnt_2020) AS difference
FROM cte3
ORDER BY difference DESC;

-- ==========================================================================================================================
-- Q5 -Get the products that have the highest and lowest manufacturing costs.
	-- The final output should contain these fields,
    -- product_code, product, manufacturing_cost.

SELECT p.product, p.product_code, m.manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost m 
USING (product_code)
WHERE m.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
   OR m.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;

-- ==========================================================================================================================
-- Q6 -Generate a report which contains the top 5 customers who received an
	-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
	-- Indian market. The final output contains these fields
	-- customer_code, customer, average_discount_percentage.
    
SELECT c.customer_code, c.customer,
	ROUND(AVG(f.pre_invoice_discount_pct)*100,2) AS avg_discount_pct
FROM dim_customer c
JOIN fact_pre_invoice_deductions f
USING (customer_code)
WHERE fiscal_year = "2021" AND market = "India"
GROUP BY customer_code, customer
ORDER BY avg_discount_pct DESC
LIMIT 5;

-- ==========================================================================================================================
-- Q7 - Get the complete report of the Gross sales amount for the customer “Atliq
	-- Exclusive” for each month. This analysis helps to get an idea of low and
	-- high-performing months and take strategic decisions.
	-- The final report contains these columns:
    -- Month, Year, Gross sales Amount.

SELECT monthname(s.date) AS Month, YEAR(s.date) AS Year,
	CONCAT(ROUND(SUM(g.gross_price*s.sold_quantity)/1000000,2), "M") AS Gross_Sales_Amt
FROM fact_gross_price g
JOIN fact_sales_monthly s
ON g.product_code = s.product_code
	AND g.fiscal_year = s.fiscal_year
JOIN dim_customer c
ON s.customer_code = c.customer_code
WHERE customer = "Atliq Exclusive"
GROUP BY Month, Year
ORDER BY Year;

-- ==========================================================================================================================
-- Q8 -In which quarter of 2020, got the maximum total_sold_quantity? The final
	-- output contains these fields sorted by the total_sold_quantity,
	-- Quarter, total_sold_quantity
	-- hint : derive the Month from the date and assign a Quarter. Note that fiscal_year
	-- for Atliq Hardware starts from September(09)

SELECT CONCAT("Q", QUARTER(DATE_ADD(date, INTERVAL 4 MONTH))) AS Quarter,
	SUM(sold_quantity) AS total_sold_qty
FROM fact_sales_monthly
WHERE fiscal_year = "2020"
GROUP BY Quarter
ORDER BY total_sold_qty DESC;

-- ==========================================================================================================================
-- Q9 -Which channel helped to bring more gross sales in the fiscal year 2021
	-- and the percentage of contribution? The final output contains these fields,
	-- channel, gross_sales_mln, percentage.

WITH cte AS(
	SELECT CONCAT(ROUND(SUM(s.sold_quantity * g.gross_price) / 1000000, 2), ' M') AS gross_sales_mln, c.channel
	FROM fact_sales_monthly s
    JOIN fact_gross_price g
    ON s.product_code = g.product_code
		AND s.fiscal_year = g.fiscal_year
	JOIN dim_customer c
    ON c.customer_code = s.customer_code
    WHERE s.fiscal_year = '2021'
    GROUP BY channel)
SELECT channel,
    gross_sales_mln,
    ROUND(gross_sales_mln / SUM(gross_sales_mln) OVER() * 100, 2) AS Percentage
FROM cte
ORDER BY Percentage DESC;

-- ==========================================================================================================================
-- Q10 -Get the Top 3 products in each division that have a high
	-- total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
	-- division, product_code, product, total_sold_quantity, rank_order.

WITH cte1 AS (
	SELECT p.division, p.product_code, p.product,
    SUM(s.sold_quantity) AS total_sold_quantity
    FROM dim_product p
    JOIN fact_sales_monthly s
    USING (product_code)
    WHERE fiscal_year = '2021'
    GROUP BY p.division,
            p.product_code,
            p.product),
cte2 AS (
	SELECT *, DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
	FROM cte1)
SELECT * FROM cte2
WHERE rank_order <= 3;