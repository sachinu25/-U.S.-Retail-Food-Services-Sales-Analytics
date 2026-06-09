-- ============================================================================
-- PROJECT  : U.S. Retail & Food Services Sales Analysis
-- FILE     : 01_analytical_views.sql
-- PURPOSE  : Reusable analytical views for dashboards and ad-hoc queries
-- ENGINE   : MySQL 8.0+
-- ============================================================================

USE retail_sales_db;

-- ============================================================================
-- VIEW 1: Monthly Industry Summary
-- Purpose : Pre-aggregated monthly totals per industry — powers most dashboards
-- ============================================================================
DROP VIEW IF EXISTS v_monthly_industry_summary;

CREATE VIEW v_monthly_industry_summary AS
SELECT
    year,
    month,
    industry,
    COUNT(DISTINCT kind_of_business)             AS business_count,
    ROUND(SUM(sales), 2)                        AS total_sales,
    ROUND(AVG(sales), 2)                        AS avg_sales,
    ROUND(MIN(sales), 2)                        AS min_sales,
    ROUND(MAX(sales), 2)                        AS max_sales
FROM retail_sales
WHERE sales IS NOT NULL
GROUP BY year, month, industry;


-- ============================================================================
-- VIEW 2: Year-over-Year Growth by Industry
-- Purpose : Ready-to-consume YoY growth metrics for trend dashboards
-- ============================================================================
DROP VIEW IF EXISTS v_yoy_growth;

CREATE VIEW v_yoy_growth AS
WITH yearly AS (
    SELECT
        year,
        industry,
        ROUND(SUM(sales), 2) AS annual_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY year, industry
)
SELECT
    curr.year,
    curr.industry,
    prev.annual_sales                            AS prev_year_sales,
    curr.annual_sales                            AS curr_year_sales,
    ROUND(curr.annual_sales - prev.annual_sales, 2) AS absolute_change,
    ROUND(
        (curr.annual_sales - prev.annual_sales)
        / prev.annual_sales * 100
    , 2)                                         AS yoy_growth_pct
FROM yearly curr
JOIN yearly prev
    ON curr.industry = prev.industry
   AND curr.year = prev.year + 1;


-- ============================================================================
-- VIEW 3: Top Businesses by Year (Top 5 per Year)
-- Purpose : Quick access to yearly revenue leaders
-- ============================================================================
DROP VIEW IF EXISTS v_top_businesses_by_year;

CREATE VIEW v_top_businesses_by_year AS
WITH ranked AS (
    SELECT
        year,
        kind_of_business,
        industry,
        ROUND(SUM(sales), 2) AS annual_sales,
        DENSE_RANK() OVER (
            PARTITION BY year
            ORDER BY SUM(sales) DESC
        ) AS sales_rank
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY year, kind_of_business, industry
)
SELECT *
FROM ranked
WHERE sales_rank <= 5;


-- ============================================================================
-- VIEW 4: Sales Distribution Summary (For Box Plot / Distribution Charts)
-- Purpose : Statistical profile of each industry's sales distribution
-- ============================================================================
DROP VIEW IF EXISTS v_sales_distribution;

CREATE VIEW v_sales_distribution AS
SELECT
    industry,
    COUNT(*) AS observations,
    ROUND(AVG(sales), 2)                        AS mean_sales,
    ROUND(STDDEV(sales), 2)                     AS stddev_sales,
    ROUND(MIN(sales), 2)                        AS min_sales,
    ROUND(MAX(sales), 2)                        AS max_sales,
    ROUND(MAX(sales) - MIN(sales), 2)           AS sales_range,
    ROUND(STDDEV(sales) / NULLIF(AVG(sales), 0) * 100, 2) AS cv_pct
FROM retail_sales
WHERE sales IS NOT NULL
GROUP BY industry;


-- ============================================================================
-- VIEW 5: Seasonal Patterns (Average Sales by Month, per Industry)
-- Purpose : Seasonality heatmap data for dashboard
-- ============================================================================
DROP VIEW IF EXISTS v_seasonal_patterns;

CREATE VIEW v_seasonal_patterns AS
WITH monthly_avg AS (
    SELECT
        industry,
        month,
        ROUND(AVG(monthly_total), 2) AS avg_sales
    FROM (
        SELECT
            industry,
            year,
            month,
            SUM(sales) AS monthly_total
        FROM retail_sales
        WHERE sales IS NOT NULL
        GROUP BY industry, year, month
    ) sub
    GROUP BY industry, month
),
industry_avg AS (
    SELECT
        industry,
        ROUND(AVG(avg_sales), 2) AS grand_avg
    FROM monthly_avg
    GROUP BY industry
)
SELECT
    m.industry,
    m.month,
    m.avg_sales,
    i.grand_avg,
    ROUND(m.avg_sales / i.grand_avg * 100, 2) AS seasonality_index
FROM monthly_avg m
JOIN industry_avg i ON m.industry = i.industry;


-- ============================================================================
-- VIEW 6: KPI Dashboard View (Executive Summary Metrics)
-- Purpose : Single query to power all executive dashboard KPI cards
-- ============================================================================
DROP VIEW IF EXISTS v_kpi_dashboard;

CREATE VIEW v_kpi_dashboard AS
WITH current_year AS (
    SELECT
        ROUND(SUM(sales), 2) AS total_revenue,
        ROUND(AVG(sales), 2) AS avg_monthly_sales,
        COUNT(DISTINCT kind_of_business) AS total_businesses,
        COUNT(DISTINCT industry) AS total_industries
    FROM retail_sales
    WHERE sales IS NOT NULL AND year = 2022
),
prev_year AS (
    SELECT ROUND(SUM(sales), 2) AS prev_revenue
    FROM retail_sales
    WHERE sales IS NOT NULL AND year = 2021
),
top_industry AS (
    SELECT industry, ROUND(SUM(sales), 2) AS sales
    FROM retail_sales
    WHERE sales IS NOT NULL AND year = 2022
    GROUP BY industry
    ORDER BY sales DESC
    LIMIT 1
),
top_business AS (
    SELECT kind_of_business, ROUND(SUM(sales), 2) AS sales
    FROM retail_sales
    WHERE sales IS NOT NULL AND year = 2022
    GROUP BY kind_of_business
    ORDER BY sales DESC
    LIMIT 1
)
SELECT
    c.total_revenue,
    c.avg_monthly_sales,
    c.total_businesses,
    c.total_industries,
    p.prev_revenue,
    ROUND((c.total_revenue - p.prev_revenue) / p.prev_revenue * 100, 2) AS yoy_growth_pct,
    ti.industry AS top_industry,
    ti.sales AS top_industry_sales,
    tb.kind_of_business AS top_business,
    tb.sales AS top_business_sales
FROM current_year c
CROSS JOIN prev_year p
CROSS JOIN top_industry ti
CROSS JOIN top_business tb;


-- ============================================================================
-- END OF ANALYTICAL VIEWS
-- ============================================================================
