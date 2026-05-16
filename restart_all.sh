#!/bin/bash
cd "/Users/pranavkoradiya/Desktop/Parking Managment Sanket Sir/Parkingapp"

echo "Starting Backend..."
source backend/.venv/bin/activate
nohup python backend/manage.py runserver 8000 > backend.log 2>&1 &

echo "Starting Flutter Apps..."

cd "mobile/apps/super_admin_app"
nohup flutter run -d web-server --web-port=8101 > app.log 2>&1 &
cd ../../../

cd "mobile/apps/admin_app"
nohup flutter run -d web-server --web-port=8102 > app.log 2>&1 &
cd ../../../

cd "mobile/apps/guard_app"
nohup flutter run -d web-server --web-port=8103 > app.log 2>&1 &
cd ../../../

cd "mobile/apps/user_app"
nohup flutter run -d web-server --web-port=8104 > app.log 2>&1 &
cd ../../../

cd "park_owner"
nohup flutter run -d web-server --web-port=8105 > app.log 2>&1 &
cd ../

echo "All services restarted!"
