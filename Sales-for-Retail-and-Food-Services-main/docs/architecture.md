# 🏗️ Project Architecture

## System Overview

This project follows a structured SQL analytics pipeline pattern, transforming raw U.S. Census Bureau data into actionable business insights through layered SQL analysis.

```
┌─────────────────────────────────────────────────────────────┐
│                     DATA SOURCE                             │
│            U.S. Census Bureau — Monthly Retail               │
│                  Trade Survey (2010-2022)                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                   DATA INGESTION                            │
│              sql/00_schema/                                 │
│   • Database creation (MySQL 8.0+)                          │
│   • Table schema with proper data types                     │
│   • LOAD DATA INFILE from CSV                               │
│   • Post-load validation queries                            │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                EXPLORATORY ANALYSIS                         │
│            sql/02_basic_analysis/                            │
│   • 15 business questions                                   │
│   • Aggregations, filtering, GROUP BY, HAVING               │
│   • Pivots with CASE WHEN                                   │
│   • COVID-19 impact analysis                                │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                 ADVANCED ANALYSIS                           │
│           sql/03_advanced_analysis/                          │
│                                                             │
│   ┌──────────────────┬────────────────┬─────────────────┐   │
│   │  Window Funcs    │  Trend Analysis │  Pareto & Seg  │   │
│   │  ROW_NUMBER()    │  MoM Growth %   │  80/20 Rule    │   │
│   │  RANK()          │  QoQ Growth %   │  NTILE Tiers   │   │
│   │  DENSE_RANK()    │  YoY Growth %   │  Outliers      │   │
│   │  NTILE()         │  CAGR           │  HHI Index     │   │
│   │  LAG() / LEAD()  │  Seasonality    │  Volatility    │   │
│   │  FIRST/LAST_VAL  │  TTM            │  Concentration │   │
│   │  Running Sum     │  COVID Recovery │                │   │
│   │  Moving Average  │                 │                │   │
│   └──────────────────┴────────────────┴─────────────────┘   │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                 PRODUCTION LAYER                            │
│                                                             │
│   ┌───────────────┐  ┌──────────────┐  ┌────────────────┐  │
│   │  6 Views      │  │ 5 Stored     │  │ 10 Indexes     │  │
│   │  (Reusable)   │  │ Procedures   │  │ (Performance)  │  │
│   │               │  │ (Parameterized│  │               │  │
│   │  v_monthly_   │  │  Reports)    │  │ Composite +    │  │
│   │  v_yoy_growth │  │              │  │ Covering       │  │
│   │  v_kpi_dash   │  │  sp_report   │  │               │  │
│   └───────────────┘  └──────────────┘  └────────────────┘  │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    OUTPUT LAYER                             │
│                                                             │
│   ┌────────────────┐  ┌──────────────┐  ┌──────────────┐   │
│   │  Dashboards    │  │  Business    │  │  Query       │   │
│   │  (Power BI /   │  │  Reports     │  │  Results     │   │
│   │   Tableau)     │  │  (Markdown)  │  │  (CSV)       │   │
│   └────────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Folder Structure

```
Sales-for-Retail-and-Food-Services/
│
├── README.md                              # Project overview & documentation
├── LICENSE                                # Apache 2.0 License
├── .gitignore                             # SQL/data project gitignore
│
├── docs/                                  # 📚 Documentation
│   ├── data_dictionary.md                 # Column definitions & NAICS codes
│   ├── architecture.md                    # This file — system design
│   ├── business_report.md                 # Executive summary & insights
│   ├── dashboard_recommendations.md       # Dashboard design specification
│   └── resume_descriptions.md             # Role-specific resume bullets
│
├── sql/                                   # 🔧 SQL Scripts (execution order)
│   ├── 00_schema/
│   │   └── 01_create_database.sql         # DDL + data loading
│   ├── 02_basic_analysis/
│   │   └── 01_exploratory_analysis.sql    # 15 foundational queries
│   ├── 03_advanced_analysis/
│   │   ├── 01_window_functions.sql        # 12 window function demos
│   │   ├── 02_trend_analysis.sql          # 10 trend & growth queries
│   │   └── 03_pareto_segmentation.sql     # 8 segmentation queries
│   ├── 04_views/
│   │   └── 01_analytical_views.sql        # 6 reusable views
│   ├── 05_stored_procedures/
│   │   └── 01_procedures.sql              # 5 parameterized procedures
│   └── 06_indexes/
│       └── 01_performance_indexes.sql     # Strategic index definitions
│
├── data/                                  # 📁 Source Data
│   └── us_monthly_retail_sales.csv        # Raw dataset (9,048 rows)
│
├── results/                               # 📊 Query Output Data
│   └── query_outputs/                     # CSV exports from analysis
│
└── assets/                                # 🎨 Visual Assets
    └── dashboard_mockup.png               # Dashboard design reference
```

---

## SQL Execution Order

Run scripts in this order for a clean setup:

| Step | Script | Purpose |
|------|--------|---------|
| 1 | `sql/00_schema/01_create_database.sql` | Create DB, table, load data |
| 2 | `sql/06_indexes/01_performance_indexes.sql` | Create performance indexes |
| 3 | `sql/04_views/01_analytical_views.sql` | Create reusable views |
| 4 | `sql/05_stored_procedures/01_procedures.sql` | Create stored procedures |
| 5 | `sql/02_basic_analysis/01_exploratory_analysis.sql` | Run basic analysis |
| 6 | `sql/03_advanced_analysis/01_window_functions.sql` | Run window functions |
| 7 | `sql/03_advanced_analysis/02_trend_analysis.sql` | Run trend analysis |
| 8 | `sql/03_advanced_analysis/03_pareto_segmentation.sql` | Run segmentation |

---

## Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Database | MySQL | 8.0+ |
| SQL Features | Window Functions, CTEs, Stored Procedures | MySQL 8.0+ |
| Data Source | U.S. Census Bureau | Monthly Retail Trade Survey |
| Documentation | Markdown | GitHub Flavored |
| Version Control | Git + GitHub | — |
| IDE | VS Code + MySQL Workbench | — |

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Single flat table | Dataset is denormalized from source; no need for star schema at this scale (9K rows) |
| `DECIMAL(12,2)` for sales | Precise financial data — avoids floating-point rounding errors |
| `TINYINT` for month | Space-efficient; month range is 1-12 |
| Composite indexes | Designed to cover the exact query patterns in the analysis scripts |
| Views over materialized views | MySQL doesn't support materialized views natively; views are sufficient for this dataset size |
| Stored procedures | Enable parameterized reporting without modifying SQL scripts |
