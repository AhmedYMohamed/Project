# Technical Architecture & Engineering Master Report
## Ministry of Interior (MoI) Digital Reporting System

> **Document Type**: Master Technical Blueprint & Tool Justification Report  
> **Author**: Lead Software Architect & Data Engineering Team  
> **Target Audience**: Technical Evaluators, Enterprise Architects, and AI Generation Engines (Claude 3.5/3.7)  
> **Project Version**: 1.1.0  
> **Date**: July 31, 2026  

---

## 📋 Table of Contents

1. [Executive Summary & Architectural Vision](#1-executive-summary--architectural-vision)
2. [Technology Stack & Justification Matrix](#2-technology-stack--justification-matrix)
3. [Security & Authentication Engineering](#3-security--authentication-engineering)
4. [AI & Speech Processing Architecture](#4-ai--speech-processing-architecture)
5. [Legal RAG Chatbot & Legal Advisory Engine](#5-legal-rag-chatbot--legal-advisory-engine)
6. [Lawyer & Advocate Portal Architecture](#6-lawyer--advocate-portal-architecture)
7. [Officer Dispatch & Geospatial Engineering](#7-officer-dispatch--geospatial-engineering)
8. [Dual Database Architecture & Data Modeling (OLTP vs OLAP)](#8-dual-database-architecture--data-modeling-oltp-vs-olap)
9. [Data Engineering & Azure Data Factory (ADF) Deep Dive](#9-data-engineering--azure-data-factory-adf-deep-dive)
10. [Frontend Mobile Architecture (Flutter / Dart)](#10-frontend-mobile-architecture-flutter--dart)
11. [Complete REST API Specifications](#11-complete-rest-api-specifications)
12. [Deployment, Infrastructure & Operations](#12-deployment-infrastructure--operations)

---

## 1. Executive Summary & Architectural Vision

The **Ministry of Interior (MoI) Digital Reporting System** is an enterprise-grade, cloud-native platform designed to bridge citizens, legal advocates, and law enforcement officers. It provides a secure, privacy-first mechanism for incident reporting, pre-filing legal consultation, advocate review, automated AI transcription, and real-time analytical monitoring.

### Key Architectural Pillars:
1. **Privacy & Identity Security**: Deterministic `SHA-256` hashing for citizen National IDs allows database lookup without storing unencrypted Personally Identifiable Information (PII).
2. **Pre-Filing Advocate Review**: Citizens can route reports to linked private lawyers via Syndicate/Bar IDs for pre-filing legal review, digital signatures, or urgent legal escalation before reaching police records.
3. **AI-Assisted Processing**: Local OpenAI Whisper speech recognition fine-tuned with Egyptian Arabic prompts, combined with an offline Retrieval-Augmented Generation (RAG) legal chatbot indexing Egyptian Law Books via FAISS.
4. **Dual Database Architecture (OLTP / OLAP Separation)**: Complete separation between high-concurrency transactional writes (`MoI_Reporting_Ops_DB`) and analytical reporting data warehousing (`MoI_Reporting_Analytics_DB`).
5. **Serverless Enterprise Data Engineering**: Azure Data Factory (ADF) pipelines handle automated incremental sync via watermark tables every 15 minutes, alongside 90-day automated hot/cold data tiering.

---

## 2. Technology Stack & Justification Matrix

This section provides a rigorous justification for every technology, framework, and library selected for the project compared to industry alternatives.

| Layer / Domain | Tool / Technology Selected | Industry Alternatives Considered | Architectural Justification & Trade-off Analysis |
| :--- | :--- | :--- | :--- |
| **Backend Framework** | **FastAPI (Python 3.11+)** | Django, Flask, Express.js | FastAPI utilizes ASGI (Starlette) for high-concurrency asynchronous I/O, matching Node.js speed while leveraging Python's AI/ML ecosystem. Native Pydantic v2 validation ensures automatic schema generation, strict request validation, and auto-generated Swagger UI / ReDoc. |
| **Mobile Client** | **Flutter (Dart)** | React Native, Native Swift/Kotlin | Single codebase compiled natively to ARM/x86 binaries for iOS, Android, and Web. Skia/Impeller rendering engines provide smooth 60 FPS UI performance for custom designs without JavaScript bridge overhead. |
| **Transactional DB (OLTP)** | **Azure SQL Database (Operations)** | PostgreSQL, MongoDB | Enterprise-grade compliance, high-availability SLA (99.99%), built-in query store, and native integration with Azure Key Vault and Azure Data Factory. Transactional compliance (ACID) ensures report consistency. |
| **Analytics DB (OLAP)** | **Azure SQL Star Schema (Analytics)** | Snowflake, Amazon Redshift | Isolating analytical queries into hot (`last 90 days`) and cold (`archived`) fact schemas prevents resource contention on operational tables. Azure SQL Star Schema provides columnstore indexing at lower operational cost than dedicated warehouses. |
| **ETL Orchestration** | **Azure Data Factory (ADF)** | Apache Airflow, Custom Python Scripts | Serverless cloud-native orchestration with native Azure connectors. Built-in watermark incremental loading, automatic retries, zero compute server maintenance, and Infrastructure as Code (IaC) via ARM templates. |
| **Speech Recognition** | **Local OpenAI Whisper ("turbo")** | Azure Speech API, Google Cloud STT | Eliminates per-request API costs and data privacy leakage. Loading the Whisper "turbo" model locally allows custom initial prompts (`يا باشا، إحنا هنا بنتكلم مصري عادي...`) for superior Egyptian Arabic transcription accuracy. |
| **Legal AI Chatbot** | **FAISS + RAG Pipeline (LangChain)** | Fine-Tuned GPT-4, Custom LLM | Fine-tuning LLMs risks hallucination of non-existent laws. RAG retrieves exact legal clauses from indexed Egyptian Law Books (`All_Law_Books`), delivering 100% verifiable legal context with source attribution. |
| **Geospatial & Geocoding** | **OpenStreetMap Nominatim + Server-Side LRU Cache** | Client-Side Google Maps Geocoding API | Client-side CORS restrictions prevent direct browser calls to open OSM servers. Moving geocoding to backend Python with `@lru_cache(maxsize=1000)` eliminates API billing costs and delivers instant cached responses for nearby coordinates. |
| **Identity Protection** | **Deterministic SHA-256 Hashing** | Plaintext, RSA Asymmetric Encryption | Plaintext risks data breaches. Asymmetric encryption requires decrypting entire tables in memory to search. Deterministic `SHA-256` hashing enables direct indexed database lookups (`WHERE hashedNationalId = hash(input)`) while keeping National IDs anonymous. |
| **File Storage** | **Dual Strategy (Local Mounted / Azure Blob)** | AWS S3, Cloudinary | Local storage mounted via FastAPI StaticFiles for low-latency local dev (`/local_storage`), seamlessly falling back to Azure Blob Storage for production scalability with SAS download token generation. |

---

## 3. Security & Authentication Engineering

### 3.1 Deterministic SHA-256 National ID Hashing
Citizens authenticate using their 14-digit Egyptian National ID. To comply with privacy laws:
$$\text{HashedID} = \text{SHA256}(\text{NationalID} + \text{SystemSalt})$$
- **Index Optimization**: A unique non-clustered filtered index is created on `dbo.[User](hashedNationalId)` filtering `WHERE hashedNationalId IS NOT NULL`.
- **Query Execution**: User login executes `SELECT * FROM dbo.[User] WHERE hashedNationalId = :hash`.

### 3.2 Role-Based Access Control (RBAC)
The system enforces strict access control across 4 distinct roles:
1. `citizen`: Can submit reports, link a lawyer, chat with lawyer, query RAG legal chatbot.
2. `lawyer`: Can view assigned client reports, sign/approve, return with feedback, escalate, and chat with clients.
3. `officer`: Can query nearby reports within spatial radius, view status metrics, open Google Maps intents, view inline evidence, and update report status.
4. `admin`: Can view high-level analytics KPIs, export CSV data, monitor system health.

### 3.3 Secrets Management via Azure Key Vault
Environment settings load dynamically from Azure Key Vault or `.env` using Pydantic Settings. Database connection strings, JWT secret keys (`SECRET_KEY`), and Azure service keys are fetched at startup.

---

## 4. AI & Speech Processing Architecture

### 4.1 Local OpenAI Whisper Turbo Integration
Voice descriptions recorded by citizens in the mobile client are posted to `/api/v1/voice/transcribe`.
- **Model Loader**: Global singleton pattern initializes the Whisper `turbo` model on first request.
- **Dialect Optimization**: Egyptian Arabic prompt tuning is passed into transcription:
  ```python
  my_prompt = "يا باشا، إحنا هنا بنتكلم مصري عادي، وبنقول كلام زي 'إزيك' و'عملت إيه' و'شغل الموتور'. ركز مع اللهجة المصرية."
  result = model.transcribe(temp_file_path, language="ar", initial_prompt=my_prompt)
  ```
- **Lifecycle Management**: Uploaded audio files are stored under `temp_audio/` with UUID names, transcribed, and deleted in a `finally` block to prevent disk leakage.

---

## 5. Legal RAG Chatbot & Legal Advisory Engine

### 5.1 Retrieval-Augmented Generation (RAG) Architecture
Citizens can ask legal questions via `/api/v1/chatbot/chat`.
- **Corpus**: Authoritative Egyptian Law Books stored in PDF format under `RAG_pipeline/All_Law_Books`.
- **Indexing Engine**: `DataPipeline` processes PDFs, chunking legal clauses, generating embeddings, and storing them in a local FAISS index (`faiss_index`).
- **Access Guard**: Endpoint enforces `user_role == 'citizen'`.
- **Query Flow**:
  1. Citizen submits natural language query in Arabic.
  2. RAG pipeline searches FAISS index for top-$k$ relevant legal clauses.
  3. LLM synthesizes an authoritative answer referencing relevant article numbers.

---

## 6. Lawyer & Advocate Portal Architecture

### 6.1 Advocate Registration & Client Linking
- **Advocate Registration**: Advocates register via `/api/v1/auth/register/lawyer` supplying their Syndicate/Bar ID (`syndicateId`).
- **Account Linking**: Citizens enter their lawyer's Syndicate ID in their profile. The system links `user.lawyerId` to the advocate's `userId`.

### 6.2 Pre-Filing Legal Review Workflow
When submitting a report, citizens can toggle `sendToLawyer = true`:
```
   [Citizen Form] 
         │ (sendToLawyer = true)
         ▼
[Report Created: status = 'PendingLawyerReview', lawyerId = linkedLawyer]
         │
         ├───► Lawyer Action: "approve" ──► [status = 'Submitted', signed by Lawyer] ──► [Officer Queue]
         ├───► Lawyer Action: "return"  ──► [status = 'ReturnedToCitizen', feedback] ──► [Citizen Form]
         └───► Lawyer Action: "escalate"──► [status = 'Submitted', isUrgentEscalation = true] ──► [High-Priority Officer Queue]
```

### 6.3 Encrypted Client-Lawyer Messaging
- **Endpoint**: `/api/v1/lawyer/reports/{report_id}/messages` (GET & POST).
- **Validation**: Enforces that only the assigned citizen or linked lawyer can view/send messages.
- **Push Notifications**: Triggered via `NotificationService` whenever a message or action is taken.

---

## 7. Officer Dispatch & Geospatial Engineering

### 7.1 Spatial Proximity Queries
Officers retrieve reports within their active region via `/api/v1/officer/reports/nearby`.
- **Euclidean/Haversine Search**: Queries reports within radius `radius_deg` around coordinates or active `OfficerServiceArea`.
- **CORS-Free Reverse Geocoding**: `/api/v1/officer/location/name` uses server-side Python calls to OpenStreetMap Nominatim with `@lru_cache(maxsize=1000)` caching, returning human-readable suburb/city names.
- **Resilient Dashboard Metrics**: `/api/v1/officer/dashboard/stats` queries Operations DB directly, ensuring officer status counts work even if the Analytics DB is undergoing maintenance.

---

## 8. Dual Database Architecture & Data Modeling (OLTP vs OLAP)

### 8.1 Operations Database Schema (`MoI_Reporting_Ops_DB`)

```sql
CREATE TABLE [dbo].[User] (
    [userId] NVARCHAR(450) NOT NULL PRIMARY KEY,
    [isAnonymous] BIT NOT NULL DEFAULT 0,
    [createdAt] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
    [role] NVARCHAR(50) NOT NULL CHECK ([role] IN ('citizen', 'officer', 'admin', 'lawyer')),
    [email] NVARCHAR(256) NULL,
    [phoneNumber] NVARCHAR(20) NULL,
    [hashedDeviceId] NVARCHAR(256) NULL,
    [hashedNationalId] NVARCHAR(256) NULL,
    [syndicateId] NVARCHAR(100) NULL,
    [digitalSignatureUrl] NVARCHAR(2048) NULL
);

CREATE TABLE [dbo].[Report] (
    [reportId] NVARCHAR(450) NOT NULL PRIMARY KEY,
    [title] NVARCHAR(500) NOT NULL,
    [descriptionText] NVARCHAR(MAX) NOT NULL,
    [locationRaw] NVARCHAR(2048) NULL,
    [latitude] FLOAT NULL,
    [longitude] FLOAT NULL,
    [status] NVARCHAR(50) NOT NULL DEFAULT 'Submitted'
        CHECK ([status] IN ('Submitted', 'Assigned', 'InProgress', 'Resolved', 'Rejected', 'PendingLawyerReview', 'ReturnedToCitizen')),
    [categoryId] NVARCHAR(100) NOT NULL,
    [aiConfidence] FLOAT NULL,
    [createdAt] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
    [updatedAt] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
    [userId] NVARCHAR(450) NULL FOREIGN KEY REFERENCES [dbo].[User]([userId]),
    [lawyerId] NVARCHAR(450) NULL FOREIGN KEY REFERENCES [dbo].[User]([userId]),
    [transcribedVoiceText] NVARCHAR(MAX) NULL,
    [officerNote] NVARCHAR(MAX) NULL,
    [lawyerSignature] NVARCHAR(MAX) NULL,
    [lawyerFeedback] NVARCHAR(MAX) NULL,
    [isUrgentEscalation] BIT NOT NULL DEFAULT 0
);

CREATE TABLE [dbo].[Attachment] (
    [attachmentId] NVARCHAR(450) NOT NULL PRIMARY KEY,
    [reportId] NVARCHAR(450) NOT NULL FOREIGN KEY REFERENCES [dbo].[Report]([reportId]) ON DELETE CASCADE,
    [blobStorageUri] NVARCHAR(2048) NOT NULL,
    [mimeType] NVARCHAR(100) NOT NULL,
    [fileType] NVARCHAR(50) NOT NULL CHECK ([fileType] IN ('image', 'video', 'audio')),
    [fileSizeBytes] BIGINT NOT NULL CHECK ([fileSizeBytes] > 0)
);

CREATE TABLE [dbo].[ReportMessage] (
    [messageId] NVARCHAR(450) NOT NULL PRIMARY KEY,
    [reportId] NVARCHAR(450) NOT NULL FOREIGN KEY REFERENCES [dbo].[Report]([reportId]) ON DELETE CASCADE,
    [senderId] NVARCHAR(450) NOT NULL FOREIGN KEY REFERENCES [dbo].[User]([userId]),
    [senderRole] NVARCHAR(50) NOT NULL,
    [messageText] NVARCHAR(MAX) NOT NULL,
    [createdAt] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE()
);

CREATE TABLE [dbo].[ETL_Watermark] (
    [TableName] NVARCHAR(100) NOT NULL PRIMARY KEY,
    [LastExtractedValue] DATETIME2(7) NOT NULL,
    [UpdatedAt] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE()
);
```

### 8.2 Analytics Database Schema (`MoI_Reporting_Analytics_DB`)

```sql
-- Hot Facts (Last 90 days)
CREATE TABLE [hot].[Fact_Reports] (
    [reportId] NVARCHAR(450) NOT NULL PRIMARY KEY,
    [title] NVARCHAR(500) NOT NULL,
    [descriptionText] NVARCHAR(MAX) NOT NULL,
    [locationRaw] NVARCHAR(2048) NULL,
    [status] NVARCHAR(50) NOT NULL,
    [categoryId] NVARCHAR(100) NOT NULL,
    [aiConfidence] FLOAT NULL,
    [createdAt] DATETIME2(7) NOT NULL,
    [updatedAt] DATETIME2(7) NOT NULL,
    [userId] NVARCHAR(450) NULL,
    [userRole] NVARCHAR(50) NULL,
    [isAnonymous] BIT NULL,
    [attachmentCount] INT NOT NULL DEFAULT 0,
    [transcribedVoiceText] NVARCHAR(MAX) NULL,
    [ExtractedAt] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE()
);

-- Cold Facts (Archived >90 days)
CREATE TABLE [cold].[Fact_Reports] (
    [reportId] NVARCHAR(450) NOT NULL PRIMARY KEY,
    [title] NVARCHAR(500) NOT NULL,
    [status] NVARCHAR(50) NOT NULL,
    [categoryId] NVARCHAR(100) NOT NULL,
    [createdAt] DATETIME2(7) NOT NULL,
    [updatedAt] DATETIME2(7) NOT NULL,
    [userRole] NVARCHAR(50) NULL,
    [isAnonymous] BIT NULL,
    [attachmentCount] INT NOT NULL DEFAULT 0,
    [aiConfidence] FLOAT NULL,
    [ExtractedAt] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE()
);

-- Unified Analytics View
CREATE VIEW [dbo].[vw_AllReports] AS
SELECT [reportId], [title], [status], [categoryId], [aiConfidence], [createdAt], [updatedAt], 'Hot' AS [DataTier]
FROM [hot].[Fact_Reports]
UNION ALL
SELECT [reportId], [title], [status], [categoryId], [aiConfidence], [createdAt], [updatedAt], 'Cold' AS [DataTier]
FROM [cold].[Fact_Reports];
```

---

## 9. Data Engineering & Azure Data Factory (ADF) Deep Dive

### 9.1 Incremental Sync Pipeline (`PL_Sync_Operations_To_Analytics`)
1. **`Lookup_Old_Watermark`**: Reads `LastExtractedValue` from `dbo.ETL_Watermark`.
2. **`Lookup_New_Watermark`**: Reads `MAX(updatedAt)` from `dbo.Report`.
3. **`Copy_Incremental_Reports`**: Executes SQL source query extracting modified rows:
   ```sql
   SELECT r.reportId, r.title, r.descriptionText, r.locationRaw, r.status, r.categoryId,
          r.aiConfidence, r.createdAt, r.updatedAt, r.userId, u.role AS userRole,
          u.isAnonymous, COUNT(a.attachmentId) AS attachmentCount, r.transcribedVoiceText
   FROM [dbo].[Report] r
   LEFT JOIN [dbo].[User] u ON r.userId = u.userId
   LEFT JOIN [dbo].[Attachment] a ON r.reportId = a.reportId
   WHERE r.updatedAt > '@{activity('Lookup_Old_Watermark').output.firstRow.LastExtractedValue}'
     AND r.updatedAt <= '@{activity('Lookup_New_Watermark').output.firstRow.NewWatermark}'
   GROUP BY r.reportId, r.title, r.descriptionText, r.locationRaw, r.status, r.categoryId,
            r.aiConfidence, r.createdAt, r.updatedAt, r.userId, u.role, u.isAnonymous, r.transcribedVoiceText
   ```
   Writes sink to `hot.Fact_Reports` using **Upsert** on `reportId`.
4. **`Copy_To_Cold`**: Copies distinct records into `cold.Fact_Reports`.
5. **`Update_Watermark`**: Invokes `[dbo].[sp_UpdateWatermark]` with `NewWatermark`.

### 9.2 Archival Pipeline (`P_Data_Archival_90Day`)
Invokes `[dbo].[sp_ArchiveAndPurge90DayData]` on a 91-day recurring schedule trigger (`Triger for purge and archive.json`).

---

## 10. Frontend Mobile Architecture (Flutter / Dart)

### 10.1 Key Libraries & Dependencies
- `provider`: State management (`AuthProvider`, `ReportProvider`).
- `geolocator`: Capture coordinates using `desiredAccuracy: LocationAccuracy.best`.
- `file_picker`: Restricts file selection using `type: FileType.media` (images and videos only).
- `video_player`: Renders inline video evidence playback on report details screens.
- `url_launcher`: Launches external intents (`https://www.google.com/maps/search/?api=1&query=$lat,$lon`).

### 10.2 Mobile Screen Catalog
- `login_screen.dart`: Hashed National ID authentication.
- `register_screen.dart`: Citizen registration with National ID & Lawyer Syndicate ID linking.
- `report_form.dart`: Form submission with voice recorder and media picker.
- `report_history_screen.dart`: Citizen submission history.
- `lawyer_dashboard_screen.dart`: Client report queue for legal review.
- `lawyer_report_details_screen.dart`: Digital signature, review feedback, urgent escalation controls.
- `officer_dashboard_screen.dart`: Incident queue & status stats.
- `officer_report_details_screen.dart`: Spatial view, external map intent, inline media player.

---

## 11. Complete REST API Specifications

### 🔐 Authentication
- `POST /api/v1/auth/register`: Citizen registration.
- `POST /api/v1/auth/register/lawyer`: Advocate registration with `syndicateId`.
- `POST /api/v1/auth/login`: OAuth2 login using National ID.
- `POST /api/v1/auth/anonymous`: Anonymous session creation.

### 📝 Incident Reports
- `POST /api/v1/reports/`: Create report with multipart media uploads and optional `sendToLawyer`.
- `GET /api/v1/reports/`: List paginated reports.
- `GET /api/v1/reports/me`: Get current user's submitted reports.
- `GET /api/v1/reports/{id}`: Get detailed report by ID.
- `PUT /api/v1/reports/{id}/status`: Update report status.

### ⚖️ Lawyer Portal
- `GET /api/v1/lawyer/reports`: List client reports awaiting lawyer review.
- `POST /api/v1/lawyer/reports/{id}/action`: Advocate action (`approve`, `return`, `escalate`).
- `GET /api/v1/lawyer/reports/{id}/messages`: Get private client-lawyer chat history.
- `POST /api/v1/lawyer/reports/{id}/messages`: Send private client-lawyer message.

### 🤖 AI Services
- `POST /api/v1/voice/transcribe`: Audio file transcription using local Whisper "turbo".
- `POST /api/v1/chatbot/chat`: Query Egyptian Law Books via FAISS RAG pipeline.

### 👮 Officer Operations
- `GET /api/v1/officer/reports/nearby`: Radius query near officer coordinates.
- `GET /api/v1/officer/dashboard/stats`: Status count stats directly from Operations DB.
- `GET /api/v1/officer/location/name`: Server-side cached OSM Nominatim reverse geocoding.

### 📊 Admin Analytics
- `GET /api/v1/admin/dashboard/stats`: Admin KPI metrics.
- `GET /api/v1/admin/analytics/export`: Download reports CSV.
- `GET /api/v1/admin/dashboard/hot/categorycount`: Category-status matrix (Active DB).
- `GET /api/v1/admin/dashboard/cold/categorycount`: Category-status matrix (Archived DB).

---

## 12. Deployment, Infrastructure & Operations

### 12.1 Docker & Multi-Container Setup
The backend is containerized via `Dockerfile` using Python 3.11-slim, installing Microsoft ODBC Driver 18 for SQL Server and ffmpeg for audio processing.

### 12.2 Azure App Service Deployment
Deployed to Azure Web App for Containers with settings configured via Azure App Settings linked to Key Vault:
```bash
az webapp config appsettings set \
  --resource-group rg-moi-reporting-prod \
  --name moi-reporting-api \
  --settings \
    AZURE_KEY_VAULT_NAME="moi-reporting-kv" \
    ENVIRONMENT="production"
```

---

*This master technical report serves as an exhaustive reference blueprint for the MoI Digital Reporting System.*
