"""Freeze the source inventory for this bounded editorial/teaching review."""
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent

def read_json(path):
    return json.loads(re.sub(r",\s*([}\]])", r"\1", path.read_text(encoding="utf-8-sig")))

def file_info(path):
    if not path.exists():
        return {"path": path.relative_to(ROOT).as_posix(), "exists": False}
    data = path.read_bytes()
    text = data.decode("utf-8-sig")
    return {"path": path.relative_to(ROOT).as_posix(), "exists": True,
            "sha256": hashlib.sha256(data).hexdigest(), "words_including_notes_code": len(text.split()),
            "headings": re.findall(r"^#{1,3} (.+)$", text, re.M),
            "code_blocks": text.count("```") // 2}

spine_path = ROOT / "commons/maps/curriculum_spine.json"
spine = sorted(read_json(spine_path)["spine"]["sequences"], key=lambda s: s["order"])
boards = {}
board_sources = []
for filename in ["opening.json", "early.json", "growth.json", "later.json"]:
    path = ROOT / "doc/book/course/storyboards" / filename
    board_sources.append(file_info(path))
    for seq in read_json(path):
        boards[seq["sequence"]] = seq

records = []
for seq in spine:
    key = seq["name"]
    path = ROOT / "commons/maps/sequences" / (key + ".json")
    definition = read_json(path)["sequences"][key]
    rows = []
    for name in definition["maps"]:
        folder = ROOT / "commons/maps" / name
        rows.append({"map": name, "files": {kind: file_info(folder / kind) for kind in
                     ["final.md", "tutorial.md", "intent.md", "critical.md", "map_data.json"]}})
    board = boards.get(key, {})
    records.append({"sequence": key, "title": definition.get("name", key), "order": seq["order"],
                    "definition": file_info(path), "arc": board.get("arc", ""), "maps": rows,
                    "storyboard_maps": [h["id"] for h in board.get("halls", [])]})

result = {"date": "2026-10-04", "scope": "Current canonical spine and authored documents; inventory is not learner or runtime verification.",
          "spine_source": file_info(spine_path), "storyboard_sources": board_sources, "sequences": records}
(OUT / "inventory.json").write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
for seq in records:
    missing = [m["map"] for m in seq["maps"] if not m["files"]["tutorial.md"]["exists"]]
    final_missing = [m["map"] for m in seq["maps"] if not m["files"]["final.md"]["exists"]]
    print(f"{seq['sequence']}: {len(seq['maps'])} halls; tutorials {len(seq['maps'])-len(missing)}/{len(seq['maps'])}; missing {', '.join(missing) or 'none'}; final missing {final_missing}")
print("TOTAL", sum(len(s["maps"]) for s in records))
