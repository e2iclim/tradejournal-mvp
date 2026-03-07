#!/usr/bin/env bash
set -euo pipefail

# Optional anchor date (YYYY-MM-DD). Defaults to today.
ANCHOR="${1:-$(date +%F)}"

echo "=== Trade Journal Week Report (ending $ANCHOR) ==="

# Compute 7-day window start (portable enough for GNU date on Linux)
START="$(date -d "$ANCHOR -6 days" +%F)"

echo "Window: $START -> $ANCHOR"
echo

echo "[Weekly Metrics]"
jq --arg s "$START" --arg e "$ANCHOR" '
.trades
| map(select(.date >= $s and .date <= $e))
| {
count: length,
wins: (map(select((.pnl // 0) > 0)) | length),
losses: (map(select((.pnl // 0) < 0)) | length),
breakeven: (map(select((.pnl // 0) == 0)) | length),
net_pnl: (map(.pnl // 0) | add // 0),
avg_pnl: (if length==0 then 0 else ((map(.pnl // 0) | add) / length) end),
win_rate: (if length==0 then 0 else ((map(select((.pnl // 0) > 0)) | length) / length * 100) end)
}
' data/trades.json

echo
echo "[P&L by Day]"
jq --arg s "$START" --arg e "$ANCHOR" '
.trades
| map(select(.date >= $s and .date <= $e))
| group_by(.date)
| map({
date: .[0].date,
trades: length,
net_pnl: (map(.pnl // 0) | add // 0)
})
| sort_by(.date)
' data/trades.json

echo
echo "[Top Symbols]"
jq --arg s "$START" --arg e "$ANCHOR" '
.trades
| map(select(.date >= $s and .date <= $e))
| group_by(.symbol)
| map({
symbol: .[0].symbol,
trades: length,
net_pnl: (map(.pnl // 0) | add // 0)
})
| sort_by(.net_pnl)
| reverse
' data/trades.json
