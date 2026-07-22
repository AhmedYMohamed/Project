import os
from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
import logging

from app.core.config import get_settings
from app.core.database import test_database_connections, engine_ops
from app.api.v1 import reports, admin,users, auth, voice, officer, lawyer

# Import models to register with SQLAlchemy (but don't use them directly)
from app.models import user, report, attachment, report_message

settings = get_settings()

logging.basicConfig(
    level=logging.DEBUG if settings.DEBUG else logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Handle application startup and shutdown events"""
    logger.info(f"Starting {settings.APP_NAME} in {settings.ENVIRONMENT} environment")
    
    try:
        test_database_connections()
        logger.info("✓ All database connections verified")
        
        # Auto-apply schema migrations
        with engine_ops.connect() as conn:
            from sqlalchemy import text
            # Add hashedNationalId to User
            conn.execute(text("""
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[User]') AND name = N'hashedNationalId')
            BEGIN ALTER TABLE dbo.[User] ADD [hashedNationalId] NVARCHAR(256) NULL; END
            """))
            conn.execute(text("""
            IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.[User]') AND name = N'IX_User_HashedNationalId')
            BEGIN CREATE UNIQUE NONCLUSTERED INDEX [IX_User_HashedNationalId] ON dbo.[User] ([hashedNationalId]) WHERE [hashedNationalId] IS NOT NULL; END
            """))
            # Add missing Report columns
            conn.execute(text("""
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[Report]') AND name = N'latitude')
            BEGIN ALTER TABLE dbo.[Report] ADD [latitude] FLOAT NULL; END
            """))
            conn.execute(text("""
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[Report]') AND name = N'longitude')
            BEGIN ALTER TABLE dbo.[Report] ADD [longitude] FLOAT NULL; END
            """))
            conn.execute(text("""
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[Report]') AND name = N'officerNote')
            BEGIN ALTER TABLE dbo.[Report] ADD [officerNote] NVARCHAR(MAX) NULL; END
            """))
            
            # Add lawyer columns to User
            conn.execute(text("""
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[User]') AND name = N'lawyerId')
            BEGIN
                ALTER TABLE dbo.[User] ADD [lawyerId] NVARCHAR(450) NULL;
                ALTER TABLE dbo.[User] ADD CONSTRAINT FK_User_Lawyer FOREIGN KEY (lawyerId) REFERENCES dbo.[User](userId) ON DELETE SET NULL;
            END
            """))
            conn.execute(text("""
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[User]') AND name = N'syndicateId')
            BEGIN
                ALTER TABLE dbo.[User] ADD [syndicateId] NVARCHAR(100) NULL;
                ALTER TABLE dbo.[User] ADD CONSTRAINT UC_User_Syndicate UNIQUE (syndicateId);
            END
            """))
            conn.execute(text("""
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[User]') AND name = N'digitalSignatureUrl')
            BEGIN
                ALTER TABLE dbo.[User] ADD [digitalSignatureUrl] NVARCHAR(2048) NULL;
            END
            """))
            conn.execute(text("""
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[User]') AND name = N'lawyerQrCode')
            BEGIN
                ALTER TABLE dbo.[User] ADD [lawyerQrCode] NVARCHAR(256) NULL;
                ALTER TABLE dbo.[User] ADD CONSTRAINT UC_User_QrCode UNIQUE (lawyerQrCode);
            END
            """))

            # Update check constraint on User.role to allow 'lawyer'
            conn.execute(text("""
            DECLARE @chkName NVARCHAR(256);
            DECLARE @definition NVARCHAR(MAX);

            SELECT TOP 1 @chkName = cc.name, @definition = cc.definition
            FROM sys.check_constraints cc
            JOIN sys.columns c ON cc.parent_object_id = c.object_id AND cc.parent_column_id = c.column_id
            WHERE cc.parent_object_id = OBJECT_ID(N'dbo.[User]') AND c.name = N'role';

            IF @chkName IS NOT NULL AND @definition NOT LIKE '%lawyer%'
            BEGIN
                EXEC('ALTER TABLE dbo.[User] DROP CONSTRAINT [' + @chkName + '];');
                ALTER TABLE dbo.[User] ADD CONSTRAINT [CK_User_Role] CHECK ([role] IN ('citizen', 'officer', 'admin', 'lawyer'));
            END
            ELSE IF @chkName IS NULL
            BEGIN
                ALTER TABLE dbo.[User] ADD CONSTRAINT [CK_User_Role] CHECK ([role] IN ('citizen', 'officer', 'admin', 'lawyer'));
            END
            """))

            # Add lawyer columns to Report
            conn.execute(text("""
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[Report]') AND name = N'lawyerId')
            BEGIN
                ALTER TABLE dbo.[Report] ADD [lawyerId] NVARCHAR(450) NULL;
                ALTER TABLE dbo.[Report] ADD CONSTRAINT FK_Report_Lawyer FOREIGN KEY (lawyerId) REFERENCES dbo.[User](userId) ON DELETE SET NULL;
            END
            """))
            conn.execute(text("""
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[Report]') AND name = N'lawyerSignature')
            BEGIN
                ALTER TABLE dbo.[Report] ADD [lawyerSignature] NVARCHAR(MAX) NULL;
            END
            """))
            conn.execute(text("""
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[Report]') AND name = N'lawyerFeedback')
            BEGIN
                ALTER TABLE dbo.[Report] ADD [lawyerFeedback] NVARCHAR(MAX) NULL;
            END
            """))
            conn.execute(text("""
            IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[Report]') AND name = N'isUrgentEscalation')
            BEGIN
                ALTER TABLE dbo.[Report] ADD [isUrgentEscalation] BIT NOT NULL DEFAULT 0;
            END
            """))

            # Create ReportMessage table
            conn.execute(text("""
            IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.[ReportMessage]') AND type = 'U')
            BEGIN
                CREATE TABLE dbo.[ReportMessage] (
                    [messageId] NVARCHAR(450) PRIMARY KEY,
                    [reportId] NVARCHAR(450) NOT NULL,
                    [senderId] NVARCHAR(450) NOT NULL,
                    [senderRole] NVARCHAR(50) NOT NULL,
                    [messageText] NVARCHAR(MAX) NOT NULL,
                    [createdAt] DATETIME NOT NULL DEFAULT GETUTCDATE(),
                    CONSTRAINT FK_ReportMessage_Report FOREIGN KEY (reportId) REFERENCES dbo.[Report](reportId) ON DELETE CASCADE,
                    CONSTRAINT FK_ReportMessage_User FOREIGN KEY (senderId) REFERENCES dbo.[User](userId) ON DELETE CASCADE
                );
            END
            """))
            conn.commit()
            logger.info("✓ Schema migrations verified and applied")
            
    except Exception as e:
        logger.critical(f"✗ Database connection or migration failed: {e}", exc_info=True)
        raise SystemExit("Database connection failed")
    
    yield
    
    logger.info("Shutting down application...")
    engine_ops.dispose()

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.API_VERSION,
    description="MoI Digital Reporting System - Two Database Architecture",
    lifespan=lifespan,
    docs_url="/api/docs",
    redoc_url="/api/redoc"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins= "*",
    allow_origin_regex=r"https://.*\.app\.github\.dev",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return RedirectResponse(url="/api/docs")

@app.get("/health", status_code=status.HTTP_200_OK)
async def health_check():
    return {
        "status": "healthy",
        "service": settings.APP_NAME,
        "version": settings.API_VERSION,
        "databases": {
            "operations": "connected",
            "analytics": "connected" if settings.SQLALCHEMY_DATABASE_URI_ANALYTICS else "not configured"
        }
    }


# Mount local storage for attachments
os.makedirs(settings.ABSOLUTE_STORAGE_PATH, exist_ok=True)
app.mount("/local_storage", StaticFiles(directory=settings.ABSOLUTE_STORAGE_PATH), name="local_storage")

# Register routers
app.include_router(
    reports.router,
    prefix="/api/v1/reports",
    tags=["Reports"]
)

app.include_router(
    admin.router,
    prefix="/api/v1/admin",
    tags=["Admin Dashboard"]
)
app.include_router(
    users.router,
    prefix=f"/api/v1/users",
    tags=["Users"]
)


app.include_router(
    auth.router,
    prefix=f"/api/v1/auth",
    tags=["Auth"]
)

app.include_router(
    voice.router,
    prefix=f"/api/v1/voice",
    tags=["Voice"]
)

app.include_router(
    officer.router,
    prefix="/api/v1/officer",
    tags=["Officer"]
)

app.include_router(
    lawyer.router,
    prefix="/api/v1/lawyer",
    tags=["Lawyer"]
)

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    logger.error(f"Unhandled exception: {str(exc)}", exc_info=True)
    origin = request.headers.get("origin", "")
    headers = {
        "Access-Control-Allow-Origin": origin if origin else "*",
        "Access-Control-Allow-Credentials": "true",
        "Access-Control-Allow-Methods": "*",
        "Access-Control-Allow-Headers": "*",
    }
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "detail": "Internal server error",
            "message": str(exc) if settings.DEBUG else "An unexpected error occurred"
        },
        headers=headers,
    )
