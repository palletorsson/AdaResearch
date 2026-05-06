#!/bin/bash
# audit_qa_matrix.sh - Gather data for SUITE_QA_MATRIX regeneration
# Run from commons/audio directory

set -e
cd "$(dirname "$0")/.."

echo "=== Audio Suite QA Audit ==="
echo "Date: $(date +%Y-%m-%d)"
echo ""

echo "## 1) Songs Count"
SONG_COUNT=$(ls -1 parameters/songs/*.json 2>/dev/null | wc -l | tr -d ' ')
echo "Total songs in parameters/songs/: $SONG_COUNT"
echo ""

echo "## 2) Soundbanks"
echo "Soundbank directories with brief.json:"
for dir in soundbanks/*/; do
    if [ -f "${dir}brief.json" ]; then
        bank_name=$(basename "$dir")
        script_count=$(ls -1 "${dir}"*.gd 2>/dev/null | wc -l | tr -d ' ')
        echo "  - $bank_name: $script_count scripts"
    fi
done | sort
echo ""

BANK_COUNT=$(find soundbanks -name "brief.json" -type f | wc -l | tr -d ' ')
echo "Total soundbanks: $BANK_COUNT"
echo ""

echo "## 3) Soundbank Details"
for dir in soundbanks/*/; do
    if [ -f "${dir}brief.json" ]; then
        bank_name=$(basename "$dir")
        echo "=== $bank_name ==="
        echo "Scripts:"
        ls -1 "${dir}"*.gd 2>/dev/null | xargs -n1 basename | sed 's/.gd$//' | sort | tr '\n' ', ' | sed 's/,$/\n/'
        echo ""
    fi
done

echo "## 4) Songs List"
echo "All songs in parameters/songs/:"
ls -1 parameters/songs/*.json | xargs -n1 basename | sed 's/.json$//' | sort
echo ""

echo "## 5) SongPreviewDesktop Songs"
echo "Songs defined in SongPreviewDesktop.gd:"
grep -oE '\["[a-z_0-9]+", "[^"]+"\]' catalog/SongPreviewDesktop.gd 2>/dev/null | \
    sed 's/\["/  - /; s/", .*//' | sort -u || echo "  (parse error)"
echo ""

echo "## 6) GENRE_SUITES Check"
echo "Genres defined in GenreSynthBrowser.gd:"
grep -A1 'GENRE_SUITES = {' catalog/GenreSynthBrowser.gd 2>/dev/null | \
    grep -oE '"[a-z_]+"' | tr -d '"' | head -20 || echo "  (parse error)"
echo ""

echo "## 7) Quick Parity Check"
echo "Checking detroit_techno and synthwave soundbanks..."
echo ""
echo "detroit_techno sounds:"
if [ -f soundbanks/detroit_techno/brief.json ]; then
    grep -oE '"soundbank":\s*\[[^\]]+\]' soundbanks/detroit_techno/brief.json | \
        sed 's/"soundbank":\s*\[/  /; s/\]//' | tr ',' '\n' | tr -d '"' | sed 's/^/  /'
fi
echo ""
echo "synthwave sounds:"
if [ -f soundbanks/synthwave/brief.json ]; then
    grep -oE '"soundbank":\s*\[[^\]]+\]' soundbanks/synthwave/brief.json | \
        sed 's/"soundbank":\s*\[/  /; s/\]//' | tr ',' '\n' | tr -d '"' | sed 's/^/  /'
fi
echo ""

echo "=== Audit Complete ==="
echo ""
echo "To regenerate SUITE_QA_MATRIX:"
echo "1. Run this script to gather current data"
echo "2. Check SongDevTools.gd _generate_reference_mix() for route mappings"
echo "3. Check SuitToSoundbankMapper.gd ELEMENT_TO_SOUND for parity rules"
echo "4. Update documentation/SUITE_QA_MATRIX_YYYY-MM-DD.md"
