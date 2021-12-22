# TPC-DI-MS-SQL-Benchmark

## The files you need...
The report in the `/Deliverables` path provides an overview of how the benchmark was performed.  
The `/Helpers` path has the scripts used to run the benchmark. 

***Note:*** *The DimSecurity table has unresolved issues in this script the result in no data being returned when it is used. As such, use of the FactMarketHistory, FactWatches and a part of DimTrade was left out of the benchmark*

## Instructions for Replication
1.	Generate files following TCP-DI instructions
2.	Use python script to unpack FINWIRE files. This was done using `Helpers/Scripts/ConvertFinwireFilesToCSV.py`
3.	Load files into MS SQL database using SSIS
4.	Move raw files into schema named “source” in SQL table format. The schema was created using `Helpers/Scripts/CreateDBTableSchema.sql`
5.	Transform and load all tables from “source” to “dbo” using main SQL script located here `Helpers/Scripts/historical_load.sql`

Even if you are not using SQL for the transformation, reading through the SQL script will provide you an overview of the transformations needed in whatever integration service you are using.

Have questions? Drop me a line at abroniewski@gmail.com

## Benchmarking Methodology

The following tools were installed to complete the benchmark: 
- SQL Server 2019 Express
- SQL Server Data Tools 2017 (Standalone along with Visual Studio)
- Materials and programs provided by TPC-DI

The benchmark queries and logging were implemented using Microsoft SQL Server Integration Services (SSIS). 
The timing results were plotted in a live Tableau dashboard  that collects the logging results automatically from the database. 
Data was generated using the TPC-DI data generator at 4 scale factors (SF):
- SF 3
- SF 10
- SF 20
- SF 30

There were two research papers used as a general reference for the TPC-DI ETL process that provided support in identifying data quality issues. These papers were:
- Data Quality Problems in TPC-DI Based Data Integration Processes
- TPC-DI: The First Industry Benchmark for Data Integration

A git repository was also used as a reference for the data warehouse table creation. The repository used was:
- https://github.com/detobel36/tpc-di (reviewed and checked against current version of TPC-DI spec)
