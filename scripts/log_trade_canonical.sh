#!/usr/bin/env bash
set -euo pipefail
cd /root/tradejournal-mvp

id="${1:-}"
date_in="${2:-}"
symbol="${3:-}"
side="${4:-}"
entry="${5:-}"
exitp="${6:-}"
pnl="${7:-}"
note="${8:-}"

if [ -z "$date_in" ] || [ -z "$symbol" ] || [ -z "$side" ] || [ -z "$entry" ] || [ -z "$exitp" ] || [ -z "$pnl" ]; then
echo 'Usage: scripts/log_trade_canonical.sh ID YYYY-MM-DD SYMBOL SIDE ENTRY EXIT PNL "optional note"'
echo 'ID can be AUTO'
exit 1
fi
# reject template placeholders
for v in "$date_in" "$symbol" "$side" "$entry" "$exitp" "$pnl"; do
case "$v" in
YYYY-MM-DD|SYMBOL|SIDE|ENTRY|EXIT|PNL|AUTO-ID)
echo "Use real values, not placeholders."
exit 1
;;
esac
done

# numeric validation
[[ "$entry" =~ ^-?[0-9]+([.][0-9]+)?$ ]] || { echo "ENTRY must be numeric"; exit 1; }
[[ "$exitp" =~ ^-?[0-9]+([.][0-9]+)?$ ]] || { echo "EXIT must be numeric"; exit 1; }
[[ "$pnl" =~ ^-?[0-9]+([.][0-9]+)?$ ]] || { echo "PNL must be numeric"; exit 1; }
if [ "$id" = "AUTO" ]; then
id="MAN-$(date +%s)"
fi

json="$(jq -nc \
--arg id "$id" \
--arg date "$date_in" \
--arg symbol "$symbol" \
--arg side "$side" \
--arg entry "$entry" \
--arg exit "$exitp" \
--arg pnl "$pnl" \
--arg note "${note:-}" \
'{id:$id,date:$date,symbol:$symbol,side:$side,entry:($entry|tonumber),exit:($exit|tonumber),pnl:($pnl|tonumber),notes:$note,setup:"Manual"}')"

node scripts/upsert-trade.js "$json"

git add data/trades.json
git commit -m "trade: upsert $id ($date_in $symbol)" || true
git push origin main
echo "✅ canonical trade upserted + pushed ($id)"
