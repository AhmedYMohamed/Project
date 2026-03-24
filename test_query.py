import sys
import os
import asyncio

# Setup path so `app` can be imported
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from app.core.database import SessionLocalOps, SessionLocalAnalytics
from app.models.report import Report
from app.models.user import User

def debug_query():
    print("Connecting to DB...")
    db_ops = SessionLocalOps()
    db_analytics = SessionLocalAnalytics() if SessionLocalAnalytics else None
    
    try:
        print("Checking users...")
        users = db_ops.query(User).all()
        for u in users:
            print(f"User: {u.role} - {u.email}")
            
        print("\nChecking reports...")
        reports = db_ops.query(Report).all()
        print(f"Total reports in Ops DB: {len(reports)}")
        for r in reports:
            print(f" - {r.reportId} | Lat: {r.latitude} | Lon: {r.longitude} | Title: {r.title}")
            
        print("\nChecking bounding box logic...")
        lat, lon = 30.0743, 31.3201
        radius_deg = 0.1
        min_lat = lat - radius_deg
        max_lat = lat + radius_deg
        min_lon = lon - radius_deg
        max_lon = lon + radius_deg
        
        filtered = db_ops.query(Report).filter(
            Report.latitude >= min_lat,
            Report.latitude <= max_lat,
            Report.longitude >= min_lon,
            Report.longitude <= max_lon
        ).all()
        print(f"Reports in bounding box: {len(filtered)}")
        
        print("\nChecking admin stats...")
        from app.services.analytics_service import AnalyticsService
        if db_analytics:
            try:
                counts = AnalyticsService.get_hot_status_counts(db_analytics)
                print(f"Analytics stats: {counts}")
            except Exception as e:
                print(f"Analytics error: {e}")
        else:
            print("Analytics DB not connected.")
            
    finally:
        db_ops.close()
        if db_analytics: db_analytics.close()

if __name__ == "__main__":
    debug_query()
