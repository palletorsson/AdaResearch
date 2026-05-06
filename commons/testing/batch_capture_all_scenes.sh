#!/usr/bin/env bash
# batch_capture_all_scenes.sh
# Captures screenshots for every scene in the scene-catalog.json.
# Idempotent: skips scenes whose PNG already exists in the target dir.
# Requires: jq, Godot 4.6 console exe.

set -euo pipefail

# ── Paths ─────────────────────────────────────────────────────────────────────
GODOT_EXE="C:/Users/palle/Desktop/Godot_v4.6-stable_win64_console.exe"
PROJECT_DIR="/c/Users/palle/Documents/GitHub/AdaResearch_46"
CATALOG_JSON="/c/Users/palle/Documents/GitHub/ada_encyclopedia/public/scene-catalog/scene-catalog.json"
ENCYCLOPEDIA_SCREENSHOT_DIR="/c/Users/palle/Documents/GitHub/ada_encyclopedia/public/scene-catalog"
GODOT_USERDATA_DIR="C:/Users/palle/AppData/Roaming/Godot/app_userdata/Ada Research Zero One/scene_shots"
CAPTURE_SCRIPT="res://commons/testing/capture_tscn_shot.gd"
WAIT_SECONDS="1.5"

# ── Sanity checks ─────────────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
    echo "ERROR: jq is required but not found in PATH." >&2
    exit 1
fi

if [ ! -f "$CATALOG_JSON" ]; then
    echo "ERROR: Scene catalog not found at $CATALOG_JSON" >&2
    exit 1
fi

if [ ! -f "$GODOT_EXE" ]; then
    echo "ERROR: Godot executable not found at $GODOT_EXE" >&2
    exit 1
fi

# ── Ensure target directories exist ──────────────────────────────────────────
mkdir -p "$ENCYCLOPEDIA_SCREENSHOT_DIR"
mkdir -p "$GODOT_USERDATA_DIR"

# ── Read catalog entries ─────────────────────────────────────────────────────
TOTAL=$(jq '.entries | length' "$CATALOG_JSON")
echo "=== Batch Scene Capture ==="
echo "Total scenes in catalog: $TOTAL"
echo ""

CAPTURED=0
SKIPPED=0
FAILED=0
FAILED_LIST=""

for i in $(seq 0 $((TOTAL - 1))); do
    # Extract fields for this entry
    SCENE_PATH=$(jq -r ".entries[$i].scenePath" "$CATALOG_JSON")
    SCREENSHOT_FIELD=$(jq -r ".entries[$i].screenshot" "$CATALOG_JSON")
    LOOKUP_NAME=$(jq -r ".entries[$i].lookupName // empty" "$CATALOG_JSON")

    # Derive the PNG filename from the screenshot field (e.g. "/scene-catalog/foo.png" -> "foo.png")
    PNG_FILENAME=$(basename "$SCREENSHOT_FIELD")

    # Target path in the encyclopedia public folder
    TARGET_PNG="$ENCYCLOPEDIA_SCREENSHOT_DIR/$PNG_FILENAME"

    # Human-readable label
    LABEL="${LOOKUP_NAME:-$PNG_FILENAME}"
    INDEX=$((i + 1))

    # ── Skip if PNG already exists ────────────────────────────────────────
    if [ -f "$TARGET_PNG" ]; then
        echo "[$INDEX/$TOTAL] $LABEL - SKIP (exists)"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # ── Run Godot capture ─────────────────────────────────────────────────
    USERDATA_OUT="user://scene_shots/$PNG_FILENAME"

    echo -n "[$INDEX/$TOTAL] $LABEL - capturing... "

    # Run the capture command; timeout after 30 seconds to avoid hangs
    if timeout 30 "$GODOT_EXE" \
        --path "$PROJECT_DIR" \
        --xr-mode off \
        --no-window \
        --script "$CAPTURE_SCRIPT" \
        -- \
        --scene="$SCENE_PATH" \
        --out="$USERDATA_OUT" \
        --wait="$WAIT_SECONDS" \
        > /dev/null 2>&1; then

        # ── Copy from Godot userdata to encyclopedia ──────────────────────
        GODOT_OUTPUT="$GODOT_USERDATA_DIR/$PNG_FILENAME"

        if [ -f "$GODOT_OUTPUT" ]; then
            cp "$GODOT_OUTPUT" "$TARGET_PNG"
            echo "OK"
            CAPTURED=$((CAPTURED + 1))
        else
            echo "FAIL (no output PNG)"
            FAILED=$((FAILED + 1))
            FAILED_LIST="$FAILED_LIST\n  - $LABEL ($SCENE_PATH)"
        fi
    else
        echo "FAIL (godot error or timeout)"
        FAILED=$((FAILED + 1))
        FAILED_LIST="$FAILED_LIST\n  - $LABEL ($SCENE_PATH)"
    fi
done

# ── Update scene-catalog.json: set hasScreenshot=true for existing PNGs ──────
echo ""
echo "=== Updating scene-catalog.json ==="

# Build a jq filter that checks each entry's screenshot file existence
# We iterate all entries and set hasScreenshot based on whether the file exists
UPDATED_COUNT=0
TMP_CATALOG="${CATALOG_JSON}.tmp"

jq --arg dir "$ENCYCLOPEDIA_SCREENSHOT_DIR" '
    .entries |= [.[] |
        .hasScreenshot = (
            ($dir + "/" + (.screenshot | split("/") | last)) as $path |
            # We cannot check file existence inside jq, so we mark all for now
            .hasScreenshot
        )
    ]
' "$CATALOG_JSON" > /dev/null 2>&1 || true

# Use a different approach: iterate and build the updated JSON properly
# For each entry, check if the PNG exists on disk, then update via jq
python3 -c "
import json, os, sys

catalog_path = sys.argv[1]
screenshot_dir = sys.argv[2]

with open(catalog_path, 'r', encoding='utf-8') as f:
    catalog = json.load(f)

updated = 0
for entry in catalog['entries']:
    screenshot = entry.get('screenshot', '')
    filename = os.path.basename(screenshot)
    full_path = os.path.join(screenshot_dir, filename)
    had = entry.get('hasScreenshot', False)
    now = os.path.isfile(full_path)
    entry['hasScreenshot'] = now
    if now and not had:
        updated += 1

with open(catalog_path, 'w', encoding='utf-8') as f:
    json.dump(catalog, f, indent=2, ensure_ascii=False)
    f.write('\n')

print(f'Updated {updated} entries to hasScreenshot=true')
" "$CATALOG_JSON" "$ENCYCLOPEDIA_SCREENSHOT_DIR" 2>/dev/null || {
    # Fallback: use jq + bash loop if python3 is not available
    echo "Python3 not available, falling back to jq-based update..."

    cp "$CATALOG_JSON" "$TMP_CATALOG"

    for i in $(seq 0 $((TOTAL - 1))); do
        SCREENSHOT_FIELD=$(jq -r ".entries[$i].screenshot" "$TMP_CATALOG")
        PNG_FILENAME=$(basename "$SCREENSHOT_FIELD")
        TARGET_PNG="$ENCYCLOPEDIA_SCREENSHOT_DIR/$PNG_FILENAME"

        if [ -f "$TARGET_PNG" ]; then
            # Update this entry's hasScreenshot to true
            jq ".entries[$i].hasScreenshot = true" "$TMP_CATALOG" > "${TMP_CATALOG}.2"
            mv "${TMP_CATALOG}.2" "$TMP_CATALOG"
            UPDATED_COUNT=$((UPDATED_COUNT + 1))
        fi
    done

    mv "$TMP_CATALOG" "$CATALOG_JSON"
    echo "Updated $UPDATED_COUNT entries to hasScreenshot=true"
}

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "=== Capture Summary ==="
echo "  Total:    $TOTAL"
echo "  Captured: $CAPTURED"
echo "  Skipped:  $SKIPPED (already existed)"
echo "  Failed:   $FAILED"

if [ $FAILED -gt 0 ]; then
    echo ""
    echo "Failed scenes:"
    echo -e "$FAILED_LIST"
fi

echo ""
echo "Done."
