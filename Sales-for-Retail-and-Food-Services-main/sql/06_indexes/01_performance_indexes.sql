-- ============================================================================
-- PROJECT  : U.S. Retail & Food Services Sales Analysis
-- FILE     : 01_performance_indexes.sql
-- PURPOSE  : Strategic index creation for query performance optimization
-- ENGINE   : MySQL 8.0+
-- ============================================================================

USE retail_sales_db;

-- ============================================================================
-- INDEX STRATEGY
-- ============================================================================
-- The following indexes are designed based on the query patterns used across
-- all analysis scripts. Each index targets specific query families.
--
-- NOTE: Indexes created in 01_create_database.sql:
--   idx_year_month, idx_industry, idx_kind_of_business,
--   idx_naics_code, idx_industry_year
--
-- The following are ADDITIONAL composite indexes for advanced queries.
-- ============================================================================

-- ============================================================================
-- IDX 1: Composite index for time-series + industry queries
-- Covers: Trend analysis, MoM, YoY, seasonality queries
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_industry_year_month
    ON retail_sales (industry, year, month);

-- ============================================================================
-- IDX 2: Composite index for business-level drill-downs
-- Covers: Business ranking, contribution analysis, Pareto
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_business_industry_year
    ON retail_sales (kind_of_business, industry, year);

-- ============================================================================
-- IDX 3: Covering index for sales aggregation queries
-- Covers: Most GROUP BY + SUM(sales) queries without table lookups
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_covering_sales
    ON retail_sales (year, industry, kind_of_business, sales);

-- ============================================================================
-- IDX 4: Index for NAICS-based distribution queries
-- Covers: Q07 exploratory analysis, NAICS distribution
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_naics_industry_sales
    ON retail_sales (naics_code, industry, sales);

-- ============================================================================
-- IDX 5: Index for specific business type lookups
-- Covers: Women's/Men's clothing comparison, seasonal analysis procedures
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_business_year_month
    ON retail_sales (kind_of_business, year, month, sales);


-- ============================================================================
-- VERIFY ALL INDEXES
-- ============================================================================
SHOW INDEX FROM retail_sales;


-- ============================================================================
-- ANALYZE TABLE (updates optimizer statistics after index creation)
-- ============================================================================
ANALYZE TABLE retail_sales;


-- ============================================================================
-- INDEX USAGE NOTES
-- ============================================================================
-- To verify index usage, prepend EXPLAIN to any query:
--   EXPLAIN SELECT ... FROM retail_sales WHERE ...
--
-- To check if indexes are being used:
--   EXPLAIN FORMAT=JSON SELECT ...
--
-- To drop an unused index:
--   DROP INDEX idx_name ON retail_sales;
-- ============================================================================

-- ============================================================================
-- END OF PERFORMANCE INDEXES
-- ============================================================================
