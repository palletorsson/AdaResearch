from pathlib import Path
import hashlib
import json
import re
import subprocess

import markdown

R = Path.cwd()
M = "Boolean_Works"
MAP = R / "commons/maps" / M
O = R / "doc/research/possible-bodies"
E = R / "doc/space/boolean-works-2026-09-15"
E.mkdir(parents=True, exist_ok=True)
data = json.loads((MAP / "map_data.json").read_text(encoding="utf-8"))
roles = json.loads((R / "commons/data/artifact_roles.json").read_text(encoding="utf-8"))["roles"][M]
tokens = [x.strip().split(":", 1)[0] for row in data["layers"]["interactables"] for x in row if x.strip()]
expected = ["csg_compose_workbench", "subtraction_suite", "sphere_splitting_showcase", "recursive_boolean_cube", "csg_architecture_cavity", "boolean_burrow", "sdf_cavern_room", "booleanvariations", "coincident_face"]
checks = {
    "map_dimensions": data["map_info"]["dimensions"] == {"width": 17, "depth": 36, "max_height": 3},
    "authored_tokens": len(tokens) == 9 and all(tokens.count(k) == 1 for k in expected),
    "primary_focus": roles.get("csg_compose_workbench") == "primary" and roles.get("sdf_cavern_room") == "primary",
    "registers_present": all((MAP / n).exists() for n in ["final.md", "tutorial.md", "technical.md", "critical.md"]),
}
try:
    audit = subprocess.run(["python", "tools/check_map_tokens.py", "--json"], capture_output=True, text=True, check=False)
    checks["registry_resolution"] = audit.returncode == 0
except OSError:
    checks["registry_resolution"] = False
verification = {"hall": M, "date": "2026-09-15", "checks": sum(checks.values()), "total_checks": len(checks), "failures": [k for k, v in checks.items() if not v], "checks_detail": checks, "tokens": tokens, "primary_artifacts": ["csg_compose_workbench", "sdf_cavern_room"], "source_sha256": {str((MAP / n).relative_to(R)): hashlib.sha256((MAP / n).read_bytes()).hexdigest() for n in ["map_data.json", "final.md", "tutorial.md", "technical.md", "critical.md"]}}
(E / "verification.json").write_text(json.dumps(verification, indent=2), encoding="utf-8")
(O / "boolean-works-verification.json").write_text(json.dumps(verification, indent=2), encoding="utf-8")
css = re.search(r"<style>(.*?)</style>", (O / "iso-introduction.html").read_text(encoding="utf-8"), re.S)[1]
book = markdown.markdown((MAP / "final.md").read_text(encoding="utf-8"), extensions=["fenced_code"])
diagram = '''<figure><svg viewBox="0 0 900 250" role="img" aria-labelledby="works-title works-desc" xmlns="http://www.w3.org/2000/svg"><title id="works-title">A room as a boolean promise</title><desc id="works-desc">A wall with a door cut through it, with the visible boundary and collision layers separated.</desc><rect width="900" height="250" rx="18" fill="#10232b"/><g transform="translate(110 50)"><rect x="0" y="0" width="420" height="150" fill="#7b8d91"/><rect x="178" y="55" width="82" height="95" fill="#10232b"/><path d="M178 55h82v95h-82z" fill="none" stroke="#f58b8b" stroke-width="6"/><text x="219" y="180" text-anchor="middle" fill="#eaf4f1" font-family="system-ui" font-size="18">VISIBLE CUT</text><text x="219" y="207" text-anchor="middle" fill="#8ec9c1" font-family="system-ui" font-size="14">wall − door</text></g><g transform="translate(610 72)" font-family="system-ui" text-anchor="middle"><circle cx="0" cy="0" r="48" fill="#f58b8b" fill-opacity=".8"/><path d="M-20 40h40" stroke="#eaf4f1" stroke-width="6"/><text y="84" fill="#eaf4f1" font-size="18">COLLISION?</text><text y="108" fill="#8ec9c1" font-size="14">a second agreement</text></g><path d="M535 125h50" stroke="#f58b8b" stroke-width="3" stroke-dasharray="8 8"/></svg><figcaption>A visible cavity becomes a place only when the collision system agrees.</figcaption></figure>'''
body = ('<p class="date">Boolean surfaces · Hall 3 · 15 September 2026</p><h1>When the Negative Gets Big</h1><p class="lead">A cut can look like a room long before it can hold a body. This hall tests the promise at architectural scale.</p><p><a href="/necklace/thread?map=Boolean_Works&amp;role=primary">Primary artifacts and book</a> · <a href="/museum-progress?sequence=boolean_surfaces">Museum progress</a></p>' + diagram + '<details><summary>Read the book passage</summary>' + book + '</details><h2>The hollow has two layers</h2><p>The primary workbench and cavern carry the chapter from operation to architecture. Around them, the wall, burrow, recursive cube, variations rack, and coincident face keep the failures visible: a caption can promise a room, but only a boundary and a collision agreement can make one.</p><p>Boolean_Works closes the chapter by changing the question. The negative is no longer merely what was removed; it is the space where an embodied claim can be tested. The next sequence, <strong>swarm intelligence</strong>, will ask how many bodies can coordinate inside a field.</p>' + f'<p>{verification["checks"]}/{verification["total_checks"]} static checks passed. <a href="boolean-works-verification.json">Verification record</a></p>')
(O / "boolean-works.html").write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>When the Negative Gets Big · Ada Research</title><style>' + css + '</style><main><nav><a href="boolean-gallery.html">Boolean gallery</a><a href="/museum-progress?sequence=boolean_surfaces">Museum progress</a></nav>' + body + '</main></html>', encoding="utf-8")
assets = ["boolean-works.html", "boolean-works-verification.json"]
(E / "publish-targets.json").write_text(json.dumps(["possible-bodies/" + a for a in assets], indent=2), encoding="utf-8")
(E / "publish-hashes.json").write_text(json.dumps({"possible-bodies/" + a: hashlib.sha256((O / a).read_bytes()).hexdigest() for a in assets}, indent=2), encoding="utf-8")
print(json.dumps(verification))
