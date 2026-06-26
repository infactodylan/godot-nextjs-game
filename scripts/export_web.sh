#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$ROOT/.tools/godot/Godot.app/Contents/MacOS/Godot"
BUILD_OUTPUT="$ROOT/build/web/index.html"
PUBLIC_GAME="$ROOT/web/public/game"

if [[ ! -x "$GODOT" ]]; then
	echo "Godot editor not found at $GODOT"
	echo "Download Godot 4.7 from https://godotengine.org/download and place it in .tools/godot/"
	exit 1
fi

mkdir -p "$(dirname "$BUILD_OUTPUT")"

"$GODOT" --headless --path "$ROOT" --export-release "Web" "$BUILD_OUTPUT"

mkdir -p "$PUBLIC_GAME"
rsync -a --delete --exclude='*.import' "$ROOT/build/web/" "$PUBLIC_GAME/"
echo "Web build exported to build/web/ and synced to web/public/game/"
