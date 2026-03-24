"""
Database Seed Script
====================
Inserts sample data into the database for testing/demo purposes.

Usage:
    python seed_data.py <attachment_file_path>
    
    attachment_file_path: Path to a file (image/video/document) to use as sample evidence.
    
Example:
    python seed_data.py ./image.png
"""

import sys
import os
import uuid
import shutil
from datetime import datetime, timezone, timedelta

# Add the project directory to sys.path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from sqlalchemy import text
from app.core.database import SessionLocalOps
from app.core.security import hash_password


def seed_data(attachment_file_path: str):
    db = SessionLocalOps()
    
    print("=" * 60)
    print("  MOI Reporting System - Database Seeder")
    print("=" * 60)
    
    # Validate the file
    if not os.path.exists(attachment_file_path):
        print(f"ERROR: File not found: {attachment_file_path}")
        sys.exit(1)
    
    file_name = os.path.basename(attachment_file_path)
    file_size = os.path.getsize(attachment_file_path)
    
    # Detect MIME type
    ext = file_name.split('.')[-1].lower()
    mime_map = {
        'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
        'gif': 'image/gif', 'mp4': 'video/mp4', 'avi': 'video/avi',
        'mp3': 'audio/mpeg', 'wav': 'audio/wav', 'pdf': 'application/pdf',
    }
    mime_type = mime_map.get(ext, 'application/octet-stream')
    file_type = 'image' if mime_type.startswith('image') else 'video' if mime_type.startswith('video') else 'audio' if mime_type.startswith('audio') else 'document'
    
    print(f"  Attachment: {file_name} ({file_size} bytes, {mime_type})")
    print("-" * 60)
    
    try:
        now = datetime.now(timezone.utc)
        hashed_pw = hash_password("password123")
        
        # ==========================
        # 1. USERS
        # ==========================
        print("\n[1/5] Creating Users...")
        
        citizen_id = f"U-{uuid.uuid4().hex[:8].upper()}"
        officer_id = f"U-{uuid.uuid4().hex[:8].upper()}"
        
        db.execute(text("""
            INSERT INTO [dbo].[User] (userId, isAnonymous, createdAt, role, email, passwordHash)
            VALUES (:uid, 0, :now, 'citizen', :email, :pw)
        """), {"uid": citizen_id, "now": now, "email": "citizen@moi.gov", "pw": hashed_pw})
        
        db.execute(text("""
            INSERT INTO [dbo].[User] (userId, isAnonymous, createdAt, role, email, passwordHash)
            VALUES (:uid, 0, :now, 'officer', :email, :pw)
        """), {"uid": officer_id, "now": now, "email": "officer@moi.gov", "pw": hashed_pw})
        
        db.commit()
        print(f"  ✓ Citizen: citizen@moi.gov (ID: {citizen_id})")
        print(f"  ✓ Officer: officer@moi.gov (ID: {officer_id})")
        print(f"  ✓ Password for both: password123")

        # ==========================
        # 2. OFFICER SERVICE AREA
        # ==========================
        print("\n[2/5] Creating Officer Service Area...")
        
        db.execute(text("""
            INSERT INTO [dbo].[OfficerServiceArea] (userId, latitude, longitude, cityName, startDate, endDate)
            VALUES (:uid, :lat, :lon, :city, :start, NULL)
        """), {"uid": officer_id, "lat": 30.0444, "lon": 31.2357, "city": "Cairo, Nasr City", "start": now - timedelta(days=30)})
        
        db.commit()
        print(f"  ✓ Active Area: Cairo, Nasr City (30.0444, 31.2357)")

        # ==========================
        # 3. REPORTS
        # ==========================
        print("\n[3/5] Creating Reports...")
        
        reports_data = [
            {
                "id": f"R-{uuid.uuid4().hex[:8].upper()}",
                "title": "إشارة مرور معطلة",
                "desc": "إشارة المرور في تقاطع شارع الخليفة المأمون مع شارع مكرم عبيد معطلة تماماً. تسببت في ازدحام مروري شديد وحوادث بسيطة.",
                "location": "Cairo, Nasr City - Makram Ebeid St",
                "lat": 30.0500, "lon": 31.3400,
                "category": "traffic", "status": "Submitted",
            },
            {
                "id": f"R-{uuid.uuid4().hex[:8].upper()}",
                "title": "كسر في ماسورة مياه",
                "desc": "يوجد كسر كبير في ماسورة المياه الرئيسية أمام عمارة 15 في الحي السابع. المياه تغمر الشارع بالكامل وتسبب ضرراً للسيارات.",
                "location": "Cairo, Nasr City - 7th District",
                "lat": 30.0480, "lon": 31.3350,
                "category": "utilities", "status": "InProgress",
            },
            {
                "id": f"R-{uuid.uuid4().hex[:8].upper()}",
                "title": "تجمع مشبوه",
                "desc": "مجموعة من الأشخاص المجهولين يتجمعون بشكل متكرر أمام المدرسة بعد منتصف الليل. السلوك مريب ويثير قلق السكان.",
                "location": "Cairo, Maadi - Street 9",
                "lat": 30.0150, "lon": 31.2580,
                "category": "crime", "status": "Submitted",
            },
            {
                "id": f"R-{uuid.uuid4().hex[:8].upper()}",
                "title": "حفرة كبيرة في الطريق",
                "desc": "حفرة عميقة جداً في منتصف الطريق الدائري بالقرب من مخرج المعادي. تسببت في تلف عدة سيارات وتحتاج إصلاح فوري.",
                "location": "Cairo, Ring Road - Maadi Exit",
                "lat": 30.0200, "lon": 31.2500,
                "category": "infrastructure", "status": "Resolved",
            },
            {
                "id": f"R-{uuid.uuid4().hex[:8].upper()}",
                "title": "إزعاج عام من ورشة",
                "desc": "ورشة حدادة تعمل حتى ساعات متأخرة من الليل مسببة ضوضاء شديدة تمنع السكان من النوم. مخالفة واضحة لقوانين البيئة.",
                "location": "Cairo, Nasr City - Abbas El-Akkad",
                "lat": 30.0550, "lon": 31.3450,
                "category": "public_nuisance", "status": "Submitted",
            },
        ]
        
        for r in reports_data:
            db.execute(text("""
                INSERT INTO [dbo].[Report] 
                (reportId, userId, title, descriptionText, locationRaw, latitude, longitude, status, categoryId, createdAt, updatedAt)
                VALUES (:rid, :uid, :title, :desc, :loc, :lat, :lon, :status, :cat, :created, :updated)
            """), {
                "rid": r["id"], "uid": citizen_id,
                "title": r["title"], "desc": r["desc"],
                "loc": r["location"], "lat": r["lat"], "lon": r["lon"],
                "status": r["status"], "cat": r["category"],
                "created": now - timedelta(hours=len(reports_data) - reports_data.index(r)),
                "updated": now,
            })
        
        db.commit()
        print(f"  ✓ Created {len(reports_data)} reports")
        for r in reports_data:
            print(f"    - [{r['status']:12s}] {r['title']}")

        # ==========================
        # 4. ATTACHMENTS (copy file to local_storage)
        # ==========================
        print("\n[4/5] Creating Attachments...")
        
        storage_base = os.path.join(os.path.dirname(__file__), "local_storage")
        
        for r in reports_data[:3]:  # Attach to first 3 reports
            report_folder = os.path.join(storage_base, r["id"])
            os.makedirs(report_folder, exist_ok=True)
            
            dest_path = os.path.join(report_folder, file_name)
            shutil.copy2(attachment_file_path, dest_path)
            
            blob_uri = f"local_storage/{r['id']}/{file_name}"
            att_id = str(uuid.uuid4())
            
            db.execute(text("""
                INSERT INTO [dbo].[Attachment]
                (attachmentId, reportId, blobStorageUri, mimeType, fileType, fileSizeBytes, createdAt)
                VALUES (:aid, :rid, :uri, :mime, :ft, :size, :now)
            """), {
                "aid": att_id, "rid": r["id"],
                "uri": blob_uri, "mime": mime_type,
                "ft": file_type, "size": file_size, "now": now
            })
        
        db.commit()
        print(f"  ✓ Attached '{file_name}' to first 3 reports")

        # ==========================
        # 5. SUMMARY
        # ==========================
        print("\n" + "=" * 60)
        print("  SEED COMPLETE!")
        print("=" * 60)
        print(f"\n  Login Credentials:")
        print(f"  ┌────────────────────────────────────────────┐")
        print(f"  │  Citizen:  citizen@moi.gov / password123   │")
        print(f"  │  Officer:  officer@moi.gov / password123   │")
        print(f"  └────────────────────────────────────────────┘")
        print(f"\n  Data Created:")
        print(f"    • 2 Users (1 Citizen + 1 Officer)")
        print(f"    • 1 Officer Service Area (Cairo, Nasr City)")
        print(f"    • {len(reports_data)} Reports (Arabic content)")
        print(f"    • 3 File Attachments")
        print()
        
    except Exception as e:
        print(f"\nERROR: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python seed_data.py <attachment_file_path>")
        print("Example: python seed_data.py ./image.png")
        sys.exit(1)
    
    seed_data(sys.argv[1])
