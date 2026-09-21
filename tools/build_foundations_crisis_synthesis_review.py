from pathlib import Path
import hashlib, json, re, subprocess
import markdown

R = Path.cwd(); M = "Crisis_Synthesis"; MAP = R / "commons/maps" / M
O = R / "doc/research/possible-bodies"; E = R / "doc/space/foundations-crisis-synthesis-2026-09-15"; E.mkdir(parents=True, exist_ok=True)
data = json.loads((MAP / "map_data.json").read_text(encoding="utf-8"))
roles = json.loads((R / "commons/data/artifact_roles.json").read_text(encoding="utf-8"))["roles"][M]
tokens = [x.strip().split(":", 1)[0] for row in data["layers"]["interactables"] for x in row if x.strip()]
checks = {
    "map_dimensions": data["map_info"]["dimensions"] == {"width": 19, "depth": 20, "max_height": 4},
    "ten_artifacts": len(tokens) == 10 and len(set(tokens)) == 10,
    "primary_focus": all(roles.get(k) == "primary" for k in ["lambda_slider", "phi_slider", "qfep_formula_3d"]),
    "registers_present": all((MAP / n).exists() for n in ["final.md", "tutorial.md", "technical.md", "critical.md"]),
    "summit_structure": len(data["layers"]["structure"]) == 20 and len(data["layers"]["structure"][0]) == 19,
}
try:
    checks["registry_resolution"] = subprocess.run(["python", "tools/check_map_tokens.py", "--json"], capture_output=True, text=True, check=False).returncode == 0
except OSError:
    checks["registry_resolution"] = False
verification = {"hall": M, "date": "2026-09-15", "checks": sum(checks.values()), "total_checks": len(checks), "failures": [k for k, v in checks.items() if not v], "checks_detail": checks, "tokens": tokens, "primary_artifacts": ["lambda_slider", "phi_slider", "qfep_formula_3d"], "source_sha256": {str((MAP / n).relative_to(R)): hashlib.sha256((MAP / n).read_bytes()).hexdigest() for n in ["map_data.json", "final.md", "tutorial.md", "technical.md", "critical.md"]}}
(E / "verification.json").write_text(json.dumps(verification, indent=2), encoding="utf-8")
(O / "foundations-crisis-synthesis-verification.json").write_text(json.dumps(verification, indent=2), encoding="utf-8")
css = re.search(r"<style>(.*?)</style>", (O / "iso-introduction.html").read_text(encoding="utf-8"), re.S)[1]
book = markdown.markdown((MAP / "final.md").read_text(encoding="utf-8"), extensions=["fenced_code"])
diagram = '''<figure><svg viewBox="0 0 900 300" role="img" aria-labelledby="s-title s-desc" xmlns="http://www.w3.org/2000/svg"><title id="s-title">Four crises around one formula</title><desc id="s-desc">Four colored wings converge on a summit formula.</desc><rect width="900" height="300" rx="18" fill="#171326"/><g font-family="system-ui,sans-serif" text-anchor="middle"><path d="M450 150L150 70M450 150L750 70M450 150L150 240M450 150L750 240" stroke="#9b8bd4" stroke-width="6" opacity=".8"/><circle cx="150" cy="70" r="48" fill="#de7d9b"/><circle cx="750" cy="70" r="48" fill="#77b9d6"/><circle cx="150" cy="240" r="48" fill="#e9b86f"/><circle cx="750" cy="240" r="48" fill="#85c89a"/><circle cx="450" cy="150" r="72" fill="#f4d58d"/><g fill="#171326" font-size="18"><text x="150" y="76">RUSSELL</text><text x="750" y="76">GÖDEL</text><text x="150" y="246">ESCHER</text><text x="750" y="246">BROUWER</text><text x="450" y="143" font-size="17">QFE = F − λE(S)</text><text x="450" y="168" font-size="17">+ φΔE(S,t)</text></g><text x="450" y="285" fill="#f5f0ff" font-size="18">the edge is where the responses meet</text></g></svg><figcaption>The synthesis keeps contradiction, incompleteness, construction, and impossible form in relation.</figcaption></figure>'''
score = f'<p>{verification["checks"]}/{verification["total_checks"]} static checks passed. <a href="foundations-crisis-synthesis-verification.json">Verification record</a></p>'
body = '<p class="date">Foundational crises · Synthesis hall · 15 September 2026</p><h1>The Edge Is the Engine</h1><p class="lead">Four limits remain visible around one summit: a formula that treats entropy and change as material for making.</p><p><a href="/necklace/thread?map=Crisis_Synthesis&amp;role=primary">Primary artifacts and book</a> · <a href="/museum-progress?sequence=foundationscrisis">Museum progress</a></p>' + diagram + '<details><summary>Read the book passage</summary>' + book + '</details><h2>A junction, not a conclusion</h2><p>The three primary controls are the room’s hinge: λ tunes the pressure toward order, φ tunes the relation to change, and the QFEP formula names the whole relation. The four wings remain secondary witnesses—Russell, Gödel, Escher, and Brouwer—so the synthesis can be walked as a set of responses rather than read as a single answer.</p><p>The next sequence carries this open formula into working systems. The crisis has become a method: keep the edges visible, then build with them.</p>' + score
(O / "foundations-crisis-synthesis.html").write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The Edge Is the Engine · Ada Research</title><style>' + css + '</style><main><nav><a href="foundations-brouwer.html">Previous hall</a><a href="/museum-progress?sequence=foundationscrisis">Museum progress</a></nav>' + body + '</main></html>', encoding="utf-8")
assets = ["foundations-crisis-synthesis.html", "foundations-crisis-synthesis-verification.json"]
(E / "publish-targets.json").write_text(json.dumps(["possible-bodies/" + a for a in assets], indent=2), encoding="utf-8")
(E / "publish-hashes.json").write_text(json.dumps({"possible-bodies/" + a: hashlib.sha256((O / a).read_bytes()).hexdigest() for a in assets}, indent=2), encoding="utf-8")
print(json.dumps(verification))
