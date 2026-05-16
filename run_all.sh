#!/bin/bash
ROOT_DIR=$(pwd)
cd "$ROOT_DIR/mobile/apps/user_app" && flutter run -d web-server --web-port=8101 > /dev/null 2>&1 &
cd "$ROOT_DIR/mobile/apps/admin_app" && flutter run -d web-server --web-port=8102 > /dev/null 2>&1 &
cd "$ROOT_DIR/mobile/apps/guard_app" && flutter run -d web-server --web-port=8103 > /dev/null 2>&1 &
cd "$ROOT_DIR/mobile/apps/superadmin_app" && flutter run -d web-server --web-port=8104 > /dev/null 2>&1 &
cd "$ROOT_DIR/park_owner" && flutter run -d web-server --web-port=8105 > /dev/null 2>&1 &
echo "Started all 5 apps correctly"
