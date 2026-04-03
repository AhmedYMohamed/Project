# 🤖 Project Tracker & AI Context Guide
## MoI Digital Reporting System

This document serves as the **Supreme Context Source** for any developers or AI agents working on this project. It tracks exactly what the system is, what features are implemented, and what remains pending across all modules.

---

## 🏗️ 1. Project Architecture Overview
The system is an advanced incident reporting platform for the Ministry of Interior.
- **Frontend:** Flutter Mobile/Web app (`moi_reporting_app/`)
- **Backend:** Python FastAPI (`app/`)
- **Database Architecture:** Dual Strategy (Transactional SQL for operations + Star Schema SQL for analytics)
- **Cloud Infrastructure:** Azure integrations (SQL DB, Blob Storage for media attachments, KeyVault for secrets, Cognitive Services for AI)

---

## 📱 2. Citizen Reporting System (Mobile App)
*The core interface for citizens to submit incident reports.*

**✅ Implementation Status [DONE]:**
- **Authentication:** Core user login and registration interfaces.
- **Form Submission:** Captures title, multiple report categories (infrastructure, crime, etc.), and descriptions.
- **Location Tracking:** Manual entry AND Automatic GPS capture (Location Input feature).
- **Multi-File Uploads:** Ability to attach multiple photos/videos/audio per report.
- **AI Voice Reporting:** A prominent record button in the description field to capture voice input, send it to the backend, and have it automatically transcribed/analyzed by Azure AI.

**⏳ Pending Features [NOT DONE]:**
- **Real-Time Notifications:** Push notifications or email updates to citizens on status changes.
- **Report History Enhancements:** Seamless fetching of the citizen's full report history in the UI without glitches or data-load delays.

---

## 👮 3. Officer Module & Dashboard
*Interface for ground officers to review, manage, and update the status of incidents.*

**✅ Implementation Status [DONE]:**
- **Officer Core Endpoints:** Dedicated backend API routes built out (`api/v1/officer.py`).
- **Services:** `officer_service.dart` handles fetching data in the Flutter app.
- **Flutter Screens:** `officer_dashboard_screen.dart` and `officer_report_details_screen.dart` scaffolded.
- **Data Models:** Schemas allowing officers to read reports and update statuses (e.g. from "Submitted" to "Resolved").

**⏳ Pending Features [NOT DONE]:**
- **Dashboard Data Binding:** Resolving critical frontend data loading issues to ensure the dashboard reliably displays open incidents.
- **Server-Side Reverse Geocoding:** Converting GPS coordinates into readable street addresses securely on the backend (to bypass strict frontend CORS restrictions).
- **Interactive Maps:** A map view for officers to visualize and pinpoint assigned incidents geographically.
- **Assignment Logistics:** Firm business logic mapping specific officers to specific regions/report types.

---

## 📊 4. Admin & Analytics Dashboard
*High-level control panel and reporting view for administrators.*

**✅ Implementation Status [DONE]:**
- **Analytics DB Foundation:** Secondary analytics database setup / star schema models created (`models/analytics.py`).
- **Admin API Layer:** Backend routes initialized (`api/v1/admin.py`).
- **Analytics Services:** Basic querying capabilities laid out in `analytics_service.py`.

**⏳ Pending Features [NOT DONE]:**
- **Admin UI Console:** Complete lack of a fleshed-out Flutter/Web interface tailored exclusively for Admins.
- **Live Reporting Statistics:** Connecting the UI to pull dynamic, accurate stats and aggregate visualizations directly from the databases.
- **System Operations Settings:** Admin capabilities to modify report categories globally or manage user roles inside the UI.

---

## ⚙️ 5. Backend Core Services & Integrations
*The engine powering the APIs.*

**✅ Implementation Status [DONE]:**
- **FastAPI Core:** Complete structure with routers, dependencies, and DB connection pooling.
- **Blob Storage Handling:** `blob_service.py` is capable of handling complex multipart files securely.
- **AI Performance:** Extensive optimization done to reduce processing time for recording and outputting voice transcriptions.

**⏳ Pending Features [NOT DONE]:**
- **Comprehensive Test Coverage:** Need full pytest unit tests for the most complex AI and Analytics services.
- **Automated CI/CD:** Hardened deployment scripts for Azure Cloud deployment.

---

## 💡 6. Current Priority / Immediate Working Phase
*(Update this regularly when focus changes)*

We are currently intensely focused on:
1. **Fixing the Officer Dashboard** (data loading, performance).
2. **Reverse Geocoding** (CORS bypass and server-side integration).
3. **Dashboard Analytics** (Extracting live report stats from the Ops Database).

---
*Note to any AI Agent reading this: Always refer directly to this file for the project's conceptual layout and your immediate objectives before proposing architectural changes!*
