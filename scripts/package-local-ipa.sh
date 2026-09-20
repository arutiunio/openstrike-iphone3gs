#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
APP="$ROOT/vendor/pocketjs/dist/ipodtouch4/OpenStrike3GS.app"
OUT="$ROOT/OpenStrike3GS-local.ipa"
STAGE="$ROOT/.ipa-stage"

if [ "$#" -ge 1 ]; then APP="$1"; fi
if [ "$#" -ge 2 ]; then OUT="$2"; fi

if [ ! -d "$APP" ]; then
  echo "missing app bundle: $APP" >&2
  exit 1
fi

rm -rf "$STAGE"
mkdir -p "$STAGE/Payload"
cp -R "$APP" "$STAGE/Payload/"

(
  cd "$STAGE"
  /usr/bin/zip -qry "$OUT" Payload
)

rm -rf "$STAGE"
echo "created $OUT"
echo "NOTE: do not publish this IPA if the embedded PAK contains proprietary game assets."
