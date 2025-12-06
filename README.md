# Salling-Group

Salling Group – Automated Foodwaste Data Pipeline

This repository contains an automated R-based data pipeline developed for Salling Group.
The pipeline fetches foodwaste and clearance data from an external API, cleans and transforms the datasets, and loads them into a MariaDB database running on an AWS EC2 instance.

The pipeline is designed for daily production use, and is executed automatically via a Linux cron job.

📌 Features

Automated API ingestion using R

Data cleaning, validation and transformation

Writing processed datasets into MariaDB

Logging of each pipeline run for monitoring

Git versioning for reproducibility and change tracking

Fully automated execution via cron on an AWS EC2 Ubuntu server

🛠️ Tech Stack

R (tidyverse, httr, jsonlite, DBI, RMariaDB)

MariaDB on AWS EC2

Shell scripting for automation

├── update_foodwaste.R     # Main R script – fetch, clean, write to DB
├── logs/                  # Log output from each run
├── cronjob.sh             # Shell script triggered by cron
└── README.md              # Project documentation

⚙️ How It Works
1. Fetch API Data

The script retrieves fresh data from Salling Group’s API endpoints.

2. Clean & Transform

Data is cleaned, validated, structured, and converted into production-ready tables.

3. Database Load

The processed tables are written to a MariaDB database using DBI and RMariaDB.

4. Logging

Each run produces a detailed log including:

Timestamp

API connection status

Cleaning steps

Database write results

5. Automation

A cron job on the EC2 instance triggers a shell script, which runs the R pipeline once per day.

🚀 Deployment

The pipeline runs automatically on an AWS EC2 Ubuntu instance.

Example cron entry:

0 5 * * * /home/ubuntu/cronjob.sh

📈 Purpose

This pipeline ensures:

Reliable, repeatable daily ingestion

Clean and structured data for analysis

A stable backend for dashboards, BI, and reporting

Better visibility into foodwaste and clearance trends

👤 Author

Stefan Bondo
Data Analysis student and developer of automated data workflows.

Cron scheduler for daily runs

GitHub for version control
