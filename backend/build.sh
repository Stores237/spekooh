#!/usr/bin/env bash
# Render build step for the spekooh-staging service — see
# ../RENDER_STAGING.md for the full deployment guide.
set -o errexit

# Real live failure (2026-09-07): apps.papers.ocr (pytesseract + pdf2image)
# needs the actual `tesseract` and `pdftoppm`/`pdftocairo` (Poppler)
# binaries on PATH — neither is a Python package, so `pip install` below
# never installed them, and every OCR attempt on staging failed outright
# ("tesseract is not installed or it's not in your PATH"). This had been
# true since OCR was first added; it only surfaced once OCR became
# automatic (process_pending_ocr) and someone actually checked why AI
# summary/chat never generated anything. Render's native build
# environment grants the build user passwordless sudo for exactly this.
sudo apt-get update && sudo apt-get install -y tesseract-ocr poppler-utils

pip install -r requirements.txt
python manage.py collectstatic --no-input
python manage.py migrate
python manage.py ensure_superuser
