#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$ROOT/.tools/godot/Godot.app/Contents/MacOS/Godot"
OUTPUT="$ROOT/build/web/index.html"

if [[ ! -x "$GODOT" ]]; then
	echo "Godot editor not found at $GODOT"
	echo "Download Godot 4.7 from https://godotengine.org/download and place it in .tools/godot/"
	exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

"$GODOT" --headless --path "$ROOT" --export-release "Web" "$OUTPUT"
echo "Web build exported to build/web/"
