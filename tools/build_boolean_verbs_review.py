from pathlib import Path
import hashlib
import json
import re
import subprocess

import markdown

R = Path.cwd()
M = "Boolean_Verbs"
MAP = R / "commons/maps" / M
O = R / "doc/research/possible-bodies"
E = R / "doc/space/boolean-verbs-2026-09-15"
E.mkdir(parents=True, exist_ok=True)

data = json.loads((MAP / "map_data.json").read_text(encoding="utf-8"))
roles = json.loads((R / "commons/data/artifact_roles.json").read_text(encoding="utf-8"))["roles"][M]
tokens = []
for row in data["layers"]["interactables"]:
    for raw in row:
        token = raw.strip()
        if token:
            tokens.append(token.split(":", 1)[0])
checks = {
    "map_dimensions": data["map_info"]["dimensions"] == {"width": 13, "depth": 26, "max_height": 3},
    "three_primary_tokens": tokens.count("csg_union_demo") == 1 and tokens.count("csg_intersection_demo") == 1 and tokens.count("csg_difference_demo") == 1,
    "closing_secondary": roles.get("the_argument_of_solids") == "secondary",
    "role_alignment": all(roles.get(k) == "primary" for k in ["csg_union_demo", "csg_intersection_demo", "csg_difference_demo"]),
    "registers_present": all((MAP / n).exists() for n in ["final.md", "tutorial.md", "technical.md", "critical.md"]),
}
try:
    audit = subprocess.run(["python", "tools/check_map_tokens.py", "--json"], capture_output=True, text=True, check=False)
    checks["registry_resolution"] = audit.returncode == 0
except OSError:
    checks["registry_resolution"] = False

verification = {
    "hall": M,
    "date": "2026-09-15",
    "checks": sum(checks.values()),
    "total_checks": len(checks),
    "failures": [name for name, ok in checks.items() if not ok],
    "checks_detail": checks,
    "primary_artifacts": ["csg_union_demo", "csg_intersection_demo", "csg_difference_demo"],
    "secondary_artifacts": ["the_argument_of_solids"],
    "source_sha256": {str((MAP / n).relative_to(R)): hashlib.sha256((MAP / n).read_bytes()).hexdigest() for n in ["map_data.json", "final.md", "tutorial.md", "technical.md", "critical.md"]},
}
(E / "verification.json").write_text(json.dumps(verification, indent=2), encoding="utf-8")
(O / "boolean-verbs-verification.json").write_text(json.dumps(verification, indent=2), encoding="utf-8")

css = re.search(r"<style>(.*?)</style>", (O / "iso-introduction.html").read_text(encoding="utf-8"), re.S)[1]
book = markdown.markdown((MAP / "final.md").read_text(encoding="utf-8"), extensions=["fenced_code"])
diagram = '''<figure><svg viewBox="0 0 900 220" role="img" aria-labelledby="boolean-title boolean-desc" xmlns="http://www.w3.org/2000/svg"><title id="boolean-title">Three boolean verbs</title><desc id="boolean-desc">Three paired circles show union, intersection and difference.</desc><rect width="900" height="220" rx="18" fill="#10232b"/><g font-family="system-ui,sans-serif" text-anchor="middle" fill="#eaf4f1"><g transform="translate(150 95)"><circle cx="-28" cy="0" r="46" fill="#f58b8b" fill-opacity=".75"/><circle cx="28" cy="0" r="46" fill="#7ec8ff" fill-opacity=".75"/><text y="84" font-size="20">UNION · A ∪ B</text></g><g transform="translate(450 95)"><circle cx="-28" cy="0" r="46" fill="#f58b8b" fill-opacity=".75"/><circle cx="28" cy="0" r="46" fill="#7ec8ff" fill-opacity=".75"/><path d="M0-38a46 46 0 0 1 0 76a46 46 0 0 1 0-76" fill="#d9f2ef" fill-opacity=".9"/><text y="84" font-size="20">INTERSECTION · A ∩ B</text></g><g transform="translate(750 95)"><circle cx="-28" cy="0" r="46" fill="#f58b8b" fill-opacity=".85"/><circle cx="28" cy="0" r="46" fill="#7ec8ff" fill-opacity=".28"/><text y="84" font-size="20">DIFFERENCE · A − B</text></g></g></svg><figcaption>The same operands, three boundaries. The verbs decide what can remain.</figcaption></figure>'''
body = ('<p class="date">Boolean surfaces · Hall 1 · 15 September 2026</p><h1>The Three Verbs</h1>'
        '<p class="lead">One box, one sphere, three operations. The room asks what a boundary can say when its vocabulary is only include, agree, and remove.</p>'
        '<p><a href="/necklace/thread?map=Boolean_Verbs&amp;role=primary">Primary artifacts and book</a> · <a href="/museum-progress?sequence=boolean_surfaces">Museum progress</a></p>'
        + diagram + '<details><summary>Read the book passage</summary>' + book + '</details>'
        + '<h2>A compact grammar with consequences</h2><p>The hall keeps the operand pair fixed so the verb is the visible change. Union deletes the seam, intersection keeps only shared territory, and difference manufactures a cavity wall. The sills separate the bays without hiding the previous result, making the three outcomes comparative and walkable.</p>'
        + '<p>The register files now agree: the map has three primary verbs, a secondary closing argument, and a tutorial, technical, critical, and book account of the same path. The next room, Boolean_Gallery, opens the values that these verbs currently conceal.</p>'
        + f'<p>{verification["checks"]}/{verification["total_checks"]} static checks passed, including registry resolution, dimensions, token counts, role alignment, and register presence. <a href="boolean-verbs-verification.json">Verification record</a></p>')
(O / "boolean-verbs.html").write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The Three Verbs · Ada Research</title><style>' + css + '</style><main><nav><a href="iso-introduction.html">Introduction</a><a href="/museum-progress?sequence=boolean_surfaces">Museum progress</a></nav>' + body + '</main></html>', encoding="utf-8")
assets = ["boolean-verbs.html", "boolean-verbs-verification.json"]
(E / "publish-targets.json").write_text(json.dumps(["possible-bodies/" + a for a in assets], indent=2), encoding="utf-8")
(E / "publish-hashes.json").write_text(json.dumps({"possible-bodies/" + a: hashlib.sha256((O / a).read_bytes()).hexdigest() for a in assets}, indent=2), encoding="utf-8")
print(json.dumps(verification))
