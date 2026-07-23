import sys
import os

# Add the project directory to sys.path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from sqlalchemy import text
from app.core.database import SessionLocalOps

def alter_columns_lawyer():
    db = SessionLocalOps()
    print("Starting database alteration for Lawyer module...")
    
    queries = [
        # Update check constraint on User.role to include 'lawyer'
        """
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
        """,
        # Update check constraint on Report.status to include 'PendingLawyerReview' and 'ReturnedToCitizen'
        """
        DECLARE @chkReportStatus NVARCHAR(256);
        DECLARE @defReportStatus NVARCHAR(MAX);

        SELECT TOP 1 @chkReportStatus = cc.name, @defReportStatus = cc.definition
        FROM sys.check_constraints cc
        JOIN sys.columns c ON cc.parent_object_id = c.object_id AND cc.parent_column_id = c.column_id
        WHERE cc.parent_object_id = OBJECT_ID(N'dbo.[Report]') AND c.name = N'status';

        IF @chkReportStatus IS NOT NULL AND (@defReportStatus NOT LIKE '%PendingLawyerReview%' OR @defReportStatus NOT LIKE '%ReturnedToCitizen%')
        BEGIN
            EXEC('ALTER TABLE dbo.[Report] DROP CONSTRAINT [' + @chkReportStatus + '];');
            ALTER TABLE dbo.[Report] ADD CONSTRAINT [CK_Report_Status] CHECK ([status] IN ('Submitted', 'Assigned', 'InProgress', 'Resolved', 'Rejected', 'PendingLawyerReview', 'ReturnedToCitizen'));
        END
        ELSE IF @chkReportStatus IS NULL
        BEGIN
            ALTER TABLE dbo.[Report] ADD CONSTRAINT [CK_Report_Status] CHECK ([status] IN ('Submitted', 'Assigned', 'InProgress', 'Resolved', 'Rejected', 'PendingLawyerReview', 'ReturnedToCitizen'));
        END
        """,
        # Update check constraint on Attachment.fileType to include 'document'
        """
        DECLARE @chkFileType NVARCHAR(256);
        DECLARE @defFileType NVARCHAR(MAX);

        SELECT TOP 1 @chkFileType = cc.name, @defFileType = cc.definition
        FROM sys.check_constraints cc
        JOIN sys.columns c ON cc.parent_object_id = c.object_id AND cc.parent_column_id = c.column_id
        WHERE cc.parent_object_id = OBJECT_ID(N'dbo.[Attachment]') AND c.name = N'fileType';

        IF @chkFileType IS NOT NULL AND @defFileType NOT LIKE '%document%'
        BEGIN
            EXEC('ALTER TABLE dbo.[Attachment] DROP CONSTRAINT [' + @chkFileType + '];');
            ALTER TABLE dbo.[Attachment] ADD CONSTRAINT [CK_Attachment_FileType] CHECK ([fileType] IN ('image', 'video', 'audio', 'document'));
        END
        ELSE IF @chkFileType IS NULL
        BEGIN
            ALTER TABLE dbo.[Attachment] ADD CONSTRAINT [CK_Attachment_FileType] CHECK ([fileType] IN ('image', 'video', 'audio', 'document'));
        END
        """,
        # Add columns to User
        """
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[User]') AND name = N'lawyerId')
        BEGIN
            ALTER TABLE dbo.[User] ADD [lawyerId] NVARCHAR(450) NULL;
            ALTER TABLE dbo.[User] ADD CONSTRAINT FK_User_Lawyer FOREIGN KEY (lawyerId) REFERENCES dbo.[User](userId) ON DELETE SET NULL;
        END
        """,
        """
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[User]') AND name = N'syndicateId')
        BEGIN
            ALTER TABLE dbo.[User] ADD [syndicateId] NVARCHAR(100) NULL;
            ALTER TABLE dbo.[User] ADD CONSTRAINT UC_User_Syndicate UNIQUE (syndicateId);
        END
        """,
        """
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[User]') AND name = N'digitalSignatureUrl')
        BEGIN
            ALTER TABLE dbo.[User] ADD [digitalSignatureUrl] NVARCHAR(2048) NULL;
        END
        """,
        """
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[User]') AND name = N'lawyerQrCode')
        BEGIN
            ALTER TABLE dbo.[User] ADD [lawyerQrCode] NVARCHAR(256) NULL;
            ALTER TABLE dbo.[User] ADD CONSTRAINT UC_User_QrCode UNIQUE (lawyerQrCode);
        END
        """,
        # Add columns to Report
        """
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[Report]') AND name = N'lawyerId')
        BEGIN
            ALTER TABLE dbo.[Report] ADD [lawyerId] NVARCHAR(450) NULL;
            ALTER TABLE dbo.[Report] ADD CONSTRAINT FK_Report_Lawyer FOREIGN KEY (lawyerId) REFERENCES dbo.[User](userId) ON DELETE SET NULL;
        END
        """,
        """
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[Report]') AND name = N'lawyerSignature')
        BEGIN
            ALTER TABLE dbo.[Report] ADD [lawyerSignature] NVARCHAR(MAX) NULL;
        END
        """,
        """
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[Report]') AND name = N'lawyerFeedback')
        BEGIN
            ALTER TABLE dbo.[Report] ADD [lawyerFeedback] NVARCHAR(MAX) NULL;
        END
        """,
        """
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.[Report]') AND name = N'isUrgentEscalation')
        BEGIN
            ALTER TABLE dbo.[Report] ADD [isUrgentEscalation] BIT NOT NULL DEFAULT 0;
        END
        """,
        # Create ReportMessage Table
        """
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
        """
    ]
    
    try:
        for q in queries:
            print(f"Executing query...")
            db.execute(text(q))
            db.commit()
            print("Done.")
            
        print("Database schema successfully updated for Lawyer Module.")
    except Exception as e:
        print(f"An error occurred: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    alter_columns_lawyer()
