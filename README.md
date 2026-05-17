# TPC-DI: MS SQL Server Benchmark

Benchmarking Microsoft SQL Server using the TPC-DI (Data Integration) industry standard, with a full ETL pipeline implemented in T-SQL and SSIS. Completed as part of the Big Data Management and Analytics (BDMA) programme at Université Libre de Bruxelles (ULB), 2021.

## The Problem

- Choosing a database platform for data warehouse workloads requires objective, reproducible performance data.
- The TPC-DI benchmark is the first industry-standard benchmark specifically designed for data integration (ETL) workloads.
- Running the benchmark end-to-end on MS SQL Server required building a full extract, transform, and load pipeline from raw TPC-generated files.

## The Approach

**Inputs:** TPC-DI generated flat files at four scale factors (SF 3, 10, 20, 30), including FINWIRE financial data files.

**Processing:**
1. FINWIRE files converted to CSV using `Helpers/Scripts/ConvertFinwireFilesToCSV.py`.
2. Files loaded into MS SQL Server via SSIS packages.
3. Raw data staged in a `source` schema using `Helpers/Scripts/CreateDBTableSchema.sql`.
4. Data transformed and loaded into the `dbo` schema using `Helpers/Scripts/historical_load.sql`.
5. Benchmark queries executed and timed via SSIS; results logged to the database and visualised in a live Tableau dashboard.

**Outputs:** Query throughput and load time measurements across four scale factors, with a full report in `Deliverables/`.

## Value Delivered

- End-to-end TPC-DI benchmark run on MS SQL Server 2019 across four scale factors.
- Reusable ETL scripts for staging and transforming TPC-DI data in SQL Server.
- Written report documenting methodology, data quality issues encountered, and results.

## Scope & Status

- **Project type:** Academic research / benchmarking
- **Current state:** Archived (completed 2021)
- **Known limitations:**
  - The `DimSecurity` table has unresolved data issues; `FactMarketHistory`, `FactWatches`, and part of `DimTrade` are excluded from the benchmark as a result.
  - Results are hardware-specific; replication on different machines will produce different numbers.
  - SSIS packages require SQL Server Data Tools 2017 or later.

## Tech Stack

- **Database:** Microsoft SQL Server 2019 Express
- **ETL tooling:** SSIS (SQL Server Integration Services)
- **Language:** T-SQL, Python
- **Visualisation:** Tableau
- **Benchmark:** TPC-DI

## Who This Is For

- Data engineers evaluating MS SQL Server for ETL workloads.
- BDMA students or researchers replicating TPC-DI benchmarks.
- Anyone reviewing the author's data engineering and database work.

## Getting Started

1. Generate benchmark files using the TPC-DI data generator.
2. Run `Helpers/Scripts/ConvertFinwireFilesToCSV.py` to convert FINWIRE files.
3. Load files into MS SQL Server using SSIS.
4. Create the source schema: `Helpers/Scripts/CreateDBTableSchema.sql`.
5. Run the main ETL script: `Helpers/Scripts/historical_load.sql`.

See `Deliverables/` for the full report and methodology detail.

Questions? Reach out at abroniewski@gmail.com.

## Project Team

Diogo Repas, Nicole Kovacs, Andres Espinal, Adam Broniewski.

## Credits

- [TPC-DI Benchmark Specification](https://www.tpc.org/tpcdi/)
- Reference repository: [detobel36/tpc-di](https://github.com/detobel36/tpc-di)
- Research papers: *Data Quality Problems in TPC-DI Based Data Integration Processes*; *TPC-DI: The First Industry Benchmark for Data Integration*

## License

Not specified.
