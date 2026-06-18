# 🛒 U.S. Retail & Food Services — Sales Analytics

<div align="center">
  
  ![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
  ![SQL](https://img.shields.io/badge/SQL-Advanced-CC2927?style=for-the-badge&logo=databricks&logoColor=white)
  ![Power BI](https://img.shields.io/badge/Power_BI-Dashboard-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
  ![License](https://img.shields.io/badge/License-Apache_2.0-green?style=for-the-badge)

  <p align="center"> 
    <strong>An Industry-Grade End-to-End SQL Analytics Pipeline</strong>
    <br />
    Translating 13 years of U.S. Census Bureau retail trade data (9,048 records) into actionable executive insights.
  </p>

  ---
  
  [📂 View Schema](sql/00_schema/01_create_database.sql) • [📖 Data Dictionary](docs/data_dictionary.md) • [🏗️ Architecture Plan](docs/architecture.md) • [📊 Executive Report](docs/business_report.md) • [🎯 Resume Bullets](docs/resume_descriptions.md)

</div>

---

## 📌 Business Problem

The U.S. retail and food services industry generates **trillions of dollars annually** across dozens of sectors. For retail operators, investors, and analysts, extracting clear signals from high-volume historical datasets is crucial for survival. 

This repository implements a production-grade database and analytical pipeline to answer core strategic questions:
* 📈 **Growth Trajectories**: Which retail sectors are expanding fastest (CAGR), and which are stagnating?
* 🦠 **Crisis Volatility**: What was the true sector-by-sector impact of the COVID-19 pandemic, and what did the recovery curve look like?
* 🔄 **Seasonality Metrics**: Which quarters and months experience the highest sales concentration, and how should this govern inventory and marketing budgets?
* 🎯 **Revenue Concentration**: Which specific business categories generate 80% of total industry revenue (Pareto Principle)?

---

## 📊 Dataset Overview

The database is populated with the official U.S. Census Bureau Monthly Retail Trade Survey data:

* **Granularity**: Monthly sales reported in millions of U.S. Dollars ($M)
* **Timeframe**: January 2010 — December 2022 (13 Years / 156 Months)
* **Scope**: 9,048 observations spanning 12 high-level industries and 63 unique sub-categories
* **Quality**: Fully wrangled, cleaned of suppressions, and formatted with proper decimal limits

---

## 🔧 Core SQL & Engineering Concepts Demonstrated

This project showcases production-level SQL engineering practices designed to scale:

* 📐 **DDL & Schema Design**: Optimized table structure utilizing space-efficient types (`TINYINT` for months, `SMALLINT` for years) and high-precision values (`DECIMAL(12,2)` for financial fields).
* 🎛️ **Performance Optimization**: Created 10 strategic indexes (composite, covering, and lookup) reducing query execution times across complex partitions.
* 🪟 **Advanced Window Functions**: Extensive utilization of `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `NTILE()`, `LAG()`, `LEAD()`, `FIRST_VALUE()`, and `LAST_VALUE()`.
* 🧱 **Modular CTE Structures**: Multi-step calculations such as Compound Annual Growth Rate (CAGR), Trailing Twelve Months (TTM) sales, and Herfindahl-Hirschman Market Concentration Index (HHI).
* ⚙️ **Encapsulation (Views & Stored Procedures)**: 6 database views to support business dashboards and 5 parameterized stored procedures for automated reporting.

---

## 💡 Analytical Queries & Business Scenarios

The analytics suite is partitioned into structured SQL files mapping to key business dimensions:

### 1. Foundational Business Questions ([exploratory_analysis.sql](sql/02_basic_analysis/01_exploratory_analysis.sql))
* **Q01–Q04**: Data validation profiles, and top/bottom 10 revenue-generating business types.
* **Q05–Q07**: Yearly industry metrics, identification of $10B+ mega-businesses, and sales distribution by NAICS code.
* **Q08–Q11**: Gender-based fashion comparison (CASE WHEN pivot), Automotive sub-category contribution, and sector market-share concentration.
* **Q12–Q15**: Matrix heatmap aggregations, seasonal peaks, and COVID-19 pandemic impact analysis.

### 2. Time-Series & Growth Trends ([trend_analysis.sql](sql/03_advanced_analysis/02_trend_analysis.sql))
* **Month-over-Month (MoM) & Quarter-over-Quarter (QoQ)** growth calculations.
* **Compound Annual Growth Rate (CAGR)** tracking long-term sector trajectories.
* **COVID-19 Recovery Status**: Metric profiling of 2019 baseline vs. 2020 drop vs. 2021-2022 rebound.
* **Trailing Twelve Months (TTM)** rolling sales averages to smooth out monthly noise.

### 3. Market Concentration & Outliers ([pareto_segmentation.sql](sql/03_advanced_analysis/03_pareto_segmentation.sql))
* **Pareto (80/20 Rule) Analysis**: Classifying the top 20% of business categories driving 80% of total revenue.
* **Statistical Outlier Detection**: Using Z-Scores to flag anomalous sales months.
* **Herfindahl-Hirschman Index (HHI)**: Quantifying market competitiveness within each industry.
* **Sales Volatility CV**: Calculating the Coefficient of Variation to classify business predictability.

---

## 🎨 Interactive Dashboard Spec & Preview

### Mockup Reference Design
The query pipeline directly feeds the visualizations designed in the dashboard specification:

![Analytics Dashboard Mockup](assets/dashboard_mockup.png)

### Database Objects Integration
The dashboard layout is powered by the views and stored procedures defined in the codebase:

| Visual Element | Dashboard Component | Source Database Object |
| :--- | :--- | :--- |
| **Top KPI Cards** | Revenue, YoY Growth %, Avg Monthly Sales | [v_kpi_dashboard](sql/04_views/01_analytical_views.sql) |
| **Line Chart** | 12-Month Rolling Trailing Sales (TTM) | [v_monthly_industry_summary](sql/04_views/01_analytical_views.sql) |
| **Heatmap Matrix** | Seasonality Indices (Month × Industry) | [v_seasonal_patterns](sql/04_views/01_analytical_views.sql) |
| **Waterfall Chart** | Pre vs. Post COVID-19 Revenue Shifts | [v_yoy_growth](sql/04_views/01_analytical_views.sql) |
| **Rankings Table** | Top 5 Businesses by Annual Sales | [v_top_businesses_by_year](sql/04_views/01_analytical_views.sql) |
| **Drilldown Report** | Interactive Parameterized Reports | [sp_get_industry_report](sql/05_stored_procedures/01_procedures.sql) |

*For full widget layouts, filters, and hex palettes, see the [docs/dashboard_recommendations.md](docs/dashboard_recommendations.md).*

---

## 📂 Repository Structure

```
Sales-for-Retail-and-Food-Services/
│
├── 📄 README.md                              # Project overview & dashboard spec
├── 📄 LICENSE                                # Apache 2.0 License
├── 📄 .gitignore                             # Custom SQL/data project config
│
├── 📁 data/                                  # Source Data
│   └── us_monthly_retail_sales.csv           # Raw dataset (9,048 rows)
│
├── 📁 docs/                                  # Project Documentation
│   ├── data_dictionary.md                    # Column definitions & NAICS ranges
│   ├── architecture.md                       # Execution order & database ERD
│   ├── business_report.md                    # Executive findings & recommendations
│   ├── dashboard_recommendations.md          # BI dashboard UI visual spec
│   └── resume_descriptions.md                # ATS-ready resume project bullet points
│
├── 📁 sql/                                   # SQL Engineering Scripts
│   ├── 00_schema/
│   │   └── 01_create_database.sql            # DDL, database creation, data load
│   ├── 02_basic_analysis/
│   │   └── 01_exploratory_analysis.sql       # 15 fundamental business questions
│   ├── 03_advanced_analysis/
│   │   ├── 01_window_functions.sql           # Window functions showcase (12 examples)
│   │   ├── 02_trend_analysis.sql             # MoM, YoY, CAGR, TTM time-series
│   │   └── 03_pareto_segmentation.sql        # HHI, Z-Score outliers, Volatility CV
│   ├── 04_views/
│   │   └── 01_analytical_views.sql           # 6 dashboard-ready views
│   ├── 05_stored_procedures/
│   │   └── 01_procedures.sql                 # 5 parameterized reporting procedures
│   └── 06_indexes/
│       └── 01_performance_indexes.sql        # Composite, covering, and lookup indexes
│
├── 📁 results/                               # Exported Outputs
│   └── query_outputs/                        # CSV query results for verification
│
└── 📁 assets/                                # Visual Assets
    └── dashboard_mockup.png                  # Dashboard mockup preview image
```

---

## 🚀 Getting Started & Setup

### Prerequisites
* MySQL Server 8.0 or newer
* SQL client (MySQL Workbench, DBeaver, or VS Code SQL extension)
* Access to run `LOAD DATA INFILE` (file privilege) or import wizard permissions

### Quick Database Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/Sales-for-Retail-and-Food-Services.git
   cd Sales-for-Retail-and-Food-Services
   ```

2. **Initialize Schema & Load Data**:
   * Open `sql/00_schema/01_create_database.sql`
   * Update the path on line 49 to point to your local dataset location:
     ```sql
     LOAD DATA INFILE '/your/absolute/path/data/us_monthly_retail_sales.csv'
     ```
   * Run the script in your MySQL console:
     ```bash
     mysql -u root -p < sql/00_schema/01_create_database.sql
     ```

3. **Deploy Database Objects (Views, Procedures, and Indexes)**:
   ```bash
   mysql -u root -p retail_sales_db < sql/06_indexes/01_performance_indexes.sql
   mysql -u root -p retail_sales_db < sql/04_views/01_analytical_views.sql
   mysql -u root -p retail_sales_db < sql/05_stored_procedures/01_procedures.sql
   ```

4. **Run Analytics Queries**:
   You can run any of the analysis scripts in `sql/02_basic_analysis/` and `sql/03_advanced_analysis/` to generate findings.

---

## 📄 License

Distributed under the Apache 2.0 License. See [LICENSE](LICENSE) for details.
