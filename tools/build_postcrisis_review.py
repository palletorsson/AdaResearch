"""Build the closing-sequence reading room and check its real content chain.

Read-only with respect to game content. Regenerates the review HTML and evidence
JSON from the authored encounter notes, maps, roles, scripts and both EM plans.
Run from any directory: python tools/build_postcrisis_review.py
"""
from __future__ import annotations

import hashlib
import html
import json
import re
import textwrap
from pathlib import Path

import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "doc/research/possible-bodies"
NOTES = OUT / "postcrisis-pass.json"
SEQ = ROOT / "commons/maps/sequences/postfoundationscrisis.json"


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def excerpt(hall):
    ref = hall["excerpt"]
    text = (ROOT / ref["file"]).read_text(encoding="utf-8")
    start = text.index(ref["start"])
    stop = text.index(ref["end"], start) + len(ref["end"])
    return textwrap.dedent(text[start:stop]).replace("\t", "    ")


def code_passage(hall):
    return "The source makes the operation inspectable:\n\n```gdscript\n" + excerpt(hall) + "\n```\n\n" + hall["explanation"]


def registry():
    entries = {}
    for p in sorted((ROOT / "commons/artifacts/registry").glob("*.json")):
        data = read_json(p).get("artifacts", {})
        if isinstance(data, dict):
            entries.update(data)
    return entries


def token_name(cell):
    return str(cell).strip().split("#", 1)[0].split(":", 1)[0]


def inspect(halls):
    roles = read_json(ROOT / "commons/data/artifact_roles.json")
    declaration = read_json(ROOT / "commons/data/map_authored.json")
    sequence = read_json(SEQ)["sequences"]["postfoundationscrisis"]
    entries = registry()
    plans = {name: read_json(ROOT / name) for name in ["commons/data/museum/em_plan.json", "ada_run/em_plan.json"]}
    expected = sequence["maps"]
    failures = []
    if [h["map"] for h in halls] != expected:
        failures.append("Encounter order differs from sequence")
    if declaration["postfoundationscrisis"] != expected:
        failures.append("Museum declaration differs from sequence")
    report = {"sequence": "postfoundationscrisis", "reviewed": "2026-09-15", "scope": "Source and data verification; headset reach, appearance and performance not measured", "maps": [], "failures": failures, "placement_warnings": []}
    for name, plan in plans.items():
        actual = [p.get("map") for p in plan["plans"] if p.get("sequence") == "postfoundationscrisis"]
        if actual != expected:
            failures.append(f"{name}: hall order differs from sequence")
    for h in halls:
        m = h["map"]
        path = ROOT / "commons/maps" / m
        data = read_json(path / "map_data.json")
        dims = data["map_info"]["dimensions"]
        placements = [(x, z, str(cell)) for z, row in enumerate(data["layers"]["interactables"]) for x, cell in enumerate(row) if str(cell).strip()]
        tokens = [token_name(c) for _, _, c in placements]
        primary = {t for t, role in roles["roles"][m].items() if role == "primary"}
        book = (path / "final.md").read_text(encoding="utf-8")
        anchors = set(re.findall(r"<!--\s*@([\w]+)\s*-->", book))
        errors = []
        for name, layer in data["layers"].items():
            if isinstance(layer, list) and (len(layer) != dims["depth"] or any(not isinstance(row, list) or len(row) != dims["width"] for row in layer)):
                errors.append(f"{name}: inconsistent row dimensions")
        if anchors != primary or h["primary"] not in primary:
            errors.append("Book anchors differ from primary roles")
        if set(roles["order"][m]["primary"]) != primary:
            errors.append("Tutorial primary order differs from roles")
        if not primary.issubset(tokens):
            errors.append("Primary artifact missing from map")
        for t in tokens:
            scene = entries.get(t, {}).get("scene", "")
            if not scene or not (ROOT / scene.removeprefix("res://")).is_file():
                errors.append(f"{t}: missing registry scene")
        group = next((g for g in sequence.get("artifact_groups", []) if g["map"] == m), {})
        if set(group.get("artifacts", [])) != set(tokens):
            errors.append("Sequence artifact group differs from placed artifacts")
        code = excerpt(h)
        for name in ["final.md", "tutorial.md", "technical.md"]:
            if code not in (path / name).read_text(encoding="utf-8"):
                errors.append(f"{name}: missing current source excerpt")
        for name, plan in plans.items():
            rows = [p for p in plan["plans"] if p.get("map") == m and p.get("sequence") == "postfoundationscrisis"]
            if len(rows) != 1:
                errors.append(f"{name}: expected one hall")
                continue
            row = rows[0]
            # Check counts as well as names: situated_readout has FOUR instances.
            if sorted(a["token"] for a in row["artifacts"]) != sorted(tokens):
                errors.append(f"{name}: artifact instances differ from map")
            tile = row["tile"]
            if len(tile) != row["h"] or any(len(r) != row["room"]["w"] for r in tile):
                errors.append(f"{name}: inconsistent museum tile dimensions")
            for a in row["artifacts"]:
                x, z = a["tile_cell"]
                if not (0 <= z < len(tile) and 0 <= x < len(tile[0])):
                    errors.append(f"{name}: artifact outside hall: {a['token']}")
                if isinstance(a.get("scale"), (int, float)) and a["scale"] > 10:
                    report["placement_warnings"].append(f"{name}: {m}/{a['token']} carries scale={a['scale']}. Inspect legacy token parsing against the live object before restaging this hall.")
        files = [path / n for n in ["map_data.json", "final.md", "tutorial.md", "technical.md", "critical.md"]] + [ROOT / h["excerpt"]["file"]]
        item = {"map": m, "primary": sorted(primary), "artifact_instances": len(tokens), "dimensions": dims, "errors": errors, "sha256": {str(f.relative_to(ROOT)).replace('\\', '/'): hashlib.sha256(f.read_bytes()).hexdigest() for f in files}, "next_improvement": h["next_test"]}
        report["maps"].append(item)
        failures.extend(f"{m}: {e}" for e in errors)
    report["artifact_instances"] = sum(m["artifact_instances"] for m in report["maps"])
    report["halls_checked"] = len(report["maps"])
    report["runtime_loads"] = []
    for m, wanted in [("SpeculativeComputation_Situated_Computation", "situated_readout"), ("AdvancedLaboratory_Lab_Equipment_Simulation", "MolecularDesigner")]:
        folder = ROOT / "ada_run/encounter_pilot" / m
        if not (folder / "report.json").exists():
            continue
        runtime = read_json(folder / "report.json")
        manifest = read_json(folder / "source_manifest.json")
        changed = [f for f, digest in manifest.get("sources", {}).items() if not (ROOT / f).exists() or hashlib.sha256((ROOT / f).read_bytes()).hexdigest() != digest]
        # The existing probe fingerprints its private bake input, then updates
        # that same file while loading. Report this, rather than mistaking its
        # own output for an implementation change or concealing the mismatch.
        generated_bake = (folder / "em_bake.json").relative_to(ROOT).as_posix()
        changed_inputs = [f for f in changed if f.replace('\\', '/') != generated_bake]
        log = (folder / "stdout.log").read_text(encoding="utf-8", errors="replace").splitlines()
        report["runtime_loads"].append({"map": m, "probe_passed": runtime.get("passed"), "source_manifest_current": not changed,
            "implementation_and_map_inputs_current": not changed_inputs, "changed_manifest_files": changed,
            "manifest_note": "The probe updates its own private em_bake.json during loading; all other fingerprinted inputs are compared separately.",
            "primary_instances_loaded": sum(a["token"] == wanted for a in runtime.get("artifacts", [])),
            "scope": "Headless load and primary presence; no traversal or VR acceptance test",
            "errors": sorted(set(line for line in log if line.startswith("ERROR:"))),
            "loading_warnings": [line for line in log if line.startswith("WARNING: [em-art]")],
            "evidence": str(folder.relative_to(ROOT)).replace('\\', '/')})
    return report


def floor_svg(hall, plan):
    """Plan diagram, explicitly distinct from an in-game screenshot."""
    row = next(p for p in plan["plans"] if p.get("map") == hall["map"] and p.get("sequence") == "postfoundationscrisis")
    tile = row["tile"]
    size = 18
    shapes = []
    for z, line in enumerate(tile):
        for x, value in enumerate(line):
            color = {"0": "#080d16", "1": "#263749", "4": "#8a999e"}.get(str(value), "#536b72")
            shapes.append(f'<rect x="{x*size}" y="{z*size}" width="17" height="17" fill="{color}"/>')
    for a in row["artifacts"]:
        x, z = a["tile_cell"]
        color = "#f3c274" if a["token"] == hall["primary"] else "#b193d6"
        shapes.append(f'<circle cx="{x*size+8}" cy="{z*size+8}" r="5" fill="{color}"><title>{html.escape(a["token"])}</title></circle>')
    return f'<svg viewBox="0 0 {len(tile[0])*size} {len(tile)*size}" role="img" aria-label="Museum floor plan for {html.escape(hall["title"])}">' + ''.join(shapes) + '</svg>'


def build():
    notes = read_json(NOTES)
    halls = notes["halls"]
    report = inspect(halls)
    (OUT / "postcrisis-verification.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    plan = read_json(ROOT / "commons/data/museum/em_plan.json")
    nav = []
    sections = []
    for i, h in enumerate(halls, 1):
        m = h["map"]
        esc = html.escape
        nav.append(f'<a href="#{m}"><b>{i:02}</b> {esc(h["title"])}</a>')
        book = markdown.markdown((ROOT / "commons/maps" / m / "final.md").read_text(encoding="utf-8"), extensions=["fenced_code", "tables"])
        sections.append(f'''<section id="{m}" data-hall><div class="eyebrow">{i:02} / 08 · {esc(h['title'])}</div>
<h2>{esc(h['question'])}</h2><p class="inherit">{esc(h['inherit'])}</p>
<div class="encounter"><div><h3>Try this encounter</h3><p>{esc(h['action'])}</p><p>{esc(h['observation'])}</p>
<p class="links"><a href="/necklace/thread?map={m}&amp;role=primary">Primary artifact + book ↗</a> · <a href="/museum-progress?sequence=postfoundationscrisis&amp;room={m}">Room progress ↗</a></p><p class="token">{esc(h['primary'])}</p></div>
<figure>{floor_svg(h,plan)}<figcaption>Current museum plan · gold = primary · violet = supporting artifacts. Diagram, not a game capture.</figcaption></figure></div>
<details class="book"><summary>Read this hall’s book passage</summary><div class="prose">{book}</div></details>
<details><summary>The next improvement to test</summary><p>{esc(h['next_test'])}</p></details>
<p class="carry">→ {esc(h['carry'])}</p></section>''')
    state = "Content chain checks passed" if not report["failures"] else f"{len(report['failures'])} data issues to inspect"
    output = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>What do we build with the limits? · Ada Research</title><style>
:root{color-scheme:dark;--ink:#f3eee7;--muted:#b6c1c8;--edge:#384650;--gold:#f3c274;--bg:#111923}*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:1.5rem}body{margin:0;background:var(--bg);color:var(--ink);font:17px/1.7 system-ui,sans-serif}a{color:var(--gold);text-underline-offset:4px}a:focus-visible,summary:focus-visible,button:focus-visible{outline:3px solid var(--gold);outline-offset:5px}main{max-width:1120px;margin:auto;padding:45px 28px 90px}header{padding:28px 0 42px;border-bottom:1px solid var(--edge)}.eyebrow{text-transform:uppercase;letter-spacing:.13em;font-size:12px;color:var(--gold)}h1{font:clamp(2.7rem,6vw,5rem)/1.08 Georgia,serif;max-width:900px;margin:22px 0}h2{font:clamp(1.9rem,4vw,2.8rem)/1.2 Georgia,serif;margin:15px 0}h3{font-size:1rem;margin:0 0 10px}.lead{max-width:800px;font-size:21px;color:#dce2e2}.status{display:flex;flex-wrap:wrap;gap:10px;margin:25px 0}.status span{padding:5px 13px;border:1px solid var(--edge);border-radius:30px;font-size:13px}.route{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin:30px 0}.route a{display:block;background:#1b2732;padding:15px;text-decoration:none}.route b{display:block;color:var(--muted);font-size:12px}.route a:hover{background:#2a3a45}button{background:transparent;color:var(--ink);border:1px solid var(--edge);padding:10px 16px;border-radius:5px;cursor:pointer;font:inherit}section{border-bottom:1px solid var(--edge);padding:48px 0;scroll-margin-top:18px}.inherit{color:var(--muted);max-width:800px}.encounter{display:grid;grid-template-columns:1.4fr 1fr;gap:45px;align-items:center;margin:28px 0}figure{margin:0;background:#0b121b;padding:18px;border-radius:8px}figure svg{width:100%;max-height:290px}figcaption{font-size:12px;line-height:1.5;color:var(--muted);margin-top:14px}.links{font-size:14px}.token{overflow-wrap:anywhere;font:13px monospace;color:#bd9adf}details{border:1px solid var(--edge);border-radius:6px;padding:17px 22px;margin-top:14px}summary{cursor:pointer;font-weight:600}details>p{max-width:780px}.prose{max-width:780px;margin:28px auto;font:20px/1.8 Georgia,serif}.prose h1{font-size:35px}.prose pre{font:13px/1.65 ui-monospace,monospace;background:#080e16;padding:20px;overflow:auto;border-left:3px solid var(--gold)}.prose code{font-size:.82em}.carry{color:var(--gold);font-size:15px;margin-top:28px}.foot{color:var(--muted);font-size:14px;margin-top:35px}.issues{color:#ffbdab}@media(max-width:750px){main{padding:20px 18px 60px}.route{grid-template-columns:repeat(2,1fr)}.encounter{grid-template-columns:1fr;gap:20px}figure svg{max-height:220px}.prose{font-size:18px}details{padding:14px}.lead{font-size:18px}}@media(prefers-reduced-motion:reduce){html{scroll-behavior:auto}}
</style></head><body><main><header><div class="eyebrow">Ada Research · closing the first pass · 15 September 2026</div><h1>What do we build<br>with the limits?</h1>'''
    output += f'<p class="lead">{html.escape(notes["premise"])}</p><div class="status"><span>8 halls in the closing sequence</span><span>{report["artifact_instances"]} artifact placements retained</span><span>Source-grounded book + tutorial</span><span>Headset walk pending</span></div>'
    output += '<p>Situated computation and the assembly laboratory have been restored to the museum declaration. The sequence now includes the same eight halls as the curriculum. Earlier design proposals are preserved in the project archive.</p></header><nav class="route" aria-label="Hall progression">' + ''.join(nav) + '</nav><button id="reading" type="button" aria-pressed="false">Open all book passages</button>' + ''.join(sections)
    output += f'<div class="foot"><p>{html.escape(state)} · <a href="postcrisis-verification.json">Inspect source and data evidence</a> · <a href="/museum-progress?sequence=postfoundationscrisis">Sequence progress</a></p><p>Each passage names an existing primary artifact. Supporting work remains in place. The diagrams describe the museum plan; they do not establish headset readability, collision or comfortable reach. Those need a walk.</p><p>Both restored halls loaded their primary artifacts in Godot. The probes reported shared startup errors and delays while building decorative objects. Legacy tutorial-table scale values also need a placement review. These remain open in the evidence record.</p></div>'
    if report["failures"]:
        output += '<ul class="issues">' + ''.join('<li>'+html.escape(f)+'</li>' for f in report['failures'])+'</ul>'
    output += '''</main><script>const button=document.getElementById('reading');button.addEventListener('click',()=>{const open=button.getAttribute('aria-pressed')!=='true';document.querySelectorAll('details.book').forEach(x=>x.open=open);button.setAttribute('aria-pressed',String(open));button.textContent=open?'Close all book passages':'Open all book passages';});</script></body></html>'''
    (OUT / "postcrisis-applied-limits.html").write_text(output, encoding="utf-8")
    print(json.dumps({"halls": len(halls), "artifact_instances": report["artifact_instances"], "failures": report["failures"]}))
    return report


if __name__ == "__main__":
    raise SystemExit(1 if build()["failures"] else 0)
