#!/bin/bash
set -e

cd "/Users/pranavkoradiya/Desktop/Parking Managment Sanket Sir/Parkingapp"

stop_port() {
	local port="$1"
	local pids
	pids=$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)
	if [ -n "$pids" ]; then
		kill $pids 2>/dev/null || true
	fi
}

start_flutter_web_app() {
	local app_dir="$1"
	local port="$2"

	cd "$app_dir"
	flutter build web --profile --pwa-strategy=none > app.log 2>&1
	nohup python3 - "$port" build/web <<'PY' > app.log 2>&1 &
import functools
import http.server
import socketserver
import sys
from pathlib import Path

port = int(sys.argv[1])
web_root = Path(sys.argv[2]).resolve()


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()


handler = functools.partial(NoCacheHandler, directory=str(web_root))
with socketserver.TCPServer(('', port), handler) as server:
    server.serve_forever()
PY
	cd "$OLDPWD"
}

echo "Stopping existing services..."
stop_port 8000
stop_port 8101
stop_port 8102
stop_port 8103
stop_port 8104
stop_port 8105

echo "Starting Backend..."
source backend/.venv/bin/activate
nohup python backend/manage.py runserver 8000 > backend.log 2>&1 &

echo "Starting Flutter Apps..."
start_flutter_web_app "mobile/apps/user_app" 8101
start_flutter_web_app "mobile/apps/admin_app" 8102
start_flutter_web_app "mobile/apps/guard_app" 8103
start_flutter_web_app "mobile/apps/super_admin_app" 8104
start_flutter_web_app "park_owner" 8105

echo "All services restarted!"
