from pathlib import Path
import hashlib, json, re, subprocess
import markdown

R = Path.cwd(); M = "QFEP_F_Term"; MAP = R / "commons/maps" / M
O = R / "doc/research/possible-bodies"; E = R / "doc/space/qfep-f-term-2026-09-15"; E.mkdir(parents=True, exist_ok=True)
data = json.loads((MAP / "map_data.json").read_text(encoding="utf-8"))
roles = json.loads((R / "commons/data/artifact_roles.json").read_text(encoding="utf-8"))["roles"][M]
tokens = [x.strip().split(":", 1)[0].split("#", 1)[0] for row in data["layers"]["interactables"] for x in row if x.strip()]
checks = {
    "map_dimensions": data["map_info"]["dimensions"] == {"width": 10, "depth": 14, "max_height": 3},
    "eight_artifacts": len(tokens) == 8 and len(set(tokens)) == 8,
    "primary_focus": roles.get("shannon_workbench") == "primary" and sum(v == "primary" for v in roles.values()) == 1,
    "registers_present": all((MAP / n).exists() for n in ["final.md", "tutorial.md", "technical.md", "critical.md"]),
    "layer_shapes": (len(data["layers"]["structure"]) == 12 and len(data["layers"]["structure"][0]) == 10 and len(data["layers"]["utilities"]) == 12 and len(data["layers"]["interactables"]) == 14),
}
try:
    checks["registry_resolution"] = subprocess.run(["python", "tools/check_map_tokens.py", "--json"], capture_output=True, text=True, check=False).returncode == 0
except OSError:
    checks["registry_resolution"] = False
verification = {"hall": M, "date": "2026-09-15", "checks": sum(checks.values()), "total_checks": len(checks), "failures": [k for k, v in checks.items() if not v], "checks_detail": checks, "tokens": tokens, "primary_artifacts": ["shannon_workbench"], "source_sha256": {str((MAP / n).relative_to(R)): hashlib.sha256((MAP / n).read_bytes()).hexdigest() for n in ["map_data.json", "final.md", "tutorial.md", "technical.md", "critical.md"]}}
(E / "verification.json").write_text(json.dumps(verification, indent=2), encoding="utf-8")
(O / "qfep-f-term-verification.json").write_text(json.dumps(verification, indent=2), encoding="utf-8")
css = re.search(r"<style>(.*?)</style>", (O / "iso-introduction.html").read_text(encoding="utf-8"), re.S)[1]
book = markdown.markdown((MAP / "final.md").read_text(encoding="utf-8"), extensions=["fenced_code"])
diagram = '''<figure><svg viewBox="0 0 900 280" role="img" aria-labelledby="f-title f-desc" xmlns="http://www.w3.org/2000/svg"><title id="f-title">Uncertainty and prediction</title><desc id="f-desc">A probability rail feeds a changing entropy curve while a predictor compares its guess with a sample.</desc><rect width="900" height="280" rx="18" fill="#121827"/><g font-family="system-ui,sans-serif"><path d="M90 185H810" stroke="#8fc7d5" stroke-width="8"/><circle cx="230" cy="185" r="18" fill="#e9b86f"/><circle cx="450" cy="185" r="18" fill="#d887b7"/><circle cx="670" cy="185" r="18" fill="#e9b86f"/><path d="M150 120 Q450 245 750 120" fill="none" stroke="#77b9d6" stroke-width="6"/><g fill="#f5f0ff" font-size="18" text-anchor="middle"><text x="230" y="225">p ≈ 0.1</text><text x="450" y="225">p = 0.5</text><text x="670" y="225">p ≈ 0.9</text><text x="450" y="70" font-size="22">H(p) = −p log₂p − (1−p) log₂(1−p)</text><text x="450" y="265" font-size="16">the same entropy can hide a different dominant value</text></g></g></svg><figcaption>The workbench separates a source model's uncertainty from the particular sample and predictor.</figcaption></figure>'''
score = f'<p>{verification["checks"]}/{verification["total_checks"]} static checks passed. <a href="qfep-f-term-verification.json">Verification record</a></p>'
body = '<p class="date">QFEP laboratory · F term · 15 September 2026</p><h1>Predictable According to What Model?</h1><p class="lead">Entropy is a property of a specified source, not a mood we can read off a single patch of pixels.</p><p><a href="/necklace/thread?map=QFEP_F_Term&amp;role=primary">Primary artifact and book</a> · <a href="/museum-progress?sequence=qfeplaboratory">Museum progress</a></p>' + diagram + '<details><summary>Read the book passage</summary>' + book + '</details><h2>One rail, several readings</h2><p>The Shannon workbench is the sole primary artifact. Its probability rail, finite bit grid, and entropy readout establish a precise first measurement. The dark sphere, predictor puzzle, tetrahedron puzzle, and crystal cluster remain secondary supports, keeping model, sample, and spatial fit in view without turning them into interchangeable quantities.</p><p>The next hall, <a href="qfep-e-term.html"><strong>QFEP_E_Term</strong></a>, counts alternatives explicitly and asks what the model has allowed into its world.</p>' + score
(O / "qfep-f-term.html").write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Predictable According to What Model? · Ada Research</title><style>' + css + '</style><main><nav><a href="qfep-introduction.html">Previous hall</a><a href="qfep-e-term.html">Next hall</a><a href="/museum-progress?sequence=qfeplaboratory">Museum progress</a></nav>' + body + '</main></html>', encoding="utf-8")
assets = ["qfep-f-term.html", "qfep-f-term-verification.json"]
(E / "publish-targets.json").write_text(json.dumps(["possible-bodies/" + a for a in assets], indent=2), encoding="utf-8")
(E / "publish-hashes.json").write_text(json.dumps({"possible-bodies/" + a: hashlib.sha256((O / a).read_bytes()).hexdigest() for a in assets}, indent=2), encoding="utf-8")
print(json.dumps(verification))
