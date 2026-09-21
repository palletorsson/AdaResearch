from pathlib import Path
import hashlib
import json
import re
import subprocess

import markdown

R = Path.cwd()
M = "NonEuclidean_Spaces"
MAP = R / "commons/maps" / M
O = R / "doc/research/possible-bodies"
E = R / "doc/space/foundations-non-euclidean-2026-09-15"
E.mkdir(parents=True, exist_ok=True)
data = json.loads((MAP / "map_data.json").read_text(encoding="utf-8"))
roles = json.loads((R / "commons/data/artifact_roles.json").read_text(encoding="utf-8"))["roles"][M]
tokens = [x.strip().split(":", 1)[0] for row in data["layers"]["interactables"] for x in row if x.strip()]
checks = {
    "map_dimensions": data["map_info"]["dimensions"] == {"width": 17, "depth": 15, "max_height": 3},
    "six_authored_artifacts": len(tokens) == 6 and len(set(tokens)) == 6,
    "primary_focus": roles.get("triangle_curvature_workbench") == "primary" and roles.get("riemann_sphere") == "primary",
    "registers_present": all((MAP / n).exists() for n in ["final.md", "tutorial.md", "technical.md", "critical.md"]),
    "walkable_split": len(data["layers"]["structure"]) == 15 and len(data["layers"]["structure"][0]) == 17,
}
try:
    audit = subprocess.run(["python", "tools/check_map_tokens.py", "--json"], capture_output=True, text=True, check=False)
    checks["registry_resolution"] = audit.returncode == 0
except OSError:
    checks["registry_resolution"] = False
verification = {"hall": M, "date": "2026-09-15", "checks": sum(checks.values()), "total_checks": len(checks), "failures": [k for k, v in checks.items() if not v], "checks_detail": checks, "tokens": tokens, "primary_artifacts": ["triangle_curvature_workbench", "riemann_sphere"], "source_sha256": {str((MAP / n).relative_to(R)): hashlib.sha256((MAP / n).read_bytes()).hexdigest() for n in ["map_data.json", "final.md", "tutorial.md", "technical.md", "critical.md"]}}
(E / "verification.json").write_text(json.dumps(verification, indent=2), encoding="utf-8")
(O / "foundations-non-euclidean-verification.json").write_text(json.dumps(verification, indent=2), encoding="utf-8")
css = re.search(r"<style>(.*?)</style>", (O / "iso-introduction.html").read_text(encoding="utf-8"), re.S)[1]
book = markdown.markdown((MAP / "final.md").read_text(encoding="utf-8"), extensions=["fenced_code"])
diagram = '''<figure><svg viewBox="0 0 900 280" role="img" aria-labelledby="geometry-title geometry-desc" xmlns="http://www.w3.org/2000/svg"><title id="geometry-title">Curvature as a choice</title><desc id="geometry-desc">A hyperbolic bowl, a flat bridge and an elliptic dome with triangle angle sums.</desc><rect width="900" height="280" rx="18" fill="#101d38"/><g fill="none" stroke="#8ec9c1" stroke-width="4"><path d="M65 76 Q190 232 315 76"/><path d="M65 76 Q190 170 315 76" stroke="#f58b8b" stroke-dasharray="8 8"/><path d="M335 150h230"/><path d="M585 76 Q710 -10 835 76"/><path d="M585 76 Q710 125 835 76" stroke="#f58b8b" stroke-dasharray="8 8"/></g><g fill="#eaf4f1" font-family="system-ui,sans-serif" text-anchor="middle"><text x="190" y="255" font-size="20">K &lt; 0 · HYPERBOLIC</text><text x="450" y="185" font-size="18">K = 0 · FLAT</text><text x="710" y="130" font-size="20">K &gt; 0 · ELLIPTIC</text><text x="190" y="48" font-size="15">angle sum &lt; 180°</text><text x="710" y="48" font-size="15">angle sum &gt; 180°</text></g></svg><figcaption>The same triangle question lands differently when the host surface changes.</figcaption></figure>'''
body = ('<p class="date">Foundational crises · Hall 1 · 15 September 2026</p><h1>Curvature as Choice</h1><p class="lead">The ground has a setting. A single number decides whether parallel lines diverge, meet, or never exist as parallels at all.</p><p><a href="/necklace/thread?map=NonEuclidean_Spaces&amp;role=primary">Primary artifacts and book</a> · <a href="/museum-progress?sequence=foundationscrisis">Museum progress</a></p>' + diagram + '<details><summary>Read the book passage</summary>' + book + '</details><h2>One dial, two witnesses</h2><p>The primary pair carries the lesson at two scales. The triangle workbench computes angle sums from the host curvature; the Riemann sphere folds the infinite plane onto a finite body. Around them, the slider, bowl, dome, and Poincaré disk keep the alternatives visible.</p><p>The hall starts the Foundations Crisis with abundance rather than contradiction. Geometry is not corrected from outside; it is selected, inhabited, and measured. Next comes <strong>Russell_Paradox</strong>, where a rule turns back on the set that contains it.</p>' + f'<p>{verification["checks"]}/{verification["total_checks"]} static checks passed. <a href="foundations-non-euclidean-verification.json">Verification record</a></p>')
(O / "foundations-non-euclidean.html").write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Curvature as Choice · Ada Research</title><style>' + css + '</style><main><nav><a href="/museum-progress?sequence=foundationscrisis">Museum progress</a><a href="boolean-works.html">Previous chapter</a></nav>' + body + '</main></html>', encoding="utf-8")
assets = ["foundations-non-euclidean.html", "foundations-non-euclidean-verification.json"]
(E / "publish-targets.json").write_text(json.dumps(["possible-bodies/" + a for a in assets], indent=2), encoding="utf-8")
(E / "publish-hashes.json").write_text(json.dumps({"possible-bodies/" + a: hashlib.sha256((O / a).read_bytes()).hexdigest() for a in assets}, indent=2), encoding="utf-8")
print(json.dumps(verification))
