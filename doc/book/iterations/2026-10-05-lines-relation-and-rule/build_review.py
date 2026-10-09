"""Publish this writing pass and its saved learner-state evidence."""
from pathlib import Path
import difflib
import html
import json
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
paths = ["Point_Lines/tutorial.md", "Point_Lines/final.md", "Primitives_Ignorance/final.md"]
texts = {}
for relative in paths:
    current = (ROOT / "commons/maps" / relative).read_text(encoding="utf-8-sig")
    before = (HERE / "before" / relative).read_text(encoding="utf-8-sig")
    texts[relative] = current
    (HERE / (relative.replace("/", "-") + ".diff")).write_text("".join(difflib.unified_diff(before.splitlines(True), current.splitlines(True), fromfile="before/" + relative, tofile="commons/maps/" + relative)), encoding="utf-8")

def render(text):
    return markdown.markdown(text, extensions=["fenced_code", "tables", "footnotes"]).replace('href="../../../doc/book/iterations/', 'href="../').replace('src="/book-review/', 'src="http://localhost:3003/book-review/')

ignorance = texts["Primitives_Ignorance/final.md"].split("You once held a point", 1)[1].split("<!-- @sphere_resolution_atlas -->", 1)[0]
report_path = HERE / "student/report-runtime.json"
report = json.loads(report_path.read_text(encoding="utf-8")) if report_path.exists() else None
checks = len(report["checks"]) if report else 0
evidence = f"{checks} native checks recorded for this code" if report and report["passed"] else "Verification not yet complete"
css = """
*{box-sizing:border-box}body{margin:0;background:#f5f3ee;color:#242526;font:17px/1.7 system-ui,sans-serif}header,main,footer{max-width:1160px;margin:auto;padding:40px 28px}header{padding-top:70px}h1{font:normal clamp(42px,7vw,76px)/1.05 Georgia,serif;letter-spacing:-.04em;margin:20px 0}h2{font:normal 32px/1.2 Georgia,serif;margin:35px 0 20px}h3{font-size:20px}a{color:#873b5c;text-underline-offset:4px}.kicker{font:11px/1.6 system-ui;letter-spacing:.15em;text-transform:uppercase;color:#6e686a}.lead{font:24px/1.45 Georgia,serif;max-width:780px}nav{display:flex;gap:22px;flex-wrap:wrap;margin-top:24px;font-size:14px}figure{margin:12px 0 34px}img{width:100%;display:block}figcaption,.small{font-size:13px;color:#696867;line-height:1.6}article{max-width:800px;margin:45px auto;border-top:1px solid #d3cec7;padding-top:24px}article h1{font-size:37px;line-height:1.15}pre{overflow:auto;background:#e9e7e2;border-left:3px solid #a7798e;padding:18px;font:12px/1.8 Consolas,monospace}code{font-family:Consolas,monospace;font-size:.88em}pre code{font-size:inherit}table{border-collapse:collapse;width:100%;font-size:12px;display:block;overflow-x:auto}td,th{border-bottom:1px solid #d3cec7;text-align:left;padding:11px 12px;vertical-align:top}blockquote{margin:25px 0;padding:10px 25px;border-left:3px solid #a7798e;font-family:Georgia,serif}.note{padding:20px 24px;background:#e9e7e2;margin:25px 0}.footnote{font-size:13px}footer{font-size:13px;border-top:1px solid #d3cec7}details{margin:24px 0}summary{cursor:pointer;color:#873b5c}
"""
page = f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Lines — relation, association, rule</title><style>{css}</style></head><body>
<header><p class="kicker">Endless Museum · Writing and student code · 5 October 2026</p><h1>A point becomes an end.</h1><p class="lead">The hand moves a point. A relation moves the line. Two lines begin to suggest something together.</p><nav><a href="#tutorial">The tutorial</a><a href="#reading">The reflective text</a><a href="#ignorance">The later threshold</a><a href="#evidence">Code and checks</a><a href="http://localhost:3003/ghost-student?state=point-lines">Ghost student ↗</a></nav></header>
<main><figure><img src="../2026-10-01-lines-triangle-research/lines-final/line-room.png" alt="Actual Point Lines hall with parallel planks, vertical beams, a grid and an X"><figcaption>Existing museum capture, 1 October. The plus and X use rods at slightly different depths. This pass changes writing and learner examples; the hall's runtime code is unchanged.</figcaption></figure>
<article><h2>What changed</h2><p>The tutorial continues the saved pickable point. Its copy becomes a second endpoint; a supplied renderer draws their relation. Another line is made from two position values without pickup bodies. Parallel, plus and X become arrangements the student can change.</p><p>The reflective text follows the line's associations: a connection, a route, a prohibition, a sign. Primitive Ignorance returns to the scale of our decisions: placing a point, specifying connections, then choosing a rule that arranges many points.</p><div class="note">A finite mesh still has countable vertices. A position was already in 3D. The transition concerns how positions are organised and how we choose to act on them; it is not a mathematical change from countable to uncountable.</div></article>
<article><h2>Two texts, two jobs</h2><p>The reflective text follows the encounter and its implications. The tutorial supplies the learning context and now prints both complete files: the continuing student script and its small drawing helper. The example code is unchanged. Its full listings and the two-line addition have been compared with the saved code separately from the earlier native run.</p><p class="small"><a href="../2026-10-05-lines-two-texts/tutorial-text-check.json">Full-code text check</a> · <a href="../2026-10-05-lines-two-texts/before/tutorial.md">Earlier excerpt-based tutorial</a></p></article>
<article id="tutorial">{render(texts['Point_Lines/tutorial.md'])}<p class="small"><a href="Point_Lines-tutorial.md.diff">Before / after tutorial diff</a> · <a href="before/Point_Lines/tutorial.md">Previous tutorial</a></p></article>
<article id="reading">{render(texts['Point_Lines/final.md'])}<p class="small"><a href="Point_Lines-final.md.diff">Reflective-text diff</a></p></article>
<article id="ignorance"><p class="kicker">Added to Primitive Ignorance</p><h2>Choosing the scale of a decision</h2>{render('You once held a point' + ignorance)}<p class="small"><a href="Primitives_Ignorance-final.md.diff">Insertion in context</a></p></article>
<article id="evidence"><h2>{html.escape(evidence)}</h2><p>The saved Coordinates output is the incoming file. Exact declared edits produce the Lines output. Native Godot checks the continued pickup behaviour, changing span, shared coordinate frame, coincidence and the two-line arrangements. A deliberately stopped renderer is checked as a failure.</p><nav><a href="student/assembled.gd">Full continuing code</a><a href="student/line_skin.gd">Supplied renderer</a><a href="student/contract.json">Declared edits</a><a href="student/report-runtime.json">Recorded result</a><a href="student/brief.json">Short brief</a></nav><p class="small">The incoming Point One reconstruction remains an explicit assumption. Native tests use XR Tools and a synthetic controller; they do not establish headset comfort or student understanding. The Ghost Student page compares each saved state's own evidence with its sources.</p></article></main><footer>Position → relation → record → face → connected mesh → generator. The geometry and the associations carry different kinds of knowledge.</footer></body></html>"""
(HERE / "index.html").write_text(page, encoding="utf-8")
print(json.dumps({"report": str(HERE / "index.html"), "native_checks": checks}))
