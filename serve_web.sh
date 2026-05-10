#!/usr/bin/env bash
# Serve the exported Web build locally on http://localhost:8000
# Uses Python's built-in HTTP server. No SharedArrayBuffer/COOP-COEP needed
# because the export was built with variant/thread_support=false.

set -e
cd "$(dirname "$0")/export/web"

PORT="${1:-8000}"
echo "Serving Web build at http://localhost:$PORT"
echo "Press Ctrl+C to stop."
python3 -m http.server "$PORT"
