-- =========================================================================
-- PART 1: Run this query against your Operations Database (e.g. moi-ops / moi-sql-hot)
-- =========================================================================

-- 1. Create watermark table if not exists
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
END;
GO

-- 2. Create sp_UpdateWatermark stored procedure
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_UpdateWatermark]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_UpdateWatermark];
GO

CREATE PROCEDURE [dbo].[sp_UpdateWatermark]
    @TableName NVARCHAR(100),
    @NewWatermarkValue DATETIME2
AS
BEGIN
    UPDATE [dbo].[ETL_Watermark]
    SET [LastExtractedValue] = @NewWatermarkValue,
        [UpdatedAt] = GETUTCDATE()
    WHERE [TableName] = @TableName;
END;
GO

-- 3. Create usp_UpdateWatermark stored procedure
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_UpdateWatermark]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[usp_UpdateWatermark];
GO

CREATE PROCEDURE [dbo].[usp_UpdateWatermark]
    @TableName NVARCHAR(100),
    @NewWatermarkValue DATETIME2
AS
BEGIN
    UPDATE [dbo].[ETL_Watermark]
    SET [LastExtractedValue] = @NewWatermarkValue,
        [UpdatedAt] = GETUTCDATE()
    WHERE [TableName] = @TableName;
END;
GO


-- =========================================================================
-- PART 2: Run this query against your Analytics Database (e.g. moi-al / moi-sql-cold)
-- =========================================================================

-- 1. Create schemas
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'hot')
    EXEC('CREATE SCHEMA [hot]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'cold')
    EXEC('CREATE SCHEMA [cold]');
GO

-- 2. Clean up incorrect tables if they exist from the old initialization
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'ReportAnalytics' AND schema_id = SCHEMA_ID('hot')) 
    DROP TABLE [hot].[ReportAnalytics];
GO
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'ReportAnalytics' AND schema_id = SCHEMA_ID('cold')) 
    DROP TABLE [cold].[ReportAnalytics];
GO
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_FullReportAnalytics' AND schema_id = SCHEMA_ID('dbo')) 
    DROP VIEW [dbo].[vw_FullReportAnalytics];
GO

-- 3. Create Fact_Reports in hot schema
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
END;
GO

-- 4. Create Fact_Reports in cold schema
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
END;
GO

-- 5. Create indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Hot_CreatedAt' AND object_id = OBJECT_ID('[hot].[Fact_Reports]'))
    CREATE NONCLUSTERED INDEX [IX_Hot_CreatedAt] ON [hot].[Fact_Reports] ([createdAt]) INCLUDE ([status], [categoryId]);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Hot_Status' AND object_id = OBJECT_ID('[hot].[Fact_Reports]'))
    CREATE NONCLUSTERED INDEX [IX_Hot_Status] ON [hot].[Fact_Reports] ([status]) INCLUDE ([categoryId], [createdAt]);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Hot_Category' AND object_id = OBJECT_ID('[hot].[Fact_Reports]'))
    CREATE NONCLUSTERED INDEX [IX_Hot_Category] ON [hot].[Fact_Reports] ([categoryId]) INCLUDE ([status], [createdAt]);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Hot_UserRole' AND object_id = OBJECT_ID('[hot].[Fact_Reports]'))
    CREATE NONCLUSTERED INDEX [IX_Hot_UserRole] ON [hot].[Fact_Reports] ([userRole]) WHERE [userRole] IS NOT NULL;
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Cold_CreatedAt' AND object_id = OBJECT_ID('[cold].[Fact_Reports]'))
    CREATE NONCLUSTERED INDEX [IX_Cold_CreatedAt] ON [cold].[Fact_Reports] ([createdAt]) INCLUDE ([status], [categoryId]);
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Cold_Status' AND object_id = OBJECT_ID('[cold].[Fact_Reports]'))
    CREATE NONCLUSTERED INDEX [IX_Cold_Status] ON [cold].[Fact_Reports] ([status]);
GO

-- 6. Create views
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_AllReports' AND schema_id = SCHEMA_ID('dbo'))
    DROP VIEW [dbo].[vw_AllReports];
GO
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
');
GO

IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_Dashboard_Summary' AND schema_id = SCHEMA_ID('dbo'))
    DROP VIEW [dbo].[vw_Dashboard_Summary];
GO
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
');
GO

-- 7. Create stored procedure for Purge and Archival
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_ArchiveAndPurge90DayData]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_ArchiveAndPurge90DayData];
GO

EXEC('
CREATE PROCEDURE [dbo].[sp_ArchiveAndPurge90DayData]
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Copy data older than 90 days from hot.Fact_Reports to cold.Fact_Reports
    INSERT INTO [cold].[Fact_Reports] (
        [reportId], [title], [status], [categoryId], 
        [createdAt], [updatedAt], [userRole], 
        [isAnonymous], [attachmentCount], [aiConfidence], [ExtractedAt]
    )
    SELECT 
        [reportId], [title], [status], [categoryId], 
        [createdAt], [updatedAt], [userRole], 
        [isAnonymous], [attachmentCount], [aiConfidence], [ExtractedAt]
    FROM [hot].[Fact_Reports]
    WHERE [createdAt] < DATEADD(DAY, -90, GETUTCDATE())
      AND [reportId] NOT IN (SELECT [reportId] FROM [cold].[Fact_Reports]);

    -- 2. Delete the archived data from hot.Fact_Reports
    DELETE FROM [hot].[Fact_Reports]
    WHERE [createdAt] < DATEADD(DAY, -90, GETUTCDATE());
END
');
GO
