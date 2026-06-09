-- ============================================================================
-- PROJECT  : U.S. Retail & Food Services Sales Analysis
-- FILE     : 01_procedures.sql
-- PURPOSE  : Reusable stored procedures for parameterized reporting
-- ENGINE   : MySQL 8.0+
-- ============================================================================

USE retail_sales_db;

-- ============================================================================
-- PROCEDURE 1: Get Industry Report for a Given Year
-- Purpose : Generate a comprehensive report for any industry in any year
-- Usage   : CALL sp_get_industry_report(2022, 'Automotive');
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_get_industry_report;

DELIMITER //

CREATE PROCEDURE sp_get_industry_report(
    IN p_year     SMALLINT,
    IN p_industry VARCHAR(100)
)
BEGIN
    -- Section 1: Summary KPIs
    SELECT
        p_year                                   AS report_year,
        p_industry                               AS report_industry,
        COUNT(DISTINCT kind_of_business)         AS business_count,
        ROUND(SUM(sales), 2)                     AS total_sales,
        ROUND(AVG(sales), 2)                     AS avg_monthly_sales,
        ROUND(MIN(sales), 2)                     AS min_sales,
        ROUND(MAX(sales), 2)                     AS max_sales
    FROM retail_sales
    WHERE year = p_year
      AND industry = p_industry
      AND sales IS NOT NULL;

    -- Section 2: Monthly Breakdown
    SELECT
        month,
        ROUND(SUM(sales), 2)                     AS monthly_sales
    FROM retail_sales
    WHERE year = p_year
      AND industry = p_industry
      AND sales IS NOT NULL
    GROUP BY month
    ORDER BY month;

    -- Section 3: Top Businesses within the Industry
    SELECT
        kind_of_business,
        ROUND(SUM(sales), 2)                     AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(sales) DESC) AS rnk
    FROM retail_sales
    WHERE year = p_year
      AND industry = p_industry
      AND sales IS NOT NULL
    GROUP BY kind_of_business
    ORDER BY total_sales DESC;
END //

DELIMITER ;


-- ============================================================================
-- PROCEDURE 2: Get Top N Businesses for a Given Year
-- Purpose : Flexible "Top N" report — useful for exec dashboards
-- Usage   : CALL sp_get_top_n_businesses(2022, 10);
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_get_top_n_businesses;

DELIMITER //

CREATE PROCEDURE sp_get_top_n_businesses(
    IN p_year INT,
    IN p_n    INT
)
BEGIN
    SELECT
        kind_of_business,
        industry,
        ROUND(SUM(sales), 2)                     AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(sales) DESC) AS sales_rank
    FROM retail_sales
    WHERE year = p_year
      AND sales IS NOT NULL
    GROUP BY kind_of_business, industry
    ORDER BY total_sales DESC
    LIMIT p_n;
END //

DELIMITER ;


-- ============================================================================
-- PROCEDURE 3: Growth Analysis Between Two Years
-- Purpose : Compare any two years and show growth/decline per industry
-- Usage   : CALL sp_get_growth_analysis(2019, 2022);
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_get_growth_analysis;

DELIMITER //

CREATE PROCEDURE sp_get_growth_analysis(
    IN p_start_year SMALLINT,
    IN p_end_year   SMALLINT
)
BEGIN
    WITH start_data AS (
        SELECT
            industry,
            ROUND(SUM(sales), 2) AS start_sales
        FROM retail_sales
        WHERE year = p_start_year AND sales IS NOT NULL
        GROUP BY industry
    ),
    end_data AS (
        SELECT
            industry,
            ROUND(SUM(sales), 2) AS end_sales
        FROM retail_sales
        WHERE year = p_end_year AND sales IS NOT NULL
        GROUP BY industry
    )
    SELECT
        s.industry,
        p_start_year                              AS from_year,
        p_end_year                                AS to_year,
        s.start_sales,
        e.end_sales,
        ROUND(e.end_sales - s.start_sales, 2)    AS absolute_change,
        ROUND((e.end_sales - s.start_sales)
              / s.start_sales * 100, 2)           AS growth_pct,
        CASE
            WHEN (e.end_sales - s.start_sales) / s.start_sales * 100 > 10
                THEN '🟢 Strong Growth'
            WHEN (e.end_sales - s.start_sales) / s.start_sales * 100 > 0
                THEN '🔵 Moderate Growth'
            WHEN (e.end_sales - s.start_sales) / s.start_sales * 100 > -10
                THEN '🟡 Slight Decline'
            ELSE '🔴 Significant Decline'
        END AS performance_label
    FROM start_data s
    JOIN end_data e ON s.industry = e.industry
    ORDER BY growth_pct DESC;
END //

DELIMITER ;


-- ============================================================================
-- PROCEDURE 4: Seasonal Analysis for Any Business Type
-- Purpose : Drill into monthly patterns for a specific business category
-- Usage   : CALL sp_seasonal_analysis('Women''s clothing stores');
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_seasonal_analysis;

DELIMITER //

CREATE PROCEDURE sp_seasonal_analysis(
    IN p_business VARCHAR(255)
)
BEGIN
    -- Monthly averages across all years
    SELECT
        month,
        ROUND(AVG(sales), 2)                     AS avg_sales,
        ROUND(MIN(sales), 2)                     AS min_sales,
        ROUND(MAX(sales), 2)                     AS max_sales,
        COUNT(*)                                  AS years_reported
    FROM retail_sales
    WHERE kind_of_business = p_business
      AND sales IS NOT NULL
    GROUP BY month
    ORDER BY month;

    -- Year-over-year trend
    SELECT
        year,
        ROUND(SUM(sales), 2)                     AS annual_sales
    FROM retail_sales
    WHERE kind_of_business = p_business
      AND sales IS NOT NULL
    GROUP BY year
    ORDER BY year;
END //

DELIMITER ;


-- ============================================================================
-- PROCEDURE 5: Executive Dashboard Data
-- Purpose : Single call to populate all dashboard KPIs and charts
-- Usage   : CALL sp_executive_dashboard(2022);
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_executive_dashboard;

DELIMITER //

CREATE PROCEDURE sp_executive_dashboard(
    IN p_year SMALLINT
)
BEGIN
    -- Result Set 1: Overall KPIs
    SELECT
        ROUND(SUM(sales), 2)                     AS total_revenue,
        ROUND(AVG(sales), 2)                     AS avg_sales,
        COUNT(DISTINCT kind_of_business)         AS total_businesses,
        COUNT(DISTINCT industry)                 AS total_industries,
        ROUND(MIN(sales), 2)                     AS min_single_sale,
        ROUND(MAX(sales), 2)                     AS max_single_sale
    FROM retail_sales
    WHERE year = p_year AND sales IS NOT NULL;

    -- Result Set 2: Sales by Industry
    SELECT
        industry,
        ROUND(SUM(sales), 2)                     AS total_sales,
        ROUND(SUM(sales) / (SELECT SUM(sales) FROM retail_sales
                            WHERE year = p_year AND sales IS NOT NULL) * 100, 2)
                                                  AS market_share_pct
    FROM retail_sales
    WHERE year = p_year AND sales IS NOT NULL
    GROUP BY industry
    ORDER BY total_sales DESC;

    -- Result Set 3: Monthly Trend
    SELECT
        month,
        ROUND(SUM(sales), 2)                     AS monthly_sales
    FROM retail_sales
    WHERE year = p_year AND sales IS NOT NULL
    GROUP BY month
    ORDER BY month;

    -- Result Set 4: Top 10 Businesses
    SELECT
        kind_of_business,
        industry,
        ROUND(SUM(sales), 2)                     AS total_sales
    FROM retail_sales
    WHERE year = p_year AND sales IS NOT NULL
    GROUP BY kind_of_business, industry
    ORDER BY total_sales DESC
    LIMIT 10;
END //

DELIMITER ;


-- ============================================================================
-- VERIFICATION: Test procedure calls
-- ============================================================================
-- CALL sp_get_industry_report(2022, 'Automotive');
-- CALL sp_get_top_n_businesses(2022, 10);
-- CALL sp_get_growth_analysis(2019, 2022);
-- CALL sp_seasonal_analysis('Women''s clothing stores');
-- CALL sp_executive_dashboard(2022);

-- ============================================================================
-- END OF STORED PROCEDURES
-- ============================================================================
