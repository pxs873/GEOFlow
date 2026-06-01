#!/usr/bin/env bash
set -euo pipefail

cd /opt/geoflow

echo "[1/5] Removing stale admin.analytics links from admin header..."
sudo -n sed -i "/admin\\.analytics/d" resources/views/admin/partials/header.blade.php
grep -n admin.analytics resources/views/admin/partials/header.blade.php || true

echo "[2/5] Rebuilding app image..."
sudo -n docker compose --env-file .env.prod -f docker-compose.prod.yml build app

echo "[3/5] Recreating PHP and web services..."
sudo -n docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --force-recreate app web queue scheduler reverb

echo "[4/5] Clearing and warming caches..."
sudo -n docker compose --env-file .env.prod -f docker-compose.prod.yml exec -T app php artisan optimize:clear
sudo -n docker compose --env-file .env.prod -f docker-compose.prod.yml exec -T app php artisan view:cache

echo "[5/5] Verifying container source..."
sudo -n docker compose --env-file .env.prod -f docker-compose.prod.yml exec -T app grep -n admin.analytics resources/views/admin/partials/header.blade.php || true

echo "DONE"
