from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from typing import Optional

from app.core.database import get_db_ops
from app.api.v1.auth import get_current_user
from app.models.user import User
from app.schemas.report import ReportListResponse
from app.services.report_service import ReportService
from functools import lru_cache

router = APIRouter()

@router.get(
    "/reports/nearby",
    response_model=ReportListResponse,
    summary="Get reports near the officer's active service area"
)
def get_nearby_reports(
    db: Session = Depends(get_db_ops),
    current_user: User = Depends(get_current_user),
    latitude: Optional[float] = Query(None, description="Officer's current latitude"),
    longitude: Optional[float] = Query(None, description="Officer's current longitude"),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    radius_deg: float = Query(0.1, description="Radius in degrees (approx 10km)")
):
    """
    Finds reports within the specified radius around the provided coordinates or the active OfficerServiceArea.
    """
    if current_user.role.lower() != "officer":
         raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only officers can access nearby reports."
         )
         
    return ReportService.get_nearby_reports(
        db=db,
        user_id=current_user.userId,
        latitude=latitude,
        longitude=longitude,
        skip=skip,
        limit=limit,
        radius_deg=radius_deg
    )

@router.get(
    "/dashboard/stats",
    summary="Get Officer Dashboard Stats from Ops DB"
)
def get_officer_dashboard_stats(
    db: Session = Depends(get_db_ops),
    current_user: User = Depends(get_current_user)
):
    """
    Get total count of reports per status from the stable Operations Database.
    Avoids hitting the Analytics DB which might be offline.
    """
    if current_user.role.lower() != "officer":
         raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden"
         )
         
    from sqlalchemy import func
    from app.models.report import Report
    
    status_counts = db.query(
        Report.status,
        func.count(Report.reportId)
    ).group_by(Report.status).all()
    
    counts_dict = {status: count for status, count in status_counts}
    
    # Ensure standard keys exist
    for k in ["Submitted", "InProgress", "Resolved"]:
        if k not in counts_dict:
            counts_dict[k] = 0
            
    return {"counts": counts_dict}

@router.get(
    "/location/name",
    summary="Reverse Geocoding without CORS limits"
)
@lru_cache(max_size=1000)
def _fetch_reverse_geocode(lat: float, lon: float):
    """Internal cached helper for Nominatim"""
    import urllib.request
    import json
    
    # Rounding coordinates slightly to increase cache hit rate for proximity
    lat_r = round(lat, 4)
    lon_r = round(lon, 4)
    
    url = f"https://nominatim.openstreetmap.org/reverse?format=json&lat={lat_r}&lon={lon_r}&zoom=14&addressdetails=1"
    req = urllib.request.Request(url, headers={'User-Agent': 'MoI_Reporting_Server/1.0'})
    
    try:
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode())
            address = data.get('address', {})
            city = address.get('city') or address.get('town') or address.get('municipality') or address.get('state') or ''
            suburb = address.get('suburb') or address.get('neighbourhood') or address.get('village') or ''
            
            parts = [p for p in [suburb, city] if p]
            if parts:
                return ", ".join(parts)
            else:
                return data.get('display_name', "Unknown Region")
    except Exception:
        return None

@router.get(
    "/location/name",
    summary="Reverse Geocoding without CORS limits"
)
def get_location_name(
    lat: float = Query(..., description="Latitude"),
    lon: float = Query(..., description="Longitude"),
    current_user: User = Depends(get_current_user)
):
    """
    Reverse geocodes using OpenStreetMap on the server side with LRU caching.
    """
    location_name = _fetch_reverse_geocode(lat, lon)
    if location_name:
        return {"name": location_name}
    return {"name": f"{lat:.4f}, {lon:.4f}"}

