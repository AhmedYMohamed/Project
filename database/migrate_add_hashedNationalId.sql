-- =============================================
-- Migration: Add hashedNationalId to dbo.[User]
-- Safe to run multiple times (idempotent)
-- =============================================

-- 1. Add column if missing
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.[User]') AND name = N'hashedNationalId'
)
BEGIN
    ALTER TABLE dbo.[User]
    ADD [hashedNationalId] NVARCHAR(256) NULL;
    PRINT 'Added column: hashedNationalId';
END
ELSE
    PRINT 'Column hashedNationalId already exists — skipping.';
GO

-- 2. Add unique filtered index if missing
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.[User]') AND name = N'IX_User_HashedNationalId'
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [IX_User_HashedNationalId]
    ON dbo.[User] ([hashedNationalId])
    WHERE [hashedNationalId] IS NOT NULL;
    PRINT 'Added index: IX_User_HashedNationalId';
END
ELSE
    PRINT 'Index IX_User_HashedNationalId already exists — skipping.';
GO
