#!/usr/bin/env python3
"""
LOD Session Writer for Ada Research.

Records session discoveries as new LOD nodes that future sessions
can query. Appends to doc/LOD_DISCOVERIES.json.

Usage:
  python tools/lod_session_writer.py --topic "meander" --insight "tiles repeat, mosaics don't" --lod 3
  python tools/lod_session_writer.py --topic "facades" --insight "42 parts in 9 categories" --lod 2 --refs "commons/facade_parts/"
  python tools/lod_session_writer.py --list                  # show all discoveries
  python tools/lod_session_writer.py --search "meander"      # search discoveries
"""

import json
import sys
import argparse
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DISCOVERIES_PATH = ROOT / "doc" / "LOD_DISCOVERIES.json"


def load_discoveries():
    """Load existing discoveries or create empty structure."""
    if DISCOVERIES_PATH.is_file():
        try:
            with open(DISCOVERIES_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {"version": "1.0", "discoveries": []}


def save_discoveries(data):
    """Save discoveries to disk."""
    DISCOVERIES_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(DISCOVERIES_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def add_discovery(topic, insight, lod, refs=None, tags=None):
    """Add a new discovery entry."""
    data = load_discoveries()

    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "topic": topic,
        "insight": insight,
        "lod": lod,
    }
    if refs:
        entry["refs"] = refs.split(",") if isinstance(refs, str) else refs
    if tags:
        entry["tags"] = tags.split(",") if isinstance(tags, str) else tags

    data["discoveries"].append(entry)
    save_discoveries(data)

    print(f"Added discovery: [{topic}] {insight} (LOD {lod})")
    print(f"Total discoveries: {len(data['discoveries'])}")


def list_discoveries():
    """Print all discoveries."""
    data = load_discoveries()
    if not data["discoveries"]:
        print("No discoveries recorded yet.")
        return

    print(f"# Session Discoveries ({len(data['discoveries'])} total)\n")
    for i, d in enumerate(data["discoveries"], 1):
        ts = d.get("timestamp", "?")[:10]
        topic = d.get("topic", "?")
        insight = d.get("insight", "")
        lod = d.get("lod", "?")
        refs = d.get("refs", [])
        ref_str = f" refs: {', '.join(refs)}" if refs else ""
        print(f"{i}. [{ts}] **{topic}** (LOD {lod}): {insight}{ref_str}")


def search_discoveries(query):
    """Search discoveries by topic/insight."""
    data = load_discoveries()
    q = query.lower()
    matches = []
    for d in data["discoveries"]:
        text = f"{d.get('topic', '')} {d.get('insight', '')} {' '.join(d.get('tags', []))}"
        if q in text.lower():
            matches.append(d)

    if not matches:
        print(f"No discoveries matching \"{query}\".")
        return

    print(f"# Discoveries matching \"{query}\" ({len(matches)} found)\n")
    for d in matches:
        ts = d.get("timestamp", "?")[:10]
        topic = d.get("topic", "?")
        insight = d.get("insight", "")
        lod = d.get("lod", "?")
        print(f"- [{ts}] **{topic}** (LOD {lod}): {insight}")


def main():
    parser = argparse.ArgumentParser(
        description="Record and query session discoveries for Ada Research LOD system"
    )
    parser.add_argument("--topic", "-t", help="Discovery topic (e.g., 'meander', 'facades')")
    parser.add_argument("--insight", "-i", help="What was discovered")
    parser.add_argument("--lod", "-l", type=int, default=3, help="LOD level (0-4)")
    parser.add_argument("--refs", "-r", help="Comma-separated file/path references")
    parser.add_argument("--tags", help="Comma-separated tags")
    parser.add_argument("--list", action="store_true", help="List all discoveries")
    parser.add_argument("--search", "-s", help="Search discoveries")

    args = parser.parse_args()

    if args.list:
        list_discoveries()
    elif args.search:
        search_discoveries(args.search)
    elif args.topic and args.insight:
        add_discovery(args.topic, args.insight, args.lod, args.refs, args.tags)
    else:
        parser.print_help()
        print("\nExamples:")
        print('  python tools/lod_session_writer.py --topic "meander" --insight "tiles repeat, mosaics don\'t" --lod 3')
        print('  python tools/lod_session_writer.py --list')
        print('  python tools/lod_session_writer.py --search "meander"')


if __name__ == "__main__":
    main()
