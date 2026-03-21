#!/bin/bash
# Mind-Mem Auto-Capture Hook — runs on Claude Code SessionStart (compact event)
# Captures signals from the session and auto-applies high-confidence decisions.

WORKSPACE="${MIND_MEM_WORKSPACE:-$HOME/.mind-mem/workspace}"
PYTHON="${MIND_MEM_PYTHON:-python3}"

# Skip if no workspace
if [ ! -d "$WORKSPACE" ]; then
  exit 0
fi

# Run the capture engine to extract signals from any daily logs
$PYTHON -c "
import sys, os
sys.path.insert(0, os.path.expanduser('~/mind-mem/src'))
os.environ['MIND_MEM_WORKSPACE'] = '$WORKSPACE'

try:
    from mind_mem.capture import run_capture
    from mind_mem.sqlite_index import build_index

    # Run capture to extract signals from memory logs
    run_capture('$WORKSPACE')

    # Rebuild index so new signals are searchable
    build_index('$WORKSPACE')
except Exception:
    pass  # Silent fail
" 2>/dev/null

exit 0
