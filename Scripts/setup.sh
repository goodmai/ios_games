#!/usr/bin/env bash
set -euo pipefail

echo "==> GameTemplate setup"

# Check Swift version
SWIFT_VERSION=$(swift --version 2>&1 | head -1)
echo "Swift: $SWIFT_VERSION"

# Resolve dependencies
echo "==> Resolving Swift Package dependencies..."
swift package resolve

# Optional tools
if ! command -v swiftlint &>/dev/null; then
    echo "WARNING: SwiftLint not found. Install with: brew install swiftlint"
fi

echo ""
echo "Setup complete. Quick commands:"
echo "  swift test                   - run all tests"
echo "  bash Scripts/test.sh         - run tests (verbose)"
echo "  bash Scripts/lint.sh         - run linter"
echo "  bash Scripts/test-watch.sh   - watch mode"
