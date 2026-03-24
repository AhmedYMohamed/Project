docker compose down 
docker build  -t moi-reporting-system:latest .

cd moi_reporting_app
flutter build web --release
cd ..