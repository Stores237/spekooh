#!/usr/bin/env bash
# Runs DEVICE_MATRIX.md's cells against Firebase Test Lab directly from a
# local machine -- the manual counterpart to
# .github/workflows/device-matrix.yml, for cell 6 (RAM tier) specifically,
# since that cell is picked by a real low-RAM model rather than an API
# level, and for ad-hoc runs without spending a workflow_dispatch.
#
# Prerequisites (see DEVICE_MATRIX.md's "How to actually get these
# devices" section for the full owner setup):
#   - gcloud CLI installed and authenticated (`gcloud auth login`) against
#     a real GCP project with the Firebase Test Lab API enabled.
#   - `gcloud config set project <your-firebase-project-id>` already run.
#   - A debug APK already built: from app/, run
#     `flutter build apk --debug --dart-define=API_BASE_URL=https://spekooh-staging.onrender.com/api`
#
# Usage: ./scripts/run_device_matrix.sh <cell>
#   cell: 1-5 (matches DEVICE_MATRIX.md's API-level cells, same mapping as
#         the GitHub Actions workflow) or "6-list" to print real low-RAM
#         physical models from the current catalog, since cell 6 needs a
#         real model id picked by hand, not a hardcoded guess.

set -euo pipefail

APK="build/app/outputs/flutter-apk/app-debug.apk"
if [ ! -f "$APK" ]; then
  echo "error: $APK not found -- build it first (see this script's own header comment)." >&2
  exit 1
fi

CELL="${1:-}"
if [ -z "$CELL" ]; then
  echo "usage: $0 <1|2|3|4|5|6-list>" >&2
  exit 1
fi

if [ "$CELL" = "6-list" ]; then
  # Real, currently-available physical models this run's authenticated
  # project can see -- pick one with 2GB RAM or less from this output by
  # hand rather than trusting any hardcoded model id here, since Test
  # Lab's real device catalog changes over time.
  echo "Real physical device catalog (pick a 2GB-RAM-or-less model by hand):"
  gcloud firebase test android models list --filter="form=PHYSICAL"
  exit 0
fi

# API level per cell, same mapping as .github/workflows/device-matrix.yml.
case "$CELL" in
  1) API=26 ;;
  2) API=30 ;;
  3) API=33 ;;
  4) API=34 ;;
  5) API=36 ;;
  *)
    echo "error: cell must be 1-5, or 6-list to browse real low-RAM models for cell 6." >&2
    exit 1
    ;;
esac

echo "Real device catalog for API $API (pick a model id from this output, then re-run with it):"
gcloud firebase test android models list --filter="supportedVersionIds=$API" 2>&1 | head -20

echo
echo "Once you've picked a real model id, run the actual test yourself:"
echo "  gcloud firebase test android run --type robo --app $APK --device model=<real-model-id>,version=$API --timeout 5m"
