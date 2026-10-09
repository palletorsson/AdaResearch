"""Freeze a coherent opening review and the exact runnable study downloads."""
from pathlib import Path
import difflib, hashlib, html, json, re, shutil, subprocess, zipfile
import markdown
from bs4 import BeautifulSoup

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
read = lambda p: p.read_text(encoding="utf-8-sig")
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
write = lambda p, text: p.write_text(text.strip() + "\n", encoding="utf-8")
chapter_names = ["Point_Zero", "Point_One", "Point_Coordinates"]
point_one = ROOT / "commons/maps/Point_One"
study = ROOT / "doc/book/studies/point-one"

assert read(point_one / "final.md") == read(OUT / "before/commons/maps/Point_One/final.md")
assert read(ROOT / "commons/maps/Point_Coordinates/final.md") == read(OUT / "before/commons/maps/Point_Coordinates/final.md")
assert read(point_one / "tutorial.md").replace("../../../doc/book/studies/point-one/README.md", "README.md").replace("../../../doc/book/studies/point-one/CONSTRUCTION.md", "CONSTRUCTION.md").replace("[Point Coordinates](../Point_Coordinates/tutorial.md)", "Point Coordinates (the next study, supplied separately)") == read(study / "TUTORIAL.md")
for script in ["position", "visible", "solid"]:
    assert read(study / (script + ".gd")).strip() in read(point_one / "tutorial.md")
for name in ["Point_One", "Point_Coordinates"]:
    current = json.loads(read(ROOT / f"commons/maps/{name}/map_data.json"))
    before = json.loads(read(OUT / f"before/commons/maps/{name}/map_data.json"))
    assert current["layers"] == before["layers"], "This task must not change hall geometry or placements"
    assert current["map_info"]["metadata"]["n_artifacts"] == sum(bool(t.strip()) for row in current["layers"]["interactables"] for t in row)

kit_files = {
    "point-zero": ["project.godot", "base.tscn", "hello_world.tscn", "hello_world.gd", "README.md", "TUTORIAL.md"],
    "point-one": ["project.godot", "base.tscn", "study.tscn", "position.gd", "visible.gd", "solid.gd", "contact_probe.gd", "README.md", "TUTORIAL.md", "CONSTRUCTION.md"],
    "point-coordinates": ["project.godot", "base.tscn", "coordinates.tscn", "points.gd", "README.md", "TUTORIAL.md"],
}
for kit, files in kit_files.items():
    with zipfile.ZipFile(OUT / (kit + "-study.zip"), "w", zipfile.ZIP_DEFLATED) as archive:
        for filename in files:
            src = ROOT / "doc/book/studies" / kit / filename
            dest = OUT / kit / filename
            dest.parent.mkdir(exist_ok=True)
            shutil.copy2(src, dest)
            archive.write(src, kit + "/" + filename)
    with zipfile.ZipFile(OUT / (kit + "-study.zip")) as archive:
        assert archive.testzip() is None
        assert all(archive.read(kit + "/" + f) == (OUT / kit / f).read_bytes() for f in files)

decisions = '''# One opening, three lessons

30 September 2026. This pass responds to the review of the older, combined Point One files. The current local manuscript had already been separated; the review's cited commit did not contain that split.

| Chapter | Encounter manuscript | Making companion |
| --- | --- | --- |
| Point Zero | Late arrival, a room already running, the counter and folding frames | _ready begins once; _process repeats; a retained value counts |
| Point One | An absent position, a visible sphere, a physical boundary, the removable sun and the pedestal sphere | Three complete scripts; change the marker and collision independently |
| Point Coordinates | A held point, WORLD/LOCAL, the frame in its basin and a target with room to arrive | Borrow the museum's pickup; change components and compare reference frames; leave with A and B |

## Applied

- Kept the current **A body in the light** manuscript and the Coordinates manuscript unchanged. The older combined opening is preserved as a version reference.
- Rewrote the Point One tutorial around the exact supplied project, root, nodes and complete scripts. point_position names the value; marker names the displayed node.
- Supplied moving contact probes. Their actual collision result stops them, so an enlarged invisible boundary can be seen resisting a body before that body reaches the surface.
- Named the probe, camera, floor and light as supplied equipment. Their implementation is available without becoming this lesson's required vocabulary.
- Updated the study README and construction reference, intent, encounter reference, technical account, placed inventories, map documentation, student toolbox and lineage note. Added a Point One file guide and corrected the scope note above its earlier critical draft.
- Distinguished target proximity from object identity in Coordinates. Identified the desktop study's RGB guides separately from the museum's pink, grey and black frame.

The map edits in this pass correct descriptions and artifact counts only. Both halls retain their current geometry and placed artifacts. The tutorial's contact helper belongs to the portable study, not to the museum.

## What remains

The Coordinates desktop kit contains no XR player. Pickup practice currently requires the already configured Ada museum project. A portable XR starter is still needed before the whole holding exercise can be offered as an independent download.

The museum's sun switch is a short source reading here; the portable Point One kit does not contain that switch. The main text can follow a wider encounter than the making exercise reconstructs.

## Version to review

Use opening-review.zip for the next external review. It freezes the current three manuscripts, their companion documents, map snapshots, lineage and the three study kits. It records the base commit and hashes of the supplied files. It is a working-copy capture, not a claim that these changes have been pushed to GitHub. Review the captured files rather than substituting the older combined Point One from the cited commit.

Godot 4.6 passed the contact comparisons, the tutorial's edits and pause/repeat behavior. The images show the standalone study. This pass did not retest the museum or a headset.
'''
write(OUT / "DECISIONS.md", decisions)

changed = []
diffs = []
for before in (OUT / "before").rglob("*"):
    if not before.is_file():
        continue
    rel = before.relative_to(OUT / "before")
    current = ROOT / rel
    if not current.is_file():
        continue
    if before.read_bytes() == current.read_bytes():
        continue
    changed.append(rel.as_posix())
    after = OUT / "after" / rel
    after.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(current, after)
    diffs.extend(difflib.unified_diff(read(before).splitlines(True), read(current).splitlines(True), fromfile="before/" + rel.as_posix(), tofile="after/" + rel.as_posix()))
for rel in ["commons/maps/Point_One/README.md", "doc/book/studies/point-one/contact_probe.gd"]:
    changed.append(rel)
    src = ROOT / rel
    dest = OUT / "after" / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest)
    diffs.extend(difflib.unified_diff([], read(src).splitlines(True), fromfile="/dev/null", tofile="after/" + rel))
write(OUT / "changes.diff", "".join(diffs))

sources = []
for name in chapter_names:
    folder = ROOT / "commons/maps" / name
    sources.extend(sorted(folder.glob("*.md")))
    sources.append(folder / "map_data.json")
sources.extend(ROOT / p for p in ["commons/maps/sequences/primitives.json", "doc/book/PRIMITIVES_LINEAGE.md", "doc/book/STUDENT_TOOLBOX.md", "doc/book/TUTORIAL_LINEAGE.md"])
for kit, files in kit_files.items():
    sources.extend(ROOT / "doc/book/studies" / kit / f for f in files)
manifest = {
    "captured_on": "2026-09-30",
    "basis": "working copy; manuscripts and supplied studies supersede the older combined Point One for this review",
    "base_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
    "files": {p.relative_to(ROOT).as_posix(): sha(p) for p in sources},
    "runtime_scope": "The portable Point One study was run. Hall snapshots are source references, not a complete standalone museum export.",
}
write(OUT / "source-manifest.json", json.dumps(manifest, indent=2))
review_readme = '''# Review the reorganized opening

Read commons/maps/Point_Zero/final.md, Point_One/final.md and Point_Coordinates/final.md in that order. Then read the matching tutorial.md and intent.md files. Preserve the difference between the encounter's inquiry and the operations chosen for a making lesson.

Point One is now A body in the light. The older Position Without Extension chapter was a combined opening; do not use it as the current manuscript. Point One/README.md identifies the current documents and earlier research. Historical research remains included as possible material, not as an installed-encounter claim.

The included study kits are independent Godot projects. Each has its own project.godot and README. The Point One contact probes are supplied equipment; compare the visible and physical radii. The Coordinates desktop study has no XR player. Its pickup exercise refers to the full Ada project.

Map files are source snapshots; this ZIP does not export the whole museum or all its artifact dependencies. Distinguish what the manuscript claims, what the supplied study performs, what source inspection supports and what would require a headset test. Do not infer a missing experience just from the absence of a portable XR player, or claim that a source-only review has tested that experience.

Read DECISIONS.md and source-manifest.json for version and verification scope. This is a working-copy capture; it does not certify the state of a remote GitHub branch.
'''
with zipfile.ZipFile(OUT / "opening-review.zip", "w", zipfile.ZIP_DEFLATED) as archive:
    archive.writestr("README.md", review_readme)
    archive.write(OUT / "DECISIONS.md", "DECISIONS.md")
    archive.write(OUT / "source-manifest.json", "source-manifest.json")
    archive.write(OUT / "native-verification.json", "native-verification.json")
    for name in ["contact-default.png", "contact-larger-boundary.png", "contact-smaller-boundary.png"]:
        archive.write(OUT / name, "images/" + name)
    for src in sources:
        archive.write(src, src.relative_to(ROOT).as_posix())
with zipfile.ZipFile(OUT / "opening-review.zip") as archive:
    assert archive.testzip() is None
    for path, digest in manifest["files"].items():
        assert hashlib.sha256(archive.read(path)).hexdigest() == digest

def render(text, prefix):
    text = re.sub(r"~~([^~\n]+)~~", r"<del>\1</del>", text)
    text = text.replace("../../../doc/book/studies/point-one/", "point-one/")
    text = text.replace("../../../doc/book/studies/point-coordinates/", "point-coordinates/")
    text = text.replace("../../../doc/book/studies/point-zero/", "point-zero/")
    text = text.replace("../Point_Coordinates/tutorial.md", "coordinates.html#making")
    soup = BeautifulSoup(markdown.markdown(text, extensions=["extra"]), "html.parser")
    for node in soup.find_all(id=True):
        node["id"] = prefix + "-" + node["id"]
    for a in soup.find_all("a", href=True):
        if a["href"].startswith("#"):
            a["href"] = "#" + prefix + "-" + a["href"][1:]
    return str(soup)

css = '''*{box-sizing:border-box}body{margin:0;background:#f6f3ed;color:#24232b;font:18px/1.7 Georgia,serif}main{max-width:1180px;margin:auto;padding:52px 26px}header{padding:16px 0 32px;border-bottom:1px solid #d7cfc4}h1{font-size:clamp(2.2rem,5vw,3.8rem);line-height:1.15;font-weight:400}h2{font-size:1.7rem;line-height:1.3;margin-top:2em}h3{line-height:1.3}p{margin:1em 0}a{color:#823957;text-underline-offset:3px}nav{display:flex;flex-wrap:wrap;gap:12px 24px;font:15px/1.5 system-ui}article{max-width:760px;margin:52px auto}pre{font:15px/1.6 Consolas,monospace;background:#24232b;color:#f4ebdf;padding:24px;border-radius:5px;overflow:auto}code{font-size:.86em}pre code{font-size:inherit}.eyebrow{font:12px/1.5 system-ui;letter-spacing:.12em;text-transform:uppercase;color:#823957}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.pair>div{min-width:0}.pair h1{font-size:2rem}.pair pre{font-size:12px}figure{margin:30px 0}img{width:100%;display:block}figcaption{font:14px/1.5 system-ui;margin-top:12px;color:#57505b}table{width:100%;border-collapse:collapse;font-size:.9em}th,td{padding:12px;text-align:left;vertical-align:top;border-bottom:1px solid #d7cfc4}details{border-top:1px solid #d7cfc4;padding:24px 0}summary{cursor:pointer}footer{font:14px/1.6 system-ui;border-top:1px solid #d7cfc4;padding:24px 0}blockquote{border-left:3px solid #ae748e;padding-left:20px}.callout{background:#ebe4db;padding:20px}.footnote{font-size:.82em}@media(max-width:800px){.pair{grid-template-columns:1fr}main{padding:24px 18px}pre{font-size:12px}}'''
nav = '<nav><a href="index.html">The reorganization</a><a href="reading.html#reading">Read Point One</a><a href="making.html#making">Make the point</a><a href="coordinates.html#making">Coordinates</a><a href="point-one-study.zip" download>Point One download</a><a href="opening-review.zip" download>Full opening review ZIP</a></nav>'

def page(title, body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><main>'+body+'</main></body></html>'

head = lambda label, title: '<header><p class="eyebrow">30 September 2026 · '+label+'</p><h1>'+title+'</h1>'+nav+'</header>'
images = '<section id="study"><h2>Make the separation visible</h2><p>Actual screenshots from the standalone Godot study. Only the collision radius changes between these two images.</p><figure><img src="contact-default.png" alt="Two pink feelers crossed their stations; the third stopped against the small white sphere."><figcaption>Matching surface and boundary. The right feeler stops at the sphere.</figcaption></figure><figure><img src="contact-larger-boundary.png" alt="The right pink feeler stops in empty space before the white sphere."><figcaption>Same visible sphere; larger collision boundary. The gap is now part of the encounter.</figcaption></figure></section>'
body = head("Current chapters and working studies", "One opening, three lessons")+'<article>'+render(decisions,"decisions")+'</article>'+images+'<footer><a href="changes.diff">Exact changes in this pass</a> · <a href="native-verification.json">Native checks</a> · <a href="source-manifest.json">Captured source versions</a> · <a href="point-zero-study.zip">Point Zero download</a> · <a href="point-coordinates-study.zip">Coordinates desktop download</a></footer>'
pages = {"index.html": page("The opening · current companions", body)}
pages["reading.html"] = page("Point One · A body in the light", head("Encounter · manuscript unchanged", "A body in the light")+'<article id="reading">'+render(read(point_one/"final.md"),"reading")+'</article><footer><a href="making.html#making">Now make the distinction</a></footer>')
comparison = '<details><summary>Before this pass / revised tutorial</summary><div class="pair"><div>'+render(read(OUT/"before/commons/maps/Point_One/tutorial.md"),"before")+'</div><div>'+render(read(point_one/"tutorial.md"),"revised")+'</div></div></details>'
pages["making.html"] = page("Point One · give the point a body", head("Making · supplied study", "Give the point a body")+'<article id="making">'+render(read(point_one/"tutorial.md"),"making")+'</article>'+comparison+'<footer><a href="point-one-study.zip">Download the exact study</a> · <a href="changes.diff">All file changes</a></footer>')
pages["coordinates.html"] = page("Point Coordinates · carry a position", head("Next lesson · desktop study and museum pickup", "Carry a position")+'<article id="making">'+render(read(ROOT/"commons/maps/Point_Coordinates/tutorial.md"),"making")+'</article><footer><a href="point-coordinates-study.zip">Download the coordinate study</a></footer>')
for name, body in pages.items():
    soup = BeautifulSoup(body, "html.parser")
    ids = [n["id"] for n in soup.find_all(id=True)]
    assert len(ids) == len(set(ids)), name
    assert not re.search(r"\[\^[^\]]+\]", soup.get_text()), name
    assert all(a["href"][1:] in ids for a in soup.find_all("a", href=True) if a["href"].startswith("#")), name
    write(OUT / name, body)

verification = {
    "main_manuscripts_preserved": True,
    "hall_geometry_and_placements_preserved": True,
    "canonical_and_portable_point_one_tutorial_match": True,
    "three_complete_examples_match_executable_scripts": True,
    "study_archives_and_review_manifest_verified": True,
    "html_anchors_and_footnotes_resolve": True,
    "changed_sources": changed,
    "native_report": json.loads(read(OUT/"native-verification.json")),
    "scope": "Canonical companions, portable Point One helper, packaging. No museum or headset test; portable XR pickup remains separate work."
}
write(OUT / "verification.json", json.dumps(verification, indent=2))
print(json.dumps({"page": str(OUT/"index.html"), "changed_sources": len(changed), "native_passed": verification["native_report"]["passed"], "review_zip": str(OUT/"opening-review.zip")}))
