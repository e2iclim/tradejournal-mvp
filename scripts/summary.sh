#!/usr/bin/env bash
set -euo pipefail

ANCHOR="${1:-$(date +%F)}"
START="$(date -d "$ANCHOR -6 days" +%F)"

echo "========================================"
echo " Trading Journal Summary"
echo " Window: $START -> $ANCHOR"
echo "========================================"

# Weekly metrics
METRICS="$(jq -r --arg s "$START" --arg e "$ANCHOR" '
.trades
| map(select(.date >= $s and .date <= $e))
| {
count: length,
wins: (map(select((.pnl // 0) > 0)) | length),
losses: (map(select((.pnl // 0) < 0)) | length),
breakeven: (map(select((.pnl // 0) == 0)) | length),
net_pnl: (map(.pnl // 0) | add // 0),
win_rate: (if length==0 then 0 else ((map(select((.pnl // 0) > 0)) | length) / length * 100) end)
}
| "\(.count)|\(.wins)|\(.losses)|\(.breakeven)|\(.net_pnl)|\(.win_rate)"
' data/trades.json)"

IFS='|' read -r COUNT WINS LOSSES BE NET WINRATE <<< "$METRICS"

printf "Trades: %s | Wins: %s | Losses: %s | BE: %s\n" "$COUNT" "$WINS" "$LOSSES" "$BE"
printf "Net PnL: %s | Win Rate: %.2f%%\n" "$NET" "$WINRATE"

echo
echo "Best/Worst Day:"
jq -r --arg s "$START" --arg e "$ANCHOR" '
.trades
| map(select(.date >= $s and .date <= $e))
| group_by(.date)
| map({date: .[0].date, net: (map(.pnl // 0) | add // 0)})
| if length == 0 then "No trade days"
else
"Best: " + ((max_by(.net) | .date) + " (" + (max_by(.net) | .net|tostring) + ")")
+ "\nWorst: " + ((min_by(.net) | .date) + " (" + (min_by(.net) | .net|tostring) + ")")
end
' data/trades.json

echo
echo "Top Symbol:"
jq -r --arg s "$START" --arg e "$ANCHOR" '
.trades
| map(select(.date >= $s and .date <= $e))
| group_by(.symbol)
| map({symbol: .[0].symbol, net: (map(.pnl // 0) | add // 0), trades: length})
| if length == 0 then "No symbols"
else (max_by(.net) | "\(.symbol) | net=\(.net) | trades=\(.trades)")
end
' data/trades.json

echo
echo "Today Journal:"
jq -r --arg d "$ANCHOR" '
.entries
| map(select(.date == $d))
| if length == 0 then "No journal entry for " + $d
else .[0] | "Mood: \(.mood // "N/A")\nSummary: \(.summary // "N/A")\nNext Rule: \(.nextTradeRule // "N/A")"
end
' data/journal.json

echo "========================================"
