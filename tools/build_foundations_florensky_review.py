from pathlib import Path
import hashlib, json, re, subprocess
import markdown

R = Path.cwd(); M = "Florensky_Paraconsistent"; MAP = R / "commons/maps" / M
O = R / "doc/research/possible-bodies"; E = R / "doc/space/foundations-florensky-2026-09-15"; E.mkdir(parents=True, exist_ok=True)
data = json.loads((MAP / "map_data.json").read_text(encoding="utf-8"))
roles = json.loads((R / "commons/data/artifact_roles.json").read_text(encoding="utf-8"))["roles"][M]
tokens = [x.strip().split(":", 1)[0] for row in data["layers"]["interactables"] for x in row if x.strip()]
checks = {
    "map_dimensions": data["map_info"]["dimensions"] == {"width": 13, "depth": 12, "max_height": 3},
    "four_artifacts": len(tokens) == 4 and len(set(tokens)) == 4,
    "primary_focus": roles.get("both_true_gate") == "primary" and roles.get("florensky_sphere") == "primary",
    "registers_present": all((MAP / n).exists() for n in ["final.md", "tutorial.md", "technical.md", "critical.md"]),
    "grid_structure": len(data["layers"]["structure"]) == 12 and len(data["layers"]["structure"][0]) == 13,
}
try:
    checks["registry_resolution"] = subprocess.run(["python", "tools/check_map_tokens.py", "--json"], capture_output=True, text=True, check=False).returncode == 0
except OSError:
    checks["registry_resolution"] = False
verification = {"hall": M, "date": "2026-09-15", "checks": sum(checks.values()), "total_checks": len(checks), "failures": [k for k, v in checks.items() if not v], "checks_detail": checks, "tokens": tokens, "primary_artifacts": ["both_true_gate", "florensky_sphere"], "source_sha256": {str((MAP / n).relative_to(R)): hashlib.sha256((MAP / n).read_bytes()).hexdigest() for n in ["map_data.json", "final.md", "tutorial.md", "technical.md", "critical.md"]}}
(E / "verification.json").write_text(json.dumps(verification, indent=2), encoding="utf-8")
(O / "foundations-florensky-verification.json").write_text(json.dumps(verification, indent=2), encoding="utf-8")
css = re.search(r"<style>(.*?)</style>", (O / "iso-introduction.html").read_text(encoding="utf-8"), re.S)[1]
book = markdown.markdown((MAP / "final.md").read_text(encoding="utf-8"), extensions=["fenced_code"])
diagram = '''<figure><svg viewBox="0 0 900 280" role="img" aria-labelledby="f-title f-desc" xmlns="http://www.w3.org/2000/svg"><title id="f-title">A contradiction held in place</title><desc id="f-desc">A gate holds two colored propositions without letting either explode into the room.</desc><rect width="900" height="280" rx="18" fill="#171326"/><g font-family="system-ui,sans-serif" text-anchor="middle"><rect x="165" y="55" width="570" height="150" rx="18" fill="none" stroke="#f0c982" stroke-width="8"/><rect x="425" y="35" width="50" height="190" rx="8" fill="#f0c982"/><circle cx="315" cy="130" r="48" fill="#6fb6df"/><circle cx="585" cy="130" r="48" fill="#db789b"/><text x="315" y="137" font-size="24" fill="#171326">A</text><text x="585" y="137" font-size="24" fill="#171326">¬A</text><text x="450" y="255" font-size="18" fill="#f5f0ff">both can be true; nothing else follows</text></g></svg><figcaption>Paraconsistency contains a contradiction instead of allowing it to make every claim true.</figcaption></figure>'''
score = f'<p>{verification["checks"]}/{verification["total_checks"]} static checks passed. <a href="foundations-florensky-verification.json">Verification record</a></p>'
body = '<p class="date">Foundational crises · Hall 7 · 15 September 2026</p><h1>Hold Both</h1><p class="lead">A contradiction can remain local. The room keeps A and not-A together without letting the whole system collapse.</p><p><a href="/necklace/thread?map=Florensky_Paraconsistent&amp;role=primary">Primary artifacts and book</a> · <a href="/museum-progress?sequence=foundationscrisis">Museum progress</a></p>' + diagram + '<details><summary>Read the book passage</summary>' + book + '</details><h2>Containment as a practice</h2><p>The both-true gate and Florensky sphere carry the primary argument. The Schrödinger box and superposition display remain secondary foils: their observation collapses a state, while the paraconsistent room lets contradiction stay present. This distinction prepares the final synthesis, where incompatible responses can be placed in relation without being made identical.</p><p>The next hall is <strong>Crisis_Synthesis</strong>, where the four limits become wings around one formula.</p>' + score
(O / "foundations-florensky.html").write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Hold Both · Ada Research</title><style>' + css + '</style><main><nav><a href="foundations-brouwer.html">Previous hall</a><a href="foundations-crisis-synthesis.html">Next hall</a></nav>' + body + '</main></html>', encoding="utf-8")
assets = ["foundations-florensky.html", "foundations-florensky-verification.json"]
(E / "publish-targets.json").write_text(json.dumps(["possible-bodies/" + a for a in assets], indent=2), encoding="utf-8")
(E / "publish-hashes.json").write_text(json.dumps({"possible-bodies/" + a: hashlib.sha256((O / a).read_bytes()).hexdigest() for a in assets}, indent=2), encoding="utf-8")
print(json.dumps(verification))
