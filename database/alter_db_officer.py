import sys
import os

# Add the project directory to sys.path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from sqlalchemy import text
from app.core.database import SessionLocalOps

def alter_columns_officer():
    db = SessionLocalOps()
    print("Starting database alteration for Officer app features...")
    
    queries = [
        # Add columns to Report
        "ALTER TABLE [dbo].[Report] ADD [latitude] FLOAT NULL;",
        "ALTER TABLE [dbo].[Report] ADD [longitude] FLOAT NULL;",
        "ALTER TABLE [dbo].[Report] ADD [officerNote] NVARCHAR(MAX) NULL;",
        
        # Create OfficerServiceArea Table
        """
        CREATE TABLE [dbo].[OfficerServiceArea] (
            [id] INT IDENTITY(1,1) PRIMARY KEY,
            [userId] NVARCHAR(450) NOT NULL,
            [latitude] FLOAT NOT NULL,
            [longitude] FLOAT NOT NULL,
            [cityName] NVARCHAR(255) NOT NULL,
            [startDate] DATETIME NOT NULL,
            [endDate] DATETIME NULL,
            CONSTRAINT FK_OfficerServiceArea_User FOREIGN KEY (userId) REFERENCES [dbo].[User](userId) ON DELETE CASCADE
        );
        """
    ]
    
    try:
        for q in queries:
            print(f"Executing: {q}")
            db.execute(text(q))
            db.commit()
            print("Done.")
            
        print("Database schema successfully updated for Officer integration.")
    except Exception as e:
        print(f"An error occurred: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    alter_columns_officer()
