#!/usr/bin/env bash
# Render build step for the spekooh-staging service — see
# ../RENDER_STAGING.md for the full deployment guide.
set -o errexit

pip install -r requirements.txt
python manage.py collectstatic --no-input
python manage.py migrate
