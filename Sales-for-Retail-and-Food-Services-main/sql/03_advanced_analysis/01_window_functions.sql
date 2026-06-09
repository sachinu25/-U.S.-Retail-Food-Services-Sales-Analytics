-- ============================================================================
-- PROJECT  : U.S. Retail & Food Services Sales Analysis
-- FILE     : 01_window_functions.sql
-- PURPOSE  : Demonstrate ALL major window functions with business context
-- ENGINE   : MySQL 8.0+
-- ============================================================================

USE retail_sales_db;

-- ============================================================================
-- W01: ROW_NUMBER — Assign Unique Rank to Each Business Within Industry
-- Business Use Case : Create a deterministic ranking (no ties)
-- ============================================================================
SELECT
    industry,
    kind_of_business,
    ROUND(SUM(sales), 2) AS total_sales,
    ROW_NUMBER() OVER (
        PARTITION BY industry
        ORDER BY SUM(sales) DESC
    ) AS row_num
FROM retail_sales
WHERE sales IS NOT NULL
GROUP BY industry, kind_of_business
ORDER BY industry, row_num;


-- ============================================================================
-- W02: RANK — Rank Industries by Annual Sales (Allows Ties with Gaps)
-- Business Use Case : Compare industry performance with tie awareness
-- ============================================================================
SELECT
    year,
    industry,
    ROUND(SUM(sales), 2) AS annual_sales,
    RANK() OVER (
        PARTITION BY year
        ORDER BY SUM(sales) DESC
    ) AS sales_rank
FROM retail_sales
WHERE sales IS NOT NULL
GROUP BY year, industry
ORDER BY year, sales_rank;


-- ============================================================================
-- W03: DENSE_RANK — Rank Without Gaps (Critical for Top-N Queries)
-- Business Use Case : Find top 5 businesses per year without gaps in ranking
-- ============================================================================
WITH yearly_business AS (
    SELECT
        year,
        kind_of_business,
        industry,
        ROUND(SUM(sales), 2) AS annual_sales,
        DENSE_RANK() OVER (
            PARTITION BY year
            ORDER BY SUM(sales) DESC
        ) AS dense_rnk
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY year, kind_of_business, industry
)
SELECT *
FROM yearly_business
WHERE dense_rnk <= 5
ORDER BY year, dense_rnk;


-- ============================================================================
-- W04: NTILE — Segment Industries into Quartiles by Sales
-- Business Use Case : Customer/product segmentation for tiered strategies
-- ============================================================================
WITH industry_totals AS (
    SELECT
        industry,
        ROUND(SUM(sales), 2) AS total_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY industry
)
SELECT
    industry,
    total_sales,
    NTILE(4) OVER (ORDER BY total_sales DESC) AS sales_quartile,
    CASE NTILE(4) OVER (ORDER BY total_sales DESC)
        WHEN 1 THEN 'Platinum (Top 25%)'
        WHEN 2 THEN 'Gold (25-50%)'
        WHEN 3 THEN 'Silver (50-75%)'
        WHEN 4 THEN 'Bronze (Bottom 25%)'
    END AS tier
FROM industry_totals
ORDER BY total_sales DESC;


-- ============================================================================
-- W05: LAG — Month-over-Month Sales Change for Women's Clothing (2022)
-- Business Use Case : Detect monthly sales momentum
-- ============================================================================
SELECT
    month,
    ROUND(sales, 2) AS current_sales,
    ROUND(LAG(sales, 1) OVER (ORDER BY month), 2) AS prev_month_sales,
    ROUND(sales - LAG(sales, 1) OVER (ORDER BY month), 2) AS mom_change,
    ROUND(
        (sales - LAG(sales, 1) OVER (ORDER BY month))
        / NULLIF(LAG(sales, 1) OVER (ORDER BY month), 0) * 100
    , 2) AS mom_growth_pct
FROM retail_sales
WHERE kind_of_business = 'Women''s clothing stores'
  AND year = 2022;


-- ============================================================================
-- W06: LEAD — Forecast Comparison (Actual vs Next Month)
-- Business Use Case : Prepare forward-looking comparisons for planning
-- ============================================================================
SELECT
    year,
    month,
    industry,
    ROUND(SUM(sales), 2) AS current_sales,
    ROUND(LEAD(SUM(sales), 1) OVER (
        PARTITION BY industry
        ORDER BY year, month
    ), 2) AS next_month_sales,
    ROUND(LEAD(SUM(sales), 1) OVER (
        PARTITION BY industry
        ORDER BY year, month
    ) - SUM(sales), 2) AS expected_change
FROM retail_sales
WHERE sales IS NOT NULL
  AND industry = 'Automotive'
  AND year BETWEEN 2021 AND 2022
GROUP BY year, month, industry
ORDER BY year, month;


-- ============================================================================
-- W07: FIRST_VALUE — Best Month for Each Industry (All Time)
-- Business Use Case : Identify historical peak performance month
-- ============================================================================
WITH monthly_industry AS (
    SELECT
        industry,
        year,
        month,
        ROUND(SUM(sales), 2) AS monthly_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY industry, year, month
)
SELECT DISTINCT
    industry,
    FIRST_VALUE(CONCAT(year, '-', LPAD(month, 2, '0'))) OVER (
        PARTITION BY industry
        ORDER BY monthly_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS best_month,
    FIRST_VALUE(monthly_sales) OVER (
        PARTITION BY industry
        ORDER BY monthly_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS peak_sales
FROM monthly_industry
ORDER BY peak_sales DESC;


-- ============================================================================
-- W08: LAST_VALUE — Worst Performing Month per Industry
-- Business Use Case : Identify lowest sales periods for improvement planning
-- ============================================================================
WITH monthly_industry AS (
    SELECT
        industry,
        year,
        month,
        ROUND(SUM(sales), 2) AS monthly_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY industry, year, month
)
SELECT DISTINCT
    industry,
    LAST_VALUE(CONCAT(year, '-', LPAD(month, 2, '0'))) OVER (
        PARTITION BY industry
        ORDER BY monthly_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS worst_month,
    LAST_VALUE(monthly_sales) OVER (
        PARTITION BY industry
        ORDER BY monthly_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS lowest_sales
FROM monthly_industry
ORDER BY lowest_sales ASC;


-- ============================================================================
-- W09: Running Total (Cumulative Sum) — YTD Sales per Industry per Year
-- Business Use Case : Track cumulative revenue toward annual targets
-- ============================================================================
WITH monthly_data AS (
    SELECT
        year,
        month,
        industry,
        ROUND(SUM(sales), 2) AS monthly_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY year, month, industry
)
SELECT
    year,
    month,
    industry,
    monthly_sales,
    ROUND(SUM(monthly_sales) OVER (
        PARTITION BY industry, year
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS ytd_cumulative_sales
FROM monthly_data
ORDER BY industry, year, month;


-- ============================================================================
-- W10: 3-Month Moving Average — Smooth Out Monthly Volatility
-- Business Use Case : Identify true trend direction by removing noise
-- ============================================================================
WITH monthly_data AS (
    SELECT
        year,
        month,
        industry,
        ROUND(SUM(sales), 2) AS monthly_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY year, month, industry
)
SELECT
    year,
    month,
    industry,
    monthly_sales,
    ROUND(AVG(monthly_sales) OVER (
        PARTITION BY industry
        ORDER BY year, month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3m,
    ROUND(AVG(monthly_sales) OVER (
        PARTITION BY industry
        ORDER BY year, month
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_6m
FROM monthly_data
ORDER BY industry, year, month;


-- ============================================================================
-- W11: Percent of Total — Each Industry's Share of Total Sales per Year
-- Business Use Case : Market share analysis
-- ============================================================================
WITH yearly_industry AS (
    SELECT
        year,
        industry,
        ROUND(SUM(sales), 2) AS industry_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY year, industry
)
SELECT
    year,
    industry,
    industry_sales,
    ROUND(SUM(industry_sales) OVER (PARTITION BY year), 2) AS yearly_total,
    ROUND(
        industry_sales / SUM(industry_sales) OVER (PARTITION BY year) * 100
    , 2) AS pct_of_total
FROM yearly_industry
ORDER BY year, pct_of_total DESC;


-- ============================================================================
-- W12: Window Aggregates — MIN, MAX, AVG within Partitions
-- Business Use Case : Compare each month against industry benchmarks
-- ============================================================================
WITH monthly_data AS (
    SELECT
        year,
        month,
        industry,
        ROUND(SUM(sales), 2) AS monthly_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
      AND year = 2022
    GROUP BY year, month, industry
)
SELECT
    month,
    industry,
    monthly_sales,
    ROUND(AVG(monthly_sales) OVER (PARTITION BY industry), 2) AS industry_avg,
    ROUND(MIN(monthly_sales) OVER (PARTITION BY industry), 2) AS industry_min,
    ROUND(MAX(monthly_sales) OVER (PARTITION BY industry), 2) AS industry_max,
    ROUND(monthly_sales - AVG(monthly_sales) OVER (PARTITION BY industry), 2) AS deviation_from_avg
FROM monthly_data
ORDER BY industry, month;


-- ============================================================================
-- END OF WINDOW FUNCTIONS SHOWCASE
-- ============================================================================
