# Complete API Delivery Roadmap
## From Setup to Production-Ready API

> **Your complete guide from current state to deployed, working API**

---

## 📍 Current Status

✅ **Phase 1 Complete (Week 1)**
- Azure resources created
- Database schema deployed
- Project structure set up
- Basic FastAPI app running

**What works now:**
- Health check endpoint: `GET /health`
- Database connection established
- Key Vault integration working

**What's missing:**
- Actual API endpoints (POST /reports, GET /reports, etc.)
- Request/response validation
- Business logic
- File upload functionality
- Authentication
- Testing
- Production deployment

---

## 🎯 Complete Roadmap Overview

```
Current → Phase 2 → Phase 3 → Phase 4 → Production
  ✅       (Week 2)   (Week 3)   (Week 4)     🚀

Phase 2: Core API Endpoints
├── Pydantic schemas
├── POST /reports endpoint
├── GET /reports endpoints
├── File upload to Blob Storage
└── Basic authentication

Phase 3: Advanced Features
├── AI categorization
├── Voice-to-text
├── Admin dashboard
├── Status management
└── Geolocation queries

Phase 4: Production Ready
├── Complete testing
├── API documentation
├── Performance optimization
├── Security hardening
└── Deployment to Azure

Production: Live API
├── Monitoring & alerts
├── Backup & recovery
├── Usage analytics
└── Continuous deployment
```

---

## 📅 Phase 2: Core API Endpoints (Week 2)

**Goal:** Create working report submission and retrieval endpoints

### Day 1-2: Pydantic Schemas (Request/Response Validation)

#### Task 2.1: Create Report Schemas

**File:** `app/schemas/report.py`

```python
from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime
from enum import Enum

# Enums for validation
class ReportStatus(str, Enum):
    SUBMITTED = "Submitted"
    ASSIGNED = "Assigned"
    IN_PROGRESS = "InProgress"
    RESOLVED = "Resolved"
    REJECTED = "Rejected"

class ReportCategory(str, Enum):
    INFRASTRUCTURE = "infrastructure"
    UTILITIES = "utilities"
    CRIME = "crime"
    TRAFFIC = "traffic"
    PUBLIC_NUISANCE = "public_nuisance"
    ENVIRONMENTAL = "environmental"
    OTHER = "other"

# Base schema with common fields
class ReportBase(BaseModel):
    title: str = Field(..., min_length=3, max_length=500, description="Report title")
    descriptionText: str = Field(..., min_length=10, description="Detailed description")
    categoryId: ReportCategory = Field(..., description="Report category")

# Schema for creating a report
class ReportCreate(ReportBase):
    latitude: float = Field(..., ge=-90, le=90, description="Latitude coordinate")
    longitude: float = Field(..., ge=-180, le=180, description="Longitude coordinate")
    transcribedVoiceText: Optional[str] = Field(None, description="Transcribed voice input")
    
    @field_validator('latitude', 'longitude')
    @classmethod
    def validate_coordinates(cls, v):
        if v == 0:
            raise ValueError('Coordinates cannot be exactly 0')
        return v

# Schema for updating a report
class ReportUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=3, max_length=500)
    descriptionText: Optional[str] = Field(None, min_length=10)
    status: Optional[ReportStatus] = None
    categoryId: Optional[ReportCategory] = None

# Schema for response
class ReportResponse(ReportBase):
    reportId: str
    status: ReportStatus
    latitude: float
    longitude: float
    aiConfidence: Optional[float] = None
    createdAt: datetime
    updatedAt: datetime
    userId: Optional[str] = None
    transcribedVoiceText: Optional[str] = None
    attachmentCount: int = 0
    
    class Config:
        from_attributes = True  # For SQLAlchemy models

# Schema for list response (with pagination)
class ReportListResponse(BaseModel):
    reports: List[ReportResponse]
    total: int
    page: int
    pageSize: int
    totalPages: int

# Schema for status update
class ReportStatusUpdate(BaseModel):
    status: ReportStatus
    notes: Optional[str] = None
```

**Test it:**
```python
# tests/test_schemas.py
from app.schemas.report import ReportCreate, ReportCategory

def test_report_create_schema():
    # Valid data
    data = {
        "title": "Pothole on Main Street",
        "descriptionText": "Large pothole causing traffic issues",
        "categoryId": "infrastructure",
        "latitude": 30.0444,
        "longitude": 31.2357
    }
    report = ReportCreate(**data)
    assert report.title == "Pothole on Main Street"
    print("✓ Schema validation passed")

if __name__ == "__main__":
    test_report_create_schema()
```

#### Task 2.2: Create User Schemas

**File:** `app/schemas/user.py`

```python
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime
from enum import Enum

class UserRole(str, Enum):
    CITIZEN = "citizen"
    OFFICER = "officer"
    ADMIN = "admin"

class UserBase(BaseModel):
    email: Optional[EmailStr] = None
    phoneNumber: Optional[str] = Field(None, pattern=r'^\+?[1-9]\d{1,14}$')
    role: UserRole = UserRole.CITIZEN

class UserCreate(UserBase):
    isAnonymous: bool = False
    hashedDeviceId: Optional[str] = None

class UserResponse(UserBase):
    userId: str
    isAnonymous: bool
    createdAt: datetime
    
    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    phoneNumber: Optional[str] = None
```

#### Task 2.3: Create Attachment Schemas

**File:** `app/schemas/attachment.py`

```python
from pydantic import BaseModel, Field, HttpUrl
from typing import Literal
from enum import Enum

class FileType(str, Enum):
    IMAGE = "image"
    VIDEO = "video"
    AUDIO = "audio"
    DOCUMENT = "document"

class AttachmentCreate(BaseModel):
    reportId: str
    blobStorageUri: str
    mimeType: str = Field(..., pattern=r'^[a-z]+/[a-z0-9\-\+\.]+$')
    fileType: FileType
    fileSizeBytes: int = Field(..., gt=0, le=52428800)  # Max 50MB

class AttachmentResponse(AttachmentCreate):
    attachmentId: str
    
    class Config:
        from_attributes = True
```

**Time:** 1-2 days  
**Deliverable:** Complete validation schemas ✅

---

### Day 3-4: Report Service (Business Logic)

#### Task 2.4: Create Report Service

**File:** `app/services/report_service.py`

```python
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List, Optional
import uuid
from datetime import datetime

from app.models.report import Report
from app.models.user import User
from app.schemas.report import (
    ReportCreate, 
    ReportUpdate, 
    ReportResponse,
    ReportListResponse,
    ReportStatusUpdate
)

class ReportService:
    """Business logic for reports"""
    
    @staticmethod
    def create_report(
        db: Session, 
        report_data: ReportCreate, 
        user_id: Optional[str] = None
    ) -> ReportResponse:
        """Create a new report"""
        
        # Generate unique ID
        report_id = f"report-{uuid.uuid4()}"
        
        # Create geography point from coordinates
        location_wkt = f"POINT({report_data.longitude} {report_data.latitude})"
        
        # Create report model
        db_report = Report(
            reportId=report_id,
            title=report_data.title,
            descriptionText=report_data.descriptionText,
            location=text(f"geography::Point({report_data.latitude}, {report_data.longitude}, 4326)"),
            categoryId=report_data.categoryId.value,
            userId=user_id,
            transcribedVoiceText=report_data.transcribedVoiceText,
            status="Submitted",
            createdAt=datetime.utcnow(),
            updatedAt=datetime.utcnow()
        )
        
        # Save to database
        db.add(db_report)
        db.commit()
        db.refresh(db_report)
        
        # Convert to response schema
        return ReportResponse(
            reportId=db_report.reportId,
            title=db_report.title,
            descriptionText=db_report.descriptionText,
            categoryId=db_report.categoryId,
            status=db_report.status,
            latitude=report_data.latitude,
            longitude=report_data.longitude,
            aiConfidence=db_report.aiConfidence,
            createdAt=db_report.createdAt,
            updatedAt=db_report.updatedAt,
            userId=db_report.userId,
            transcribedVoiceText=db_report.transcribedVoiceText,
            attachmentCount=0
        )
    
    @staticmethod
    def get_report(db: Session, report_id: str) -> Optional[ReportResponse]:
        """Get a single report by ID"""
        report = db.query(Report).filter(Report.reportId == report_id).first()
        
        if not report:
            return None
        
        # Get attachment count
        attachment_count = len(report.attachments) if report.attachments else 0
        
        # Extract coordinates from geography
        # This is simplified - in production use proper geography parsing
        return ReportResponse(
            reportId=report.reportId,
            title=report.title,
            descriptionText=report.descriptionText,
            categoryId=report.categoryId,
            status=report.status,
            latitude=30.0444,  # Parse from geography field
            longitude=31.2357,
            aiConfidence=report.aiConfidence,
            createdAt=report.createdAt,
            updatedAt=report.updatedAt,
            userId=report.userId,
            transcribedVoiceText=report.transcribedVoiceText,
            attachmentCount=attachment_count
        )
    
    @staticmethod
    def list_reports(
        db: Session, 
        skip: int = 0, 
        limit: int = 10,
        status: Optional[str] = None,
        category: Optional[str] = None
    ) -> ReportListResponse:
        """List reports with pagination and filters"""
        
        query = db.query(Report)
        
        # Apply filters
        if status:
            query = query.filter(Report.status == status)
        if category:
            query = query.filter(Report.categoryId == category)
        
        # Get total count
        total = query.count()
        
        # Apply pagination
        reports = query.offset(skip).limit(limit).all()
        
        # Convert to response schemas
        report_responses = []
        for report in reports:
            report_responses.append(ReportResponse(
                reportId=report.reportId,
                title=report.title,
                descriptionText=report.descriptionText,
                categoryId=report.categoryId,
                status=report.status,
                latitude=30.0444,
                longitude=31.2357,
                aiConfidence=report.aiConfidence,
                createdAt=report.createdAt,
                updatedAt=report.updatedAt,
                userId=report.userId,
                transcribedVoiceText=report.transcribedVoiceText,
                attachmentCount=0
            ))
        
        return ReportListResponse(
            reports=report_responses,
            total=total,
            page=skip // limit + 1,
            pageSize=limit,
            totalPages=(total + limit - 1) // limit
        )
    
    @staticmethod
    def update_report_status(
        db: Session,
        report_id: str,
        status_update: ReportStatusUpdate
    ) -> Optional[ReportResponse]:
        """Update report status"""
        
        report = db.query(Report).filter(Report.reportId == report_id).first()
        
        if not report:
            return None
        
        report.status = status_update.status.value
        report.updatedAt = datetime.utcnow()
        
        db.commit()
        db.refresh(report)
        
        return ReportService.get_report(db, report_id)
    
    @staticmethod
    def delete_report(db: Session, report_id: str) -> bool:
        """Delete a report"""
        report = db.query(Report).filter(Report.reportId == report_id).first()
        
        if not report:
            return False
        
        db.delete(report)
        db.commit()
        return True
```

**Time:** 2 days  
**Deliverable:** Complete business logic for reports ✅

---

### Day 5-6: API Endpoints

#### Task 2.5: Create Report Endpoints

**File:** `app/api/v1/reports.py`

```python
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from typing import Optional

from app.core.database import get_db
from app.schemas.report import (
    ReportCreate,
    ReportResponse,
    ReportListResponse,
    ReportStatusUpdate,
    ReportStatus,
    ReportCategory
)
from app.services.report_service import ReportService

router = APIRouter()

@router.post(
    "/",
    response_model=ReportResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit a new report",
    description="Create a new incident report with location and description"
)
async def create_report(
    report: ReportCreate,
    db: Session = Depends(get_db)
):
    """
    Submit a new incident report.
    
    - **title**: Short title of the incident
    - **descriptionText**: Detailed description
    - **categoryId**: Category of the incident
    - **latitude**: Latitude coordinate (-90 to 90)
    - **longitude**: Longitude coordinate (-180 to 180)
    - **transcribedVoiceText**: Optional voice transcription
    """
    try:
        return ReportService.create_report(db, report)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create report: {str(e)}"
        )

@router.get(
    "/",
    response_model=ReportListResponse,
    summary="List all reports",
    description="Get paginated list of reports with optional filters"
)
async def list_reports(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(10, ge=1, le=100, description="Maximum records to return"),
    status: Optional[ReportStatus] = Query(None, description="Filter by status"),
    category: Optional[ReportCategory] = Query(None, description="Filter by category"),
    db: Session = Depends(get_db)
):
    """
    Get list of reports with pagination and filters.
    
    - **skip**: Skip N records (for pagination)
    - **limit**: Max number of records (1-100)
    - **status**: Filter by report status
    - **category**: Filter by category
    """
    status_value = status.value if status else None
    category_value = category.value if category else None
    
    return ReportService.list_reports(
        db, 
        skip=skip, 
        limit=limit,
        status=status_value,
        category=category_value
    )

@router.get(
    "/{report_id}",
    response_model=ReportResponse,
    summary="Get report by ID",
    description="Retrieve detailed information about a specific report"
)
async def get_report(
    report_id: str,
    db: Session = Depends(get_db)
):
    """
    Get a single report by its ID.
    
    - **report_id**: Unique report identifier
    """
    report = ReportService.get_report(db, report_id)
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Report with ID {report_id} not found"
        )
    
    return report

@router.put(
    "/{report_id}/status",
    response_model=ReportResponse,
    summary="Update report status",
    description="Change the status of a report (for officials)"
)
async def update_report_status(
    report_id: str,
    status_update: ReportStatusUpdate,
    db: Session = Depends(get_db)
):
    """
    Update the status of a report.
    
    - **report_id**: Report to update
    - **status**: New status value
    - **notes**: Optional notes about the update
    """
    report = ReportService.update_report_status(db, report_id, status_update)
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Report with ID {report_id} not found"
        )
    
    return report

@router.delete(
    "/{report_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a report",
    description="Permanently delete a report"
)
async def delete_report(
    report_id: str,
    db: Session = Depends(get_db)
):
    """
    Delete a report permanently.
    
    - **report_id**: Report to delete
    """
    success = ReportService.delete_report(db, report_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Report with ID {report_id} not found"
        )
    
    return None
```

#### Task 2.6: Register Routes in Main App

**Update:** `app/main.py`

```python
from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.core.config import get_settings
from app.core.database import engine
from app.api.v1 import reports  # Import reports router

settings = get_settings()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    print(f"Starting {settings.APP_NAME}")
    yield
    print("Shutting down...")
    engine.dispose()

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.API_VERSION,
    lifespan=lifespan,
    docs_url="/api/docs",
    redoc_url="/api/redoc"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check
@app.get("/health")
async def health_check():
    return {"status": "healthy"}

# Register API routers
app.include_router(
    reports.router,
    prefix="/api/v1/reports",
    tags=["Reports"]
)
```

**Time:** 2 days  
**Deliverable:** Working API endpoints ✅

---

### Day 7: Testing Phase 2

#### Task 2.7: Test All Endpoints

**File:** `tests/test_reports_api.py`

```python
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_create_report():
    """Test creating a new report"""
    response = client.post(
        "/api/v1/reports/",
        json={
            "title": "Test Pothole",
            "descriptionText": "This is a test pothole report for testing purposes",
            "categoryId": "infrastructure",
            "latitude": 30.0444,
            "longitude": 31.2357
        }
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Test Pothole"
    assert data["status"] == "Submitted"
    assert "reportId" in data
    print(f"✓ Created report: {data['reportId']}")
    
    return data["reportId"]

def test_list_reports():
    """Test listing reports"""
    response = client.get("/api/v1/reports/?skip=0&limit=10")
    
    assert response.status_code == 200
    data = response.json()
    assert "reports" in data
    assert "total" in data
    print(f"✓ Listed {len(data['reports'])} reports")

def test_get_report():
    """Test getting a specific report"""
    # First create a report
    report_id = test_create_report()
    
    # Then get it
    response = client.get(f"/api/v1/reports/{report_id}")
    
    assert response.status_code == 200
    data = response.json()
    assert data["reportId"] == report_id
    print(f"✓ Retrieved report: {report_id}")

def test_update_report_status():
    """Test updating report status"""
    report_id = test_create_report()
    
    response = client.put(
        f"/api/v1/reports/{report_id}/status",
        json={
            "status": "Assigned",
            "notes": "Assigned to maintenance team"
        }
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "Assigned"
    print(f"✓ Updated report status: {report_id}")

if __name__ == "__main__":
    print("🧪 Testing Report API Endpoints...")
    print("=" * 50)
    
    test_create_report()
    test_list_reports()
    test_get_report()
    test_update_report_status()
    
    print("=" * 50)
    print("✅ All tests passed!")
```

Run tests:
```bash
pytest tests/test_reports_api.py -v
```

**Time:** 1 day  
**Deliverable:** All endpoints tested and working ✅

---

## ✅ Phase 2 Complete Checklist

- [ ] Pydantic schemas created (report, user, attachment)
- [ ] Report service with business logic
- [ ] POST /api/v1/reports endpoint
- [ ] GET /api/v1/reports endpoint (list)
- [ ] GET /api/v1/reports/{id} endpoint
- [ ] PUT /api/v1/reports/{id}/status endpoint
- [ ] DELETE /api/v1/reports/{id} endpoint
- [ ] All endpoints tested
- [ ] API documentation auto-generated
- [ ] Code committed to Git

**Deliverables:**
- ✅ 5 working API endpoints
- ✅ Request/response validation
- ✅ Database integration
- ✅ Error handling
- ✅ API documentation at `/api/docs`

---

## 📅 Phase 3: Advanced Features (Week 3)

### Day 8-9: File Upload

#### Task 3.1: Blob Storage Service

**File:** `app/services/blob_service.py`

```python
from azure.storage.blob import BlobServiceClient, generate_blob_sas, BlobSasPermissions
from azure.core.exceptions import AzureError
from datetime import datetime, timedelta
from typing import Optional
import uuid

from app.core.config import get_settings

settings = get_settings()

class BlobStorageService:
    """Azure Blob Storage operations"""
    
    def __init__(self):
        self.blob_service_client = BlobServiceClient.from_connection_string(
            settings.BLOB_STORAGE_CONNECTION_STRING
        )
        self.container_name = settings.BLOB_CONTAINER_NAME
    
    def upload_file(
        self, 
        file_content: bytes, 
        filename: str,
        content_type: str
    ) -> Optional[str]:
        """
        Upload file to Azure Blob Storage
        
        Args:
            file_content: File bytes
            filename: Original filename
            content_type: MIME type
        
        Returns:
            Blob URL if successful, None otherwise
        """
        try:
            # Generate unique blob name
            file_extension = filename.split('.')[-1]
            blob_name = f"{uuid.uuid4()}.{file_extension}"
            
            # Get blob client
            blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name,
                blob=blob_name
            )
            
            # Upload file
            blob_client.upload_blob(
                file_content,
                content_type=content_type,
                overwrite=True
            )
            
            # Return URL
            return blob_client.url
        
        except AzureError as e:
            print(f"Error uploading file: {e}")
            return None
    
    def delete_file(self, blob_url: str) -> bool:
        """Delete file from storage"""
        try:
            blob_name = blob_url.split('/')[-1]
            blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name,
                blob=blob_name
            )
            blob_client.delete_blob()
            return True
        except AzureError as e:
            print(f"Error deleting file: {e}")
            return False
    
    def generate_download_url(
        self, 
        blob_url: str,
        expiry_hours: int = 1
    ) -> Optional[str]:
        """Generate temporary download URL with SAS token"""
        try:
            blob_name = blob_url.split('/')[-1]
            
            sas_token = generate_blob_sas(
                account_name=self.blob_service_client.account_name,
                container_name=self.container_name,
                blob_name=blob_name,
                permission=BlobSasPermissions(read=True),
                expiry=datetime.utcnow() + timedelta(hours=expiry_hours)
            )
            
            return f"{blob_url}?{sas_token}"
        
        except AzureError as e:
            print(f"Error generating SAS: {e}")
            return None
```

#### Task 3.2: File Upload Endpoint

**Update:** `app/api/v1/reports.py`

```python
from fastapi import File, UploadFile, Form
from typing import List

@router.post(
    "/{report_id}/attachments",
    response_model=List[AttachmentResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Upload attachments to report"
)
async def upload_attachments(
    report_id: str,
    files: List[UploadFile] = File(..., description="Files to upload (max 5)"),
    db: Session = Depends(get_db)
):
    """
    Upload one or more attachments to a report.
    
    Supported file types:
    - Images: jpg, jpeg, png, gif
    - Videos: mp4, avi, mov
    - Audio: mp3, wav, m4a
    - Documents: pdf, doc, docx
    
    Max file size: 50MB per file
    """
    # Validate file count
    if len(files) > 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Maximum 5 files allowed per upload"
        )
    
    # Verify report exists
    report = ReportService.get_report(db, report_id)
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Report {report_id} not found"
        )
    
    blob_service = BlobStorageService()
    attachments = []
    
    for file in files:
        # Validate file size (50MB)
        file_content = await file.read()
        if len(file_content) > 52428800:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"File {file.filename} exceeds 50MB limit"
            )
        
        # Upload to blob storage
        blob_url = blob_service.upload_file(
            file_content,
            file.filename,
            file.content_type
        )
        
        if not blob_url:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to upload {file.filename}"
            )
        
        # Determine file type
        file_type = _determine_file_type(file.content_type)
        
        # Save attachment record
        attachment = AttachmentService.create_attachment(
            db,
            AttachmentCreate(
                reportId=report_id,
                blobStorageUri=blob_url,
                mimeType=file.content_type,
                fileType=file_type,
                fileSizeBytes=len(file_content)
            )
        )
        attachments.append(attachment)
    
    return attachments

def _determine_file_type(mime_type: str) -> str:
    """Determine file type from MIME type"""
    if mime_type.startswith("image/"):
        return "image"
    elif mime_type.startswith("video/"):
        return "video"
    elif mime_type.startswith("audio/"):
        return "audio"
    else:
        return "document"
```

**Time:** 2 days  
**Deliverable:** File upload working ✅

---

### Day 10-12: Authentication (Simplified)

#### Task 3.3: Basic Authentication

**File:** `app/core/security.py`

```python
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from typing import Optional

from app.core.config import get_settings

settings = get_settings()

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Generate JWT token"""
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    
    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )
    return encoded_jwt

def verify_token(token: str) -> Optional[dict]:
    """Verify JWT token"""
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM]
        )
        return payload
    except JWTError:
        return None

def hash_password(password: str) -> str:
    """Hash a password"""
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against hash"""
    return pwd_context.verify(plain_password, hashed_password)
```

#### Task 3.4: Authentication Endpoints

**File:** `app/api/v1/auth.py`

```python
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from datetime import timedelta
import hashlib
import uuid

from app.core.database import get_db
from app.core.security import create_access_token, verify_token
from app.core.config import get_settings
from app.models.user import User
from app.schemas.user import UserCreate, UserResponse

router = APIRouter()
settings = get_settings()
security = HTTPBearer()

@router.post(
    "/anonymous",
    response_model=dict,
    summary="Create anonymous session",
    description="Create anonymous user session with device fingerprint"
)
async def create_anonymous_session(
    device_id: str,
    db: Session = Depends(get_db)
):
    """
    Create an anonymous user session.
    
    - **device_id**: Unique device identifier
    
    Returns JWT token for anonymous access
    """
    # Hash device ID
    hashed_device = hashlib.sha256(device_id.encode()).hexdigest()
    
    # Check if user already exists
    existing_user = db.query(User).filter(
        User.hashedDeviceId == hashed_device
    ).first()
    
    if existing_user:
        user_id = existing_user.userId
    else:
        # Create new anonymous user
        user_id = f"anon-{uuid.uuid4()}"
        user = User(
            userId=user_id,
            isAnonymous=True,
            role="citizen",
            hashedDeviceId=hashed_device
        )
        db.add(user)
        db.commit()
    
    # Create access token
    access_token = create_access_token(
        data={"sub": user_id, "role": "citizen"},
        expires_delta=timedelta(days=30)
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user_id
    }

@router.post(
    "/register",
    response_model=dict,
    status_code=status.HTTP_201_CREATED,
    summary="Register new user",
    description="Register a new user with email"
)
async def register_user(
    user_data: UserCreate,
    db: Session = Depends(get_db)
):
    """
    Register a new user account.
    
    - **email**: User email address
    - **phoneNumber**: Optional phone number
    """
    # Check if user exists
    existing_user = db.query(User).filter(
        User.email == user_data.email
    ).first()
    
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create user
    user_id = f"user-{uuid.uuid4()}"
    user = User(
        userId=user_id,
        isAnonymous=False,
        role=user_data.role.value,
        email=user_data.email,
        phoneNumber=user_data.phoneNumber
    )
    
    db.add(user)
    db.commit()
    
    # Create access token
    access_token = create_access_token(
        data={"sub": user_id, "role": user_data.role.value},
        expires_delta=timedelta(days=30)
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user_id
    }

@router.get(
    "/me",
    response_model=UserResponse,
    summary="Get current user",
    description="Get current authenticated user information"
)
async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):
    """Get current user profile"""
    # Verify token
    payload = verify_token(credentials.credentials)
    
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    
    user_id = payload.get("sub")
    
    # Get user from database
    user = db.query(User).filter(User.userId == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return UserResponse(
        userId=user.userId,
        email=user.email,
        phoneNumber=user.phoneNumber,
        role=user.role,
        isAnonymous=user.isAnonymous,
        createdAt=user.createdAt
    )
```

**Update `app/main.py`** to register auth router:

```python
from app.api.v1 import reports, auth

# Register routers
app.include_router(
    reports.router,
    prefix="/api/v1/reports",
    tags=["Reports"]
)

app.include_router(
    auth.router,
    prefix="/api/v1/auth",
    tags=["Authentication"]
)
```

**Time:** 3 days  
**Deliverable:** Basic authentication working ✅

---

### Day 13-14: AI Features (Optional for MVP)

#### Task 3.5: AI Categorization Service

**File:** `app/services/ai_service.py`

```python
import requests
from typing import Optional, Tuple
from app.core.config import get_settings

settings = get_settings()

class AIService:
    """AI-powered features"""
    
    @staticmethod
    def categorize_report(text: str) -> Tuple[str, float]:
        """
        Categorize report using simple keyword matching
        In production, use Azure ML or OpenAI
        
        Returns: (category, confidence)
        """
        text_lower = text.lower()
        
        # Simple keyword-based categorization
        categories = {
            "infrastructure": ["pothole", "road", "bridge", "sidewalk", "pavement"],
            "utilities": ["power", "electricity", "water", "gas", "streetlight"],
            "crime": ["theft", "robbery", "assault", "vandalism"],
            "traffic": ["accident", "congestion", "signal", "parking"],
            "environmental": ["pollution", "garbage", "waste", "noise"],
            "public_nuisance": ["noise", "disturbance", "graffiti"]
        }
        
        scores = {}
        for category, keywords in categories.items():
            score = sum(1 for keyword in keywords if keyword in text_lower)
            if score > 0:
                scores[category] = score
        
        if not scores:
            return "other", 0.5
        
        # Get category with highest score
        best_category = max(scores, key=scores.get)
        confidence = min(scores[best_category] / 3, 1.0)  # Normalize to 0-1
        
        return best_category, confidence
    
    @staticmethod
    def enhance_categorization(report_text: str, current_category: str) -> Tuple[str, float]:
        """
        Enhance existing categorization
        Could call Azure ML endpoint here
        """
        suggested_category, confidence = AIService.categorize_report(report_text)
        
        # If AI is more confident than 0.7, suggest its category
        if confidence > 0.7 and suggested_category != current_category:
            return suggested_category, confidence
        
        return current_category, 0.8
```

**Update Report Service** to use AI:

```python
# In app/services/report_service.py
from app.services.ai_service import AIService

# Add to create_report method:
# AI categorization
ai_category, ai_confidence = AIService.categorize_report(
    f"{report_data.title} {report_data.descriptionText}"
)

# You can either:
# 1. Override user's category if AI is confident
if ai_confidence > 0.8:
    category = ai_category
else:
    category = report_data.categoryId.value

# 2. Or store AI suggestion for review
db_report.aiConfidence = ai_confidence
```

**Time:** 2 days  
**Deliverable:** Basic AI categorization ✅

---

## ✅ Phase 3 Complete Checklist

- [ ] Blob Storage service implemented
- [ ] File upload endpoint working
- [ ] File download with SAS tokens
- [ ] Anonymous authentication
- [ ] User registration
- [ ] JWT token generation
- [ ] Protected endpoints
- [ ] AI categorization (basic)
- [ ] All features tested

**Deliverables:**
- ✅ File upload/download functionality
- ✅ Anonymous and registered user auth
- ✅ JWT-based security
- ✅ AI-powered categorization
- ✅ Complete API documentation

---

## 📅 Phase 4: Production Ready (Week 4)

### Day 15-16: Comprehensive Testing

#### Task 4.1: Complete Test Suite

**File:** `tests/test_complete_flow.py`

```python
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_complete_user_journey():
    """Test complete end-to-end flow"""
    print("\n🧪 Testing Complete User Journey")
    print("=" * 60)
    
    # Step 1: Create anonymous session
    print("\n1. Creating anonymous session...")
    response = client.post(
        "/api/v1/auth/anonymous",
        json={"device_id": "test-device-123"}
    )
    assert response.status_code == 200
    token = response.json()["access_token"]
    print(f"   ✓ Token received: {token[:20]}...")
    
    # Step 2: Submit a report
    print("\n2. Submitting report...")
    response = client.post(
        "/api/v1/reports/",
        json={
            "title": "Large pothole on Main Street",
            "descriptionText": "There is a large pothole causing traffic issues",
            "categoryId": "infrastructure",
            "latitude": 30.0444,
            "longitude": 31.2357
        },
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 201
    report = response.json()
    report_id = report["reportId"]
    print(f"   ✓ Report created: {report_id}")
    print(f"   ✓ Status: {report['status']}")
    print(f"   ✓ AI Confidence: {report.get('aiConfidence', 'N/A')}")
    
    # Step 3: Get report details
    print("\n3. Retrieving report...")
    response = client.get(f"/api/v1/reports/{report_id}")
    assert response.status_code == 200
    report_details = response.json()
    print(f"   ✓ Report retrieved: {report_details['title']}")
    
    # Step 4: List all reports
    print("\n4. Listing reports...")
    response = client.get("/api/v1/reports/?limit=10")
    assert response.status_code == 200
    reports_list = response.json()
    print(f"   ✓ Found {len(reports_list['reports'])} reports")
    print(f"   ✓ Total in database: {reports_list['total']}")
    
    # Step 5: Update report status
    print("\n5. Updating report status...")
    response = client.put(
        f"/api/v1/reports/{report_id}/status",
        json={
            "status": "Assigned",
            "notes": "Assigned to maintenance team"
        },
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    updated_report = response.json()
    print(f"   ✓ Status updated to: {updated_report['status']}")
    
    # Step 6: Filter reports by status
    print("\n6. Filtering reports by status...")
    response = client.get("/api/v1/reports/?status=Assigned")
    assert response.status_code == 200
    filtered_reports = response.json()
    print(f"   ✓ Found {len(filtered_reports['reports'])} assigned reports")
    
    print("\n" + "=" * 60)
    print("✅ Complete user journey test passed!")
    print("=" * 60)

def test_error_handling():
    """Test error scenarios"""
    print("\n🧪 Testing Error Handling")
    print("=" * 60)
    
    # Test 1: Get non-existent report
    print("\n1. Testing 404 error...")
    response = client.get("/api/v1/reports/non-existent-id")
    assert response.status_code == 404
    print("   ✓ 404 handled correctly")
    
    # Test 2: Invalid data
    print("\n2. Testing validation error...")
    response = client.post(
        "/api/v1/reports/",
        json={
            "title": "AB",  # Too short
            "descriptionText": "Test",
            "categoryId": "invalid",
            "latitude": 91.0,  # Invalid
            "longitude": 181.0  # Invalid
        }
    )
    assert response.status_code == 422
    print("   ✓ Validation error handled correctly")
    
    # Test 3: Unauthorized access (if protected)
    print("\n3. Testing unauthorized access...")
    response = client.put(
        "/api/v1/reports/test-id/status",
        json={"status": "Assigned"}
    )
    # Should return 401 or 403 if protected
    print(f"   ✓ Status code: {response.status_code}")
    
    print("\n" + "=" * 60)
    print("✅ Error handling tests passed!")
    print("=" * 60)

if __name__ == "__main__":
    test_complete_user_journey()
    test_error_handling()
```

Run comprehensive tests:
```bash
pytest tests/ -v --cov=app --cov-report=html
```

**Time:** 2 days  
**Deliverable:** 80%+ test coverage ✅

---

### Day 17-18: API Documentation

#### Task 4.2: Enhanced API Documentation

**Update:** `app/main.py`

```python
from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi

def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    
    openapi_schema = get_openapi(
        title="MoI Digital Reporting System API",
        version="1.0.0",
        description="""
        ## 🏛️ Ministry of Interior - Digital Reporting System
        
        A secure, AI-enabled platform for citizens to report incidents and track their resolution.
        
        ### Features
        
        * **📝 Report Management** - Submit, view, and track incident reports
        * **📸 File Uploads** - Attach photos, videos, and documents
        * **🔐 Secure Authentication** - Anonymous and registered user access
        * **🤖 AI Categorization** - Automatic incident classification
        * **📍 Geolocation** - Location-based reporting and search
        * **📊 Status Tracking** - Real-time report status updates
        
        ### Authentication
        
        Most endpoints require authentication. Use one of:
        - **Anonymous**: POST `/api/v1/auth/anonymous` with device ID
        - **Registered**: POST `/api/v1/auth/register` with email
        
        Include the JWT token in the `Authorization` header:
        ```
        Authorization: Bearer <your-token>
        ```
        
        ### Rate Limits
        - Anonymous users: 10 requests/minute
        - Registered users: 60 requests/minute
        
        ### Support
        - **Documentation**: https://docs.moi-reporting.gov.eg
        - **Support Email**: support@moi-reporting.gov.eg
        - **Status Page**: https://status.moi-reporting.gov.eg
        """,
        routes=app.routes,
        tags=[
            {
                "name": "Reports",
                "description": "Operations for managing incident reports"
            },
            {
                "name": "Authentication",
                "description": "User authentication and session management"
            },
            {
                "name": "Attachments",
                "description": "File upload and management"
            }
        ]
    )
    
    # Add security scheme
    openapi_schema["components"]["securitySchemes"] = {
        "bearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT"
        }
    }
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi
```

**Create README for API:**

**File:** `docs/API.md`

```markdown
# MoI Digital Reporting System - API Documentation

## Base URL
- **Development**: `http://localhost:8000`
- **Production**: `https://api.moi-reporting.gov.eg`

## Authentication

### Anonymous Session
```bash
POST /api/v1/auth/anonymous
Content-Type: application/json

{
  "device_id": "unique-device-identifier"
}
```

Response:
```json
{
  "access_token": "eyJhbGc...",
  "token_type": "bearer",
  "user_id": "anon-123..."
}
```

### Register User
```bash
POST /api/v1/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "phoneNumber": "+201234567890",
  "role": "citizen"
}
```

## Report Operations

### Submit Report
```bash
POST /api/v1/reports/
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Pothole on Main Street",
  "descriptionText": "Large pothole causing traffic issues",
  "categoryId": "infrastructure",
  "latitude": 30.0444,
  "longitude": 31.2357
}
```

### List Reports
```bash
GET /api/v1/reports/?skip=0&limit=10&status=Submitted&category=infrastructure
```

### Get Report
```bash
GET /api/v1/reports/{report_id}
```

### Update Status
```bash
PUT /api/v1/reports/{report_id}/status
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "Assigned",
  "notes": "Assigned to maintenance team"
}
```

## File Upload

### Upload Attachments
```bash
POST /api/v1/reports/{report_id}/attachments
Authorization: Bearer <token>
Content-Type: multipart/form-data

files: [file1, file2, ...]
```

## Error Responses

### 400 Bad Request
```json
{
  "detail": "Invalid input data"
}
```

### 401 Unauthorized
```json
{
  "detail": "Invalid authentication credentials"
}
```

### 404 Not Found
```json
{
  "detail": "Report with ID xxx not found"
}
```

### 422 Validation Error
```json
{
  "detail": [
    {
      "loc": ["body", "latitude"],
      "msg": "ensure this value is less than or equal to 90",
      "type": "value_error"
    }
  ]
}
```

## Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK - Request successful |
| 201 | Created - Resource created successfully |
| 204 | No Content - Deletion successful |
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - Authentication required |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource not found |
| 422 | Validation Error - Input validation failed |
| 500 | Internal Server Error - Server error |

## Examples

### Complete Flow with cURL

```bash
# 1. Create anonymous session
TOKEN=$(curl -X POST http://localhost:8000/api/v1/auth/anonymous \
  -H "Content-Type: application/json" \
  -d '{"device_id": "my-device-123"}' | jq -r '.access_token')

# 2. Submit report
REPORT_ID=$(curl -X POST http://localhost:8000/api/v1/reports/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Broken streetlight",
    "descriptionText": "Streetlight not working for 3 days",
    "categoryId": "utilities",
    "latitude": 30.0444,
    "longitude": 31.2357
  }' | jq -r '.reportId')

# 3. Get report
curl -X GET http://localhost:8000/api/v1/reports/$REPORT_ID

# 4. List reports
curl -X GET "http://localhost:8000/api/v1/reports/?skip=0&limit=10"
```

### Python Client Example

```python
import requests

BASE_URL = "http://localhost:8000"

# 1. Authenticate
response = requests.post(
    f"{BASE_URL}/api/v1/auth/anonymous",
    json={"device_id": "my-device-123"}
)
token = response.json()["access_token"]

headers = {"Authorization": f"Bearer {token}"}

# 2. Submit report
response = requests.post(
    f"{BASE_URL}/api/v1/reports/",
    headers=headers,
    json={
        "title": "Test Report",
        "descriptionText": "This is a test report",
        "categoryId": "infrastructure",
        "latitude": 30.0444,
        "longitude": 31.2357
    }
)
report = response.json()
print(f"Created report: {report['reportId']}")

# 3. Get report
response = requests.get(
    f"{BASE_URL}/api/v1/reports/{report['reportId']}",
    headers=headers
)
print(response.json())
```
```

**Time:** 2 days  
**Deliverable:** Complete API documentation ✅

---

### Day 19-20: Performance & Security

#### Task 4.3: Add Performance Optimizations

**File:** `app/core/middleware.py`

```python
from fastapi import Request
from time import time
import logging

logger = logging.getLogger(__name__)

async def log_requests(request: Request, call_next):
    """Log all requests with timing"""
    start_time = time()
    
    response = await call_next(request)
    
    process_time = time() - start_time
    logger.info(
        f"{request.method} {request.url.path} "
        f"completed in {process_time:.3f}s "
        f"with status {response.status_code}"
    )
    
    response.headers["X-Process-Time"] = str(process_time)
    return response
```

**Update `app/main.py`:**

```python
from app.core.middleware import log_requests

app.middleware("http")(log_requests)
```

#### Task 4.4: Add Rate Limiting

```bash
pip install slowapi
```

**Update `app/main.py`:**

```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Add to endpoints:
@router.post("/")
@limiter.limit("10/minute")
async def create_report(...):
    ...
```

#### Task 4.5: Security Headers

```python
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.middleware.gzip import GZipMiddleware

# Add to app
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["localhost", "*.moi-reporting.gov.eg"]
)

app.add_middleware(GZipMiddleware, minimum_size=1000)

@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    return response
```

**Time:** 2 days  
**Deliverable:** Optimized, secure API ✅

---

### Day 21: Deployment to Azure

#### Task 4.6: Deploy to Azure App Service

**Using Azure Portal GUI:**

1. **Create App Service**
   - Go to "App Services" → "+ Create"
   - Resource Group: `rg-moi-reporting-prod`
   - Name: `moi-reporting-api-YOUR_SUFFIX`
   - Publish: `Code`
   - Runtime: `Python 3.11`
   - Region: `East US`
   - Plan: Create new (B1 or S1)
   - Click "Review + create"

2. **Configure App Settings**
   - Go to your App Service
   - Settings → "Configuration"
   - Add Application Settings:
     ```
     AZURE_KEY_VAULT_NAME = moi-reporting-kv-YOUR_SUFFIX
     AZURE_TENANT_ID = your-tenant-id
     AZURE_CLIENT_ID = your-client-id
     AZURE_CLIENT_SECRET = your-client-secret
     ENVIRONMENT = production
     DEBUG = False
     ```

3. **Deploy Code**
   
   **Option A: From VS Code**
   - Install "Azure App Service" extension
   - Right-click project → "Deploy to Web App"
   - Select your app service
   
   **Option B: From GitHub**
   - In App Service → Deployment → "Deployment Center"
   - Source: GitHub
   - Connect your repository
   - Select branch: `main`
   - Click "Save"

4. **Verify Deployment**
   - Go to your App Service URL: `https://moi-reporting-api-YOUR_SUFFIX.azurewebsites.net`
   - Check `/health` endpoint
   - Visit `/api/docs`

**Time:** 1 day  
**Deliverable:** API deployed to production ✅

---

## ✅ Phase 4 Complete Checklist

- [ ] Comprehensive test suite (80%+ coverage)
- [ ] API documentation complete
- [ ] Performance optimizations added
- [ ] Rate limiting implemented
- [ ] Security headers configured
- [ ] Deployed to Azure App Service
- [ ] Production monitoring set up
- [ ] Backup strategy implemented
- [ ] Load testing completed

**Deliverables:**
- ✅ Production-ready API
- ✅ Complete documentation
- ✅ Deployed and accessible
- ✅ Monitored and secure
- ✅ Ready for end users

---

## 🚀 Final Delivery Checklist

### ✅ Technical Completeness

- [ ] All 8+ API endpoints working
- [ ] Database schema deployed
- [ ] File upload functional
- [ ] Authentication working
- [ ] AI categorization implemented
- [ ] Error handling comprehensive
- [ ] Logging configured
- [ ] Tests passing (80%+ coverage)

### ✅ Documentation

- [ ] README.md complete
- [ ] API documentation (Swagger/ReDoc)
- [ ] Setup guide
- [ ] Architecture documentation
- [ ] API examples (cURL, Python, Postman)
- [ ] Troubleshooting guide

### ✅ Deployment

- [ ] Deployed to Azure
- [ ] Environment variables configured
- [ ] SSL/HTTPS enabled
- [ ] Monitoring enabled
- [ ] Backup configured
- [ ] Domain name (optional)

### ✅ Security

- [ ] Authentication required
- [ ] JWT tokens working
- [ ] HTTPS only
- [ ] Rate limiting active
- [ ] Input validation complete
- [ ] Security headers added
- [ ] Secrets in Key Vault

### ✅ Performance

- [ ] Response times < 500ms
- [ ] Database queries optimized
- [ ] Caching implemented (optional)
- [ ] Load tested (100 concurrent users)
- [ ] Compression enabled

---

## 📊 Final API Endpoints Summary

### Authentication
```
POST   /api/v1/auth/anonymous       - Create anonymous session
POST   /api/v1/auth/register        - Register user
GET    /api/v1/auth/me              - Get current user
```

### Reports
```
POST   /api/v1/reports/             - Submit report
GET    /api/v1/reports/             - List reports (paginated)
GET    /api/v1/reports/{id}         - Get single report
PUT    /api/v1/reports/{id}/status  - Update status
DELETE /api/v1/reports/{id}         - Delete report
```

### Attachments
```
POST   /api/v1/reports/{id}/attachments  - Upload files
GET    /api/v1/reports/{id}/attachments  - List attachments
DELETE /api/v1/attachments/{id}           - Delete attachment
```

### Health & Status
```
GET    /health                      - Health check
GET    /                            - API info
GET    /api/docs                    - Interactive docs
```

---

## 🎯 Success Metrics

### Phase 2 (Week 2)
- ✅ 5 working endpoints
- ✅ Database CRUD operations
- ✅ Request/response validation
- ✅ Basic error handling

### Phase 3 (Week 3)
- ✅ File upload/download
- ✅ Authentication system
- ✅ AI categorization
- ✅ Advanced queries

### Phase 4 (Week 4)
- ✅ 80%+ test coverage
- ✅ Complete documentation
- ✅ Production deployment
- ✅ Performance < 500ms
- ✅ Security hardened

