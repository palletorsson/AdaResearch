from pathlib import Path
import hashlib
import json
import re
import subprocess

import markdown

R = Path.cwd()
M = "Boolean_Gallery"
MAP = R / "commons/maps" / M
O = R / "doc/research/possible-bodies"
E = R / "doc/space/boolean-gallery-2026-09-15"
E.mkdir(parents=True, exist_ok=True)
data = json.loads((MAP / "map_data.json").read_text(encoding="utf-8"))
roles = json.loads((R / "commons/data/artifact_roles.json").read_text(encoding="utf-8"))["roles"][M]
tokens = [x.strip().split(":", 1)[0] for row in data["layers"]["interactables"] for x in row if x.strip()]
families = {k: tokens.count(k) for k in ["csg_difference_demo", "csg_union_demo", "csg_intersection_demo", "subtraction_suite", "coincident_face", "removal_room"]}
checks = {
    "map_dimensions": data["map_info"]["dimensions"] == {"width": 17, "depth": 32, "max_height": 3},
    "six_families": len(families) == 6 and all(v == 4 for v in families.values()),
    "twenty_four_placements": len(tokens) == 24,
    "primary_focus": roles.get("csg_difference_demo") == "primary" and roles.get("removal_room") == "primary",
    "registers_present": all((MAP / n).exists() for n in ["final.md", "tutorial.md", "technical.md", "critical.md"]),
}
try:
    audit = subprocess.run(["python", "tools/check_map_tokens.py", "--json"], capture_output=True, text=True, check=False)
    checks["registry_resolution"] = audit.returncode == 0
except OSError:
    checks["registry_resolution"] = False
verification = {"hall": M, "date": "2026-09-15", "checks": sum(checks.values()), "total_checks": len(checks), "failures": [k for k, v in checks.items() if not v], "checks_detail": checks, "families": families, "primary_artifacts": ["csg_difference_demo", "removal_room"], "source_sha256": {str((MAP / n).relative_to(R)): hashlib.sha256((MAP / n).read_bytes()).hexdigest() for n in ["map_data.json", "final.md", "tutorial.md", "technical.md", "critical.md"]}}
(E / "verification.json").write_text(json.dumps(verification, indent=2), encoding="utf-8")
(O / "boolean-gallery-verification.json").write_text(json.dumps(verification, indent=2), encoding="utf-8")
css = re.search(r"<style>(.*?)</style>", (O / "iso-introduction.html").read_text(encoding="utf-8"), re.S)[1]
book = markdown.markdown((MAP / "final.md").read_text(encoding="utf-8"), extensions=["fenced_code"])
diagram = '''<figure><svg viewBox="0 0 900 260" role="img" aria-labelledby="gallery-title gallery-desc" xmlns="http://www.w3.org/2000/svg"><title id="gallery-title">Six families, four values each</title><desc id="gallery-desc">Six horizontal rows of four variant tiles, with two primary families highlighted.</desc><rect width="900" height="260" rx="18" fill="#10232b"/><g font-family="system-ui,sans-serif"><text x="28" y="30" fill="#eaf4f1" font-size="19">THE GALLERY IS A WALKABLE REGISTER</text><g fill="#8ec9c1" font-size="13"><text x="28" y="62">DIFFERENCE</text><text x="28" y="94">UNION</text><text x="28" y="126">INTERSECTION</text><text x="28" y="158">BREACH</text><text x="28" y="190">COINCIDENT</text><text x="28" y="222">REMOVAL</text></g><g fill="#f58b8b" opacity=".9"><rect x="170" y="48" width="110" height="22" rx="5"/><rect x="170" y="208" width="110" height="22" rx="5"/></g><g fill="#5f8890"><rect x="294" y="48" width="110" height="22" rx="5"/><rect x="418" y="48" width="110" height="22" rx="5"/><rect x="542" y="48" width="110" height="22" rx="5"/><rect x="170" y="80" width="110" height="22" rx="5"/><rect x="294" y="80" width="110" height="22" rx="5"/><rect x="418" y="80" width="110" height="22" rx="5"/><rect x="542" y="80" width="110" height="22" rx="5"/><rect x="170" y="112" width="110" height="22" rx="5"/><rect x="294" y="112" width="110" height="22" rx="5"/><rect x="418" y="112" width="110" height="22" rx="5"/><rect x="542" y="112" width="110" height="22" rx="5"/><rect x="170" y="144" width="110" height="22" rx="5"/><rect x="294" y="144" width="110" height="22" rx="5"/><rect x="418" y="144" width="110" height="22" rx="5"/><rect x="542" y="144" width="110" height="22" rx="5"/><rect x="294" y="176" width="110" height="22" rx="5"/><rect x="418" y="176" width="110" height="22" rx="5"/><rect x="542" y="176" width="110" height="22" rx="5"/><rect x="294" y="208" width="110" height="22" rx="5"/><rect x="418" y="208" width="110" height="22" rx="5"/><rect x="542" y="208" width="110" height="22" rx="5"/></g><g fill="#10232b" font-size="11" text-anchor="middle"><text x="225" y="63">PRIMARY</text><text x="225" y="223">PRIMARY</text><text x="715" y="64" fill="#8ec9c1" text-anchor="start">four values →</text></g></g></svg><figcaption>Each row keeps a family together. Primary focus is marked in coral; comparison values remain visible.</figcaption></figure>'''
body = ('<p class="date">Boolean surfaces · Hall 2 · 15 September 2026</p><h1>Where the Variants Stand</h1><p class="lead">A gallery is a catalogue you can cross. Six families, four values each, and every disagreement between code, registry, and body left in view.</p><p><a href="/necklace/thread?map=Boolean_Gallery&amp;role=primary">Primary artifacts and book</a> · <a href="/museum-progress?sequence=boolean_surfaces">Museum progress</a></p>' + diagram + '<details><summary>Read the book passage</summary>' + book + '</details><h2>The claim beside the thing</h2><p>The room holds two primary witnesses: <strong>csg_difference_demo</strong>, where disclosure opens in four steps, and <strong>removal_room</strong>, which checks its vocabulary while carrying a flawed explanation. Four secondary families make the comparison broad enough to expose order, wildcard, ratio, and rendering seams.</p><p>The next hall, <strong>Boolean_Works</strong>, enlarges the negative until it asks whether a cavity can become architecture.</p>' + f'<p>{verification["checks"]}/{verification["total_checks"]} static checks passed. <a href="boolean-gallery-verification.json">Verification record</a></p>')
(O / "boolean-gallery.html").write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Where the Variants Stand · Ada Research</title><style>' + css + '</style><main><nav><a href="boolean-verbs.html">Boolean verbs</a><a href="/museum-progress?sequence=boolean_surfaces">Museum progress</a></nav>' + body + '</main></html>', encoding="utf-8")
assets = ["boolean-gallery.html", "boolean-gallery-verification.json"]
(E / "publish-targets.json").write_text(json.dumps(["possible-bodies/" + a for a in assets], indent=2), encoding="utf-8")
(E / "publish-hashes.json").write_text(json.dumps({"possible-bodies/" + a: hashlib.sha256((O / a).read_bytes()).hexdigest() for a in assets}, indent=2), encoding="utf-8")
print(json.dumps(verification))
