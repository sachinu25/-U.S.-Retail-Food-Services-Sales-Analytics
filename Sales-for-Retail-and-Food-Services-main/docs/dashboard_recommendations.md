# 📊 Dashboard Design Specification

## U.S. Retail & Food Services — Analytics Dashboard

---

## Dashboard Layout

The dashboard should follow a **Z-pattern reading flow** with KPI cards at the top, primary visuals in the middle, and detail tables at the bottom.

```
┌──────────────────────────────────────────────────────────────────┐
│  HEADER: U.S. Retail & Food Services — Sales Analytics          │
│  [Year Filter ▼]  [Industry Filter ▼]  [Business Type ▼]       │
├──────────┬──────────┬──────────┬──────────┬──────────┬──────────┤
│  Total   │  YoY     │  Avg     │  Top     │  Top     │  Active  │
│  Revenue │  Growth% │  Monthly │  Industry│  Business│  Segments│
│  $X.XB   │  +X.X%   │  $X.XM   │  Name    │  Name    │  12      │
├──────────┴──────────┴──────────┴──────────┴──────────┴──────────┤
│                                                                  │
│  ┌────────────────────────────┐  ┌────────────────────────────┐  │
│  │   📈 LINE CHART            │  │   📊 BAR CHART              │  │
│  │   Monthly Sales Trend      │  │   Sales by Industry         │  │
│  │   (Multi-year overlay)     │  │   (Horizontal, sorted)      │  │
│  └────────────────────────────┘  └────────────────────────────┘  │
│                                                                  │
│  ┌────────────────────────────┐  ┌────────────────────────────┐  │
│  │   🔥 HEATMAP               │  │   🌳 TREEMAP                │  │
│  │   Sales by Month × Year    │  │   Revenue Contribution      │  │
│  │   (Seasonality)            │  │   by Business Type           │  │
│  └────────────────────────────┘  └────────────────────────────┘  │
│                                                                  │
│  ┌────────────────────────────┐  ┌────────────────────────────┐  │
│  │   📉 WATERFALL CHART       │  │   🍩 DONUT CHART            │  │
│  │   COVID Impact by Industry │  │   Market Share by Industry  │  │
│  │   (2019 vs 2020)           │  │   (Current Year)            │  │
│  └────────────────────────────┘  └────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────────┐│
│  │   📋 DETAIL TABLE                                            ││
│  │   Business-Level Performance with Ranking & Growth           ││
│  └──────────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────┘
```

---

## KPI Cards (Top Row)

| # | KPI | SQL Source | Purpose |
|---|-----|-----------|---------|
| 1 | **Total Revenue** | `SELECT SUM(sales) FROM retail_sales WHERE year = @year` | Overall revenue magnitude |
| 2 | **YoY Growth %** | View: `v_yoy_growth` | Performance vs prior year |
| 3 | **Avg Monthly Sales** | `SELECT AVG(sales)...` | Normalized per-month metric |
| 4 | **Top Industry** | View: `v_kpi_dashboard` → `top_industry` | Industry leader identification |
| 5 | **Top Business** | View: `v_kpi_dashboard` → `top_business` | Business category leader |
| 6 | **Active Segments** | `SELECT COUNT(DISTINCT industry)...` | Coverage metric |

---

## Visualization Specifications

### 1. 📈 Line Chart — Monthly Sales Trend

| Attribute | Specification |
|-----------|---------------|
| **Type** | Multi-series line chart |
| **X-Axis** | Month (Jan–Dec) |
| **Y-Axis** | Total Sales (in millions USD) |
| **Series** | One line per year (2019, 2020, 2021, 2022) |
| **Purpose** | Compare monthly patterns across years to identify seasonality and COVID disruption |
| **Business Value** | Reveals seasonal peaks (Nov–Dec), COVID dips (Apr 2020), and recovery trajectory |
| **Insight Generated** | December consistently peaks; April 2020 was the lowest point; 2022 exceeds 2019 across all months |
| **SQL Source** | `SELECT year, month, SUM(sales) FROM retail_sales WHERE year IN (2019,2020,2021,2022) GROUP BY year, month` |
| **Interactivity** | Click on data point → drill down to industry breakdown for that month |

### 2. 📊 Horizontal Bar Chart — Sales by Industry

| Attribute | Specification |
|-----------|---------------|
| **Type** | Horizontal bar chart (sorted descending) |
| **X-Axis** | Total Sales |
| **Y-Axis** | Industry names |
| **Color** | Gradient (darkest = highest sales) |
| **Purpose** | Show relative revenue size of each industry |
| **Business Value** | Instantly identifies which sectors drive the economy |
| **Insight Generated** | Automotive dominates; wide gap between top 3 and bottom industries |
| **SQL Source** | `SELECT industry, SUM(sales) FROM retail_sales WHERE year = @year GROUP BY industry ORDER BY 2 DESC` |

### 3. 🔥 Heatmap — Sales by Month × Year

| Attribute | Specification |
|-----------|---------------|
| **Type** | Matrix heatmap |
| **Rows** | Years (2010–2022) |
| **Columns** | Months (Jan–Dec) |
| **Color Scale** | Cold (blue) → Hot (red) based on sales value |
| **Purpose** | Visualize seasonality patterns and year-over-year growth simultaneously |
| **Business Value** | Identifies consistent seasonal patterns and anomalous periods (COVID-19 in 2020) |
| **Insight Generated** | November-December are consistently "hot" across all years; April 2020 shows a cold spot |
| **SQL Source** | Query Q12 from `01_exploratory_analysis.sql` |

### 4. 🌳 Treemap — Revenue Contribution by Business Type

| Attribute | Specification |
|-----------|---------------|
| **Type** | Treemap (proportional rectangles) |
| **Hierarchy** | Industry → Kind of Business |
| **Size** | Total sales (area proportional to revenue) |
| **Color** | Industry category (consistent color per industry) |
| **Purpose** | Show hierarchical revenue breakdown at a glance |
| **Business Value** | Reveals which sub-categories within industries contribute most |
| **Insight Generated** | "Motor vehicle and parts dealers" visually dominates; many small niche segments visible |
| **SQL Source** | Query Q11 from `01_exploratory_analysis.sql` |

### 5. 📉 Waterfall Chart — COVID-19 Impact

| Attribute | Specification |
|-----------|---------------|
| **Type** | Waterfall / bridge chart |
| **Categories** | Industries (sorted by impact magnitude) |
| **Positive Bars** | Industries that grew during COVID (green) |
| **Negative Bars** | Industries that declined (red) |
| **Reference Line** | 2019 baseline = 0 |
| **Purpose** | Quantify the pandemic's sector-by-sector impact |
| **Business Value** | Shows which sectors are pandemic-resilient vs. vulnerable |
| **Insight Generated** | Grocery grew while restaurants collapsed; building supplies surged |
| **SQL Source** | Query Q15 from `01_exploratory_analysis.sql` |

### 6. 🍩 Donut Chart — Market Share by Industry

| Attribute | Specification |
|-----------|---------------|
| **Type** | Donut chart with center total |
| **Segments** | One per industry |
| **Center Value** | Total annual revenue |
| **Purpose** | Show proportional market share distribution |
| **Business Value** | Understand industry concentration and competitive landscape |
| **Insight Generated** | Top 3 industries hold ~50% of total retail sales |
| **SQL Source** | Window function `pct_of_total` from `01_window_functions.sql` (W11) |

### 7. 📈 Area Chart — Running Total (YTD Cumulative)

| Attribute | Specification |
|-----------|---------------|
| **Type** | Stacked area chart |
| **X-Axis** | Month (Jan–Dec) |
| **Y-Axis** | Cumulative YTD Sales |
| **Series** | One area per year |
| **Purpose** | Track progress toward annual targets |
| **Business Value** | Early warning if current year is tracking below/above plan |
| **SQL Source** | Window function `ytd_cumulative_sales` from `01_window_functions.sql` (W09) |

### 8. 📊 Grouped Bar Chart — Top 5 vs Bottom 5 Businesses

| Attribute | Specification |
|-----------|---------------|
| **Type** | Diverging horizontal bar chart |
| **Left (Green)** | Top 5 by sales |
| **Right (Red)** | Bottom 5 by sales |
| **Purpose** | Contrast revenue leaders vs. laggards |
| **Business Value** | Identify both opportunities (leaders to emulate) and risks (declining segments) |
| **SQL Source** | Queries Q03 and Q04 from `01_exploratory_analysis.sql` |

---

## Filters & Interactivity

| Filter | Type | Default | Options |
|--------|------|---------|---------|
| Year | Dropdown | 2022 | 2010–2022 |
| Industry | Multi-select | All | 12 industries |
| Business Type | Search dropdown | All | 63 business types |
| Month Range | Slider | Jan–Dec | 1–12 |

---

## Color Palette

| Element | Color | Hex |
|---------|-------|-----|
| Primary (Headers) | Deep Navy | `#1B2A4A` |
| Accent (KPIs) | Electric Blue | `#2196F3` |
| Positive Growth | Emerald Green | `#00C853` |
| Negative Growth | Coral Red | `#FF5252` |
| Neutral | Slate Gray | `#607D8B` |
| Background | Off-White | `#F5F7FA` |

---

## Implementation Options

| Tool | Effort | Best For |
|------|--------|----------|
| **Power BI** | Medium | Enterprise dashboards, scheduled refresh |
| **Tableau** | Medium | Visual exploration, publishing to Tableau Public |
| **Looker Studio** (Google) | Low | Free, shareable dashboards |
| **Streamlit** (Python) | High | Custom interactive apps |
| **Excel** | Low | Quick prototyping, pivot tables |

---

## SQL Views Powering the Dashboard

| Dashboard Element | SQL View/Procedure |
|-------------------|--------------------|
| All KPI Cards | `v_kpi_dashboard` |
| Monthly Trend | `v_monthly_industry_summary` |
| YoY Growth Bars | `v_yoy_growth` |
| Top Businesses Table | `v_top_businesses_by_year` |
| Seasonality Heatmap | `v_seasonal_patterns` |
| Full Executive Report | `CALL sp_executive_dashboard(2022)` |
| Industry Deep-Dive | `CALL sp_get_industry_report(2022, 'Automotive')` |
