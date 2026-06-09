-- ============================================================================
-- PROJECT  : U.S. Retail & Food Services Sales Analysis
-- FILE     : 01_exploratory_analysis.sql
-- PURPOSE  : Foundational business questions — aggregations, filtering, pivots
-- ENGINE   : MySQL 8.0+
-- ============================================================================

USE retail_sales_db;

-- ============================================================================
-- Q01: Dataset Overview — Row Count, Date Range, Industry Count
-- Business Use Case : Data validation before any analysis
-- Complexity        : Basic
-- ============================================================================
SELECT
    COUNT(*)                                    AS total_records,
    COUNT(DISTINCT industry)                    AS unique_industries,
    COUNT(DISTINCT kind_of_business)            AS unique_businesses,
    COUNT(DISTINCT naics_code)                  AS unique_naics_codes,
    MIN(year)                                   AS earliest_year,
    MAX(year)                                   AS latest_year,
    ROUND(SUM(sales), 2)                        AS total_sales_millions,
    ROUND(AVG(sales), 2)                        AS avg_monthly_sales,
    SUM(CASE WHEN sales IS NULL THEN 1 ELSE 0 END) AS null_sales_count
FROM retail_sales;


-- ============================================================================
-- Q02: Total Sales by Industry (All Time)
-- Business Use Case : Identify which industries drive the most revenue
-- Complexity        : Basic (GROUP BY + ORDER BY)
-- ============================================================================
SELECT
    industry,
    COUNT(DISTINCT kind_of_business)            AS business_count,
    ROUND(SUM(sales), 2)                        AS total_sales,
    ROUND(AVG(sales), 2)                        AS avg_monthly_sales,
    ROUND(MIN(sales), 2)                        AS min_sales,
    ROUND(MAX(sales), 2)                        AS max_sales
FROM retail_sales
WHERE sales IS NOT NULL
GROUP BY industry
ORDER BY total_sales DESC;


-- ============================================================================
-- Q03: Top 10 Business Types by Total Sales
-- Business Use Case : Pinpoint the highest-revenue business categories
-- Complexity        : Basic (GROUP BY + LIMIT)
-- ============================================================================
SELECT
    kind_of_business,
    industry,
    ROUND(SUM(sales), 2)                        AS total_sales,
    COUNT(*)                                     AS months_reported
FROM retail_sales
WHERE sales IS NOT NULL
GROUP BY kind_of_business, industry
ORDER BY total_sales DESC
LIMIT 10;


-- ============================================================================
-- Q04: Bottom 10 Business Types by Total Sales
-- Business Use Case : Identify underperforming or niche segments
-- Complexity        : Basic
-- ============================================================================
SELECT
    kind_of_business,
    industry,
    ROUND(SUM(sales), 2)                        AS total_sales,
    COUNT(*)                                     AS months_reported
FROM retail_sales
WHERE sales IS NOT NULL
GROUP BY kind_of_business, industry
ORDER BY total_sales ASC
LIMIT 10;


-- ============================================================================
-- Q05: Yearly Sales by Industry
-- Business Use Case : Track industry performance across years
-- Complexity        : Basic (GROUP BY with two dimensions)
-- ============================================================================
SELECT
    year,
    industry,
    ROUND(SUM(sales), 2)                        AS annual_sales
FROM retail_sales
WHERE sales IS NOT NULL
GROUP BY year, industry
ORDER BY year, annual_sales DESC;


-- ============================================================================
-- Q06: Businesses with Average Monthly Sales Above $10 Billion
-- Business Use Case : Identify mega-scale retail segments
-- Complexity        : Basic (HAVING clause)
-- Note              : Sales are in millions, so $10B = 10,000 million
-- ============================================================================
SELECT
    kind_of_business,
    industry,
    ROUND(AVG(sales), 2)                        AS avg_monthly_sales_millions,
    ROUND(SUM(sales), 2)                        AS total_sales_millions
FROM retail_sales
WHERE sales IS NOT NULL
GROUP BY kind_of_business, industry
HAVING AVG(sales) > 10000
ORDER BY avg_monthly_sales_millions DESC;


-- ============================================================================
-- Q07: Sales Distribution by NAICS Code
-- Business Use Case : Analyze revenue concentration across classification codes
-- Complexity        : Basic
-- ============================================================================
SELECT
    naics_code,
    industry,
    COUNT(DISTINCT kind_of_business)             AS business_types,
    ROUND(SUM(sales), 2)                        AS total_sales,
    ROUND(AVG(sales), 2)                        AS avg_sales
FROM retail_sales
WHERE sales IS NOT NULL
  AND naics_code IS NOT NULL
GROUP BY naics_code, industry
ORDER BY total_sales DESC;


-- ============================================================================
-- Q08: Women's vs Men's Clothing — Yearly Sales Comparison (CASE WHEN Pivot)
-- Business Use Case : Gender-based retail trend analysis
-- Complexity        : Medium (CASE WHEN pivot)
-- ============================================================================
SELECT
    year,
    ROUND(SUM(CASE WHEN kind_of_business = 'Women''s clothing stores'
              THEN sales ELSE 0 END), 2)        AS womens_sales,
    ROUND(SUM(CASE WHEN kind_of_business = 'Men''s clothing stores'
              THEN sales ELSE 0 END), 2)         AS mens_sales,
    ROUND(
        SUM(CASE WHEN kind_of_business = 'Women''s clothing stores' THEN sales ELSE 0 END) /
        NULLIF(SUM(CASE WHEN kind_of_business = 'Men''s clothing stores' THEN sales ELSE 0 END), 0)
    , 2)                                         AS women_to_men_ratio
FROM retail_sales
WHERE kind_of_business IN ('Women''s clothing stores', 'Men''s clothing stores')
GROUP BY year
ORDER BY year;


-- ============================================================================
-- Q09: Automotive Industry Deep Dive — 2022
-- Business Use Case : Break down automotive sub-categories
-- Complexity        : Medium (CTE + contribution %)
-- ============================================================================
WITH auto_sales AS (
    SELECT
        kind_of_business,
        ROUND(SUM(sales), 2) AS total_sales
    FROM retail_sales
    WHERE industry = 'Automotive'
      AND year = 2022
      AND sales IS NOT NULL
    GROUP BY kind_of_business
),
auto_total AS (
    SELECT SUM(total_sales) AS grand_total FROM auto_sales
)
SELECT
    a.kind_of_business,
    a.total_sales,
    ROUND(a.total_sales / t.grand_total * 100, 2) AS contribution_pct
FROM auto_sales a
CROSS JOIN auto_total t
ORDER BY a.total_sales DESC;


-- ============================================================================
-- Q10: Top Industry Per Month (All Years Combined — Eliminates Copy-Paste)
-- Business Use Case : Which industry dominates each month, across all years?
-- Complexity        : Medium (CTE + RANK window function)
-- Note              : This replaces the original 4 duplicate queries (Q1-Q4)
-- ============================================================================
WITH monthly_industry_sales AS (
    SELECT
        year,
        month,
        industry,
        ROUND(SUM(sales), 2) AS total_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
      AND year BETWEEN 2019 AND 2022
    GROUP BY year, month, industry
),
ranked AS (
    SELECT
        year,
        month,
        industry,
        total_sales,
        RANK() OVER (PARTITION BY year, month ORDER BY total_sales DESC) AS rnk
    FROM monthly_industry_sales
)
SELECT
    year,
    month,
    industry,
    total_sales
FROM ranked
WHERE rnk = 1
ORDER BY year, month;


-- ============================================================================
-- Q11: Business Contribution to Industry (All Industries)
-- Business Use Case : Understand sub-category concentration within each industry
-- Complexity        : Medium (CTE + percentage calculation)
-- ============================================================================
WITH business_totals AS (
    SELECT
        industry,
        kind_of_business,
        ROUND(SUM(sales), 2) AS business_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY industry, kind_of_business
),
industry_totals AS (
    SELECT
        industry,
        SUM(business_sales) AS industry_sales
    FROM business_totals
    GROUP BY industry
)
SELECT
    b.industry,
    b.kind_of_business,
    b.business_sales,
    i.industry_sales,
    ROUND(b.business_sales / i.industry_sales * 100, 2) AS contribution_pct
FROM business_totals b
JOIN industry_totals i ON b.industry = i.industry
ORDER BY b.industry, contribution_pct DESC;


-- ============================================================================
-- Q12: Monthly Sales Heatmap Data (Month × Year Matrix)
-- Business Use Case : Feed into dashboard heatmap visualization
-- Complexity        : Medium (Conditional aggregation)
-- ============================================================================
SELECT
    month,
    ROUND(SUM(CASE WHEN year = 2018 THEN sales END), 0) AS y2018,
    ROUND(SUM(CASE WHEN year = 2019 THEN sales END), 0) AS y2019,
    ROUND(SUM(CASE WHEN year = 2020 THEN sales END), 0) AS y2020,
    ROUND(SUM(CASE WHEN year = 2021 THEN sales END), 0) AS y2021,
    ROUND(SUM(CASE WHEN year = 2022 THEN sales END), 0) AS y2022
FROM retail_sales
WHERE sales IS NOT NULL
GROUP BY month
ORDER BY month;


-- ============================================================================
-- Q13: Seasonal Peak Detection — Which Month Has Highest Sales per Industry?
-- Business Use Case : Inventory planning, staffing, and marketing campaigns
-- Complexity        : Medium (Subquery)
-- ============================================================================
SELECT
    s.industry,
    s.month                                      AS peak_month,
    s.total_sales
FROM (
    SELECT
        industry,
        month,
        ROUND(SUM(sales), 2) AS total_sales,
        RANK() OVER (PARTITION BY industry ORDER BY SUM(sales) DESC) AS rnk
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY industry, month
) s
WHERE s.rnk = 1
ORDER BY s.total_sales DESC;


-- ============================================================================
-- Q14: Year-over-Year Growth Rate by Industry
-- Business Use Case : Measure annual performance trajectory
-- Complexity        : Medium (Self-join)
-- ============================================================================
WITH yearly_totals AS (
    SELECT
        year,
        industry,
        ROUND(SUM(sales), 2) AS annual_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY year, industry
)
SELECT
    curr.industry,
    prev.year                                    AS previous_year,
    curr.year                                    AS current_year,
    prev.annual_sales                            AS prev_sales,
    curr.annual_sales                            AS curr_sales,
    ROUND((curr.annual_sales - prev.annual_sales)
          / prev.annual_sales * 100, 2)          AS yoy_growth_pct
FROM yearly_totals curr
JOIN yearly_totals prev
    ON curr.industry = prev.industry
   AND curr.year = prev.year + 1
ORDER BY curr.industry, curr.year;


-- ============================================================================
-- Q15: COVID-19 Impact Analysis — 2019 vs 2020 by Industry
-- Business Use Case : Quantify pandemic's effect on each retail sector
-- Complexity        : Medium (Filtered self-join)
-- ============================================================================
WITH pre_covid AS (
    SELECT industry, ROUND(SUM(sales), 2) AS sales_2019
    FROM retail_sales
    WHERE year = 2019 AND sales IS NOT NULL
    GROUP BY industry
),
during_covid AS (
    SELECT industry, ROUND(SUM(sales), 2) AS sales_2020
    FROM retail_sales
    WHERE year = 2020 AND sales IS NOT NULL
    GROUP BY industry
)
SELECT
    p.industry,
    p.sales_2019,
    d.sales_2020,
    ROUND(d.sales_2020 - p.sales_2019, 2)       AS absolute_change,
    ROUND((d.sales_2020 - p.sales_2019)
          / p.sales_2019 * 100, 2)               AS pct_change,
    CASE
        WHEN (d.sales_2020 - p.sales_2019) / p.sales_2019 * 100 > 5
            THEN 'GROWTH'
        WHEN (d.sales_2020 - p.sales_2019) / p.sales_2019 * 100 < -5
            THEN 'DECLINE'
        ELSE 'STABLE'
    END                                          AS covid_impact
FROM pre_covid p
JOIN during_covid d ON p.industry = d.industry
ORDER BY pct_change;


-- ============================================================================
-- END OF EXPLORATORY ANALYSIS
-- ============================================================================
