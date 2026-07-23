# deploy_schemas.py
import sys
import os
import urllib.parse

# Add the project directory to sys.path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from sqlalchemy import create_engine, text
from app.core.config import get_settings

def get_pymssql_url(conn_str: str) -> str:
    """Converts SQL Server Connection String to a pymssql SQLAlchemy URL"""
    if not conn_str:
        raise ValueError("Database connection string is required")
        
    # Parse key-value pairs
    pairs = {}
    for part in conn_str.split(';'):
        if '=' in part:
            k, v = part.split('=', 1)
            pairs[k.strip().lower()] = v.strip()
            
    # Extract properties
    server = pairs.get('server', '')
    if server.startswith('tcp:'):
        server = server[4:]
        
    database = pairs.get('database', pairs.get('initial catalog', ''))
    uid = pairs.get('uid', pairs.get('user id', ''))
    pwd = pairs.get('pwd', pairs.get('password', ''))
    
    # URL encode credentials
    uid_enc = urllib.parse.quote_plus(uid)
    pwd_enc = urllib.parse.quote_plus(pwd)
    
    return f"mssql+pymssql://{uid_enc}:{pwd_enc}@{server}/{database}"

def deploy_ops_schema(settings):
    print("\n--- Deploying Operations DB Schema Additions ---")
    if not settings.SQLALCHEMY_DATABASE_URI_OPS:
        print("✗ Operations DB URI not configured.")
        return
    
    url = get_pymssql_url(settings.SQLALCHEMY_DATABASE_URI_OPS)
    print(f"Connecting to Operations DB...")
    engine = create_engine(url)
    
    queries = [
        # 1. Create watermark table if not exists
        """
        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ETL_Watermark' AND schema_id = SCHEMA_ID('dbo'))
        BEGIN
            CREATE TABLE [dbo].[ETL_Watermark] (
                [TableName] NVARCHAR(100) NOT NULL PRIMARY KEY,
                [LastExtractedValue] DATETIME2(7) NOT NULL,
                [UpdatedAt] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE()
            );
            INSERT INTO [dbo].[ETL_Watermark] ([TableName], [LastExtractedValue])
            VALUES ('Report', '1900-01-01 00:00:00');
            PRINT 'Created ETL_Watermark table.';
        END
        ELSE
        BEGIN
            PRINT 'ETL_Watermark table already exists.';
        END
        """,
        # 2. Create sp_UpdateWatermark stored procedure
        """
        IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_UpdateWatermark]') AND type in (N'P', N'PC'))
            DROP PROCEDURE [dbo].[sp_UpdateWatermark];
        """,
        """
        CREATE PROCEDURE [dbo].[sp_UpdateWatermark]
            @TableName NVARCHAR(100),
            @NewWatermarkValue DATETIME2
        AS
        BEGIN
            UPDATE [dbo].[ETL_Watermark]
            SET [LastExtractedValue] = @NewWatermarkValue,
                [UpdatedAt] = GETUTCDATE()
            WHERE [TableName] = @TableName;
        END
        """,
        # 3. Create usp_UpdateWatermark (alternative name used in some templates)
        """
        IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_UpdateWatermark]') AND type in (N'P', N'PC'))
            DROP PROCEDURE [dbo].[usp_UpdateWatermark];
        """,
        """
        CREATE PROCEDURE [dbo].[usp_UpdateWatermark]
            @TableName NVARCHAR(100),
            @NewWatermarkValue DATETIME2
        AS
        BEGIN
            UPDATE [dbo].[ETL_Watermark]
            SET [LastExtractedValue] = @NewWatermarkValue,
                [UpdatedAt] = GETUTCDATE()
            WHERE [TableName] = @TableName;
        END
        """
    ]
    
    connection = engine.connect()
    transaction = connection.begin()
    try:
        for q in queries:
            connection.execute(text(q))
        transaction.commit()
        print("✓ Operations DB additions completed successfully.")
    except Exception as e:
        transaction.rollback()
        print(f"✗ Operations DB deployment failed: {e}")
        raise
    finally:
        connection.close()

def deploy_analytics_schema(settings):
    print("\n--- Deploying Analytics DB Schema ---")
    if not settings.SQLALCHEMY_DATABASE_URI_ANALYTICS:
        print("✗ Analytics DB URI not configured.")
        return
    
    url = get_pymssql_url(settings.SQLALCHEMY_DATABASE_URI_ANALYTICS)
    print(f"Connecting to Analytics DB...")
    engine = create_engine(url)
    
    queries = [
        # 1. Create schemas
        "IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'hot') EXEC('CREATE SCHEMA [hot]');",
        "IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'cold') EXEC('CREATE SCHEMA [cold]');",
        
        # 2. Clean up incorrect tables if they exist from the old initialization
        """
        IF EXISTS (SELECT * FROM sys.tables WHERE name = 'ReportAnalytics' AND schema_id = SCHEMA_ID('hot')) 
            DROP TABLE [hot].[ReportAnalytics];
        """,
        """
        IF EXISTS (SELECT * FROM sys.tables WHERE name = 'ReportAnalytics' AND schema_id = SCHEMA_ID('cold')) 
            DROP TABLE [cold].[ReportAnalytics];
        """,
        """
        IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_FullReportAnalytics' AND schema_id = SCHEMA_ID('dbo')) 
            DROP VIEW [dbo].[vw_FullReportAnalytics];
        """,
        
        # 3. Create Fact_Reports in hot schema
        """
        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Fact_Reports' AND schema_id = SCHEMA_ID('hot'))
        BEGIN
            CREATE TABLE [hot].[Fact_Reports] (
                [reportId] NVARCHAR(450) NOT NULL,
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
                [ExtractedAt] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
                CONSTRAINT [PK_Hot_Fact_Reports] PRIMARY KEY CLUSTERED ([reportId])
            );
            PRINT 'Created [hot].[Fact_Reports] table.';
        END
        ELSE
        BEGIN
            PRINT '[hot].[Fact_Reports] table already exists.';
        END
        """,
        
        # 4. Create Fact_Reports in cold schema
        """
        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Fact_Reports' AND schema_id = SCHEMA_ID('cold'))
        BEGIN
            CREATE TABLE [cold].[Fact_Reports] (
                [reportId] NVARCHAR(450) NOT NULL,
                [title] NVARCHAR(500) NOT NULL,
                [status] NVARCHAR(50) NOT NULL,
                [categoryId] NVARCHAR(100) NOT NULL,
                [createdAt] DATETIME2(7) NOT NULL,
                [updatedAt] DATETIME2(7) NOT NULL,
                [userRole] NVARCHAR(50) NULL,
                [isAnonymous] BIT NULL,
                [attachmentCount] INT NOT NULL DEFAULT 0,
                [aiConfidence] FLOAT NULL,
                [ExtractedAt] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
                CONSTRAINT [PK_Cold_Fact_Reports] PRIMARY KEY CLUSTERED ([reportId])
            );
            PRINT 'Created [cold].[Fact_Reports] table.';
        END
        ELSE
        BEGIN
            PRINT '[cold].[Fact_Reports] table already exists.';
        END
        """,
        
        # 5. Create indexes
        """
        IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Hot_CreatedAt' AND object_id = OBJECT_ID('[hot].[Fact_Reports]'))
            CREATE NONCLUSTERED INDEX [IX_Hot_CreatedAt] ON [hot].[Fact_Reports] ([createdAt]) INCLUDE ([status], [categoryId]);
        """,
        """
        IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Hot_Status' AND object_id = OBJECT_ID('[hot].[Fact_Reports]'))
            CREATE NONCLUSTERED INDEX [IX_Hot_Status] ON [hot].[Fact_Reports] ([status]) INCLUDE ([categoryId], [createdAt]);
        """,
        """
        IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Hot_Category' AND object_id = OBJECT_ID('[hot].[Fact_Reports]'))
            CREATE NONCLUSTERED INDEX [IX_Hot_Category] ON [hot].[Fact_Reports] ([categoryId]) INCLUDE ([status], [createdAt]);
        """,
        """
        IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Hot_UserRole' AND object_id = OBJECT_ID('[hot].[Fact_Reports]'))
            CREATE NONCLUSTERED INDEX [IX_Hot_UserRole] ON [hot].[Fact_Reports] ([userRole]) WHERE [userRole] IS NOT NULL;
        """,
        """
        IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Cold_CreatedAt' AND object_id = OBJECT_ID('[cold].[Fact_Reports]'))
            CREATE NONCLUSTERED INDEX [IX_Cold_CreatedAt] ON [cold].[Fact_Reports] ([createdAt]) INCLUDE ([status], [categoryId]);
        """,
        """
        IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Cold_Status' AND object_id = OBJECT_ID('[cold].[Fact_Reports]'))
            CREATE NONCLUSTERED INDEX [IX_Cold_Status] ON [cold].[Fact_Reports] ([status]);
        """,
        
        # 6. Create views
        """
        IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_AllReports' AND schema_id = SCHEMA_ID('dbo'))
            DROP VIEW [dbo].[vw_AllReports];
        """,
        """
        EXEC('
        CREATE VIEW [dbo].[vw_AllReports] AS
        SELECT 
            [reportId], [title], [descriptionText], [locationRaw],
            [status], [categoryId], [aiConfidence],
            [createdAt], [updatedAt], [userId], [userRole],
            [isAnonymous], [attachmentCount], [transcribedVoiceText],
            ''Hot'' AS [DataTier]
        FROM [hot].[Fact_Reports]
        UNION ALL
        SELECT 
            [reportId], [title], NULL AS [descriptionText], NULL AS [locationRaw],
            [status], [categoryId], [aiConfidence],
            [createdAt], [updatedAt], NULL AS [userId], [userRole],
            [isAnonymous], [attachmentCount], NULL AS [transcribedVoiceText],
            ''Cold'' AS [DataTier]
        FROM [cold].[Fact_Reports];
        ')
        """,
        """
        IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_Dashboard_Summary' AND schema_id = SCHEMA_ID('dbo'))
            DROP VIEW [dbo].[vw_Dashboard_Summary];
        """,
        """
        EXEC('
        CREATE VIEW [dbo].[vw_Dashboard_Summary] AS
        SELECT 
            [categoryId],
            [status],
            COUNT(*) AS [ReportCount],
            AVG([aiConfidence]) AS [AvgConfidence],
            MAX([createdAt]) AS [LatestReport]
        FROM [dbo].[vw_AllReports]
        GROUP BY [categoryId], [status];
        ')
        """
    ]
    
    connection = engine.connect()
    transaction = connection.begin()
    try:
        for q in queries:
            connection.execute(text(q))
        transaction.commit()
        print("✓ Analytics DB deployment completed successfully.")
    except Exception as e:
        transaction.rollback()
        print(f"✗ Analytics DB deployment failed: {e}")
        raise
    finally:
        connection.close()

def main():
    print("Loading application settings and resolving Key Vault secrets...")
    settings = get_settings()
    
    deploy_ops_schema(settings)
    deploy_analytics_schema(settings)
    print("\n✓ Schema deployment complete.")

if __name__ == "__main__":
    main()
