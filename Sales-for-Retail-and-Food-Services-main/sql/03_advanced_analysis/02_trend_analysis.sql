-- ============================================================================
-- PROJECT  : U.S. Retail & Food Services Sales Analysis
-- FILE     : 02_trend_analysis.sql
-- PURPOSE  : Monthly, quarterly, yearly trends + growth rate calculations
-- ENGINE   : MySQL 8.0+
-- ============================================================================

USE retail_sales_db;

-- ============================================================================
-- T01: Monthly Sales Trend (All Industries Combined)
-- Business Use Case : Executive dashboard — overall monthly trajectory
-- ============================================================================
SELECT
    year,
    month,
    ROUND(SUM(sales), 2)                        AS total_sales,
    COUNT(DISTINCT industry)                     AS industries_reporting
FROM retail_sales
WHERE sales IS NOT NULL
GROUP BY year, month
ORDER BY year, month;


-- ============================================================================
-- T02: Quarterly Sales Trend
-- Business Use Case : Quarterly business reviews (QBR) and board reporting
-- ============================================================================
SELECT
    year,
    CASE
        WHEN month BETWEEN 1 AND 3  THEN 'Q1'
        WHEN month BETWEEN 4 AND 6  THEN 'Q2'
        WHEN month BETWEEN 7 AND 9  THEN 'Q3'
        WHEN month BETWEEN 10 AND 12 THEN 'Q4'
    END                                         AS quarter,
    ROUND(SUM(sales), 2)                        AS quarterly_sales,
    COUNT(*)                                     AS records
FROM retail_sales
WHERE sales IS NOT NULL
GROUP BY year, quarter
ORDER BY year, quarter;


-- ============================================================================
-- T03: Yearly Sales Trend with Year-over-Year Growth
-- Business Use Case : Annual performance tracking & board presentations
-- ============================================================================
WITH annual AS (
    SELECT
        year,
        ROUND(SUM(sales), 2) AS annual_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY year
)
SELECT
    year,
    annual_sales,
    LAG(annual_sales) OVER (ORDER BY year)       AS prev_year_sales,
    ROUND(annual_sales - LAG(annual_sales) OVER (ORDER BY year), 2) AS yoy_change,
    ROUND(
        (annual_sales - LAG(annual_sales) OVER (ORDER BY year))
        / LAG(annual_sales) OVER (ORDER BY year) * 100
    , 2)                                         AS yoy_growth_pct
FROM annual
ORDER BY year;


-- ============================================================================
-- T04: Month-over-Month Growth % by Industry
-- Business Use Case : Detect momentum shifts within each industry
-- ============================================================================
WITH monthly AS (
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
    LAG(monthly_sales) OVER (
        PARTITION BY industry ORDER BY year, month
    )                                            AS prev_month_sales,
    ROUND(
        (monthly_sales - LAG(monthly_sales) OVER (
            PARTITION BY industry ORDER BY year, month))
        / NULLIF(LAG(monthly_sales) OVER (
            PARTITION BY industry ORDER BY year, month), 0) * 100
    , 2)                                         AS mom_growth_pct
FROM monthly
ORDER BY industry, year, month;


-- ============================================================================
-- T05: Quarter-over-Quarter Growth %
-- Business Use Case : QoQ trend analysis for strategic planning
-- ============================================================================
WITH quarterly AS (
    SELECT
        year,
        CEIL(month / 3) AS quarter_num,
        ROUND(SUM(sales), 2) AS quarterly_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY year, quarter_num
)
SELECT
    year,
    CONCAT('Q', quarter_num) AS quarter,
    quarterly_sales,
    LAG(quarterly_sales) OVER (ORDER BY year, quarter_num) AS prev_quarter_sales,
    ROUND(
        (quarterly_sales - LAG(quarterly_sales) OVER (ORDER BY year, quarter_num))
        / NULLIF(LAG(quarterly_sales) OVER (ORDER BY year, quarter_num), 0) * 100
    , 2) AS qoq_growth_pct
FROM quarterly
ORDER BY year, quarter_num;


-- ============================================================================
-- T06: Seasonality Index — Average Sales per Month Across All Years
-- Business Use Case : Identify consistent seasonal patterns for forecasting
-- ============================================================================
WITH monthly_avg AS (
    SELECT
        month,
        ROUND(AVG(total_monthly), 2) AS avg_monthly_sales
    FROM (
        SELECT
            year,
            month,
            SUM(sales) AS total_monthly
        FROM retail_sales
        WHERE sales IS NOT NULL
        GROUP BY year, month
    ) sub
    GROUP BY month
),
overall_avg AS (
    SELECT ROUND(AVG(avg_monthly_sales), 2) AS grand_avg FROM monthly_avg
)
SELECT
    m.month,
    m.avg_monthly_sales,
    o.grand_avg,
    ROUND(m.avg_monthly_sales / o.grand_avg * 100, 2) AS seasonality_index,
    CASE
        WHEN m.avg_monthly_sales / o.grand_avg > 1.05 THEN '📈 Peak Season'
        WHEN m.avg_monthly_sales / o.grand_avg < 0.95 THEN '📉 Off Season'
        ELSE '➡️ Normal'
    END AS season_label
FROM monthly_avg m
CROSS JOIN overall_avg o
ORDER BY m.month;


-- ============================================================================
-- T07: Industry Growth Trend — CAGR (Compound Annual Growth Rate)
-- Business Use Case : Long-term growth rate useful for investment analysis
-- Formula           : CAGR = (End_Value / Start_Value)^(1/n) - 1
-- ============================================================================
WITH first_last AS (
    SELECT
        industry,
        MIN(year) AS start_year,
        MAX(year) AS end_year
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY industry
),
yearly_sales AS (
    SELECT
        industry,
        year,
        ROUND(SUM(sales), 2) AS annual_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY industry, year
)
SELECT
    f.industry,
    f.start_year,
    f.end_year,
    ys_start.annual_sales AS start_sales,
    ys_end.annual_sales   AS end_sales,
    ROUND(
        (POW(ys_end.annual_sales / ys_start.annual_sales,
             1.0 / (f.end_year - f.start_year)) - 1) * 100
    , 2) AS cagr_pct
FROM first_last f
JOIN yearly_sales ys_start
    ON f.industry = ys_start.industry AND f.start_year = ys_start.year
JOIN yearly_sales ys_end
    ON f.industry = ys_end.industry AND f.end_year = ys_end.year
ORDER BY cagr_pct DESC;


-- ============================================================================
-- T08: COVID Recovery Analysis — 2019 Baseline vs 2020 Drop vs 2021-2022 Recovery
-- Business Use Case : Track pandemic recovery trajectory per industry
-- ============================================================================
WITH yearly AS (
    SELECT
        year,
        industry,
        ROUND(SUM(sales), 2) AS annual_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
      AND year BETWEEN 2019 AND 2022
    GROUP BY year, industry
),
pivoted AS (
    SELECT
        industry,
        MAX(CASE WHEN year = 2019 THEN annual_sales END) AS sales_2019,
        MAX(CASE WHEN year = 2020 THEN annual_sales END) AS sales_2020,
        MAX(CASE WHEN year = 2021 THEN annual_sales END) AS sales_2021,
        MAX(CASE WHEN year = 2022 THEN annual_sales END) AS sales_2022
    FROM yearly
    GROUP BY industry
)
SELECT
    industry,
    sales_2019,
    sales_2020,
    sales_2021,
    sales_2022,
    ROUND((sales_2020 - sales_2019) / sales_2019 * 100, 2) AS covid_drop_pct,
    ROUND((sales_2021 - sales_2019) / sales_2019 * 100, 2) AS recovery_2021_pct,
    ROUND((sales_2022 - sales_2019) / sales_2019 * 100, 2) AS recovery_2022_pct,
    CASE
        WHEN sales_2022 >= sales_2019 THEN 'FULLY RECOVERED'
        WHEN sales_2021 >= sales_2019 THEN 'RECOVERED IN 2021'
        ELSE 'NOT YET RECOVERED'
    END AS recovery_status
FROM pivoted
ORDER BY covid_drop_pct;


-- ============================================================================
-- T09: Rolling 12-Month Sales (Trailing Twelve Months — TTM)
-- Business Use Case : Smooth annualized metric used in financial analysis
-- ============================================================================
WITH monthly AS (
    SELECT
        year,
        month,
        ROUND(SUM(sales), 2) AS monthly_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY year, month
)
SELECT
    year,
    month,
    monthly_sales,
    ROUND(SUM(monthly_sales) OVER (
        ORDER BY year, month
        ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
    ), 2) AS trailing_12m_sales
FROM monthly
ORDER BY year, month;


-- ============================================================================
-- T10: Fastest Growing Industries Year-over-Year (Top 3 per Year)
-- Business Use Case : Spot emerging sectors for investment or market entry
-- ============================================================================
WITH yearly AS (
    SELECT
        year,
        industry,
        ROUND(SUM(sales), 2) AS annual_sales
    FROM retail_sales
    WHERE sales IS NOT NULL
    GROUP BY year, industry
),
with_growth AS (
    SELECT
        year,
        industry,
        annual_sales,
        LAG(annual_sales) OVER (
            PARTITION BY industry ORDER BY year
        ) AS prev_year_sales,
        ROUND(
            (annual_sales - LAG(annual_sales) OVER (
                PARTITION BY industry ORDER BY year))
            / NULLIF(LAG(annual_sales) OVER (
                PARTITION BY industry ORDER BY year), 0) * 100
        , 2) AS yoy_growth_pct
    FROM yearly
),
ranked_growth AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY year ORDER BY yoy_growth_pct DESC
        ) AS growth_rank
    FROM with_growth
    WHERE yoy_growth_pct IS NOT NULL
)
SELECT
    year,
    industry,
    annual_sales,
    yoy_growth_pct,
    growth_rank
FROM ranked_growth
WHERE growth_rank <= 3
ORDER BY year, growth_rank;


-- ============================================================================
-- END OF TREND ANALYSIS
-- ============================================================================
