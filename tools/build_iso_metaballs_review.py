from pathlib import Path
import hashlib
import json
import re
import shutil

import markdown


R = Path.cwd()
O = R / "doc/research/possible-bodies"
E = R / "doc/space/iso-metaballs-2026-09-15"
run = R / "ada_run/iso-metaballs-review-2026-09-15"
M = "ISO_Metaballs"

r = json.loads((run / "run.json").read_text(encoding="utf-8"))
assert r["exit"] == 0 and r["sources_unchanged"] and r["original_hand_unchanged"]
assert all(
    hashlib.sha256((R / p).read_bytes()).hexdigest() == h
    for p, h in r["source_sha256"].items()
)

css_match = re.search(
    r"<style>(.*?)</style>",
    (O / "iso-introduction.html").read_text(encoding="utf-8"),
    re.S,
)
assert css_match
css = css_match[1]

assets = ["iso-learning-arc.md", "iso-learning-arc.html"]
figures = ""
for name in ["entrance", "overview"]:
    out = f"iso-metaballs-{name}.png"
    shutil.copyfile(run / M / f"{name}.png", O / out)
    assets.append(out)
    figures += (
        f'<figure><img src="{out}" alt="Actual Godot ISO Metaballs hall: {name}" '
        'loading="lazy"><figcaption>Actual Godot museum capture · '
        f'{name}. Desktop review; headset review remains pending.</figcaption></figure>'
    )

links = []
for kind in ["final", "technical", "critical"]:
    for before in [False, True]:
        p = (E / "before" if before else R) / f"commons/maps/{M}/{kind}.md"
        if p.exists():
            out = "iso-metaballs-" + ("previous-" if before else "current-") + kind + ".md"
            shutil.copyfile(p, O / out)
            assets.append(out)
            links.append(
                f'<a href="{out}">'
                f'{"Previous" if before else "Current"} {kind}</a>'
            )

for src, name in [
    (run / "run.json", "receipt.json"),
    (run / M / "probe.json", "runtime-report.json"),
    (run / M / "engine.log", "engine.log"),
]:
    shutil.copyfile(src, E / name)
shutil.copyfile(run / "run.json", O / "iso-metaballs-verification.json")
assets.append("iso-metaballs-verification.json")

book_text = (R / f"commons/maps/{M}/final.md").read_text(encoding="utf-8")
body = (
    '<p class="date">Isosurfaces · Hall 12 · 15 September 2026</p>'
    '<h1>A neck between sources</h1>'
    '<p class="lead">When several influences enter one field, a body appears at their shared threshold. The question is where that body begins.</p>'
    '<p>ISO_Metaballs keeps the original four specimens and gives them room to be compared. The primary field, <strong>metaball_world</strong>, is a live sum of ten sources. A small desk exposes two causes that are easy to confuse: EMPLACE changes where the sources gather, while KERNEL changes how each source falls away. The field changes without changing its vocabulary.</p>'
    '<p><a href="/necklace/thread?map=ISO_Metaballs&amp;role=primary">Primary artifact and book</a> · <a href="iso-learning-arc.html">Learning arc</a></p>'
    '<details><summary>Read the book passage</summary>'
    + markdown.markdown(book_text, extensions=["fenced_code"])
    + "</details>"
    + figures
    + '<h2>A body can be a relation</h2>'
    '<p>Cycle EMPLACE through column, ring, pair, shell and scatter. Then cycle KERNEL through inverse square, Wyvill, Gaussian and cone. The visible surface is the isovalue crossing, not a stored skin. Ten sources can therefore read as a column, a necklace, a shell or a scattered weather system while the generator remains the same.</p>'
    '<p>HOLD copies the current boundary and carries it into the room. The held surface is a memory of one threshold beside the live field. RULE opens the short proposition: a field is a sum, not a census. The secondary raymarched and Nakama examples keep other renderings present, so the primary does not pretend to be the only way to make an isosurface.</p>'
    '<p>The museum wall makes the distinction legible. The preserved source map remains archived at its former scale and offset; the longer hall is a staging layer around it. One primary artifact gives the hall a sentence, while the retained specimens give that sentence friction.</p>'
    f'<p>{r["checks"]} rendered desktop checks passed, including real pointer presses, arrangement and kernel changes, held-surface preservation, rule-card reading, reset, duplicate-token checks and source-map integrity. These checks do not certify a human headset session or Quest performance.</p>'
    '<p><a href="iso-metaballs-verification.json">Runtime receipt</a></p><p>'
    + " · ".join(links)
    + '</p><p>Next: <strong>Boolean_Verbs</strong> — when surfaces meet, what can their operations say?</p>'
)

(O / "iso-metaballs.html").write_text(
    '<!doctype html><html lang="en"><meta charset="utf-8">'
    '<meta name="viewport" content="width=device-width,initial-scale=1">'
    '<title>A neck between sources · Ada Research</title><style>'
    + css
    + '</style><main><nav><a href="iso-introduction.html">Introduction</a>'
    '<a href="iso-learning-arc.html">Learning arc</a>'
    '<a href="/museum-progress?sequence=isosurfaces">Museum progress</a></nav>'
    + body
    + "</main></html>",
    encoding="utf-8",
)
assets.append("iso-metaballs.html")
manifest = ["possible-bodies/" + a for a in assets]
(E / "publish-targets.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
(E / "publish-hashes.json").write_text(
    json.dumps(
        {
            a: hashlib.sha256((R / "doc/research" / a).read_bytes()).hexdigest()
            for a in manifest
        },
        indent=2,
    ),
    encoding="utf-8",
)
print("Built", len(assets), "verified ISO_Metaballs review assets.")
