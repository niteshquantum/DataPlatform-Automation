# DataPlatform-Automation

## Overview

DataPlatform-Automation is a reusable Data Engineering automation framework designed to automate:

* Database deployment
* Schema deployment using Liquibase
* Data loading from CSV files
* Environment validation
* Tool installation
* Jenkins pipeline execution

Current supported database:

* MySQL

Future roadmap:

* PostgreSQL
* SQL Server
* MongoDB

---

# Project Architecture

CSV Files
↓
Validation
↓
Database Deployment
↓
Liquibase Schema Deployment
↓
Data Loading
↓
Database Validation

---

# Folder Structure

DataPlatform-Automation/

config/

* mysql/

  * mysql.conf
  * datasets.yaml

datasets/

* mysql/

scripts/

* batch/
* python/
* powershell/
* bash/

terraform/

liquibase/

* mysql/

jenkins/

* mysql/

logs/

tools/

* drivers/
* liquibase/

docs/

---

# Prerequisites

* Python
* MySQL
* Java
* Terraform
* Jenkins

---

# Setup Process

Step 1

Start MySQL

scripts\batch\mysql\start_mysql.bat

Step 2

Validate Environment

scripts\batch\mysql\validate_environment.bat

Step 3

Deploy Database

scripts\batch\mysql\mysql_setup_with_logging.bat

Step 4

Load Data

scripts\batch\mysql\mysql_load_with_logging.bat

---

# Validation Framework

Current validations:

* Python Requirements Validation
* Tool Validation
* Port Validation
* Database Validation
* Table Validation
* CSV Validation
* Required Columns Validation

---

# Tool Installation

Install all tools:

scripts\batch\common\install_tools.bat

Validate tools:

scripts\batch\common\validate_tools.bat

Installed tools:

* Liquibase
* MySQL JDBC Driver

---

# Logging

Generated logs:

logs/mysql_setup.log

logs/mysql_load.log

---

# Jenkins Pipelines

Setup Pipeline

jenkins/mysql/Jenkinsfile.setup

Load Pipeline

jenkins/mysql/Jenkinsfile.load

Pipeline Stages:

Setup:

* Start MySQL
* Validate Environment
* Install Tools
* Deploy MySQL
* Create Database
* Run Liquibase
* Validate MySQL

Load:

* Start MySQL
* Validate Environment
* Validate CSV
* Load Data
* Validate MySQL

---

# Current Status

Completed:

* Infrastructure Automation
* Validation Framework
* Logging Framework
* Tool Installation Framework
* CSV Validation Framework
* Jenkins Pipeline Framework

---

# Future Roadmap

Phase 1

* Jenkins Pipeline V2

Phase 2

* Cleanup Implementation
* Destroy Implementation

Phase 3

* Duplicate Primary Key Validation
* Null Validation
* Datatype Validation
* Foreign Key Validation

Phase 4

* PostgreSQL Support

Phase 5

* SQL Server Support

Phase 6

* MongoDB Support
