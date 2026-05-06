#!/bin/bash
# tts_technical.sh — Convert technical.md files to speech using macOS `say`
#
# Usage:
#   ./tools/tts_technical.sh <map_name> [speed] [voice]
#
# Examples:
#   ./tools/tts_technical.sh Forces_1              # 1x speed, Samantha
#   ./tools/tts_technical.sh Forces_1 1.5          # 1.5x speed
#   ./tools/tts_technical.sh Forces_1 2 Daniel     # 2x speed, Daniel (British)
#   ./tools/tts_technical.sh all 1.5               # all technicals at 1.5x
#
# Speed multiplier: 1 = ~175 wpm, 1.5 = ~262 wpm, 2 = ~350 wpm
#
# Voices worth trying:
#   Samantha  (en_US) — clear, neutral, default
#   Daniel    (en_GB) — British, warm
#   Shelley   (en_US) — slightly lower
#   Reed      (en_US) — male

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MAPS_DIR="$REPO_DIR/commons/maps"
OUTPUT_DIR="/Users/pato/Documents/GitHub/ada_writer/audio"

MAP_NAME="${1:?Usage: tts_technical.sh <map_name|all> [speed] [voice]}"
SPEED="${2:-1}"
VOICE="${3:-Samantha}"

# Convert speed multiplier to words-per-minute (say uses -r for wpm)
BASE_WPM=175
WPM=$(echo "$SPEED * $BASE_WPM" | bc | cut -d. -f1)

mkdir -p "$OUTPUT_DIR"

strip_markdown() {
    # Remove markdown formatting, code blocks, and headers for clean speech
    sed -E \
        -e '/^```/,/^```/d' \
        -e 's/^#+ //' \
        -e 's/\*\*//g' \
        -e 's/\*//g' \
        -e 's/`[^`]*`//g' \
        -e 's/\[([^]]*)\]\([^)]*\)/\1/g' \
        -e '/^---$/d' \
        -e '/^$/d' \
        -e 's/^- //' \
        -e 's/^[0-9]+\. //' \
        "$1"
}

convert_one() {
    local map="$1"
    local src="$MAPS_DIR/$map/technical.md"

    if [ ! -f "$src" ]; then
        echo "  ⚠ No technical.md for $map — skipping"
        return
    fi

    local outfile="$OUTPUT_DIR/${map}_technical_${SPEED}x.aiff"
    local mp4file="$OUTPUT_DIR/${map}_technical_${SPEED}x.m4a"

    echo "  🔊 $map → ${SPEED}x (${WPM} wpm, voice: $VOICE)"

    # Strip markdown to temp file, then feed to say
    local tmpfile
    tmpfile=$(mktemp)
    strip_markdown "$src" > "$tmpfile"
    say -v "$VOICE" -r "$WPM" -o "$outfile" -f "$tmpfile"
    rm "$tmpfile"

    # Convert AIFF to M4A (AAC) for smaller file size
    if command -v afconvert &> /dev/null; then
        afconvert -f m4af -d aac "$outfile" "$mp4file" 2>/dev/null
        rm "$outfile"
        local size
        size=$(du -h "$mp4file" | cut -f1)
        echo "  ✓ $mp4file ($size)"
    else
        local size
        size=$(du -h "$outfile" | cut -f1)
        echo "  ✓ $outfile ($size)"
    fi
}

echo "━━━ Ada Technical TTS ━━━"
echo "Speed: ${SPEED}x (${WPM} wpm) · Voice: $VOICE"
echo ""

if [ "$MAP_NAME" = "all" ]; then
    for dir in "$MAPS_DIR"/*/; do
        map=$(basename "$dir")
        if [ -f "$dir/technical.md" ]; then
            convert_one "$map"
        fi
    done
else
    convert_one "$MAP_NAME"
fi

echo ""
echo "Done. Audio files in $OUTPUT_DIR/"
