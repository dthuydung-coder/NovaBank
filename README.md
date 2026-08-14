# NovaBank — Bank Loan Risk Analysis

A data analytics project using **SQL** and **Power BI** to explore a bank loan portfolio, analyze borrower and loan characteristics, and visualize credit-risk patterns through an interactive dashboard.

## Project Objective

The project is designed to turn raw loan data into a clear analytical view of portfolio performance and risk. The analysis focuses on understanding how loan characteristics and borrower segments relate to repayment/default behavior and identifying groups that may require closer monitoring.

## Tools & Technologies

- **SQL** — data cleaning, transformation, feature creation, aggregation, and analytical queries
- **Power BI** — data modeling, dashboard development, filtering, and visualization
- **Power Query** — data preparation and transformation
- **DAX** — calculated measures and dashboard KPIs

## Analysis Workflow

1. **Data preparation in SQL**
   - Cleaned and standardized the source data.
   - Created analytical fields and customer/loan segments.
   - Used aggregations and conditional logic to support risk analysis.

2. **Exploratory analysis**
   - Compared portfolio performance across different loan and borrower groups.
   - Examined variables such as loan amount bands, loan grades, loan terms, and risk scores.
   - Evaluated patterns associated with default and repayment behavior.

3. **Power BI dashboard**
   - Built an interactive dashboard with KPI cards, charts, tables, and slicers.
   - Enabled drill-down analysis across risk and loan segments.
   - Organized the report so users can move from portfolio-level KPIs to detailed borrower/loan views.

## Dashboard Preview

> Dashboard screenshot will be added in `screenshots/`.

![NovaBank Power BI Dashboard](screenshots/dashboard-overview.png)

## Repository Structure

```text
NovaBank/
├── README.md
├── sql/
│   └── README.md
├── powerbi/
│   └── README.md
└── screenshots/
    └── README.md
```

## Files to Explore

- `sql/` — SQL scripts used for cleaning, transformation, and analysis
- `powerbi/` — Power BI `.pbix` project file
- `screenshots/` — dashboard screenshots for quick preview without opening Power BI

## How to View the Project

For a quick review, open the dashboard image in `screenshots/`. For the full interactive report, download the `.pbix` file from `powerbi/` and open it with **Power BI Desktop**.

## Author

**Do Thuy Dung**  
Data Analytics Portfolio Project
