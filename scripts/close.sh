#!/usr/bin/env bash
set -euo pipefail

ID="${1:-}"; shift || true
if [ -z "$ID" ]; then
echo "Usage: ./scripts/close.sh <trade_id> exit=<price> pnl=<amount> [notes='...']"
exit 1
fi

# defaults
EXIT=""
PNL=""
NOTES="closed via close.sh"

for kv in "$@"; do
case "$kv" in
exit=*) EXIT="${kv#exit=}" ;;
pnl=*) PNL="${kv#pnl=}" ;;
notes=*) NOTES="${kv#notes=}" ;;
esac
done

if [ -z "$EXIT" ] || [ -z "$PNL" ]; then
echo "Error: exit and pnl are required."
echo "Example: ./scripts/close.sh MAN-TEST-003 exit=18310 pnl=220 notes='tp hit'"
exit 1
fi

# Re-upsert trade as closed-like record (schema-compatible)
./scripts/log.sh trade id="$ID" exit="$EXIT" pnl="$PNL" status="CLOSED" notes="$NOTES"
echo "Closed trade $ID"
