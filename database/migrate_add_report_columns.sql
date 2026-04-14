-- =============================================
-- Migration: Add missing columns to dbo.[Report]
-- Safe to run multiple times (idempotent)
-- =============================================

-- 1. Add latitude
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.[Report]') AND name = N'latitude'
)
BEGIN
    ALTER TABLE dbo.[Report]
    ADD [latitude] FLOAT NULL;
    PRINT 'Added column: latitude';
END
ELSE
    PRINT 'Column latitude already exists — skipping.';
GO

-- 2. Add longitude
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.[Report]') AND name = N'longitude'
)
BEGIN
    ALTER TABLE dbo.[Report]
    ADD [longitude] FLOAT NULL;
    PRINT 'Added column: longitude';
END
ELSE
    PRINT 'Column longitude already exists — skipping.';
GO

-- 3. Add officerNote
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.[Report]') AND name = N'officerNote'
)
BEGIN
    ALTER TABLE dbo.[Report]
    ADD [officerNote] NVARCHAR(MAX) NULL;
    PRINT 'Added column: officerNote';
END
ELSE
    PRINT 'Column officerNote already exists — skipping.';
GO
