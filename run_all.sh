#!/bin/bash
set -e

ROOT_DIR=$(pwd)

start_flutter_web_app() {
	local app_dir="$1"
	local port="$2"

	cd "$ROOT_DIR/$app_dir"
	flutter build web --release --pwa-strategy=none > /dev/null 2>&1
	nohup python3 - "$port" build/web <<'PY' > /dev/null 2>&1 &
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
}

start_flutter_web_app "mobile/apps/user_app" 8101
start_flutter_web_app "mobile/apps/admin_app" 8102
start_flutter_web_app "mobile/apps/guard_app" 8103
start_flutter_web_app "mobile/apps/super_admin_app" 8104
start_flutter_web_app "park_owner" 8105

echo "Started all 5 apps correctly"
