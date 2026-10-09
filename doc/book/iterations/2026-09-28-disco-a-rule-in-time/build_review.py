from pathlib import Path
import difflib,hashlib,json,re,shutil
import markdown
from PIL import Image
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render=lambda s:markdown.markdown(s,extensions=["fenced_code","footnotes","tables"])
checks=[]
def check(name,ok):
 checks.append({"name":name,"passed":bool(ok)})
 assert ok,name
changed={"commons/maps/Tutorial_Disco/final.md","commons/maps/Tutorial_Disco/summary.md","commons/maps/Tutorial_Disco/technical.md","commons/data/museum_core_encounters.json"}
for file,digest in json.loads(read(HERE/"baseline.json")).items():
 if file not in changed:check("Preserved "+file,sha(ROOT/file)==digest)
rel=Path("commons/maps/Tutorial_Disco/final.md");old=read(HERE/"before"/rel);new=read(ROOT/rel)
check("Encounter markers retained",re.findall(r"<!--.*?-->",old)==re.findall(r"<!--.*?-->",new))
check("Exact checker rule retained",re.findall(r"```gdscript.*?```",old,re.S)==re.findall(r"```gdscript.*?```",new,re.S))
check("Entire score and critical ending retained",old.split("<!-- @step_sequencer -->")[1]==new.split("<!-- @step_sequencer -->")[1])
images=lambda s:re.findall(r"!\[[^\]]*\]\(([^)]+)\)",s)
check("Existing book figures retained",images(old)==images(new))
for url in images(new):
 with Image.open(ROOT/url.removeprefix("/book-review/")) as image:image.verify()
 check("Book image readable "+url,True)
for name in ["checker-underfoot-zero.png","checker-underfoot-one.png","triangles-within-reach.png","triangles-held-turn.png"]:
 with Image.open(HERE/name) as image:image.verify()
 check("New native view readable "+name,True)
core=json.loads(read(ROOT/"commons/data/museum_core_encounters.json"));before=json.loads(read(HERE/"before/commons/data/museum_core_encounters.json"))
entry=core["rooms"]["Tutorial_Disco"]
check("Canonical text hash current",entry["text_sha256"]==sha(ROOT/rel))
for key in ["text_sha256","runtime_check","local_review"]:before["rooms"]["Tutorial_Disco"][key]=entry[key]
check("Rest of catalogue retained",before==core)
report=json.loads(read(HERE/"report.json"));check("Native run passed",report["passed"] and len(report["checks"])==60 and not report["failures"])
for name,digest in report["observations"].items():
 if name.startswith("commons/"):check("Tested source current "+name,sha(ROOT/name)==digest)
check("Triangle comparison held between exact poses",report["observations"]["triangle_held_motion"]%1!=0)
manifest=json.loads(read(ROOT/"doc/book/captures/array_tutorial/array_tutorial-book.manifest.json"))
check("All five capture source hashes current",len(manifest["maps"])==5 and all(sha(ROOT/r["path"])==r["sha256"] for r in manifest["maps"]))
check("Capture output current",sha(ROOT/"doc/book/captures/array_tutorial/array_tutorial-book.md")==manifest["output_sha256"])
for name in ["array_tutorial-book.md","array_tutorial-book.manifest.json"]:shutil.copy2(ROOT/"doc/book/captures/array_tutorial"/name,HERE/name)
(HERE/"Tutorial_Disco.current.md").write_text(new,encoding="utf-8")
(HERE/"Tutorial_Disco.diff").write_text("".join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile="before/Tutorial_Disco/final.md",tofile="current/Tutorial_Disco/final.md")),encoding="utf-8")
summaryold=read(HERE/"before/commons/maps/Tutorial_Disco/summary.md");summarynew=read(ROOT/"commons/maps/Tutorial_Disco/summary.md")
(HERE/"summary.diff").write_text("".join(difflib.unified_diff(summaryold.splitlines(True),summarynew.splitlines(True),fromfile="before/summary.md",tofile="current/summary.md")),encoding="utf-8")
table=difflib.HtmlDiff(wrapcolumn=62).make_table(old.splitlines(),new.splitlines(),"Before this pass","Current final.md",context=True,numlines=3)
css=re.search(r"<style>(.*?)</style>",read(ROOT/"doc/book/iterations/2026-09-27-rotation-follow-a-turn/index.html"),re.S).group(1)
css+=".native-pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}.native-pair figure{margin:0}figure img{width:100%;height:auto}.phase-controls{display:flex;gap:10px;margin:15px 0}.phase-controls button{padding:10px 18px;border:1px solid #756754;border-radius:4px;background:#ede6db;color:#28241e;font:inherit;cursor:pointer}.phase-controls button[aria-pressed=true]{background:#28241e;color:#fff}.phase-controls button:focus-visible{outline:3px solid #ba592c}figcaption{font-size:16px;color:#524b41}.diff-scroll{overflow:auto}@media(max-width:760px){.native-pair{grid-template-columns:1fr}}"
page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A rule in time</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">TUTORIAL_DISCO · ARRAYS AND REGULARITY · 28 SEPTEMBER 2026</p><h1>A rule in time.</h1><p>One square changes beneath your foot. The instruction has stayed the same; its phase has advanced. Later, a rhythm can repeat without deciding how you must move with it.</p><nav><a href="#reading">Read the chapter</a><a href="#museum">Inside the floor</a><a href="#changes">Before / after</a><a href="#decisions">Decisions</a><a href="array_tutorial-book.md">Full Arrays capture</a></nav></header>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Tutorial_Disco&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="museum"><h2>The same place, one step later</h2><p>Two native held states from the same eye-height position inside the museum floor. Switch between them: the receiving tiles retain their positions.</p><div class="phase-controls" role="group" aria-label="Compare two captured checker phases"><button type="button" data-phase="0" aria-pressed="true">Phase 0</button><button type="button" data-phase="1" aria-pressed="false">Phase 1</button></div><figure><a id="phase-link" href="checker-underfoot-zero.png"><img id="phase-image" src="checker-underfoot-zero.png" alt="Checker phase zero, from standing height within the floor"></a><figcaption id="phase-caption" aria-live="polite">Phase 0. The clock is held; black and white have fixed addresses.</figcaption></figure><noscript><p><a href="checker-underfoot-one.png">View phase 1</a></p></noscript>
<h2>The diagonal returns</h2><div class="native-pair"><figure><a href="triangles-within-reach.png"><img src="triangles-within-reach.png" alt="Triangles gathering into diamonds across the museum floor"></a><figcaption>An exact SUPER TRIANGLE pose. The square joints remain visible through the larger figure.</figcaption></figure><figure><a href="triangles-held-turn.png"><img src="triangles-held-turn.png" alt="The same floor held partway through the next visual turn"></a><figcaption>A held turn between poses. No tile body has rotated.</figcaption></figure></div><p>The artifact was already capable of this encounter. This pass sharpens the writing and refreshes the views; it adds no controls or runtime behaviour.</p></section>
<section id="changes"><h2>Before and after</h2><p>{len(old.split())} → {len(new.split())} words, including captions and code. The whole passage from making one note to the end remains verbatim. <a href="Tutorial_Disco.diff">Text diff</a> · <a href="Tutorial_Disco.current.md">Current Markdown</a> · <a href="summary.diff">Corrected supporting summary</a></p><div class="diff-scroll">{table}</div></section>
<section class="decisions" id="decisions">{render(read(HERE/"DECISIONS.md"))}<p><a href="report.json">60 runtime checks</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a> · <a href="array_tutorial-book.manifest.json">Current capture manifest</a></p></section>
<footer><p>Previous: <a href="/book-review/doc/book/iterations/2026-09-28-tiling-rule-study/index.html">One instruction, many places</a>. Next: <a href="/compose/sources?map=Color_Context_Placed&amp;doc=final">Colour among familiar forms</a>.</p></footer>
</main><script>
const pictures=['checker-underfoot-zero.png','checker-underfoot-one.png'];
const captions=['Phase 0. The clock is held; black and white have fixed addresses.','Phase 1. One step exchanges the values. The tiles and the instruction stay in place.'];
const buttons=document.querySelectorAll('[data-phase]');
buttons.forEach(button=>button.addEventListener('click',()=>{{const phase=Number(button.dataset.phase);document.getElementById('phase-image').src=pictures[phase];document.getElementById('phase-image').alt='Checker phase '+phase+', from the same standing-height position';document.getElementById('phase-link').href=pictures[phase];document.getElementById('phase-caption').textContent=captions[phase];buttons.forEach(b=>b.setAttribute('aria-pressed',String(b===button)));}}));
</script></body></html>'''
(HERE/"index.html").write_text(page,encoding="utf-8")
(HERE/"checks.json").write_text(json.dumps({"passed":True,"checks":checks,"words":{"before":len(old.split()),"after":len(new.split())}},indent=2)+"\n",encoding="utf-8")
print("Built review;",len(checks),"publication checks passed")
