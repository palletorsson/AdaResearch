from pathlib import Path
import html, json, re
import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
CHANGES = json.loads((OUT / "changes.json").read_text(encoding="utf-8"))
TITLES = {"Point_One": "A moment before the explanation", "Point_Triangle_Context": "Follow the fill", "Trans_Pre": "The interval begins to matter"}
NOTES = {"Point_One": "A little space to look around; fewer repeated explanations. The borrowed-world paragraph and the rest of the encounter remain.", "Point_Triangle_Context": "The boundary, fan and changed starting corner stay central. The detailed drawing recipe remains in the technical companion. The overspill can also become a form to pursue.", "Trans_Pre": "One added paragraph: the time interval introduced in the first room now gives the cube its turn. The primer keeps its existing order."}

def render(source, prefix):
    source = re.sub(r"<!--\s*@([^>]*?)\s*-->", lambda m: '<a id="' + prefix + '-encounter-' + html.escape(m.group(1).strip(), quote=True) + '"></a>', source)
    source = re.sub(r"~~([^~\n]+)~~", r"<del>\1</del>", source)
    result = markdown.markdown(source, extensions=["extra", "sane_lists"])
    result = result.replace('id="fn', 'id="' + prefix + '-fn').replace('href="#fn', 'href="#' + prefix + '-fn')
    return result

parts=[]
for name, edits in CHANGES.items():
    current=(ROOT / "commons/maps" / name / "final.md").read_text(encoding="utf-8")
    snapshot=(OUT / (name + ".after.md")).read_text(encoding="utf-8")
    assert current == snapshot, "Refresh reading copy deliberately after another edit: " + name
    pairs=[]
    for i,(before, after) in enumerate(edits):
        pairs.append('<div class="pair"><div><h4>Before</h4>' + render(before, f"{name}-before-{i}") + '</div><div><h4>Now</h4>' + render(after, f"{name}-after-{i}") + '</div></div>')
    parts.append(f'<section id="{name}"><header class="chapter"><span class="eyebrow">{name.replace("_", " ")}</span><h2>{TITLES[name]}</h2><p>{NOTES[name]}</p><a href="/compose/sources?map={name}&amp;doc=final">Read and comment on final.md</a></header><details><summary>Compare the small changes</summary>{"".join(pairs)}<p><a href="{name}.diff">Exact text diff</a></p></details><article class="reading" id="reading-{name}">{render(current, name)}</article></section>')

page="""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A little room to notice — Ada Research</title><style>
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f4f0e7;color:#27313b;font:18px/1.75 Georgia,serif}main{max-width:1250px;margin:auto;padding:48px 34px 70px}.eyebrow,nav,summary,footer,.status,h4{font-family:system-ui,sans-serif}.eyebrow{text-transform:uppercase;letter-spacing:.15em;font-size:11px;color:#90616e}h1{font-size:clamp(38px,6vw,65px);font-weight:400;line-height:1.1;letter-spacing:-.025em;margin:15px 0 25px}h2{font-size:32px;line-height:1.25;font-weight:400}h4{font-size:12px;text-transform:uppercase;letter-spacing:.1em;margin:0 0 14px;color:#90616e}.intro,.chapter{max-width:760px}.status{font-size:14px;max-width:820px;padding:16px 22px;background:#ece5dc;border-left:3px solid #cd6b95}nav{display:flex;flex-wrap:wrap;gap:12px 25px;font-size:14px;margin:25px 0 34px}a{color:#87465e;text-underline-offset:4px}section{border-top:1px solid #d4ccbe;margin-top:60px;padding-top:30px;scroll-margin-top:25px}.chapter>a{font:14px system-ui,sans-serif}details{margin:30px 0;background:#eee8de;border:1px solid #dcd2c3;padding:18px 22px}summary{font-size:15px;cursor:pointer}.pair{display:grid;grid-template-columns:1fr 1fr;gap:30px;padding:25px 0;border-bottom:1px solid #d4ccbe;font-size:16px}.pair>div{min-width:0}.pair p{margin-top:0}.reading{max-width:760px;margin:48px auto}.reading h2{font-size:26px;margin-top:35px}.reading img{width:100%;height:auto;margin:15px 0}.reading blockquote{margin:24px 0;padding:0 22px;border-left:2px solid #b38d90;color:#77666b}code{font:14px/1.6 ui-monospace,monospace;background:#e8e2d7;padding:2px 4px;overflow-wrap:anywhere}pre{background:#e8e2d7;padding:20px;overflow:auto;white-space:pre-wrap}pre code{padding:0}.footnote{font-size:14px;border-top:1px solid #d4ccbe;margin-top:35px}.footnote ol{padding-left:24px}footer{font-size:14px;border-top:1px solid #d4ccbe;padding-top:25px;max-width:850px}sup{font-size:11px}a:focus-visible,summary:focus-visible{outline:2px solid #87465e;outline-offset:5px}@media(max-width:700px){main{padding:28px 18px 45px}body{font-size:17px}.pair{grid-template-columns:1fr}.pair>div+div{border-top:1px dashed #c9bfaf;padding-top:20px}.reading{margin:32px 0}}
</style></head><body><main><div class="eyebrow">Ada Research / Primitives into Transformation / 23 September 2026</div><h1>A little room to notice.</h1><div class="intro"><p>The opening keeps its questions, objects and code. This pass makes a little more room for arrival, lets the triangle experiment read without its full drawing recipe, and leaves the unwanted patch available as a form to want.</p><p>Transformation begins with a return: the interval the first counter ignored now gives a cube its turn.</p></div><p class="status">Applied to the three current <strong>final.md</strong> files below. Expand the comparisons to read the exact before-and-after passages. The capsule and Melencolia passages are preserved.</p><nav><a href="#Point_One">Point One</a><a href="#Point_Triangle_Context">Triangle</a><a href="#Trans_Pre">Begin Transformation</a><a href="SUMMARY.md">Scope and checks</a></nav>"""
page += "".join(parts)
page += '<footer><p>These are text changes. Code blocks, encounter anchors, footnotes and map files are preserved. Existing illustrations come from the native Godot work already in the chapters. No new runtime or headset test is claimed.</p><p>Next: <a href="/compose/sources?map=Trans_Introduction&amp;doc=final">Trans Introduction — when movement becomes a crossing</a>.</p></footer></main></body></html>'
(OUT / "index.html").write_text(page, encoding="utf-8")
print(OUT / "index.html")
