#!/usr/bin/env bash
set -euo pipefail

DATE="${1:-$(date +%F)}"

echo "=== Trade Journal Day Report: $DATE ==="

# Trades section
echo
echo "[Trades]"
jq --arg d "$DATE" '
.trades
| map(select(.date == $d))
| if length == 0 then
"No trades"
else
.
end
' data/trades.json

# Metrics section
echo
echo "[Metrics]"
jq --arg d "$DATE" '
.trades
| map(select(.date == $d))
| {
count: length,
wins: (map(select((.pnl // 0) > 0)) | length),
losses: (map(select((.pnl // 0) < 0)) | length),
breakeven: (map(select((.pnl // 0) == 0)) | length),
net_pnl: (map(.pnl // 0) | add // 0)
}
' data/trades.json

# Journal section
echo
echo "[Journal]"
jq --arg d "$DATE" '
.entries
| map(select(.date == $d))
| if length == 0 then
"No journal entry"
else
.[0] | {
date,
mood,
summary,
lessonLearned,
nextTradeRule
}
end
' data/journal.json
