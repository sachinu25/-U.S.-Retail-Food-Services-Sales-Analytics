-- ============================================================================
-- PROJECT  : U.S. Retail & Food Services Sales Analysis
-- FILE     : 01_create_database.sql
-- PURPOSE  : Create database, table schema, and load source data
-- ENGINE   : MySQL 8.0+
-- DATASET  : U.S. Census Bureau — Monthly Retail Trade Survey (2010–2022)
-- ============================================================================

-- ---------------------------------------------------------------------
-- 1. DATABASE CREATION
-- ---------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS retail_sales_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE retail_sales_db;

-- ---------------------------------------------------------------------
-- 2. TABLE SCHEMA
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS retail_sales;

CREATE TABLE retail_sales (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    month           TINYINT        NOT NULL  COMMENT 'Calendar month (1-12)',
    year            SMALLINT       NOT NULL  COMMENT 'Calendar year (2010-2022)',
    naics_code      VARCHAR(20)    DEFAULT NULL COMMENT 'North American Industry Classification System code',
    kind_of_business VARCHAR(255)  NOT NULL  COMMENT 'Specific business type / sub-category',
    industry        VARCHAR(100)   NOT NULL  COMMENT 'High-level industry grouping',
    sales           DECIMAL(12,2)  DEFAULT NULL COMMENT 'Monthly sales in millions of USD'
) ENGINE=InnoDB
  COMMENT='U.S. monthly retail and food services sales data (2010-2022)';

-- ---------------------------------------------------------------------
-- 3. PERFORMANCE INDEXES  (created before data load for faster queries)
-- ---------------------------------------------------------------------
CREATE INDEX idx_year_month       ON retail_sales (year, month);
CREATE INDEX idx_industry         ON retail_sales (industry);
CREATE INDEX idx_kind_of_business ON retail_sales (kind_of_business);
CREATE INDEX idx_naics_code       ON retail_sales (naics_code);
CREATE INDEX idx_industry_year    ON retail_sales (industry, year);

-- ---------------------------------------------------------------------
-- 4. DATA LOADING
-- ---------------------------------------------------------------------
-- Option A: MySQL LOAD DATA (adjust path to your local CSV location)
-- NOTE: Ensure MySQL has FILE privilege and secure_file_priv allows the path

LOAD DATA INFILE '/path/to/data/us_monthly_retail_sales_wrangled.csv'
INTO TABLE retail_sales
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@dummy, month, year, naics_code, kind_of_business, industry, @sales)
SET sales = NULLIF(@sales, '');

-- Option B: If using MySQL Workbench, use the Table Data Import Wizard
-- File → data/us_monthly_retail_sales_wrangled.csv

-- ---------------------------------------------------------------------
-- 5. POST-LOAD VALIDATION
-- ---------------------------------------------------------------------
-- Verify row count (expected: ~9,048 rows)
SELECT COUNT(*) AS total_rows FROM retail_sales;

-- Verify year range
SELECT MIN(year) AS min_year, MAX(year) AS max_year FROM retail_sales;

-- Verify industry distribution
SELECT industry, COUNT(*) AS row_count
FROM retail_sales
GROUP BY industry
ORDER BY row_count DESC;

-- Verify for NULL sales (expected — some categories don't report)
SELECT COUNT(*) AS null_sales_count
FROM retail_sales
WHERE sales IS NULL;

-- Quick data preview
SELECT * FROM retail_sales LIMIT 10;

-- ============================================================================
-- END OF SCHEMA SETUP
-- ============================================================================
