#!/usr/bin/env bash
set -euo pipefail

DRY=0
if [[ "${1:-}" == "--dry-run" ]]; then DRY=1; shift; fi
DATE="${1:-}"
if [[ -z "$DATE" ]]; then
  echo "Usage: ./scripts/delete-journal.sh [--dry-run] <YYYY-MM-DD>"
  exit 1
fi
if [[ ! "$DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "Invalid date format, expected YYYY-MM-DD"
  exit 1
fi

JFILE="data/journal.json"
TFILE="data/trades.json"
if [[ ! -f "$JFILE" ]]; then
  echo "Missing $JFILE"
  exit 1
fi
if [[ ! -f "$TFILE" ]]; then
  echo "Missing $TFILE"
  exit 1
fi

MATCHES=$(jq --arg d "$DATE" '[.entries[] | select(.date==$d)] | length' "$JFILE")
if [[ "$MATCHES" -eq 0 ]]; then
  echo "No journal entry found for date=$DATE"
  exit 1
fi

echo "Found $MATCHES journal entry(ies) for $DATE"
if [[ "$DRY" -eq 1 ]]; then
  jq --arg d "$DATE" '.entries[] | select(.date==$d)' "$JFILE"
  echo "DRY RUN: no changes written"
  exit 0
fi

cp "$JFILE" "${JFILE}.bak.delete.$(date +%Y%m%d-%H%M%S)"
cp "$TFILE" "${TFILE}.bak.delete.$(date +%Y%m%d-%H%M%S)"

jq --arg d "$DATE" '.entries |= map(select(.date != $d))' "$JFILE" > /tmp/journal.json && mv /tmp/journal.json "$JFILE"

if [[ -x scripts/sync-journal-to-trades.js ]]; then
  node scripts/sync-journal-to-trades.js
fi

REMAIN=$(jq --arg d "$DATE" '[.entries[] | select(.date==$d)] | length' "$JFILE")
if [[ "$REMAIN" -ne 0 ]]; then
  echo "Delete failed: $REMAIN entries still present"
  exit 1
fi

echo "Deleted journal date=$DATE"
