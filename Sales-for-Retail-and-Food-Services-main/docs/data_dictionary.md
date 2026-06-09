# 📊 Data Dictionary

## Dataset: U.S. Monthly Retail Trade Survey

**Source**: [U.S. Census Bureau — Monthly Retail Trade Survey](https://www.census.gov/retail/index.html)  
**Coverage**: January 2010 — December 2022 (13 years, 156 months)  
**Total Records**: 9,048 rows  
**Granularity**: Monthly sales by business type within industry sectors

---

## Table: `retail_sales`

| # | Column | Data Type | Nullable | Description |
|---|--------|-----------|----------|-------------|
| 1 | `id` | `INT AUTO_INCREMENT` | No | Primary key — unique row identifier |
| 2 | `month` | `TINYINT` | No | Calendar month (1 = January, 12 = December) |
| 3 | `year` | `SMALLINT` | No | Calendar year (range: 2010–2022) |
| 4 | `naics_code` | `VARCHAR(20)` | Yes | [NAICS](https://www.census.gov/naics/) classification code |
| 5 | `kind_of_business` | `VARCHAR(255)` | No | Specific business sub-category (e.g., "New car dealers") |
| 6 | `industry` | `VARCHAR(100)` | No | High-level industry grouping (e.g., "Automotive") |
| 7 | `sales` | `DECIMAL(12,2)` | Yes | Monthly sales in **millions of USD** |

---

## Column Details

### `month` (1–12)
Standard calendar month. Used for seasonality analysis, MoM trends, and monthly aggregation.

### `year` (2010–2022)
Calendar year. The dataset spans **13 years**, enabling long-term trend analysis, CAGR calculations, and COVID-19 impact studies (2019 vs 2020).

### `naics_code`
The **North American Industry Classification System (NAICS)** is the standard used by federal statistical agencies to classify business establishments. Codes can be:
- 3-digit (broad sector, e.g., `441` = Motor vehicle dealers)
- 4-digit (sub-sector, e.g., `4411` = Automobile dealers)
- 5-digit (industry group, e.g., `44111` = New car dealers)
- Composite (e.g., `44,114,412` = combined category)

Some rows have `NULL` NAICS codes where the category is an aggregated total.

### `kind_of_business`
The specific business sub-category as defined by the Census Bureau. There are **63 unique business types** in the dataset. Examples:
- "New car dealers"
- "Women's clothing stores"
- "Grocery stores"
- "Food services and drinking places"

### `industry`
High-level industry grouping mapped from NAICS codes. There are **12 unique industries**:

| Industry | NAICS Range | Description |
|----------|-------------|-------------|
| Automotive | 441–4413 | Vehicle dealers, parts, tires |
| Home Goods & Electronics | 442–443 | Furniture, electronics, appliances |
| Home Goods & Building Supplies | 444 | Building materials, hardware, garden |
| Food & Beverage | 445 | Grocery, specialty food, beer/wine |
| Health & Personal Care | 446 | Pharmacies, cosmetics, optical goods |
| Fuel & Gasoline | 447 | Gas stations, fuel dealers |
| Fashion & Accessories | 448 | Clothing, shoes, jewelry |
| Sports & Recreation | 451 | Sporting goods, books, music, hobbies |
| General Merchandise | 452 | Department stores, warehouse clubs |
| Miscellaneous | 453–454 | Gift shops, nonstore retailers, online |
| Office Supplies & Gifts | 4532 | Office supplies, stationery, gifts |
| Restaurants & Bars | 722 | Full-service restaurants, bars, cafeterias |

### `sales`
Monthly sales figures reported in **millions of U.S. dollars**.
- Values are reported by the U.S. Census Bureau's Monthly Retail Trade Survey
- `NULL` values exist where data was not reported or suppressed for confidentiality
- Original zero values were converted to `NULL` during data cleaning

---

## Data Quality Notes

| Aspect | Detail |
|--------|--------|
| **NULL Sales** | ~200 records have NULL sales (suppressed by Census Bureau) |
| **Time Range** | Complete monthly data from Jan 2010 to Dec 2022 |
| **Hierarchy** | Some businesses are sub-categories of others (e.g., "Automobile dealers" is a subset of "Motor vehicle and parts dealers") |
| **Currency** | All sales values are in millions of USD, not adjusted for inflation |
| **Seasonality** | Data exhibits strong seasonal patterns, especially in retail (Nov-Dec peaks) |

---

## Entity-Relationship Diagram

```
┌──────────────────────────────────┐
│          retail_sales            │
├──────────────────────────────────┤
│ PK  id         INT AUTO_INC     │
│     month      TINYINT NOT NULL │
│     year       SMALLINT NOT NULL│
│     naics_code VARCHAR(20)      │
│     kind_of_business VARCHAR(255)│
│     industry   VARCHAR(100)     │
│     sales      DECIMAL(12,2)    │
├──────────────────────────────────┤
│ IDX idx_year_month              │
│ IDX idx_industry                │
│ IDX idx_kind_of_business        │
│ IDX idx_naics_code              │
│ IDX idx_industry_year           │
│ IDX idx_industry_year_month     │
│ IDX idx_covering_sales          │
└──────────────────────────────────┘
```

---

## Sample Data

| id | month | year | naics_code | kind_of_business | industry | sales |
|----|-------|------|------------|------------------|----------|-------|
| 1 | 1 | 2022 | 441 | Motor vehicle and parts dealers | Automotive | 113548.00 |
| 2 | 1 | 2022 | 44,114,412 | Automobile and other motor vehicle dealers | Automotive | 104500.00 |
| 3 | 1 | 2022 | 4411 | Automobile dealers | Automotive | 96689.00 |
| 4 | 1 | 2022 | 44111 | New car dealers | Automotive | 84442.00 |
| 5 | 1 | 2022 | 44112 | Used car dealers | Automotive | 12247.00 |
