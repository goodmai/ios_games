#!/usr/bin/env bash
set -euo pipefail

if command -v swiftlint &>/dev/null; then
    echo "==> Running SwiftLint..."
    swiftlint lint --config .swiftlint.yml
    echo "==> Lint complete."
else
    echo "SwiftLint not found. Install with: brew install swiftlint"
    exit 1
fi
