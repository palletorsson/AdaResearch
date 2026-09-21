from pathlib import Path
import hashlib, json, re, subprocess
import markdown

R = Path.cwd(); M = "QFEP_Introduction"; MAP = R / "commons/maps" / M
O = R / "doc/research/possible-bodies"; E = R / "doc/space/qfep-introduction-2026-09-15"; E.mkdir(parents=True, exist_ok=True)
data = json.loads((MAP / "map_data.json").read_text(encoding="utf-8"))
roles = json.loads((R / "commons/data/artifact_roles.json").read_text(encoding="utf-8"))["roles"][M]
tokens = [x.strip().split(":", 1)[0].split("#", 1)[0] for row in data["layers"]["interactables"] for x in row if x.strip()]
checks = {
    "map_dimensions": data["map_info"]["dimensions"] == {"width": 13, "depth": 12, "max_height": 3},
    "eleven_placements": len(tokens) == 11 and len(set(tokens)) == 11,
    "primary_focus": roles.get("qfep_balance_workbench") == "primary" and sum(v == "primary" for v in roles.values()) == 1,
    "registers_present": all((MAP / n).exists() for n in ["final.md", "tutorial.md", "technical.md", "critical.md"]),
    "grid_structure": len(data["layers"]["structure"]) == 12 and len(data["layers"]["structure"][0]) == 13,
}
try:
    checks["registry_resolution"] = subprocess.run(["python", "tools/check_map_tokens.py", "--json"], capture_output=True, text=True, check=False).returncode == 0
except OSError:
    checks["registry_resolution"] = False
verification = {"hall": M, "date": "2026-09-15", "checks": sum(checks.values()), "total_checks": len(checks), "failures": [k for k, v in checks.items() if not v], "checks_detail": checks, "tokens": tokens, "primary_artifacts": ["qfep_balance_workbench"], "source_sha256": {str((MAP / n).relative_to(R)): hashlib.sha256((MAP / n).read_bytes()).hexdigest() for n in ["map_data.json", "final.md", "tutorial.md", "technical.md", "critical.md"]}}
(E / "verification.json").write_text(json.dumps(verification, indent=2), encoding="utf-8")
(O / "qfep-introduction-verification.json").write_text(json.dumps(verification, indent=2), encoding="utf-8")
css = re.search(r"<style>(.*?)</style>", (O / "iso-introduction.html").read_text(encoding="utf-8"), re.S)[1]
book = markdown.markdown((MAP / "final.md").read_text(encoding="utf-8"), extensions=["fenced_code"])
diagram = '''<figure><svg viewBox="0 0 900 280" role="img" aria-labelledby="q-title q-desc" xmlns="http://www.w3.org/2000/svg"><title id="q-title">Four terms, one balance</title><desc id="q-desc">Four weighted terms feed a central QFEP result.</desc><rect width="900" height="280" rx="18" fill="#121827"/><g font-family="system-ui,sans-serif" text-anchor="middle"><path d="M160 78L450 140M370 78L450 140M530 78L450 140M740 78L450 140" stroke="#8fc7d5" stroke-width="5"/><circle cx="160" cy="72" r="40" fill="#e9b86f"/><circle cx="370" cy="72" r="40" fill="#77b9d6"/><circle cx="530" cy="72" r="40" fill="#d887b7"/><circle cx="740" cy="72" r="40" fill="#8ec99b"/><rect x="270" y="145" width="360" height="70" rx="14" fill="#f0d48c"/><g fill="#121827" font-size="18"><text x="160" y="79">F</text><text x="370" y="79">E</text><text x="530" y="79">λ</text><text x="740" y="79">φ</text><text x="450" y="176">QFE = F − λE(S) + φΔE(S,t)</text><text x="450" y="260" fill="#f5f0ff" font-size="17">change one term; watch the others keep their meaning</text></g></g></svg><figcaption>The workbench makes compensation visible: different arrangements can approach the same result.</figcaption></figure>'''
score = f'<p>{verification["checks"]}/{verification["total_checks"]} static checks passed. <a href="qfep-introduction-verification.json">Verification record</a></p>'
body = '<p class="date">QFEP laboratory · Introduction · 15 September 2026</p><h1>Four Terms, One Balance</h1><p class="lead">The formula returns as an instrument. Pick up its terms, change their weights, and notice what a single result cannot tell you.</p><p><a href="/necklace/thread?map=QFEP_Introduction&amp;role=primary">Primary artifact and book</a> · <a href="/museum-progress?sequence=qfeplaboratory">Museum progress</a></p>' + diagram + '<details><summary>Read the book passage</summary>' + book + '</details><h2>The first instrument</h2><p>The balance workbench is the sole primary artifact. The colored term spheres, sliders, formula stand, and science screen remain secondary supports: they give the workbench a vocabulary without competing with its experiment. Change one contribution, then compensate with another. The result can return while the configuration—and the story it tells—has changed.</p><p>The next hall, <a href="qfep-f-term.html"><strong>QFEP_F_Term</strong></a>, isolates F, moving from a complete expression to one forceful component.</p>' + score
(O / "qfep-introduction.html").write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Four Terms, One Balance · Ada Research</title><style>' + css + '</style><main><nav><a href="foundations-crisis-synthesis.html">Previous sequence</a><a href="qfep-f-term.html">Next hall</a><a href="/museum-progress?sequence=qfeplaboratory">Museum progress</a></nav>' + body + '</main></html>', encoding="utf-8")
assets = ["qfep-introduction.html", "qfep-introduction-verification.json"]
(E / "publish-targets.json").write_text(json.dumps(["possible-bodies/" + a for a in assets], indent=2), encoding="utf-8")
(E / "publish-hashes.json").write_text(json.dumps({"possible-bodies/" + a: hashlib.sha256((O / a).read_bytes()).hexdigest() for a in assets}, indent=2), encoding="utf-8")
print(json.dumps(verification))
