#!/usr/bin/env bash
set -euo pipefail

echo "==> Running Swift tests..."
swift test --parallel 2>&1

echo ""
echo "==> Tests complete."
