#!/usr/bin/env python3
"""Auto-generate project heat map from multiple signals."""

import json, os, subprocess, re, sys
from datetime import datetime, timedelta

sys.stdout.reconfigure(encoding='utf-8')

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENCY = os.path.join(os.path.dirname(REPO), "ada_encyclopedia")

def get_heat():
    heat = []

    # 1. GDScript compile errors (100°)
    # Check for known broken files from recent session

    # 2. Blocked items from FOCUS_VECTOR (90°)
    fv_path = os.path.join(REPO, "doc", "FOCUS_VECTOR.json")
    if os.path.exists(fv_path):
        with open(fv_path, encoding='utf-8') as f:
            fv = json.load(f)
        for b in fv.get("current_focus", {}).get("blocked", []):
            heat.append({"item": b[:80], "temperature": 90, "reason": "blocked", "action": "unblock"})

    # 3. Recent git activity (80°)
    try:
        result = subprocess.run(
            ["git", "-C", REPO, "log", "--oneline", "-20", "--format=%s"],
            capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=10
        )
        topics = {}
        keywords = ['meander', 'facade', 'mosaic', 'pattern', 'floor', 'museum',
                     'presentation', 'LOD', 'primitive', 'command', 'oversight',
                     'blog', 'encyclopedia', 'capture', 'shader']
        for line in result.stdout.strip().split('\n'):
            for kw in keywords:
                if kw.lower() in line.lower():
                    topics[kw.lower()] = topics.get(kw.lower(), 0) + 1

        for topic, count in sorted(topics.items(), key=lambda x: -x[1]):
            heat.append({
                "item": topic,
                "temperature": min(80, 60 + count * 5),
                "reason": f"active ({count} recent commits)",
                "action": "continue"
            })
    except:
        pass

    # 4. Empty sequences (50°)
    seq_dir = os.path.join(REPO, "commons", "maps", "sequences")
    if os.path.exists(seq_dir):
        for f in os.listdir(seq_dir):
            if not f.endswith('.json'): continue
            try:
                with open(os.path.join(seq_dir, f), encoding='utf-8') as fh:
                    d = json.load(fh)
                for sid, seq in d.get('sequences', {}).items():
                    maps = seq.get('maps', [])
                    if len(maps) == 0:
                        heat.append({
                            "item": f"sequence:{sid}",
                            "temperature": 50,
                            "reason": f"empty sequence ({seq.get('name', sid)[:40]})",
                            "action": "create maps"
                        })
            except:
                continue

    # 5. Maps without captures (40°)
    maps_dir = os.path.join(REPO, "commons", "maps")
    verify_dir = os.path.join(ENCY, "public", "blog", "2026-03-25-all-maps-verify") if os.path.exists(ENCY) else ""
    if os.path.exists(maps_dir) and verify_dir:
        for d in os.listdir(maps_dir):
            fp = os.path.join(maps_dir, d, "floor_plan.json")
            if not os.path.exists(fp): continue
            capture = os.path.join(verify_dir, f"{d}.png")
            if not os.path.exists(capture):
                heat.append({
                    "item": f"map:{d}",
                    "temperature": 40,
                    "reason": "no verification capture",
                    "action": "capture screenshot"
                })

    # 6. Recent discoveries to follow up (60°)
    disc_path = os.path.join(REPO, "doc", "LOD_DISCOVERIES.json")
    if os.path.exists(disc_path):
        with open(disc_path, encoding='utf-8') as f:
            discoveries = json.load(f)
        recent = [d for d in discoveries.get("discoveries", [])
                  if d.get("lod", 0) >= 3
                  and d.get("status") != "resolved"]  # deep discoveries, not yet resolved
        for disc in recent[-3:]:  # last 3 unresolved deep discoveries
            heat.append({
                "item": disc.get("topic", "unknown")[:60],
                "temperature": 60,
                "reason": f"deep discovery: {disc.get('insight', '')[:40]}",
                "action": "follow up"
            })

    # Sort and deduplicate
    heat.sort(key=lambda x: -x["temperature"])
    seen = set()
    unique = []
    for h in heat:
        key = h["item"].lower()
        if key not in seen:
            seen.add(key)
            unique.append(h)

    return unique[:30]

if __name__ == "__main__":
    heat = get_heat()

    output = {
        "generated": datetime.now().isoformat(),
        "description": "Auto-generated heat map from project signals",
        "items": heat
    }

    out_path = os.path.join(REPO, "doc", "HEAT_MAP.json")
    with open(out_path, "w", encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    print("=== HEAT MAP ===")
    for h in heat[:15]:
        print(f"  {h['temperature']:3d}  {h['item'][:50]:50s}  [{h['reason'][:30]}]")
    print(f"\nTotal: {len(heat)} items. Saved to {out_path}")
