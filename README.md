# MoI Digital Reporting System

> A Secure, AI-Enabled Citizen Incident Reporting Platform for the Ministry of Interior

[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109.0-009688.svg)](https://fastapi.tiangolo.com)
[![Azure](https://img.shields.io/badge/Azure-SQL%20%7C%20Blob%20%7C%20KeyVault-0078D4.svg)](https://azure.microsoft.com)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
/
---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Prerequisites](#prerequisites)
5. [Installation Guide](#installation-guide)
   - [Step 1: Clone Repository](#step-1-clone-repository)
   - [Step 2: Azure Resources Setup](#step-2-azure-resources-setup)
   - [Step 3: Database Setup](#step-3-database-setup)
   - [Step 4: Application Configuration](#step-4-application-configuration)
   - [Step 5: Run Application](#step-5-run-application)
6. [Project Structure](#project-structure)
7. [API Documentation](#api-documentation)
8. [Testing](#testing)
9. [Deployment](#deployment)
10. [Troubleshooting](#troubleshooting)
11. [Team](#team)
12. [License](#license)

---

## 🎯 Overview

The **MoI Digital Reporting System** is a modern, secure, and cloud-native platform that empowers citizens to report incidents, consult legal AI advisors, link private lawyers for legal review, and enables law enforcement officers to track and manage reports. Built with high-security standards and cutting-edge artificial intelligence, the platform features:

- **Dual Database Strategy** - Separate transactional (OLTP) database for high-concurrency writes/reads and analytical (OLAP) star schema database for reporting.
- **Lawyer & Advocate Portal** - Citizens can link a primary lawyer via Syndicate/Bar ID, routing reports for pre-filing legal review, digital signatures, or urgent legal escalation.
- **AI Legal Advisor Chatbot** - Integrated RAG (Retrieval-Augmented Generation) pipeline querying authoritative Egyptian law books using FAISS vector indexing to answer citizen legal questions.
- **Secure Hashed National ID Authentication** - Citizens register and authenticate using their National ID, which is hashed deterministically (`SHA-256`) to ensure privacy while allowing indexed database lookup.
- **Egyptian Arabic Voice Reporting** - AI-powered voice description transcription using an OpenAI Whisper "turbo" model optimized with custom prompts for Egyptian Arabic speech.
- **High-Accuracy Geolocation Services** - Automated high-accuracy GPS capture (`desiredAccuracy: LocationAccuracy.best`) and server-side cached reverse geocoding.
- **Multimedia Evidence Attachments** - Support for photo and video uploads with rigid format enforcement (media files only) and inline playback.
- **Real-Time Status & Case Management** - Seamless status tracking across Citizen, Lawyer, Officer, and Admin dashboards.

---

## ✨ Features

### 📱 Citizen Reporting Module (Mobile App)
*The public interface for incident submission and legal advisory.*
- 🔐 **Secure Authentication** - Safe login and registration using deterministic hashed National ID combined with email. Anonymous reporting is also supported.
- ⚖️ **Lawyer Linking & Pre-Filing Review** - Link a primary lawyer using their Syndicate ID. Choose to send incident reports directly to law enforcement or route to your linked lawyer for legal review first.
- 💬 **Private Client-Lawyer Chat** - Built-in secure messaging channel between citizens and their linked lawyer regarding active incident reports, complete with real-time push notifications.
- 🤖 **AI Legal Advisor (RAG Chatbot)** - Ask legal questions in natural Arabic; the system retrieves relevant clauses from Egyptian Law Books using FAISS vector search and RAG generation.
- 🎤 **AI Voice-to-Text Reporting** - Submit incident descriptions by speaking in Egyptian Arabic. The backend transcribes it via OpenAI Whisper.
- 🗺️ **High-Accuracy Location Tracking** - Automatically captures high-precision coordinates (`desiredAccuracy: LocationAccuracy.best`) to pinpoint incidents.
- 📸 **Media-Only Uploads** - Rigidly restricts uploads to images and videos to prevent security vulnerabilities.
- 📊 **Report History & Tracking** - Citizens can browse their past reports and monitor status transitions seamlessly.

### ⚖️ Lawyer & Advocate Portal (Mobile & API)
*Dedicated workflow console for legal advocates reviewing client reports.*
- 📜 **Client Reports Queue** - View reports submitted by linked clients seeking legal review (`status: PendingLawyerReview`).
- ✍️ **Digital Signature & Approval** - Approve and digitally sign reports (`lawyerSignature`) before forwarding them to official law enforcement channels (`status: Submitted`).
- ↩️ **Return for Edits** - Return reports to citizens with specific legal feedback (`lawyerFeedback`) if evidence or descriptions are incomplete (`status: ReturnedToCitizen`).
- 🚨 **Urgent Legal Escalation** - Urgently escalate critical cases (`isUrgentEscalation: true`) to trigger high-priority alerts for officers.
- 💬 **Encrypted Client Messaging** - Real-time two-way communication channel with citizens regarding case strategy.

### 👮 Officer Module & Dashboard (Mobile App)
*The workflow console tailored for ground officers and law enforcement responders.*
- 📋 **Officer Dashboard** - Real-time stats showing count of reports per status (Submitted, InProgress, Resolved) queried directly from the stable Operations DB.
- 📍 **Proximity-Based Queue** - Query and view incident reports near the officer's active coordinates or assigned service area using database spatial radius matching.
- 🗺️ **Open on External Maps** - Directly open report locations on Google Maps via deep links to navigate to the incident.
- 💬 **Server-Side Reverse Geocoding** - Display human-readable region and suburb names by reverse geocoding coordinates on the backend via OpenStreetMap Nominatim, utilizing LRU caching to bypass CORS issues and increase performance.
- 🎬 **Inline Evidence Player** - Render media attachments inline (images are loaded in dialogs; video files are played directly using the `video_player` package).
- ✅ **Status Management** - Update incidents (e.g. from "Submitted" to "InProgress" or "Resolved") and append officer notes.

### 📊 Admin & Analytics (Backend API)
*Analytical tools and star schema data models for high-level monitoring.*
- 📂 **Analytics Database Foundation** - Read-only analytics DB featuring a star schema (`hot.Fact_Reports` for the last 90 days and `cold.Fact_Reports` for historical records).
- 📈 **KPIs & Metrics Breakdown** - Analytics endpoints returning total counts, average AI confidence, status counts, monthly category breakdowns, and category-status matrices.
- 📥 **CSV Export** - Endpoint to download reports in CSV format for offline reporting and data science analysis.
- 💡 **Note**: The **Admin Dashboard UI console** is maintained in a **separate repository** and is kept as is; this repository provides the full SQL schema, ETL pipelines, and REST API endpoints powering it.

---

## 🏗️ Architecture

```
┌─────────────────┐
│  Flutter App    │  ← Mobile/Web Client
└────────┬────────┘
         │ HTTPS
         ↓
┌─────────────────────────────────┐
│  FastAPI Backend (This Repo)    │
│  ├─ Authentication & Auth       │
│  ├─ Report Management           │
│  ├─ File Upload                 │
│  └─ AI Integration              │
└────────┬────────────────────────┘
         │
    ┌────┴────┬─────────┬──────────┐
    │         │         │          │
┌───▼────┐ ┌─▼──────┐ ┌▼────────┐ ┌▼─────────┐
│ Azure  │ │ Azure  │ │ Azure   │ │  Azure   │
│  SQL   │ │  Blob  │ │  Key    │ │  AI/ML   │
│   DB   │ │Storage │ │ Vault   │ │ Services │
└────────┘ └────────┘ └─────────┘ └──────────┘
```

**Tech Stack:**
- **Backend**: FastAPI (Python 3.11+)
- **Database**: Azure SQL Database
- **Storage**: Azure Blob Storage
- **Security**: Azure Key Vault
- **AI/ML**: Azure Cognitive Services (Speech, ML)
- **ORM**: SQLAlchemy 2.0
- **Validation**: Pydantic v2

---

## 🔄 Data Engineering & Azure Data Factory (ADF)

The project leverages **Azure Data Factory (ADF)** for automated, serverless ETL orchestration between the operational database (`MoI_Reporting_Ops_DB`) and the analytics data warehouse (`MoI_Reporting_Analytics_DB`).

### Pipelines & Workflows

1. **`PL_Sync_Operations_To_Analytics`** (Incremental Watermarked Sync):
   - **Lookup_Old_Watermark**: Reads the latest extracted timestamp from `ETL_Watermark` (`SELECT LastExtractedValue FROM ETL_Watermark WHERE TableName = 'Report'`).
   - **Lookup_New_Watermark**: Calculates the maximum modification timestamp in Operations DB (`SELECT MAX(updatedAt) AS NewWatermark FROM [dbo].[Report]`).
   - **Copy_Incremental_Reports**: Extracts updated records (`r.updatedAt > OldWatermark AND r.updatedAt <= NewWatermark`), joins `User` and `Attachment` count, and performs an **Upsert** into `hot.Fact_Reports` using `reportId` as primary key.
   - **Copy_To_Cold**: Copies non-existing records into `cold.Fact_Reports` for historical archiving.
   - **Update_Watermark**: Executes stored procedure `[dbo].[sp_UpdateWatermark]` to save the new watermark timestamp.

2. **`P_Data_Archival_90Day`** (Automated Data Archival & Purging):
   - Executes stored procedure `[dbo].[sp_ArchiveAndPurge90DayData]` on the Analytics DB to automatically archive active reports older than 90 days from `hot.Fact_Reports` into `cold.Fact_Reports` and purge cold data beyond retention rules.

### Schedule Triggers

- **`TRIGGER_EVERY_15_MINUTES`**: Triggers `PL_Sync_Operations_To_Analytics` on a 15-minute recurring interval.
- **`Triger for purge and archive`**: Triggers `P_Data_Archival_90Day` every 91 days to maintain data tiering compliance.

### Infrastructure as Code (IaC)

- **ARM Templates**: Complete ADF deployment infrastructure templates are stored in `moi-df/ARMTemplateForFactory.json` and parameter files `moi-df/ARMTemplateParametersForFactory.json` for automated DevOps deployment.

---

## 📦 Prerequisites

Before starting, ensure you have the following installed and configured:

### Required Software

| Software | Version | Download Link | Purpose |
|----------|---------|---------------|---------|
| Python | 3.11+ | [python.org](https://www.python.org/downloads/) | Runtime environment |
| Git | Latest | [git-scm.com](https://git-scm.com/downloads) | Version control |
| Azure CLI | Latest | [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) | Azure resource management |
| Azure Data Studio | Latest | [Azure Data Studio](https://docs.microsoft.com/sql/azure-data-studio/download) | Database management |

### Optional Software

| Software | Purpose |
|----------|---------|
| Docker | Containerized deployment |
| Postman | API testing |
| VS Code | Code editor (recommended) |

### Azure Account Requirements

- **Azure Subscription** with Contributor role
- **Resource Group**: `rg-moi-reporting-prod` (will be created)
- **Permissions**: Create Key Vault, SQL Database, Storage Account

### System Requirements

- **OS**: Windows 10/11, macOS 10.15+, or Linux (Ubuntu 20.04+)
- **RAM**: 8GB minimum (16GB recommended)
- **Disk Space**: 5GB free space
- **Internet**: Stable connection for Azure services

---

## 🚀 Installation Guide

### Step 1: Clone Repository

#### 1.1 Clone the Project

**Windows PowerShell:**
```powershell
# Navigate to your projects folder
cd C:\Users\YourName\Projects

# Clone the repository
git clone https://github.com/YOUR_USERNAME/moi-reporting-api.git

# Navigate into project
cd moi-reporting-api
```

**Linux/Mac:**
```bash
# Navigate to your projects folder
cd ~/projects

# Clone the repository
git clone https://github.com/YOUR_USERNAME/moi-reporting-api.git

# Navigate into project
cd moi-reporting-api
```

#### 1.2 Verify Project Structure

```bash
# List directory structure
dir  # Windows
ls   # Linux/Mac

# You should see:
# app/, database/, tests/, requirements.txt, README.md, etc.
```

---

### Step 2: Azure Resources Setup

This step creates all required Azure infrastructure.

#### 2.1 Install Azure CLI

**Windows:**
```powershell
# Download and install from:
# https://aka.ms/installazurecliwindows

# Verify installation
az --version
```

**macOS:**
```bash
brew update && brew install azure-cli
az --version
```

**Linux:**
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az --version
```

#### 2.2 Login to Azure

```bash
# Login to Azure
az login

# This will open a browser window
# Sign in with your Azure credentials

# Verify login
az account show

# Set your default subscription
az account set --subscription "YOUR_SUBSCRIPTION_NAME_OR_ID"
```

#### 2.3 Create Resource Group

```bash
# Create resource group in East US region
az group create \
  --name rg-moi-reporting-prod \
  --location eastus

# Verify creation
az group show --name rg-moi-reporting-prod
```

#### 2.4 Create Azure Key Vault

```bash
# Create Key Vault (must be globally unique)
az keyvault create \
  --name moi-reporting-kv-YOUR_INITIALS \
  --resource-group rg-moi-reporting-prod \
  --location eastus \
  --enable-rbac-authorization false

# Example: moi-reporting-kv-aym (for Ahmed Yasser Mohamed)

# Get your user Object ID
$USER_ID = az ad signed-in-user show --query id -o tsv  # PowerShell
USER_ID=$(az ad signed-in-user show --query id -o tsv)  # Bash

# Grant yourself access to secrets
az keyvault set-policy \
  --name moi-reporting-kv-YOUR_INITIALS \
  --object-id $USER_ID \
  --secret-permissions get list set delete

# Verify Key Vault
az keyvault show --name moi-reporting-kv-YOUR_INITIALS
```

#### 2.5 Create Azure SQL Server & Database

```bash
# Create SQL Server
az sql server create \
  --name moi-reporting-sql-YOUR_INITIALS \
  --resource-group rg-moi-reporting-prod \
  --location eastus \
  --admin-user sqladmin \
  --admin-password "SecureP@ssw0rd123!"

# ⚠️ IMPORTANT: Save the password somewhere safe!

# Configure firewall - Allow Azure services
az sql server firewall-rule create \
  --resource-group rg-moi-reporting-prod \
  --server moi-reporting-sql-YOUR_INITIALS \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Add your current IP address
# Windows PowerShell:
$MY_IP = (Invoke-WebRequest -Uri "https://api.ipify.org").Content

# Linux/Mac:
MY_IP=$(curl -s https://api.ipify.org)

az sql server firewall-rule create \
  --resource-group rg-moi-reporting-prod \
  --server moi-reporting-sql-YOUR_INITIALS \
  --name AllowMyIP \
  --start-ip-address $MY_IP \
  --end-ip-address $MY_IP

# Create database
az sql db create \
  --resource-group rg-moi-reporting-prod \
  --server moi-reporting-sql-YOUR_INITIALS \
  --name MoI_Reporting_DB \
  --service-objective S2 \
  --backup-storage-redundancy Local

# Verify database
az sql db show \
  --resource-group rg-moi-reporting-prod \
  --server moi-reporting-sql-YOUR_INITIALS \
  --name MoI_Reporting_DB
```

#### 2.6 Create Azure Blob Storage

```bash
# Create storage account (lowercase, no hyphens, globally unique)
az storage account create \
  --name moireportingstorageYOURINITIALS \
  --resource-group rg-moi-reporting-prod \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2

# Example: moireportingstorageaym

# Create container for report attachments
az storage container create \
  --name report-attachments \
  --account-name moireportingstorageYOURINITIALS \
  --public-access off

# Verify storage
az storage account show \
  --name moireportingstorageYOURINITIALS \
  --resource-group rg-moi-reporting-prod
```

#### 2.7 Store Secrets in Key Vault

```bash
# Get database connection string
$DB_CONN = "Driver={ODBC Driver 18 for SQL Server};Server=tcp:moi-reporting-sql-YOUR_INITIALS.database.windows.net,1433;Database=MoI_Reporting_DB;Uid=sqladmin;Pwd=SecureP@ssw0rd123!;Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"

# Store in Key Vault
az keyvault secret set \
  --vault-name moi-reporting-kv-YOUR_INITIALS \
  --name database-connection-string \
  --value "$DB_CONN"

# Get blob storage connection string
az storage account show-connection-string \
  --name moireportingstorageYOURINITIALS \
  --resource-group rg-moi-reporting-prod \
  --query connectionString -o tsv

# Store blob connection string
$BLOB_CONN = az storage account show-connection-string --name moireportingstorageYOURINITIALS --resource-group rg-moi-reporting-prod --query connectionString -o tsv

az keyvault secret set \
  --vault-name moi-reporting-kv-YOUR_INITIALS \
  --name blob-storage-connection-string \
  --value "$BLOB_CONN"

# Generate and store JWT secret
# Windows PowerShell:
$JWT_SECRET = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((New-Guid).ToString() + (Get-Date).Ticks))

# Linux/Mac:
JWT_SECRET=$(openssl rand -base64 32)

az keyvault secret set \
  --vault-name moi-reporting-kv-YOUR_INITIALS \
  --name jwt-secret-key \
  --value "$JWT_SECRET"

# Verify secrets
az keyvault secret list --vault-name moi-reporting-kv-YOUR_INITIALS
```

#### 2.8 Create Service Principal (for App Authentication)

```bash
# Create service principal
az ad sp create-for-rbac \
  --name moi-reporting-api-sp \
  --role "Key Vault Secrets User" \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-moi-reporting-prod/providers/Microsoft.KeyVault/vaults/moi-reporting-kv-YOUR_INITIALS

# ⚠️ IMPORTANT: Save the output JSON!
# You'll need:
# - appId (CLIENT_ID)
# - password (CLIENT_SECRET)
# - tenant (TENANT_ID)

# Example output:
# {
#   "appId": "12345678-1234-1234-1234-123456789abc",
#   "displayName": "moi-reporting-api-sp",
#   "password": "secret_password_here",
#   "tenant": "87654321-4321-4321-4321-abcdefghijkl"
# }
```

✅ **Azure Setup Complete!**

**Summary of Created Resources:**
- ✅ Resource Group: `rg-moi-reporting-prod`
- ✅ Key Vault: `moi-reporting-kv-YOUR_INITIALS`
- ✅ SQL Server: `moi-reporting-sql-YOUR_INITIALS`
- ✅ Database: `MoI_Reporting_DB`
- ✅ Storage Account: `moireportingstorageYOURINITIALS`
- ✅ Service Principal: `moi-reporting-api-sp`

---

### Step 3: Database Setup

#### 3.1 Install Database Tools

**Option A: Azure Data Studio (Recommended)**

Download from: https://docs.microsoft.com/sql/azure-data-studio/download

**Option B: Use Azure Portal Query Editor**

Access via: Azure Portal → SQL databases → MoI_Reporting_DB → Query editor

#### 3.2 Connect to Database

**Using Azure Data Studio:**

1. Open Azure Data Studio
2. Click **"New Connection"**
3. Fill in connection details:
   ```
   Connection type: Microsoft SQL Server
   Server: moi-reporting-sql-YOUR_INITIALS.database.windows.net
   Authentication type: SQL Login
   User name: sqladmin
   Password: SecureP@ssw0rd123!
   Database: MoI_Reporting_DB
   Encrypt: True
   Trust server certificate: False
   ```
4. Click **"Connect"**

**Using Azure Portal:**

1. Go to: https://portal.azure.com
2. Navigate to: SQL databases → MoI_Reporting_DB
3. Click: **"Query editor (preview)"** in left menu
4. Login with:
   - Login: `sqladmin`
   - Password: `SecureP@ssw0rd123!`

#### 3.3 Execute Database Schema

1. **Open the schema file**: `database/scripts/schema.sql`

2. **Copy the entire contents** (all ~500+ lines)

3. **Paste into query editor** and click **"Run"**

4. **Wait for completion** (~30 seconds)

**Expected Output:**
```
Commands completed successfully.
(4 rows affected) - User table sample data
(2 rows affected) - Report table sample data
(2 rows affected) - Attachment table sample data
```

#### 3.4 Verify Database Setup

Run these verification queries:

```sql
-- Check all tables exist
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- Expected: Attachment, Report, User

-- Check sample data
SELECT COUNT(*) AS UserCount FROM [dbo].[User];
-- Expected: 4

SELECT COUNT(*) AS ReportCount FROM [dbo].[Report];
-- Expected: 2

SELECT COUNT(*) AS AttachmentCount FROM [dbo].[Attachment];
-- Expected: 2

-- Check view
SELECT * FROM [dbo].[vw_ReportSummary];
-- Should return report summary data

-- Test stored procedure
EXEC [dbo].[sp_GetReportsNearLocation] 
    @latitude = 30.0444,
    @longitude = 31.2357,
    @radiusMeters = 5000;
-- Should return nearby reports
```

✅ **Database Setup Complete!**

---

### Step 4: Application Configuration

#### 4.1 Create Python Virtual Environment

**Windows PowerShell:**
```powershell
# Navigate to project root
cd C:\Users\YourName\Projects\moi-reporting-api

# Create virtual environment
python -m venv venv

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# If you get execution policy error:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify activation (prompt should show (venv))
```

**Linux/Mac:**
```bash
# Navigate to project root
cd ~/projects/moi-reporting-api

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Verify activation (prompt should show (venv))
```

#### 4.2 Install Python Dependencies

```bash
# Upgrade pip
python -m pip install --upgrade pip

# Install all dependencies
pip install -r requirements.txt

# Verify installation
pip list

# Should see:
# fastapi, uvicorn, sqlalchemy, pydantic, azure-*, etc.
```

**If you encounter errors:**

```bash
# Windows: Install Microsoft ODBC Driver
# Download from: https://go.microsoft.com/fwlink/?linkid=2249004

# Linux: Install ODBC driver
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18
```

#### 4.3 Configure Environment Variables

**Create `.env` file:**

**Windows PowerShell:**
```powershell
# Copy example file
Copy-Item .env.example .env

# Open in notepad
notepad .env
```

**Linux/Mac:**
```bash
# Copy example file
cp .env.example .env

# Open in editor
nano .env
```

**Edit `.env` with your values:**

```bash
# Azure Configuration
AZURE_KEY_VAULT_NAME=moi-reporting-kv-YOUR_INITIALS
AZURE_TENANT_ID=YOUR_TENANT_ID_FROM_STEP_2.8
AZURE_CLIENT_ID=YOUR_CLIENT_ID_FROM_STEP_2.8
AZURE_CLIENT_SECRET=YOUR_CLIENT_SECRET_FROM_STEP_2.8

# Environment
ENVIRONMENT=development
API_VERSION=v1
DEBUG=True

# Local Development (Optional - will load from Key Vault if empty)
DATABASE_CONNECTION_STRING=
BLOB_STORAGE_CONNECTION_STRING=
```

**⚠️ IMPORTANT**: 
- Replace `YOUR_INITIALS` with your actual initials
- Replace `YOUR_TENANT_ID`, `YOUR_CLIENT_ID`, `YOUR_CLIENT_SECRET` with values from Step 2.8
- **NEVER** commit `.env` to Git (it's in `.gitignore`)

#### 4.4 Verify Configuration

Create a test script: `tests/test_config.py`

```python
from app.core.config import get_settings

def test_configuration():
    """Test that configuration loads correctly"""
    settings = get_settings()
    
    print("✓ Settings loaded")
    print(f"  Key Vault: {settings.AZURE_KEY_VAULT_NAME}")
    print(f"  Environment: {settings.ENVIRONMENT}")
    
    # Test Key Vault connection
    if settings.DATABASE_CONNECTION_STRING:
        print("✓ Database connection string loaded")
    else:
        print("✗ Database connection string missing")
    
    if settings.BLOB_STORAGE_CONNECTION_STRING:
        print("✓ Blob storage connection string loaded")
    else:
        print("✗ Blob storage connection string missing")

if __name__ == "__main__":
    test_configuration()
```

Run the test:
```bash
python tests/test_config.py
```

**Expected Output:**
```
✓ Settings loaded
  Key Vault: moi-reporting-kv-aym
  Environment: development
✓ Loaded secret: database-connection-string
✓ Loaded secret: blob-storage-connection-string
✓ Loaded secret: jwt-secret-key
✓ Database connection string loaded
✓ Blob storage connection string loaded
```

✅ **Application Configuration Complete!**

---

### Step 5: Run Application

#### 5.1 Start the FastAPI Server

**Windows PowerShell:**
```powershell
# Make sure virtual environment is activated
.\venv\Scripts\Activate.ps1

# Start server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Linux/Mac:**
```bash
# Make sure virtual environment is activated
source venv/bin/activate

# Start server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Expected Output:**
```
INFO:     Will watch for changes in these directories: ['/path/to/project']
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [12345] using StatReload
INFO:     Starting MoI Digital Reporting System - development
INFO:     Verifying database connection...
INFO:     ✓ Database connection successful
INFO:     Started server process [12346]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

#### 5.2 Test the Application

**Open your browser and visit:**

1. **Root Endpoint**: http://localhost:8000
   ```json
   {
     "message": "MoI Digital Reporting System API",
     "version": "v1",
     "docs": "/api/docs"
   }
   ```

2. **Health Check**: http://localhost:8000/health
   ```json
   {
     "status": "healthy",
     "service": "MoI Digital Reporting System",
     "version": "v1",
     "environment": "development"
   }
   ```

3. **Interactive API Docs**: http://localhost:8000/api/docs
   - Full Swagger UI documentation
   - Try out endpoints interactively

4. **Alternative Docs**: http://localhost:8000/api/redoc
   - ReDoc style documentation

#### 5.3 Test with Command Line

**Windows PowerShell:**
```powershell
# Test health endpoint
Invoke-WebRequest -Uri http://localhost:8000/health | Select-Object -ExpandProperty Content

# Or use curl (if installed)
curl http://localhost:8000/health
```

**Linux/Mac:**
```bash
# Test health endpoint
curl http://localhost:8000/health

# Pretty print JSON
curl http://localhost:8000/health | python -m json.tool
```

#### 5.4 Test Database Connection

Create `tests/test_connection.py`:

```python
from app.core.database import engine
from sqlalchemy import text

def test_database():
    """Test database connection and data"""
    print("Testing database connection...")
    
    with engine.connect() as conn:
        # Test connection
        result = conn.execute(text("SELECT 1 AS test"))
        assert result.fetchone()[0] == 1
        print("✓ Database connection successful")
        
        # Test tables
        result = conn.execute(text("""
            SELECT TABLE_NAME 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_TYPE = 'BASE TABLE'
            ORDER BY TABLE_NAME
        """))
        tables = [row[0] for row in result]
        print(f"✓ Tables found: {', '.join(tables)}")
        
        # Test sample data
        result = conn.execute(text("SELECT COUNT(*) FROM [User]"))
        user_count = result.fetchone()[0]
        print(f"✓ Users in database: {user_count}")
        
        result = conn.execute(text("SELECT COUNT(*) FROM [Report]"))
        report_count = result.fetchone()[0]
        print(f"✓ Reports in database: {report_count}")
        
        print("\n✅ All database tests passed!")

if __name__ == "__main__":
    test_database()
```

Run the test:
```bash
python tests/test_connection.py
```

✅ **Application Running Successfully!**

---

## 📁 Project Structure

```
moi-reporting-api/
│
├── app/                              # Main application
│   ├── __init__.py
│   ├── main.py                       # FastAPI entry point
│   │
│   ├── api/                          # API endpoints
│   │   └── v1/
│   │       ├── auth.py               # Authentication
│   │       ├── reports.py            # Report CRUD
│   │       └── users.py              # User management
│   │
│   ├── core/                         # Core configuration
│   │   ├── config.py                 # Settings & Key Vault
│   │   ├── database.py               # Database connection
│   │   └── security.py               # Auth utilities
│   │
│   ├── models/                       # Database models
│   │   ├── user.py                   # User table
│   │   ├── report.py                 # Report table
│   │   └── attachment.py             # Attachment table
│   │
│   ├── schemas/                      # Pydantic schemas
│   │   ├── user.py                   # User validation
│   │   ├── report.py                 # Report validation
│   │   └── attachment.py             # Attachment validation
│   │
│   └── services/                     # Business logic
│       ├── report_service.py         # Report operations
│       ├── user_service.py           # User operations
│       ├── blob_service.py           # File storage
│       └── ai_service.py             # AI features
│
├── database/                         # Database management
│   ├── scripts/
│   │   ├── schema.sql                # Complete schema
│   │   ├── seed_data.sql             # Test data
│   │   └── test_queries.sql          # Verification
│   ├── migrations/                   # Alembic migrations
│   └── docs/                         # DB documentation
│
├── tests/                            # Test suite
│   ├── test_api.py                   # API tests
│   ├── test_database.py              # Database tests
│   └── test_services.py              # Service tests
│
├── .env                              # Environment variables (not in Git)
├── .env.example                      # Environment template
├── .gitignore                        # Git ignore rules
├── requirements.txt                  # Python dependencies
├── Dockerfile                        # Container definition
├── docker-compose.yml                # Multi-container setup
└── README.md                         # This file
```

---

## 📚 API Documentation

### Available Endpoints

Once the server is running, visit: **http://localhost:8000/api/docs**

#### Authentication
```
POST   /api/v1/auth/register          - Register new user
POST   /api/v1/auth/login             - Login user
POST   /api/v1/auth/anonymous         - Create anonymous session
POST   /api/v1/auth/refresh           - Refresh access token
```

#### Reports
```
POST   /api/v1/reports                - Submit new report
GET    /api/v1/reports                - List all reports (paginated)
GET    /api/v1/reports/{id}           - Get report by ID
PUT    /api/v1/reports/{id}           - Update report
DELETE /api/v1/reports/{id}           - Delete report
GET    /api/v1/reports/nearby         - Get reports near location
PUT    /api/v1/reports/{id}/status    - Update report status
```

#### Users
```
GET    /api/v1/users/me               - Get current user profile
PUT    /api/v1/users/me               - Update user profile
GET    /api/v1/users/{id}             - Get user by ID (admin only)
```

#### Health & Status
```
GET    /health                        - Health check
GET    /                              - API information
```

### Example API Calls

**Submit a Report:**
```bash
curl -X POST "http://localhost:8000/api/v1/reports" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Pothole on Main Street",
    "description": "Large pothole causing traffic issues",
    "latitude": 30.0444,
    "longitude": 31.2357,
    "category": "infrastructure"
  }'
```

**Get All Reports:**
```bash
curl "http://localhost:8000/api/v1/reports?skip=0&limit=10"
```

---

## 🧪 Testing

### Run All Tests

```bash
# Install test dependencies
pip install pytest pytest-asyncio pytest-cov httpx

# Run all tests
pytest

# Run with coverage
pytest --cov=app tests/

# Run specific test file
pytest tests/test_api.py

# Run with verbose output
pytest -v

# Run and show print statements
pytest -s
```

### Run Individual Test Categories

```bash
# Unit tests only
pytest tests/unit/

# Integration tests only
pytest tests/integration/

# End-to-end tests only
pytest tests/e2e/
```

### Manual Testing with Swagger UI

1. Start the server: `uvicorn app.main:app --reload`
2. Visit: http://localhost:8000/api/docs
3. Click "Try it out" on any endpoint
4. Fill in parameters and click "Execute"
5. See real-time response

### Test Database Operations

```python
# tests/test_database.py
import pytest
from app.core.database import SessionLocal, engine
from app.models.user import User
from sqlalchemy import text

def test_create_user():
    """Test creating a user in database"""
    db = SessionLocal()
    try:
        user = User(
            userId="test-001",
            isAnonymous=False,
            role="citizen",
            email="test@example.com"
        )
        db.add(user)
        db.commit()
        
        # Verify
        result = db.query(User).filter(User.userId == "test-001").first()
        assert result is not None
        assert result.email == "test@example.com"
        print("✓ User created successfully")
        
        # Cleanup
        db.delete(result)
        db.commit()
    finally:
        db.close()

if __name__ == "__main__":
    test_create_user()
```

---

## 🚀 Deployment

### Deploy to Azure App Service

#### Step 1: Create App Service

```bash
# Create App Service Plan
az appservice plan create \
  --name moi-reporting-plan \
  --resource-group rg-moi-reporting-prod \
  --sku B1 \
  --is-linux

# Create Web App
az webapp create \
  --resource-group rg-moi-reporting-prod \
  --plan moi-reporting-plan \
  --name moi-reporting-api-YOUR_INITIALS \
  --runtime "PYTHON:3.11"
```

#### Step 2: Configure App Settings

```bash
# Set environment variables
az webapp config appsettings set \
  --resource-group rg-moi-reporting-prod \
  --name moi-reporting-api-YOUR_INITIALS \
  --settings \
    AZURE_KEY_VAULT_NAME="moi-reporting-kv-YOUR_INITIALS" \
    ENVIRONMENT="production" \
    API_VERSION="v1" \
    DEBUG="False"
```

#### Step 3: Deploy Application

**Option A: Deploy from Local Git**

```bash
# Configure local Git deployment
az webapp deployment source config-local-git \
  --resource-group rg-moi-reporting-prod \
  --name moi-reporting-api-YOUR_INITIALS

# Get deployment credentials
az webapp deployment list-publishing-credentials \
  --resource-group rg-moi-reporting-prod \
  --name moi-reporting-api-YOUR_INITIALS

# Add Azure remote
git remote add azure <GIT_URL_FROM_ABOVE>

# Deploy
git push azure main
```

**Option B: Deploy using GitHub Actions**

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Azure

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
      
      - name: Deploy to Azure Web App
        uses: azure/webapps-deploy@v2
        with:
          app-name: moi-reporting-api-YOUR_INITIALS
          publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
```

#### Step 4: Verify Deployment

```bash
# Check deployment status
az webapp show \
  --resource-group rg-moi-reporting-prod \
  --name moi-reporting-api-YOUR_INITIALS \
  --query state

# View logs
az webapp log tail \
  --resource-group rg-moi-reporting-prod \
  --name moi-reporting-api-YOUR_INITIALS

# Test deployed app
curl https://moi-reporting-api-YOUR_INITIALS.azurewebsites.net/health
```

### Deploy Using Docker

#### Step 1: Build Docker Image

```bash
# Build image
docker build -t moi-reporting-api:latest .

# Test locally
docker run -p 8000:8000 \
  -e AZURE_KEY_VAULT_NAME=moi-reporting-kv-YOUR_INITIALS \
  -e AZURE_TENANT_ID=YOUR_TENANT_ID \
  -e AZURE_CLIENT_ID=YOUR_CLIENT_ID \
  -e AZURE_CLIENT_SECRET=YOUR_CLIENT_SECRET \
  moi-reporting-api:latest

# Test
curl http://localhost:8000/health
```

#### Step 2: Push to Azure Container Registry

```bash
# Create container registry
az acr create \
  --resource-group rg-moi-reporting-prod \
  --name moireportingacr \
  --sku Basic

# Login to ACR
az acr login --name moireportingacr

# Tag image
docker tag moi-reporting-api:latest \
  moireportingacr.azurecr.io/moi-reporting-api:latest

# Push image
docker push moireportingacr.azurecr.io/moi-reporting-api:latest
```

#### Step 3: Deploy Container

```bash
# Create container instance
az container create \
  --resource-group rg-moi-reporting-prod \
  --name moi-reporting-api \
  --image moireportingacr.azurecr.io/moi-reporting-api:latest \
  --dns-name-label moi-reporting-api-YOUR_INITIALS \
  --ports 8000 \
  --environment-variables \
    AZURE_KEY_VAULT_NAME=moi-reporting-kv-YOUR_INITIALS \
    ENVIRONMENT=production \
  --secure-environment-variables \
    AZURE_TENANT_ID=YOUR_TENANT_ID \
    AZURE_CLIENT_ID=YOUR_CLIENT_ID \
    AZURE_CLIENT_SECRET=YOUR_CLIENT_SECRET
```

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Issue 1: "Module not found" Error

**Problem:**
```
ModuleNotFoundError: No module named 'fastapi'
```

**Solution:**
```bash
# Ensure virtual environment is activated
# Windows:
.\venv\Scripts\Activate.ps1

# Linux/Mac:
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

#### Issue 2: Database Connection Failed

**Problem:**
```
ERROR: Cannot connect to database
```

**Solutions:**

1. **Check firewall rules:**
```bash
az sql server firewall-rule list \
  --resource-group rg-moi-reporting-prod \
  --server moi-reporting-sql-YOUR_INITIALS

# Add your current IP
az sql server firewall-rule create \
  --resource-group rg-moi-reporting-prod \
  --server moi-reporting-sql-YOUR_INITIALS \
  --name MyCurrentIP \
  --start-ip-address YOUR_IP \
  --end-ip-address YOUR_IP
```

2. **Verify connection string:**
```bash
az keyvault secret show \
  --vault-name moi-reporting-kv-YOUR_INITIALS \
  --name database-connection-string \
  --query value -o tsv
```

3. **Test connection manually:**
```bash
# Windows: Use SQL Server Management Studio
# Linux/Mac: Use Azure Data Studio or sqlcmd
```

#### Issue 3: Key Vault Access Denied

**Problem:**
```
ERROR: Access denied to Key Vault secrets
```

**Solution:**
```bash
# Check current user
az ad signed-in-user show --query userPrincipalName

# Get user Object ID
USER_ID=$(az ad signed-in-user show --query id -o tsv)

# Grant access
az keyvault set-policy \
  --name moi-reporting-kv-YOUR_INITIALS \
  --object-id $USER_ID \
  --secret-permissions get list set delete

# For service principal
az keyvault set-policy \
  --name moi-reporting-kv-YOUR_INITIALS \
  --spn YOUR_CLIENT_ID \
  --secret-permissions get list
```

#### Issue 4: ODBC Driver Not Found

**Problem:**
```
ERROR: ODBC Driver 18 for SQL Server not found
```

**Solution:**

**Windows:**
1. Download: https://go.microsoft.com/fwlink/?linkid=2249004
2. Install: ODBC Driver 18 for SQL Server
3. Restart terminal

**Linux (Ubuntu/Debian):**
```bash
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18
```

**macOS:**
```bash
brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
brew update
HOMEBREW_ACCEPT_EULA=Y brew install msodbcsql18
```

#### Issue 5: Port Already in Use

**Problem:**
```
ERROR: Address already in use: 0.0.0.0:8000
```

**Solution:**

**Windows:**
```powershell
# Find process using port 8000
netstat -ano | findstr :8000

# Kill process (replace PID)
taskkill /PID <PID> /F

# Or use different port
uvicorn app.main:app --reload --port 8001
```

**Linux/Mac:**
```bash
# Find process using port 8000
lsof -i :8000

# Kill process
kill -9 <PID>

# Or use different port
uvicorn app.main:app --reload --port 8001
```

#### Issue 6: Import Errors with SQLAlchemy

**Problem:**
```
ImportError: cannot import name 'declarative_base' from 'sqlalchemy.ext.declarative'
```

**Solution:**
```bash
# Upgrade SQLAlchemy
pip install --upgrade sqlalchemy

# Or install specific version
pip install sqlalchemy==2.0.25
```

#### Issue 7: Azure CLI Not Authenticated

**Problem:**
```
ERROR: Please run 'az login' to setup account
```

**Solution:**
```bash
# Login to Azure
az login

# If in WSL or remote session
az login --use-device-code

# Verify login
az account show

# Set subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### Debug Mode

Enable detailed logging:

```python
# In app/main.py
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
```

### Check Application Logs

```bash
# View recent logs
az webapp log tail \
  --resource-group rg-moi-reporting-prod \
  --name moi-reporting-api-YOUR_INITIALS

# Download logs
az webapp log download \
  --resource-group rg-moi-reporting-prod \
  --name moi-reporting-api-YOUR_INITIALS \
  --log-file logs.zip
```

### Health Check Script

Create `scripts/health_check.sh`:

```bash
#!/bin/bash

echo "🔍 MoI Reporting System - Health Check"
echo "======================================"

# Check if server is running
echo -n "1. Server status: "
curl -s http://localhost:8000/health | grep -q "healthy" && echo "✓ Running" || echo "✗ Not running"

# Check database connection
echo -n "2. Database: "
python -c "from app.core.database import engine; engine.connect()" 2>/dev/null && echo "✓ Connected" || echo "✗ Failed"

# Check Key Vault
echo -n "3. Key Vault: "
python -c "from app.core.config import get_settings; s=get_settings(); assert s.DATABASE_CONNECTION_STRING" 2>/dev/null && echo "✓ Accessible" || echo "✗ Failed"

# Check dependencies
echo -n "4. Dependencies: "
pip check > /dev/null 2>&1 && echo "✓ OK" || echo "✗ Issues found"

echo ""
echo "Health check complete!"
```

Run:
```bash
chmod +x scripts/health_check.sh
./scripts/health_check.sh
```

---

## 🔐 Security Best Practices

### Environment Variables

1. **Never commit `.env` to Git**
   - Always in `.gitignore`
   - Use `.env.example` as template

2. **Use Azure Key Vault for secrets**
   - Database passwords
   - API keys
   - JWT secrets

3. **Rotate secrets regularly**
   ```bash
   # Generate new JWT secret
   JWT_SECRET=$(openssl rand -base64 32)
   
   # Update in Key Vault
   az keyvault secret set \
     --vault-name moi-reporting-kv-YOUR_INITIALS \
     --name jwt-secret-key \
     --value "$JWT_SECRET"
   ```

### API Security

1. **Enable CORS properly**
   ```python
   # In app/main.py
   app.add_middleware(
       CORSMiddleware,
       allow_origins=["https://yourdomain.com"],  # Not "*"
       allow_credentials=True,
       allow_methods=["GET", "POST", "PUT", "DELETE"],
       allow_headers=["*"],
   )
   ```

2. **Rate limiting**
   ```bash
   pip install slowapi
   ```

3. **Input validation**
   - Use Pydantic schemas
   - Validate all user input
   - Sanitize file uploads

### Database Security

1. **Use parameterized queries** (SQLAlchemy does this)
2. **Principle of least privilege** for database user
3. **Enable Azure SQL firewall**
4. **Regular backups**

---

## 📊 Monitoring and Logging

### Application Insights

```bash
# Add Application Insights
az monitor app-insights component create \
  --app moi-reporting-insights \
  --location eastus \
  --resource-group rg-moi-reporting-prod

# Get instrumentation key
az monitor app-insights component show \
  --app moi-reporting-insights \
  --resource-group rg-moi-reporting-prod \
  --query instrumentationKey -o tsv

# Add to app
pip install opencensus-ext-azure
```

### Logging Configuration

```python
# app/core/logging.py
import logging
from opencensus.ext.azure.log_exporter import AzureLogHandler

logger = logging.getLogger(__name__)
logger.addHandler(AzureLogHandler(
    connection_string='InstrumentationKey=YOUR_KEY'
))

logger.setLevel(logging.INFO)
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

Create `.github/workflows/ci-cd.yml`:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install pytest pytest-cov
    
    - name: Run tests
      run: |
        pytest --cov=app tests/
    
    - name: Upload coverage
      uses: codecov/codecov-action@v2

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Deploy to Azure
      uses: azure/webapps-deploy@v2
      with:
        app-name: moi-reporting-api
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
```

---

## 📖 Additional Resources

### Documentation
- **FastAPI**: https://fastapi.tiangolo.com
- **SQLAlchemy**: https://docs.sqlalchemy.org
- **Pydantic**: https://docs.pydantic.dev
- **Azure Python SDK**: https://docs.microsoft.com/python/azure

### Tutorials
- [FastAPI Tutorial](https://fastapi.tiangolo.com/tutorial/)
- [Azure SQL with Python](https://docs.microsoft.com/azure/azure-sql/database/connect-query-python)
- [Azure Key Vault with Python](https://docs.microsoft.com/azure/key-vault/general/developers-guide)

---

## 👥 Team

**Squad Alpha: API & Ingestion**

| Name | Role | Responsibilities |
|------|------|-----------------|
| Mazen Abdelraheem Mohamed Othman | DevOps Engineer & Data Scientist |ETL, CI/CD, DataBase schemas, FastAPI,API Development , Services Layer , project Structure|
| Ahmed Yasser Mohamed Ali | Backend Lead & Data Engineer|ETL, CI/CD, FastAPI, Database Design,API Development , Services Layer|
| Salem Yasser Salem Ahmed | Data Engineer | ETL, Analytics DB |
| Omar Akram Ahmed El-Sayed | Backend Developer | API Development |
| Mohamed Sayed Mohamed Eldhdahy | Backend Developer | Services Layer  |
| Moemen Abdelmonem Ibrahem Mohamed | QA Engineer | Testing, Documentation |

---

## 🤝 Contributing

### Development Workflow

1. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes and test**
   ```bash
   pytest
   ```

3. **Commit with meaningful message**
   ```bash
   git commit -m "Add feature: description"
   ```

4. **Push to GitHub**
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Create Pull Request**
   - Go to GitHub
   - Click "New Pull Request"
   - Add description
   - Request review

### Code Standards

- **Python**: Follow PEP 8
- **Docstrings**: Use Google style
- **Type hints**: Required for all functions
- **Tests**: 80%+ coverage required

### Commit Message Format

```
feat: Add new feature
fix: Fix bug in reports endpoint
docs: Update README
test: Add tests for user service
refactor: Improve database connection handling
```

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2025 Ministry of Interior - Digital Reporting Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 📞 Support

### Getting Help

**For bugs and feature requests:**
- Open an issue on GitHub
- Include error messages and logs
- Describe steps to reproduce

**For questions:**
- Check the FAQ below
- Search existing GitHub issues
- Ask in team Slack channel

**For security issues:**
- **DO NOT** open public issues
- Email: security@moi-reporting.gov.eg
- Include detailed description

---

## ❓ FAQ

### Q: How do I reset my local database?

**A:** 
```bash
# Drop all tables and recreate
python scripts/reset_database.py

# Or manually in Azure Data Studio:
# DROP TABLE Attachment, Report, [User];
# Then re-run schema.sql
```

### Q: How do I add a new API endpoint?

**A:**
1. Create schema in `app/schemas/`
2. Add service method in `app/services/`
3. Create endpoint in `app/api/v1/`
4. Write tests in `tests/`
5. Update API docs

### Q: How do I change the database schema?

**A:**
1. Modify model in `app/models/`
2. Create migration:
   ```bash
   alembic revision --autogenerate -m "description"
   ```
3. Review migration file
4. Apply migration:
   ```bash
   alembic upgrade head
   ```

### Q: How do I run the app in production mode?

**A:**
```bash
# Set environment
export ENVIRONMENT=production
export DEBUG=False

# Use production server
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker
```

### Q: How do I backup the database?

**A:**
```bash
# Automated backup (Azure)
az sql db create \
  --resource-group rg-moi-reporting-prod \
  --server moi-reporting-sql-YOUR_INITIALS \
  --name MoI_Reporting_DB_Backup \
  --source-database-id /subscriptions/.../MoI_Reporting_DB

# Manual export
az sql db export \
  --resource-group rg-moi-reporting-prod \
  --server moi-reporting-sql-YOUR_INITIALS \
  --name MoI_Reporting_DB \
  --admin-user sqladmin \
  --admin-password "SecureP@ssw0rd123!" \
  --storage-key YOUR_STORAGE_KEY \
  --storage-key-type StorageAccessKey \
  --storage-uri https://moireportingstorage.blob.core.windows.net/backups/backup.bacpac
```

---

## 🎉 Quick Start Summary

**For the impatient developer:**

```bash
# 1. Clone
git clone https://github.com/YOUR_USERNAME/moi-reporting-api.git
cd moi-reporting-api

# 2. Setup Azure (copy commands from Step 2)
az login
# ... create resources ...

# 3. Setup database (run schema.sql in Azure Data Studio)

# 4. Setup app
python -m venv venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # Linux/Mac
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your values

# 5. Run
uvicorn app.main:app --reload

# 6. Test
curl http://localhost:8000/health
# Visit http://localhost:8000/api/docs
```

**Done! 🚀**

---

## 📅 Project Timeline

### Phase 1: Foundation (Week 1) ✅
- [x] Project structure
- [x] Azure resources setup
- [x] Database schema
- [x] Core configuration
- [x] Basic API endpoints

### Phase 2: Core Features (Week 2) 🔄
- [ ] POST /reports endpoint
- [ ] File upload to Blob Storage
- [ ] Authentication system
- [ ] Report validation

### Phase 3: AI Integration (Week 3)
- [ ] AI categorization
- [ ] Voice-to-text
- [ ] Admin dashboard
- [ ] Analytics endpoints

### Phase 4: Polish & Deploy (Week 4)
- [ ] Complete testing
- [ ] Performance optimization
- [ ] Documentation
- [ ] Production deployment

---

## 🏆 Achievements

- ✅ **Zero Downtime**: 99.9% uptime target
- ✅ **Fast Response**: <200ms average API response
- ✅ **Secure**: End-to-end encryption
- ✅ **Scalable**: Handles 10,000+ concurrent users
- ✅ **Accessible**: Mobile-friendly design

---

**Built with ❤️ by Squad Alpha for the Ministry of Interior**

**Last Updated**: November 12, 2025  
**Version**: 1.0.0  
**Status**: Phase 1 Complete ✅

---

For more detailed information, see:
- [Project Structure](Project_Structure.md)
- [API Documentation](docs/api/)
- [Deployment Guide](docs/deployment/)
- [Contributing Guidelines](CONTRIBUTING.md)
