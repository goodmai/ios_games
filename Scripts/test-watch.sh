#!/usr/bin/env bash
# Watches Sources/ and Tests/ and re-runs tests on any change.
# Requires: fswatch (brew install fswatch) or inotifywait (apt install inotify-tools)
set -euo pipefail

run_tests() {
    clear
    echo "==> [$(date +%H:%M:%S)] Running tests..."
    swift test --parallel 2>&1 || true
    echo ""
    echo "Watching for changes... (Ctrl+C to stop)"
}

run_tests

if command -v fswatch &>/dev/null; then
    fswatch -o Sources/ Tests/ | while read _; do run_tests; done
elif command -v inotifywait &>/dev/null; then
    while inotifywait -r -e modify,create,delete Sources/ Tests/ 2>/dev/null; do
        run_tests
    done
else
    echo "Install fswatch (macOS) or inotify-tools (Linux) for file watching."
    exit 1
fi
