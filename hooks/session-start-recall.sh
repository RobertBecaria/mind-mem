#!/bin/bash
# Mind-Mem Auto-Recall Hook — runs on Claude Code SessionStart
# Recalls recent decisions relevant to the current working directory
# and injects them as context for the new session.

WORKSPACE="${MIND_MEM_WORKSPACE:-$HOME/.mind-mem/workspace}"
PYTHON="${MIND_MEM_PYTHON:-python3}"
INDEX_DB="$WORKSPACE/.mind-mem-index/fts.db"

# Skip if no workspace or index
if [ ! -d "$WORKSPACE" ] || [ ! -f "$INDEX_DB" ]; then
  exit 0
fi

# Detect project from current working directory
CWD="$(pwd)"
PROJECT_NAME=""

case "$CWD" in
  *ZION*|*zion*)    PROJECT_NAME="zion-city" ;;
  *household*|*crm*) PROJECT_NAME="household-crm" ;;
  *mind-mem*)       PROJECT_NAME="mind-mem" ;;
  *dios*)           PROJECT_NAME="zion-dios" ;;
esac

# Build recall query
if [ -n "$PROJECT_NAME" ]; then
  QUERY="$PROJECT_NAME recent decisions"
else
  QUERY="recent decisions and tasks"
fi

# Run recall via Python and output context
$PYTHON -c "
import sys, os, json
sys.path.insert(0, os.path.expanduser('~/mind-mem/src'))
os.environ['MIND_MEM_WORKSPACE'] = '$WORKSPACE'

try:
    from mind_mem.sqlite_index import search_fts
    results = search_fts('$WORKSPACE', '$QUERY', limit=5)
    if not results:
        sys.exit(0)

    print('# Mind-Mem Context (auto-recalled)')
    print('')
    for r in results[:5]:
        block_id = r.get('block_id', '?')
        tags = r.get('tags', '')
        excerpt = r.get('content', r.get('statement', ''))[:200]
        date = r.get('date', '')
        print(f'- [{block_id}] ({date}) {excerpt}')
        if tags:
            print(f'  Tags: {tags}')
    print('')
except Exception as e:
    # Silent fail — don't break session startup
    pass
" 2>/dev/null
