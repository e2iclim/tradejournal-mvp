#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"; shift || true
if [ -z "$MODE" ]; then
echo "Usage: ./scripts/log.sh trade|journal key=value ..."
exit 1
fi

JSON="$(printf '%s\n' "$@" | jq -Rn '
[inputs | select(length>0)] as $arr
| reduce $arr[] as $kv ({};
if ($kv | contains("=")) then
($kv | index("=")) as $i
| if $i == null then . else
($kv[0:$i]) as $k
| ($kv[$i+1:]) as $v
| . + { ($k):
(if ($v|test("^-?[0-9]+(\\.[0-9]+)?$")) then ($v|tonumber) else $v end)
}
end
else . end
)
')"

case "$MODE" in
trade) node scripts/upsert-trade.js "$JSON" ;;
journal) node scripts/upsert-journal.js "$JSON" ;;
*) echo "Unknown mode: $MODE"; exit 1 ;;
esac
