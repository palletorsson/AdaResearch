from pathlib import Path
import difflib
import hashlib
import html
import json
import shutil

import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
read = lambda p: p.read_text(encoding="utf-8-sig")
files = json.loads(read(OUT / "files.json"))
diffs, text_diffs, comparisons, hashes = [], [], [], {}
for rel in files:
    src = ROOT / rel
    dest = OUT / "after" / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest)
    old, new = read(OUT / "before" / rel), read(src)
    delta = list(difflib.unified_diff(old.splitlines(True), new.splitlines(True),
                                    fromfile="before/" + rel, tofile="after/" + rel))
    diffs.extend(delta)
    hashes[rel] = hashlib.sha256(src.read_bytes()).hexdigest()
    if rel.endswith("/final.md") or rel == "commons/maps/Primitives_Portals/tutorial.md":
        text_diffs.extend(delta)
        chunks = []
        a, b = old.split("\n\n"), new.split("\n\n")
        for tag, i, j, k, l in difflib.SequenceMatcher(a=a, b=b).get_opcodes():
            if tag == "equal":
                continue
            chunks.append('<div class="pair"><div><span class="eyebrow">Before</span><p>'
                          + html.escape("\n\n".join(a[i:j]))
                          + '</p></div><div><span class="eyebrow">Now</span><p>'
                          + html.escape("\n\n".join(b[k:l])) + '</p></div></div>')
        m = Path(rel).parent.name
        label = m.replace("_", " ") + (" · tutorial" if rel.endswith("/tutorial.md") else "")
        comparisons.append('<section id="' + m + '"><h3>' + html.escape(label)
                           + '</h3>' + "".join(chunks)
                           + '<a href="/compose/sources?map=' + m
                           + '&amp;doc=' + Path(rel).stem + '">Read current source →</a></section>')

rel = "doc/book/PRIMITIVES_LINEAGE.md"
dest = OUT / "after" / rel
dest.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(ROOT / rel, dest)
hashes[rel] = hashlib.sha256((ROOT / rel).read_bytes()).hexdigest()
(OUT / "changes.diff").write_text("".join(diffs), encoding="utf-8")
(OUT / "text-changes.diff").write_text("".join(text_diffs), encoding="utf-8")
(OUT / "sources.json").write_text(json.dumps(hashes, indent=2), encoding="utf-8")
sequence = json.loads(read(ROOT / "commons/maps/sequences/primitives.json"))["sequences"]["primitives"]
before = json.loads(read(OUT / "before/commons/maps/sequences/primitives.json"))["sequences"]["primitives"]
assert sequence["maps"] == before["maps"]
assert [s.split(":")[0] for s in sequence["content"]] == sequence["maps"]
config = json.loads(read(ROOT / "doc/book/tutorial-lineage/curriculum.json"))
nodes = {n["id"]: n for n in config["nodes"]}
assert nodes["face"]["requires"] == ["line"]
assert nodes["enclosure"]["halls"] == ["Primitives_Polythedra"]
assert nodes["mesh"]["halls"] == ["Point_Animatedcube"]
assert nodes["refinement"]["halls"] == ["Primitives_Portals"]
assert nodes["primitive"]["halls"] == ["Primitives_Ignorance"]
agreement = markdown.markdown(read(ROOT / rel), extensions=["tables", "fenced_code"])
steps = [
    ("Ready / again", "Point Zero", "loop"),
    ("Position / body", "Point One", "point"),
    ("Reference", "Coordinates", "coordinates"),
    ("Connection", "Lines", "line"),
    ("Record", "Trace", "trace"),
    ("Address", "Grid", "grid"),
    ("Face", "Triangle", "face"),
    ("Enclosure", "Polyhedra", "enclosure"),
    ("Shared corners", "Cube", "mesh"),
    ("Configuration", "Ignorance", "primitive"),
    ("Stopping", "Portals", "refinement"),
    ("Purpose", "Melencolia", "geometry_return"),
]
route = "".join('<a href="/tutorial-lineage#node=' + node + '"><b>' + str(i)
                + '</b><strong>' + label + '</strong><small>' + hall + '</small></a>'
                for i, (label, hall, node) in enumerate(steps, 1))
figures = "".join('<figure><img loading="lazy" src="/book-review/doc/book/figures/'
                  + path + '" alt="' + caption + '"><figcaption>' + caption + '</figcaption></figure>'
                  for path, caption in [
                      ("Point_Triangle_Context/triangle-construction.png", "Connect the points. Then add a face."),
                      ("Primitives_Polythedra/polyhedra-boundaries.png", "The visible opening and the collision hull can disagree."),
                      ("Point_Animatedcube/cube-hidden-diagonal.png", "Move one corner. Find which face must follow."),
                  ])
page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Primitives · a closer lineage</title><style>
:root{color-scheme:light}body{margin:0;background:#f3efe8;color:#29282a;font:19px/1.65 Georgia,serif}main{max-width:1200px;margin:auto;padding:45px 25px 90px}h1{font-weight:400;font-size:clamp(40px,6vw,76px);line-height:1.08;max-width:950px}h2{font-weight:400;font-size:34px;margin-top:65px}h3{font-weight:400;font-size:25px}p{max-width:820px}.eyebrow,nav,figcaption,small,footer{font:13px/1.6 system-ui,sans-serif;color:#696069}a{color:#864361}nav{display:flex;gap:22px;flex-wrap:wrap}.route{display:grid;grid-template-columns:repeat(6,1fr);gap:1px;background:#d5ccc4;border:1px solid #d5ccc4;margin:38px 0}.route a{padding:20px 15px;background:#faf7f0;text-decoration:none;color:inherit;display:flex;flex-direction:column;gap:6px}.route b{font:14px system-ui;color:#a35877}.route strong{font-weight:400;font-size:20px}.geometric{font-size:clamp(21px,3.2vw,35px);border-left:3px solid #ac6582;padding:10px 22px;background:#e9e3dd}.pair{display:grid;grid-template-columns:1fr 1fr;gap:26px;margin:22px 0;border-top:1px solid #cfc5c0;padding:20px 0}.pair p{font-size:17px;white-space:pre-wrap;overflow-wrap:anywhere}img{display:block;width:100%;height:auto}figure{margin:40px 0}figcaption{margin-top:10px}details{margin:38px 0}summary{cursor:pointer;font:18px system-ui}article{max-width:1000px}article h1{font-size:38px}table{border-collapse:collapse;font:14px/1.55 system-ui;width:100%}td,th{text-align:left;vertical-align:top;padding:13px;border-bottom:1px solid #cfc5c0}th{background:#e9e3dd}code{font:14px Consolas,monospace}section{scroll-margin-top:25px}footer{border-top:1px solid #cfc5c0;margin-top:60px;padding-top:18px}@media(max-width:800px){.route{grid-template-columns:repeat(3,1fr)}.pair{grid-template-columns:1fr}article{overflow-x:auto}}@media(max-width:450px){.route{grid-template-columns:repeat(2,1fr)}main{padding:28px 16px}}
</style><main><div class="eyebrow">ADA · PRIMITIVES · 29 SEPTEMBER 2026</div>
<h1>What must we add<br>before we can continue?</h1>
<p>The rooms already carry a strong inquiry. This pass gives each handover a distinct job, while keeping the twelve halls in their current order.</p>
<nav><a href="#lineage">The route</a><a href="#joins">Three joins</a><a href="#changes">Text changes</a><a href="#agreement">Full agreement</a><a href="/tutorial-lineage#node=enclosure">Live atlas</a></nav>
<section id="lineage"><h2>A short geometric construction.</h2><div class="geometric">Point → segment → triangular face → tetrahedral enclosure</div>
<p>A third point must leave the line; a fourth must leave the plane. We still have to connect them and make the faces. The visible sphere used as a point was three-dimensional all along.</p>
<h2>A longer route through making.</h2>ROUTE
<p>Trace adds an ordered record. Grid adds repeatable addresses. Neither is a mathematical requirement for a triangle, but both give this particular journey something to carry forward.</p>
<p>At Cube, another branch begins: reusable scenes and their instances. In Ignorance, generated meshes expose their parameters. A prefab and a primitive mesh are different kinds of supplied beginning.</p></section>
<section id="joins"><h2>Let the construction make the distinction.</h2>FIGURES
<p class="eyebrow">Existing native Godot illustrations, shared by book and museum. This editorial pass did not rebuild the rooms.</p>
<p>The poetic question can change with the operation: what appears, what stops us, what the record admits, what counts as inside, which shape we recognise, and why we want the construction at all.</p></section>
<section id="changes"><h2>The small changes in the text.</h2><p>These edits are in the current sources. They sharpen the handovers and update references to the remaining drawing pens.</p>COMPARISONS</section>
<section><h2>Where the work remains concrete.</h2>
<p>The next making pass is Coordinates into Line: supply the held point and build one measured connection. The current Line tutorial still begins with an 8×8 grid. Trace then needs an introduced list and one recording condition. These are unfinished lessons, even though their museum encounters already exist.</p>
<p>The cleaned Trace hall also has no placed amber short-memory dot, although its passage remains in the manuscript. Its idea should be resolved through an encounter deliberately; this pass has not quietly put a fourth dot back.</p>
<p>The saved pen drawing really travels to Grid and Triangle. Both read the original record independently. The later face, tetrahedron and cube share ideas rather than automatically sharing the visitor's particular geometry.</p></section>
<details id="agreement"><summary>Read the complete twelve-hall agreement</summary><article>AGREEMENT</article></details>
<footer>The atlas build validates coverage of all 204 active halls, dependency references and absence of cycles. All twelve Primitives chapter entries now appear in sequence metadata, including Coordinates. This is source and editorial verification; no new museum runtime or learner test is claimed.<p><a href="text-changes.diff">Text diff</a> · <a href="changes.diff">All changes</a> · <a href="after/doc/book/PRIMITIVES_LINEAGE.md">Agreement source</a> · <a href="sources.json">Source fingerprints</a></p></footer></main></html>'''
page = page.replace("ROUTE", route).replace("FIGURES", figures).replace("COMPARISONS", "".join(comparisons)).replace("AGREEMENT", agreement)
(OUT / "index.html").write_text(page, encoding="utf-8")
print(json.dumps({"published": str(OUT / "index.html"), "maps_unchanged": True, "chapter_entries": len(sequence["content"]), "source_files": len(hashes)}))
