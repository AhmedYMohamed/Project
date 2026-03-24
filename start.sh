#!/bin/bash

# Start backend services
echo "Starting backend services..."
docker compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 10


# Start Flutter web app
echo "Starting Flutter web app..."
cd moi_reporting_app
flutter run -d web-server --web-port=8080 --release 
