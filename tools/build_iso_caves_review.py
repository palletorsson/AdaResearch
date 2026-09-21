from pathlib import Path
import hashlib, json, re, shutil, markdown

R = Path.cwd()
O = R / "doc/research/possible-bodies"
E = R / "doc/space/iso-caves-2026-09-15"
run = R / "ada_run/iso-caves-review-2026-09-15"
M = "ISO_Caves"
r = json.loads((run / "run.json").read_text(encoding="utf-8"))
assert r["exit"] == 0 and r["sources_unchanged"] and r["original_hand_unchanged"]
assert all(hashlib.sha256((R / p).read_bytes()).hexdigest() == h for p, h in r["source_sha256"].items())

css = re.search(r"<style>(.*?)</style>", (O / "iso-introduction.html").read_text(encoding="utf-8"), re.S)[1]
assets = ["iso-learning-arc.md", "iso-learning-arc.html", "spine-iteration.md", "spine-iteration.html"]
figures = ""
for name in ["entrance", "enclosure", "overview"]:
    out = f"iso-caves-{name}.png"
    shutil.copyfile(run / M / f"{name}.png", O / out)
    assets.append(out)
    figures += f'<figure><img src="{out}" alt="Actual Godot ISO Caves hall: {name}" loading="lazy"><figcaption>Actual Godot museum capture · {name}. Desktop review; headset review remains pending.</figcaption></figure>'

links = []
for kind in ["final", "technical", "critical"]:
    for before in [False, True]:
        p = (E / "before" if before else R) / f"commons/maps/{M}/{kind}.md"
        if p.exists():
            out = "iso-caves-" + ("previous-" if before else "current-") + kind + ".md"
            shutil.copyfile(p, O / out); assets.append(out)
            links.append(f'<a href="{out}">{"Previous" if before else "Current"} {kind}</a>')

for src, name in [(run / "run.json", "receipt.json"), (run / M / "probe.json", "runtime-report.json"), (run / M / "engine.log", "engine.log")]:
    shutil.copyfile(src, E / name)
shutil.copyfile(run / "run.json", O / "iso-caves-verification.json"); assets.append("iso-caves-verification.json")

book_text = (R / f"commons/maps/{M}/final.md").read_text(encoding="utf-8")
body = (
    '<p class="date">Isosurfaces · Hall 7 · 15 September 2026</p>'
    '<h1>On the enclosing side</h1>'
    '<p class="lead">A portal is an opening in a surface. A cave asks whether that opening remains a route when the surface surrounds you.</p>'
    '<p>ISO_Caves preserves the original cave, portal, marching-cave, rhizome and metaball specimens in one longer hall. The two primary fields are the comparison: INSIDE_CAVE encloses a body in a sampled volume; PORTAL_LANDSCAPE joins terrain and rings into one field. The desk lets you change plumb, octaves, portal count and burial, then HOLD the earlier boundary behind the live one.</p>'
    '<p><a href="/necklace/thread?map=ISO_Caves&amp;role=primary">Primary artifacts and book</a> · <a href="iso-learning-arc.html">Learning arc</a></p>'
    '<details><summary>Read the book passage</summary>' + markdown.markdown(book_text, extensions=["fenced_code"]) + '</details>' + figures +
    '<h2>An opening is not yet a route</h2>'
    '<p>The controls make two kinds of change visible. Octaves and plumb alter the enclosing field; portal count and burial alter how an opening meets it. A visible hole can close by crowding or sink into the terrain. A clean sample is therefore a claim about a boundary, not proof that a body can pass.</p>'
    '<p>The retained secondary specimens keep the question plural: cave, rhizome and metaball each give volume a different temperament. The small transparent readout states the current parameters while the fields remain visible through it.</p>'
    f'<p>{r["checks"]} rendered desktop checks passed, including real pointer presses, field rebuilds, held-boundary preservation, rule-card reading, duplicate-token checks and side-aisle support. These checks do not certify a human headset session or Quest performance.</p>'
    '<p><a href="iso-caves-verification.json">Runtime receipt</a></p><p>' + " · ".join(links) + '</p>'
    '<p>Next: <strong>ISO_Metaballs</strong> — when several bodies share one field, where does one end?</p>'
)
(O / "iso-caves.html").write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>On the enclosing side · Ada Research</title><style>' + css + '</style><main><nav><a href="iso-introduction.html">Introduction</a><a href="iso-learning-arc.html">Learning arc</a><a href="/museum-progress?sequence=isosurfaces">Museum progress</a></nav>' + body + '</main></html>', encoding="utf-8")
assets.append("iso-caves.html")
manifest = ["possible-bodies/" + a for a in assets]
(E / "publish-targets.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
(E / "publish-hashes.json").write_text(json.dumps({a: hashlib.sha256((R / "doc/research" / a).read_bytes()).hexdigest() for a in manifest}, indent=2), encoding="utf-8")
print("Built", len(assets), "verified ISO_Caves review assets.")
