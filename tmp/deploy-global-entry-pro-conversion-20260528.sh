#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVER="ubuntu@43.161.240.101"
APP_DIR="/opt/geoflow"

FILES=(
  "app/Http/Controllers/Site/ContactController.php"
  "routes/web.php"
  "resources/views/site/contact.blade.php"
  "resources/views/theme/global-entry-pro-20260509/home.blade.php"
  "resources/views/theme/global-entry-pro-20260509/article.blade.php"
  "resources/views/theme/global-entry-pro-20260509/contact.blade.php"
  "resources/views/theme/global-entry-pro-20260509/partials/header.blade.php"
  "resources/views/theme/global-entry-pro-20260509/partials/footer.blade.php"
  "resources/views/theme/global-entry-pro-20260509/partials/sidebar.blade.php"
  "resources/views/theme/global-entry-pro-20260509/assets/theme.css"
  "public/themes/global-entry-pro-20260509/theme.css"
)

echo "Deploying Global Entry Pro conversion update to ${SERVER}:${APP_DIR}"
echo "You may be prompted once for the server password."

tar -czf - -C "$ROOT" "${FILES[@]}" \
  | ssh -o StrictHostKeyChecking=no "$SERVER" "
      set -euo pipefail
      cd '$APP_DIR'
      tar -xzf - -C '$APP_DIR'
      docker compose --env-file .env.prod -f docker-compose.prod.yml build app web
      docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --force-recreate app web queue scheduler reverb
      docker compose --env-file .env.prod -f docker-compose.prod.yml exec -T app php artisan optimize:clear
      docker compose --env-file .env.prod -f docker-compose.prod.yml exec -T app php artisan view:cache
    "

echo
echo "Deployment finished."
echo "Check:"
echo "  https://globalentrypro.com/"
echo "  https://globalentrypro.com/contact"
