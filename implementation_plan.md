# Goal Description

Update the officer dashboard and citizen apps to include new requirements: tighter location fetching, external map integration for officers, an embedded media player for viewing evidence, restricted file uploads (photos/videos only), and switching the authentication mechanism to use a hashed National ID instead of an email address.

## User Review Required

> [!WARNING]
> **Authentication Breaking Change**: Changing the authentication mechanism from Email to National ID will require modifying the database schema. If there are existing users, their rows might need backfilling or migration. 

> [!IMPORTANT]
> **Deterministic Hashing for National ID**: To allow users to login, we must be able to look up their National ID. As confirmed, we will use a deterministic hash (`SHA-256`) for the National ID. This ensures the raw ID is not stored in plaintext, but still allows us to directly query `WHERE hashedNationalId = hash(input)`.

## Proposed Changes

---

### Backend Components

#### [MODIFY] [user.py](file:///e:/Project/app/models/user.py)
- Add `hashedNationalId` (String, unique=True) column.
- Keep the `email` column as is.

#### [MODIFY] [user_schema.py](file:///e:/Project/app/schemas/user.py)
- Add `nationalId: str` to `UserCreate` and `UserLogin`. 
- Ensure `email` remains in the schemas.

#### [MODIFY] [user_service.py](file:///e:/Project/app/services/user_service.py)
- Update `create_user()`:
  - Hash the incoming `nationalId` using `hashlib.sha256`.
  - Check if `hashedNationalId` already exists. If so, return a 400 error.
  - Save both `email` and `hashedNationalId`.
- Update `authenticate()`:
  - Hash the incoming login identifier (now National ID).
  - Query by `hashedNationalId` instead of `email`.

#### [MODIFY] [auth.py](file:///e:/Project/app/api/v1/auth.py)
- Update login logic to treat the `username` field as the `nationalId`.

---

### Frontend (Flutter) - Authentication

#### [MODIFY] [register_screen.dart](file:///e:/Project/moi_reporting_app/lib/screens/register_screen.dart)
- Add a new `National ID Number` text field (numeric keyboard).
- Keep the `Email` field.
- Show an alert message if the National ID is already registered.

#### [MODIFY] [login_screen.dart](file:///e:/Project/moi_reporting_app/lib/screens/login_screen.dart)
- Change the `Email` label/hint to `National ID Number`.

#### [MODIFY] [auth_provider.dart](file:///e:/Project/moi_reporting_app/lib/providers/auth_provider.dart)
- Update `register` and `login` methods to include `nationalId`.

---

### Frontend (Flutter) - Shared

#### [CREATE/MODIFY] [location_service.dart](file:///e:/Project/moi_reporting_app/lib/services/location_service.dart)
- Create or update a common method for high-accuracy location fetching. 
- **High Accuracy Location**: Ensure `Geolocator.getCurrentPosition()` uses `desiredAccuracy: LocationAccuracy.best`.
- This common service will be used by both the Citizen App and the Officer side.

### Frontend (Flutter) - Citizen App

#### [MODIFY] [report_form.dart](file:///e:/Project/moi_reporting_app/lib/screens/report_form.dart)
- **High Accuracy Location**: Use the new common location service.
- **Restrict File Types**: Update the `FilePicker.platform.pickFiles()` parameters to restrict the user to images and videos only by setting `type: FileType.media`.

---

### Frontend (Flutter) - Officer Dashboard

#### [MODIFY] [officer_report_details_screen.dart](file:///e:/Project/moi_reporting_app/lib/screens/officer_report_details_screen.dart)
- **High Accuracy Location**: Use the same common location service as the citizen side for pinning the officer's current position more accurately.
- **Open on Maps**: Update the Map icon button (`Icons.map`) to launch an intent using `url_launcher`: `https://www.google.com/maps/search/?api=1&query=$lat,$lon`.
- **Evidence Media Player**: 
  - Instead of simply saying "Tap to view externally" with a download icon, integrate a media dialog or player inline.
  - If it's an image, use `Image.network(url)` in a dialog.
  - If it's a video, use the `video_player` package to show a playable widget when tapped.
- Ensure `pubspec.yaml` has `url_launcher` and `video_player` dependencies added.

## Open Questions
- Do you want the `video_player` to be shown seamlessly on the details screen, or do you prefer a pop-up dialog that appears when the user taps on the video attachment?
- When migrating the database schema, should we drop the `email` column entirely, or keep it as an optional field for recovery purposes? 

## Verification Plan
### Automated Tests
- N/A - we will mostly rely on manual functional testing.

### Manual Verification
- Attempt to register with a new National ID and check the DB to ensure it's hashed correctly.
- Register again with the same National ID to verify the already registered alert pops up.
- Pick files in the form and verify it only allows images and videos.
- Verify that finding the current location is quick and accurate.
- Login as Officer, click the "Map" button on the Report details to verify it externally launches to Google/Apple maps.
- Upload photo/video to a report, and open the evidence tab to verify the media player plays the video.
