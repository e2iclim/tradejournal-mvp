#!/usr/bin/env bash
set -euo pipefail

DRY=0
if [[ "${1:-}" == "--dry-run" ]]; then DRY=1; shift; fi
ID="${1:-}"
if [[ -z "$ID" ]]; then
  echo "Usage: ./scripts/delete-trade.sh [--dry-run] <trade_id>"
  exit 1
fi

FILE="data/trades.json"
if [[ ! -f "$FILE" ]]; then
  echo "Missing $FILE"
  exit 1
fi

MATCHES=$(jq --arg id "$ID" '[.trades[] | select(.id==$id)] | length' "$FILE")
if [[ "$MATCHES" -eq 0 ]]; then
  echo "No trade found for id=$ID"
  exit 1
fi

echo "Found $MATCHES trade(s) with id=$ID"
if [[ "$DRY" -eq 1 ]]; then
  jq --arg id "$ID" '.trades[] | select(.id==$id)' "$FILE"
  echo "DRY RUN: no changes written"
  exit 0
fi

cp "$FILE" "${FILE}.bak.delete.$(date +%Y%m%d-%H%M%S)"
jq --arg id "$ID" '.trades |= map(select(.id != $id))' "$FILE" > /tmp/trades.json && mv /tmp/trades.json "$FILE"
REMAIN=$(jq --arg id "$ID" '[.trades[] | select(.id==$id)] | length' "$FILE")
if [[ "$REMAIN" -ne 0 ]]; then
  echo "Delete failed: $REMAIN entries still present"
  exit 1
fi

echo "Deleted trade id=$ID"
