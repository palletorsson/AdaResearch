"""Carry this one hall's authored focus into the current teaching register."""
from pathlib import Path
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
subjects = ["Endpoints and a segment", "Displacement and distance", "Reusing an object", "Parallel, cross and X", "Position in depth"]
short = "Use existing line and relations gallery. Reuse Coordinates' pickable point; duplicate once. Teach same-frame endpoints, b-a and length; redraw the segment each frame. Supply visible skin and museum hands. Add a second segment from stored positions: parallel, +, X; separate in Z. Check an authored arrangement and coincidence. Carry relation into Trace. Reflection: line as route, prohibition, sign. Later Ignorance: choose rules/connectivity; finite vertices remain countable."
full = "At the existing line and relations gallery, the student brings the same pickable point from Coordinates. Its copy becomes another endpoint. Reading both positions in the station's frame gives a displacement and its length; a supplied visible skin draws their relation each frame. A second segment uses two stored positions without pickup bodies. Parallel, plus and X become arrangements the student can alter, including a depth change that separates an apparent crossing. The learner predicts and makes another arrangement, tests coincident endpoints, and carries the connecting operation into Trace. The reflective text follows a line as route, prohibition and sign; Primitive Ignorance later considers choosing rules that organise many finite vertices."

def load(relative):
    p = ROOT / relative
    backup = HERE / "before" / relative
    if not backup.exists():
        backup.parent.mkdir(parents=True, exist_ok=True)
        backup.write_bytes(p.read_bytes())
    return p, json.loads(p.read_text(encoding="utf-8-sig"))

p, data = load("doc/book/course/hall-cards/lineage-opening.json")
row = next(h for h in data["halls"] if h["map"] == "Point_Lines")
row.update(subjects=subjects, focus=full,
    adds="Adds a relation between two positions, returned length, reuse of a held body and arrangements of two segments. A crossing in view does not create a shared vertex.",
    carries="The same held point, a second endpoint and a segment that follows their relation; optional second segment uses stored positions.",
    status="aligned",
    review="5 October: continued saved Coordinates code and printed additions checked; 70 native checks and a failing frozen-renderer control. Initial Point One fixture remains an assumption; no headset or student-comprehension claim. Museum logic unchanged.",
    tutorial_sha256_before=hashlib.sha256((HERE / "before/Point_Lines/tutorial.md").read_bytes()).hexdigest(),
    tutorial_sha256_after=hashlib.sha256((ROOT / "commons/maps/Point_Lines/tutorial.md").read_bytes()).hexdigest(),
    revision_report="doc/book/iterations/2026-10-05-lines-relation-and-rule/index.html")
p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

p, data = load("doc/book/course/storyboards/opening.json")
row = next(h for s in data for h in s["halls"] if h["id"] == "Point_Lines")
row.update(storyboard=full, storyboard_short=short,
    brings=["Pickable point from Coordinates", "Position values in a named frame", "Repeated updates"],
    learns=subjects, carries="Connect two positions; reuse that relation to join retained positions in Trace.",
    supplied=["Configured museum hands and room", "line_skin.gd visible segment renderer"],
    review_note="Canonical lesson now continues the saved point. Native checks validate this reconstruction, not the starting assumption or learner understanding.")
p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

# Keep the two current text summaries aligned without rebuilding unrelated halls.
p = ROOT / "doc/book/course/TUTORIAL_STORYBOARDS_SHORT.md"
text = p.read_text(encoding="utf-8-sig")
text, count = re.subn(r"(### Point_Lines\n).*?(?=\n### )", lambda m: m[1] + short + "\n", text, count=1, flags=re.S)
assert count == 1
p.write_text(text, encoding="utf-8")
p = ROOT / "doc/book/course/TUTORIAL_STORYBOARDS.md"
text = p.read_text(encoding="utf-8-sig")
text, count = re.subn(r"(### Point_Lines[^\n]*\n).*?(?=\n### )", lambda m: m[1] + full + "\n\n**Short AI alternative**\n" + short + "\n\n[Revised lesson and evidence](iterations/2026-10-05-lines-relation-and-rule/index.html)\n", text, count=1, flags=re.S)
assert count == 1
text = text.replace("(iterations/2026-10-05-lines-relation-and-rule/index.html)", "(../iterations/2026-10-05-lines-relation-and-rule/index.html)")
p.write_text(text, encoding="utf-8")
print("Updated Point Lines focus and both current summary lengths.")
