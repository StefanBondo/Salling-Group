🛒 Salling Group – Anti Food Waste Data Pipeline
📌 Project Overview

This project demonstrates a complete end-to-end data pipeline for collecting, processing, storing, and analysing Anti Food Waste offers from the Salling Group API.

The solution is designed to run both locally and on a Linux server (Ubuntu / AWS EC2) and focuses on automation, reproducibility, and clean data handling.

Developed as part of an academic examination

Awarded the highest grade (12) for technical implementation and structure

🎯 Project Purpose

The project aims to:

Automatically collect Anti Food Waste data by postcode

Store structured data in a relational database

Enable analysis of:

product types

time-based patterns

Demonstrate real-world data engineering workflows

⚙️ Key Features

API ingestion using the Salling Group Food Waste API

Parameterised execution via command line arguments

Automated execution using cron

Execution logging for monitoring and debugging

Secure credential handling using environment variables

Separation of:

data collection

processing logic

data storage

🧰 Tech Stack

R – data collection and transformation

MariaDB / MySQL – relational data storage

Ubuntu Linux – server environment

AWS EC2 – cloud hosting

Git & GitHub – version control and deployment

cron – task scheduling and automation

```bash
📁 Project Structure
Salling-Group/
│
├── Valby test.R           # Main data pipeline script
├── update.log             # Log file from scheduled runs
├── README.md              # Project documentation
├── main_df.xlsx           # Example output (local testing)
├── main_clearances.xlsx   # Example output (local testing)
└── SQL/                   # SQL table definitions (optional)
```

🔄 How the Pipeline Works

Reads postcode from the command line

Fetches Anti Food Waste data from the API

Cleans and structures store and offer data

Converts timestamps from ISO 8601 to SQL datetime

Writes data to the database:

main_df (stores)

clearance_df (offers)

Logs execution status and timestamps

▶️ Running the Script
```bash
Rscript "Valby test.R" 2500

Manual execution with logging
Rscript "Valby test.R" 2500 >> update.log 2>&1

Automated execution (cron – hourly example)
0 * * * * /usr/bin/Rscript /home/ubuntu/git/Salling-Group/Valby\ test.R 2500 >> /home/ubuntu/git/Salling-Group/update.log 2>&1
```

🗄️ Database Design

main_df

One row per store

Primary key: store_id

clearance_df

One row per offer

Linked to stores via store_id

This structure supports:

efficient SQL queries

downstream analysis in R

scalable data collection

🔐 Security & Best Practices

Database credentials handled via Sys.getenv()

No secrets committed to GitHub

Same codebase runs locally and on server

Absolute paths used for cron execution

🚀 Possible Extensions

Support for multiple postcodes per run

Deduplication and historical tracking

Dashboard visualisation (Power BI / Shiny)

Predictive modelling of offer timing

Integration with additional data sources

👤 Author

Stefan Torp Bondo
