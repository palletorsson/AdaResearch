"""Record the live spine for private editorial notes; never rewrite a manuscript."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "commons/maps/curriculum_spine.json").exists())

def read_json(path):
    # Current source files can contain trailing commas. Do not alter quoted text.
    text = path.read_text(encoding="utf-8-sig")
    return json.loads(re.sub(r'("(?:\\.|[^"\\])*"\s*)|,\s*(?=[}\]])',
                             lambda m: m.group(1) or "", text))

def fingerprint(path):
    return {"path": path.relative_to(ROOT).as_posix(),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None}

def collect():
    spine_path = ROOT / "commons/maps/curriculum_spine.json"
    spine = sorted(read_json(spine_path)["spine"]["sequences"], key=lambda s: float(s["order"]))
    result = {"captured_at": datetime.now(timezone.utc).isoformat(),
              "basis": "Manuscript and authored placement inspection; not runtime verification",
              "spine": fingerprint(spine_path), "sequences": []}
    for seq in spine:
        path = ROOT / f"commons/maps/sequences/{seq['name']}.json"
        data = read_json(path)["sequences"][seq["name"]]
        entry = {"id": seq["name"], "name": data.get("name", seq["name"]),
                 "source": fingerprint(path), "halls": []}
        for name in data["maps"]:
            folder = ROOT / "commons/maps" / name
            final = folder / "final.md"
            manuscript = final.read_text(encoding="utf-8-sig") if final.exists() else ""
            map_path = folder / "map_data.json"
            map_data = read_json(map_path) if map_path.exists() else {}
            grid = map_data.get("layers", {}).get("interactables", [])
            placements = [{"x": x, "z": z, "token": str(value)}
                          for z, row in enumerate(grid) for x, value in enumerate(row)
                          if str(value).strip() not in ("", "0", "None")]
            entry["halls"].append({"id": name, "manuscript": fingerprint(final),
                "map": fingerprint(map_path),
                "anchors": re.findall(r"<!--\s*@([^>]*?)\s*-->", manuscript),
                "placements": placements,
                "note": f"halls/{name}.md"})
        result["sequences"].append(entry)
    return result

if __name__ == "__main__":
    dest = HERE / "sources.json"
    if dest.exists():
        raise SystemExit("sources.json already exists; preserve its reading baseline. Use build_index.py to flag changed sources.")
    result = collect()
    (HERE / "halls").mkdir(exist_ok=True)
    dest.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"Recorded {len(result['sequences'])} sequences / {sum(len(s['halls']) for s in result['sequences'])} halls.")
