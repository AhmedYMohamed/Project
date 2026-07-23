import sys
import os

# Add the project directory to sys.path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from sqlalchemy import text
from app.core.database import SessionLocalOps

def alter_columns():
    db = SessionLocalOps()
    print("Starting database alteration...")
    
    queries = [
        "ALTER TABLE [dbo].[Report] ALTER COLUMN [title] NVARCHAR(500) NOT NULL;",
        "ALTER TABLE [dbo].[Report] ALTER COLUMN [descriptionText] NVARCHAR(max) NOT NULL;",
        "ALTER TABLE [dbo].[Report] ALTER COLUMN [locationRaw] NVARCHAR(2048) NULL;",
        "ALTER TABLE [dbo].[Report] ALTER COLUMN [transcribedVoiceText] NVARCHAR(max) NULL;"
    ]
    
    try:
        for q in queries:
            print(f"Executing: {q}")
            db.execute(text(q))
            db.commit()
            print("Done.")
            
        print("Database schema successfully updated to support Arabic Characters.")
    except Exception as e:
        print(f"An error occurred: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    alter_columns()
