#!/usr/bin/env bash
set -euo pipefail

TYPE="${1:-}"; shift || true
KEY="${1:-}"; shift || true

if [ -z "$TYPE" ] || [ -z "$KEY" ]; then
echo "Usage:"
echo " ./scripts/edit.sh trade <id> field=value ..."
echo " ./scripts/edit.sh journal <date> field=value ..."
exit 1
fi

case "$TYPE" in
trade)
# turns into log.sh trade id=<id> ...
./scripts/log.sh trade id="$KEY" "$@"
;;
journal)
# turns into log.sh journal date=<date> ...
./scripts/log.sh journal date="$KEY" "$@"
;;
*)
echo "Unknown type: $TYPE (use trade|journal)"
exit 1
;;
esac
