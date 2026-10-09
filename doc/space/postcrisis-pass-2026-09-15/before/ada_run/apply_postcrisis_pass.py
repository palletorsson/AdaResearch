"""One-time, backed-up alignment of the final eight halls (2026-09-15)."""
import copy
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from build_postcrisis_review import read_json, code_passage, excerpt, registry
from em_map_halls import derive_row, normalize_row

ARCHIVE = ROOT / "doc/space/postcrisis-pass-2026-09-15/before"
ARCHIVE.mkdir(parents=True, exist_ok=True)


def backup(path):
    target = ARCHIVE / path.relative_to(ROOT)
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists():
        target.write_bytes(path.read_bytes())


def write(path, text):
    backup(path)
    path.write_text(text, encoding="utf-8")


notes = read_json(ROOT / "doc/research/possible-bodies/postcrisis-pass.json")
halls = notes["halls"]
entries = registry()
redundant_starts = [
    "Keep one chosen pair as your reference", "Count the places as well as",
    "Keep three possible responses apart", "Write a mental four-part description",
    "Look for a repeated source during", "Compare the moment just before",
    "During assembly, compare a part’s route", "Stay with your chosen example after"
]
for h, redundant in zip(halls, redundant_starts):
    path = ROOT / "commons/maps" / h["map"]
    book = (path / "final.md").read_text(encoding="utf-8")
    paragraphs = book.split("\n\n")
    paragraphs = [p for p in paragraphs if not p.startswith(redundant)]
    book = "\n\n".join(paragraphs)
    if h["map"] == "AdvancedLaboratory_Lab_Equipment_Simulation":
        book = book.replace("Compare the part’s changing role with the properties it retains.", "Notice whether the same part instance keeps its shape and colour when it takes a new role.")
        book = book.replace("An assembly chooses instances, assigns target positions and orientations, and declares connections.", "An assembly chooses instances, assigns target positions, reapplies shapes from the catalogue, and declares connections.")
    if "The source makes the operation inspectable:" not in book:
        # After the initial encounter and observation, before the conceptual argument.
        paragraphs = book.split("\n\n")
        anchor = next(i for i, p in enumerate(paragraphs) if p.startswith("<!-- @"))
        paragraphs.insert(anchor + 3, code_passage(h))
        book = "\n\n".join(paragraphs)
    write(path / "final.md", book.rstrip() + "\n")
    src = h["excerpt"]["file"]
    scene = entries[h["primary"]]["scene"].removeprefix("res://")
    source_link = f"[Implementation](../../../{src})"
    archive_link = f"[Earlier design proposal](../../../doc/space/postcrisis-pass-2026-09-15/before/commons/maps/{h['map']}/technical.md)"
    tutorial = f"""# {h['question']}

{h['inherit']}

<!-- @{h['primary']} -->

{h['action']}

{h['observation']}

{code_passage(h)}

{source_link}. This is an excerpt from the artifact, not a standalone program.

{h['critical']}

<!-- @ -->

{h['carry']}

## Next experiment — not yet a visitor control

{h['next_test']}
"""
    write(path / "tutorial.md", tutorial)
    technical = f"""# {h['title']} — implementation and encounter

The primary artifact is `{h['primary']}`. Its [scene](../../../{scene}) and {source_link.lower()} supply the behaviour described here.

{h['technical']}

## Operation to read after the encounter

```gdscript
{excerpt(h)}
```

{h['explanation']}

## What to compare

{h['action']}

{h['observation']}

## Limits and next test

{h['next_test']}

This source audit does not establish headset readability, comfortable reach, collision clearance or frame rate. Those remain runtime observations. Existing supporting artifacts stay in the map; primary status identifies the book's encounter, not the only permitted content.

{archive_link} preserves the previous text and its proposed systems. It is not a description of the current implementation.
"""
    write(path / "technical.md", technical)
    critical = f"""# {h['question']}

{h['action']}

{h['critical']}

{h['explanation']}

The material comparison is specific: {h['observation'][0].lower() + h['observation'][1:]}

{h['carry']}

## A question the next version can test

{h['next_test']}

The earlier theoretical and design text is [preserved for further development](../../../doc/space/postcrisis-pass-2026-09-15/before/commons/maps/{h['map']}/critical.md). This encounter grounds the claim in the current primary artifact; it does not turn an illustrative scene into empirical evidence about people.
"""
    write(path / "critical.md", critical)

# Sequence group metadata must describe placed artifacts, not unbuilt proposals.
seq_path = ROOT / "commons/maps/sequences/postfoundationscrisis.json"
seq = read_json(seq_path)
s = seq["sequences"]["postfoundationscrisis"]
for h, g in zip(halls, s["artifact_groups"]):
    assert h["map"] == g["map"]
    d = read_json(ROOT / "commons/maps" / h["map"] / "map_data.json")
    from build_postcrisis_review import token_name
    tokens = list(dict.fromkeys(token_name(c) for row in d["layers"]["interactables"] for c in row if str(c).strip()))
    g["artifacts"] = tokens
    g["rationale"] = f"Book encounter: {h['primary']}. {h['question']} Supporting artifacts remain available."
s["learning_objectives"] = [
    "Separate authored spatial compression from measured model behaviour",
    "Compare how count, scale and arrangement shape participation",
    "Distinguish retaining a conflict from changing inference rules",
    "Keep a claim, its source and its criteria distinguishable",
    "Distinguish contribution counts, contributor identity and revision",
    "Inspect how nearest-neighbour growth distributes connections",
    "Separate authored assembly targets from the motion towards them",
    "Propose a specific change, observe its consequence and test its reuse"
]
s["description"] = notes["premise"]
s["content"] = [h["map"] + ": " + h["title"] for h in halls]
write(seq_path, json.dumps(seq, indent=1, ensure_ascii=False) + "\n")

# Restore only the two absent rows; preserve all six existing hall geometries.
expected = [h["map"] for h in halls]
for file in ["commons/data/museum/em_plan.json", "ada_run/em_plan.json"]:
    p = ROOT / file
    plan = read_json(p)
    other_before = [r for r in plan["plans"] if r.get("sequence") != "postfoundationscrisis"]
    old_rows = {r["map"]: r for r in plan["plans"] if r.get("sequence") == "postfoundationscrisis"}
    museum = next(iter(old_rows.values()))["museum"]
    rows = []
    for i, m in enumerate(expected):
        if m in old_rows:
            row = copy.deepcopy(old_rows[m])
        else:
            row = derive_row(m.replace("_", " ").lower(), m, museum, i, len(expected), "postfoundationscrisis")
            normalize_row(row, post_color=True, dirlocked=False)
        row["pearl_index"] = i
        row["pearls_total"] = len(expected)
        rows.append(row)
    # Keep the sequence at its prior location instead of moving it to the end.
    new_plans = []
    inserted = False
    for row in plan["plans"]:
        if row.get("sequence") == "postfoundationscrisis":
            if not inserted:
                new_plans.extend(rows)
                inserted = True
        else:
            new_plans.append(row)
    assert [r for r in new_plans if r.get("sequence") != "postfoundationscrisis"] == other_before
    plan["plans"] = new_plans
    meta = plan.get("_map_halls", {})
    for ch in meta.get("chapters", []):
        if ch.get("chapter") == "postfoundationscrisis":
            ch.update({"halls": len(rows), "maps": expected, "restored": ["SpeculativeComputation_Situated_Computation", "AdvancedLaboratory_Lab_Equipment_Simulation"], "reviewed": "2026-09-15"})
    meta["halls"] = sum(ch.get("halls", 0) for ch in meta.get("chapters", []))
    write(p, json.dumps(plan, ensure_ascii=False) + "\n")

scores_path = ROOT / "doc/final_lap_scores.json"
scores = read_json(scores_path)
scores["_meta"]["source_review"] = "2026-09-15: final eight halls reconciled with primary source. Historical numeric aesthetic/helper scores retained; no new headset walk claimed."
scores["scaffolded_maps_awaiting_artifacts"]["postfoundationscrisis"] = []
for h in halls:
    record = scores["maps"][h["map"]]
    record["source_review"] = "2026-09-15"
    record["note"] = "Book, tutorial and technical grounded in " + h["primary"] + ". Next test: " + h["next_test"]
write(scores_path, json.dumps(scores, indent=2, ensure_ascii=False) + "\n")
print("Aligned eight halls; previous texts and museum plans preserved in " + str(ARCHIVE))
