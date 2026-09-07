# Docker-based deploy (2026-09-07) — Render's native Python build
# environment blocks apt-get/OS-level package installs entirely
# (confirmed against Render's own community docs), so a plain build.sh
# could never install the real `tesseract`/`pdftoppm` binaries
# apps.papers.ocr needs — pytesseract and pdf2image are just thin Python
# wrappers around those CLI tools, not something pip alone can provide.
# Docker is Render's own documented path for exactly this situation.
# See RENDER_STAGING.md's own note on this for the full incident.
FROM python:3.13-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        tesseract-ocr \
        poppler-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# collectstatic/migrate/ensure_superuser run at container *start*, not
# during this image build — real settings (DATABASE_URL,
# DJANGO_SECRET_KEY, the AWS_*/REDIS_URL secrets, ...) only exist as
# Render dashboard env vars injected into the running container; `docker
# build` never sees them, so importing settings.py at build time would
# raise ImproperlyConfigured before collectstatic could even run. Same
# three steps build.sh used to run at build time on the old native
# runtime, just moved to when they can actually succeed — each one is
# already idempotent (migrate/collectstatic always are; ensure_superuser
# skips a user that already exists, per its own real log line: "already
# exists — skipping."). `exec` hands gunicorn PID 1 directly so it
# receives SIGTERM straight from Render on deploy/restart, rather than
# an intermediate shell swallowing it.
CMD ["sh", "-c", "python manage.py collectstatic --no-input && python manage.py migrate && python manage.py ensure_superuser && exec gunicorn config.wsgi:application --bind 0.0.0.0:$PORT --workers ${WEB_CONCURRENCY:-2}"]
