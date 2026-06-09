-- ============================================================================
-- PROJECT  : U.S. Retail & Food Services Sales Analysis
-- FILE     : 03_pareto_segmentation.sql
-- PURPOSE  : Pareto (80/20) analysis, segmentation, outlier detection
-- ENGINE   : MySQL 8.0+
-- ============================================================================

USE retail_sales_db;

-- ============================================================================
-- P01: Pareto Analysis (80/20 Rule) — Which Businesses Drive 80% of Revenue?
-- Business Use Case : Focus resources on the vital few, not the trivial many
-- Complexity        : Advanced (CTE + running sum + window function)
-- ============================================================================
WITH business_sales AS (
    SELECT
        kind_of_business,
        industry,
        ROUND(SUM(sales), 2) AS total_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY kind_of_business, industry
),
ranked AS (
    SELECT
        kind_of_business,
        industry,
        total_sales,
        ROUND(SUM(total_sales) OVER (ORDER BY total_sales DESC), 2) AS running_total,
        ROUND(SUM(total_sales) OVER (), 2) AS grand_total,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn,
        COUNT(*) OVER () AS total_businesses
    FROM business_sales
)
SELECT
    kind_of_business,
    industry,
    total_sales,
    running_total,
    grand_total,
    ROUND(running_total / grand_total * 100, 2) AS cumulative_pct,
    ROUND(rn / total_businesses * 100, 2) AS pct_of_businesses,
    CASE
        WHEN running_total / grand_total <= 0.80 THEN 'A — Top 80% Revenue'
        WHEN running_total / grand_total <= 0.95 THEN 'B — Next 15% Revenue'
        ELSE 'C — Bottom 5% Revenue'
    END AS pareto_class
FROM ranked
ORDER BY total_sales DESC;


-- ============================================================================
-- P02: Industry Segmentation Using NTILE Quartiles
-- Business Use Case : Classify industries into performance tiers
-- Complexity        : Medium (NTILE)
-- ============================================================================
WITH industry_performance AS (
    SELECT
        industry,
        ROUND(SUM(sales), 2) AS total_sales,
        ROUND(AVG(sales), 2) AS avg_sales,
        COUNT(DISTINCT kind_of_business) AS num_businesses,
        COUNT(DISTINCT year) AS years_active
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY industry
)
SELECT
    industry,
    total_sales,
    avg_sales,
    num_businesses,
    NTILE(4) OVER (ORDER BY total_sales DESC) AS performance_quartile,
    CASE NTILE(4) OVER (ORDER BY total_sales DESC)
        WHEN 1 THEN '🏆 Tier 1 — Market Leaders'
        WHEN 2 THEN '📈 Tier 2 — Strong Performers'
        WHEN 3 THEN '📊 Tier 3 — Average Performers'
        WHEN 4 THEN '📉 Tier 4 — Underperformers'
    END AS segment
FROM industry_performance
ORDER BY total_sales DESC;


-- ============================================================================
-- P03: Revenue Contribution Analysis — Cumulative % by Industry
-- Business Use Case : Identify revenue concentration risk
-- Complexity        : Advanced (Running percentage)
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
    ROUND(total_sales / SUM(total_sales) OVER () * 100, 2) AS pct_of_total,
    ROUND(SUM(total_sales) OVER (
        ORDER BY total_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) / SUM(total_sales) OVER () * 100, 2) AS cumulative_pct,
    RANK() OVER (ORDER BY total_sales DESC) AS revenue_rank
FROM industry_totals
ORDER BY total_sales DESC;


-- ============================================================================
-- P04: Outlier Detection Using IQR Method
-- Business Use Case : Flag anomalous sales months for investigation
-- Complexity        : Advanced (Multiple CTEs, percentile simulation)
-- ============================================================================
WITH monthly_sales AS (
    SELECT
        industry,
        year,
        month,
        ROUND(SUM(sales), 2) AS monthly_total
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY industry, year, month
),
industry_stats AS (
    SELECT
        industry,
        ROUND(AVG(monthly_total), 2)       AS avg_sales,
        ROUND(STDDEV(monthly_total), 2)    AS stddev_sales,
        ROUND(MIN(monthly_total), 2)       AS min_sales,
        ROUND(MAX(monthly_total), 2)       AS max_sales
    FROM monthly_sales
    GROUP BY industry
)
SELECT
    m.industry,
    m.year,
    m.month,
    m.monthly_total,
    s.avg_sales,
    s.stddev_sales,
    ROUND((m.monthly_total - s.avg_sales) / NULLIF(s.stddev_sales, 0), 2) AS z_score,
    CASE
        WHEN ABS((m.monthly_total - s.avg_sales) / NULLIF(s.stddev_sales, 0)) > 3
            THEN '🔴 Extreme Outlier (|z| > 3)'
        WHEN ABS((m.monthly_total - s.avg_sales) / NULLIF(s.stddev_sales, 0)) > 2
            THEN '🟡 Moderate Outlier (|z| > 2)'
        ELSE '🟢 Normal'
    END AS outlier_flag
FROM monthly_sales m
JOIN industry_stats s ON m.industry = s.industry
WHERE ABS((m.monthly_total - s.avg_sales) / NULLIF(s.stddev_sales, 0)) > 2
ORDER BY ABS((m.monthly_total - s.avg_sales) / NULLIF(s.stddev_sales, 0)) DESC;


-- ============================================================================
-- P05: Product Ranking — Top N Businesses Per Industry Per Year
-- Business Use Case : Identify category leaders within each industry
-- Complexity        : Advanced (CTE + DENSE_RANK + filtering)
-- ============================================================================
WITH ranked_businesses AS (
    SELECT
        year,
        industry,
        kind_of_business,
        ROUND(SUM(sales), 2) AS annual_sales,
        DENSE_RANK() OVER (
            PARTITION BY year, industry
            ORDER BY SUM(sales) DESC
        ) AS business_rank
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY year, industry, kind_of_business
)
SELECT
    year,
    industry,
    kind_of_business,
    annual_sales,
    business_rank
FROM ranked_businesses
WHERE business_rank <= 3
ORDER BY year, industry, business_rank;


-- ============================================================================
-- P06: Sales Volatility Analysis — Standard Deviation & Coefficient of Variation
-- Business Use Case : Assess predictability / risk of each industry's revenue
-- Complexity        : Medium (Aggregate statistics)
-- ============================================================================
WITH monthly_sales AS (
    SELECT
        industry,
        year,
        month,
        ROUND(SUM(sales), 2) AS monthly_total
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY industry, year, month
)
SELECT
    industry,
    ROUND(AVG(monthly_total), 2)             AS avg_monthly_sales,
    ROUND(STDDEV(monthly_total), 2)          AS stddev_sales,
    ROUND(MIN(monthly_total), 2)             AS min_monthly_sales,
    ROUND(MAX(monthly_total), 2)             AS max_monthly_sales,
    ROUND(MAX(monthly_total) - MIN(monthly_total), 2) AS sales_range,
    ROUND(STDDEV(monthly_total) / AVG(monthly_total) * 100, 2) AS coeff_of_variation,
    CASE
        WHEN STDDEV(monthly_total) / AVG(monthly_total) * 100 > 30 THEN 'High Volatility'
        WHEN STDDEV(monthly_total) / AVG(monthly_total) * 100 > 15 THEN 'Medium Volatility'
        ELSE 'Low Volatility (Stable)'
    END AS volatility_class
FROM monthly_sales
GROUP BY industry
ORDER BY coeff_of_variation DESC;


-- ============================================================================
-- P07: Market Concentration — Herfindahl-Hirschman Index (HHI)
-- Business Use Case : Measure market concentration within industries
-- Complexity        : Advanced
-- ============================================================================
WITH business_shares AS (
    SELECT
        industry,
        kind_of_business,
        ROUND(SUM(sales), 2) AS business_sales,
        ROUND(SUM(sales) / SUM(SUM(sales)) OVER (PARTITION BY industry) * 100, 2) AS market_share
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY industry, kind_of_business
)
SELECT
    industry,
    COUNT(*) AS num_businesses,
    ROUND(SUM(POW(market_share, 2)), 2) AS hhi_index,
    CASE
        WHEN SUM(POW(market_share, 2)) > 2500 THEN 'Highly Concentrated'
        WHEN SUM(POW(market_share, 2)) > 1500 THEN 'Moderately Concentrated'
        ELSE 'Competitive'
    END AS concentration_level
FROM business_shares
GROUP BY industry
ORDER BY hhi_index DESC;


-- ============================================================================
-- P08: Year-over-Year Performance Matrix (All Industries)
-- Business Use Case : Bird's-eye view of multi-year industry performance
-- Complexity        : Advanced (Multiple CASE WHEN + window functions)
-- ============================================================================
WITH yearly AS (
    SELECT
        industry,
        year,
        ROUND(SUM(sales), 2) AS annual_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY industry, year
),
with_growth AS (
    SELECT
        industry,
        year,
        annual_sales,
        ROUND(
            (annual_sales - LAG(annual_sales) OVER (
                PARTITION BY industry ORDER BY year))
            / NULLIF(LAG(annual_sales) OVER (
                PARTITION BY industry ORDER BY year), 0) * 100
        , 2) AS yoy_pct
    FROM yearly
)
SELECT
    industry,
    MAX(CASE WHEN year = 2015 THEN yoy_pct END) AS growth_2015,
    MAX(CASE WHEN year = 2016 THEN yoy_pct END) AS growth_2016,
    MAX(CASE WHEN year = 2017 THEN yoy_pct END) AS growth_2017,
    MAX(CASE WHEN year = 2018 THEN yoy_pct END) AS growth_2018,
    MAX(CASE WHEN year = 2019 THEN yoy_pct END) AS growth_2019,
    MAX(CASE WHEN year = 2020 THEN yoy_pct END) AS growth_2020,
    MAX(CASE WHEN year = 2021 THEN yoy_pct END) AS growth_2021,
    MAX(CASE WHEN year = 2022 THEN yoy_pct END) AS growth_2022
FROM with_growth
GROUP BY industry
ORDER BY industry;


-- ============================================================================
-- END OF PARETO & SEGMENTATION ANALYSIS
-- ============================================================================
