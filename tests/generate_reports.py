import requests
import random
import string
import time
import os

# Configuration
BASE_URL = "https://moi-reporting-app-f2hwfsdaddexgcak.germanywestcentral-01.azurewebsites.net"  # Change if deploying to Azure
API_VERSION = "v1"
REPORT_ENDPOINT = f"{BASE_URL}/api/{API_VERSION}/reports/"

# --- CHANGE THIS TO YOUR IMAGE PATH ---
# Ensure this file actually exists on your machine before running!
IMAGE_PATH = r"E:\Training\DEPI Learning\MoI\MoI-Reporting-System\tests\unnamed (1).jpg" 
# --------------------------------------

# Mock Data Arrays for Realism
TITLES = [
    "Pothole on Main St", "Broken Streetlight", "Illegal Parking", "Graffiti on Wall",
    "Water Leak", "Suspicious Activity", "Traffic Light Malfunction", "Garbage Pileup",
    "Noise Complaint", "Vandalism in Park", "Collapsed Sidewalk", "Fallen Tree Blocking Road",
    "Exposed Wiring on Pole", "Flooded Underpass", "Abandoned Vehicle", "Stray Dogs Pack",
    "Chemical Smell", "Illegal Dumping Site", "Manhole Cover Missing", "Broken Park Bench",
    "Signal Crossing Failure", "Bridge Railing Damaged", "Blocked Storm Drain", "Fire Hydrant Leaking",
    "Unsafe Construction Site", "Public Light Flickering", "Dead Animal on Road", "Playground Equipment Broken",
    "Overgrown Vegetation Blocking Sign", "Smoke from Unknown Source"
]

DESCRIPTIONS = [
    "A large pothole is causing traffic slowdowns.",
    "Streetlight has been out for three days.",
    "Car blocking the fire hydrant access.",
    "Spray paint on the community center wall.",
    "Water is gushing from a pipe near the sidewalk.",
    "Saw someone looking into car windows at night.",
    "Red light is stuck on for 5 minutes.",
    "Trash has not been collected this week.",
    "Loud music playing after 11 PM.",
    "Benches in the park have been broken.",
    "Sidewalk has collapsed creating a dangerous hole.", 
    "Large tree branch fell blocking the right lane.",
    "Electrical wires are hanging low from the pole.",
    "Underpass is flooded with water, impossible to pass.",
    "Old rusted car left on the side of the road for weeks.",
    "Aggressive stray dogs chasing pedestrians.",
    "Strong chemical odor coming from the sewer.",
    "Large pile of construction debris dumped illegally.",
    "Open manhole in the middle of the street!",
    "Wooden slats on the bench are rotted and broken.",
    "Pedestrian crossing signal is not working.",
    "Guard rail on the bridge is rusted and detached.",
    "Storm drain is clogged causing street flooding.",
    "Fire hydrant is leaking water onto the street.",
    "Construction barrier fell over into the walkway.",
    "Street lamp is flickering constantly.",
    "Roadkill needs removal from the highway.",
    "Swing set chain is broken at the playground.",
    "Stop sign is completely hidden by bushes.",
    "Thick black smoke rising from behind the building."
]

CATEGORIES = [
    "infrastructure", "utilities", "traffic", "public_nuisance", 
    "environmental", "crime", "other"
]

def generate_random_coordinate():
    # Roughly around Cairo/Giza coordinates for realism
    lat = 30.0 + random.uniform(-0.1, 0.1)
    lng = 31.2 + random.uniform(-0.1, 0.1)
    lng = 31.2 + random.uniform(-0.1, 0.1)
    return f"{lat:.6f}, {lng:.6f}"

def generate_random_date_2025():
    """Generates a random timestamp in the year 2025"""
    start_timestamp = time.mktime(time.strptime("2025-01-01 00:00:00", "%Y-%m-%d %H:%M:%S"))
    end_timestamp = time.mktime(time.strptime("2025-12-31 23:59:59", "%Y-%m-%d %H:%M:%S"))
    
    random_time = start_timestamp + random.random() * (end_timestamp - start_timestamp)
    # Convert to ISO 8601 format string
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(random_time))

def get_auth_token(email, password="0123456789"):
    """
    Logs in to get a token for the user. 
    Assumes the user is already registered.
    """
    login_url = f"{BASE_URL}/api/{API_VERSION}/auth/login"
    payload = {
        "username": email,
        "password": password
    }
    try:
        response = requests.post(login_url, data=payload)
        response.raise_for_status()
        return response.json()["access_token"]
    except requests.exceptions.RequestException as e:
        print(f"❌ Login Failed: {e}")
        return None

def create_reports(user_email, count=50):
    if not os.path.exists(IMAGE_PATH):
        print(f"❌ Error: Image file '{IMAGE_PATH}' not found!")
        print("Please put a .jpg file in this directory or update IMAGE_PATH.")
        return

    print(f"🚀 Starting generation of {count} reports for user: {user_email}")
    print(f"📸 Using evidence image: {IMAGE_PATH}")
    
    # 1. Login to get token (Authorization)
    token = get_auth_token(user_email)
    if not token:
        print("⚠️ Aborting: Could not authenticate user.")
        return

    headers = {
        "Authorization": f"Bearer {token}"
    }

    success_count = 0
    
    # 3. Loop to create reports
    for i in range(count):
        title = random.choice(TITLES) + f" #{i+1}"
        desc = random.choice(DESCRIPTIONS)
        category = random.choice(CATEGORIES)
        category = random.choice(CATEGORIES)
        location = generate_random_coordinate()
        created_at = generate_random_date_2025()
        
        print(f"[{i+1}/{count}] Creating: {title} ({category}) Date: {created_at} ...")

        data = {
            "title": title,
            "user_id":"user-d8671e9e-d71f-43c6-8a36-fdfc54233a1b",
            "descriptionText": desc,
            "categoryId": category,
            "location": location,
            "createdAt": created_at
        }

        # ⚡ FIX: Open the file FRESH for every request
        try:
            with open(IMAGE_PATH, 'rb') as img_file:
                # Prepare Multipart Form Data
                files = [
                    ('files', (f'evidence_{i}.jpg', img_file, 'image/jpeg'))
                ]
                
                response = requests.post(REPORT_ENDPOINT, headers=headers, data=data, files=files)

                if response.status_code == 201:
                    print(f"   ✅ Success! ID: {response.json().get('reportId')}")
                    success_count += 1
                else:
                    print(f"   ❌ Failed: {response.status_code} - {response.text}")
        
        except Exception as e:
            print(f"   ❌ Error processing request: {e}")
        
        # Small delay to be nice to the server/rate limits
        time.sleep(0.1)

    print(f"\n🎉 Finished! Created {success_count}/{count} reports.")

if __name__ == "__main__":
    # --- CONFIGURATION ---
    # Change this email to the user you want to assign reports to
    TARGET_USER_EMAIL = "ahmedya618@gmail.com" 
    
    create_reports(TARGET_USER_EMAIL, count=50)