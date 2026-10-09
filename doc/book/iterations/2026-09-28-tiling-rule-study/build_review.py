from pathlib import Path
import difflib, hashlib, html, json, re, shutil
import markdown
from PIL import Image
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render=lambda s:markdown.markdown(s,extensions=["fenced_code","footnotes","tables"])
checks=[]
def check(name,ok):
    checks.append({"name":name,"passed":bool(ok)})
    assert ok,name
baseline=json.loads(read(HERE/"baseline.json"))
for file in ["commons/maps/sequences/array_tutorial.json"]+[f"commons/maps/{m}/{f}" for m in ["Tutorial_Tiling_Floor","Tutorial_Tiling_Walls"] for f in ["map_data.json","critical.md"]]:
    check("Preserved "+file,sha(ROOT/file)==baseline[file])
core=json.loads(read(ROOT/"commons/data/museum_core_encounters.json"))
oldcore=json.loads(read(HERE/"before/commons/data/museum_core_encounters.json"))
readings=[];diffs=[]
for room,short in [("Tutorial_Tiling_Floor","floor"),("Tutorial_Tiling_Walls","wall")]:
    rel=Path("commons/maps")/room/"final.md"
    old=read(HERE/"before"/rel);new=read(ROOT/rel)
    check(room+" preserves encounter markers",re.findall(r"<!--.*?-->",old)==re.findall(r"<!--.*?-->",new))
    check(room+" preserves existing code",re.findall(r"```gdscript.*?```",old,re.S)==re.findall(r"```gdscript.*?```",new,re.S))
    oldimages=re.findall(r"!\[[^\]]*\]\(([^)]+)\)",old)
    for path in oldimages:check("Existing figure retained "+path,path in new)
    for path in re.findall(r"!\[[^\]]*\]\(([^)]+)\)",new):
        with Image.open(ROOT/path.removeprefix("/book-review/")) as im:im.verify()
        check("Figure readable "+path,True)
    check(room+" text hash current",core["rooms"][room]["text_sha256"]==sha(ROOT/rel))
    for key in ["primary_tokens","sequence","map_sha256","learner_verified"]:
        check(room+" keeps "+key,core["rooms"][room][key]==oldcore["rooms"][room][key])
    oldcore["rooms"][room]=core["rooms"][room]
    report=json.loads(read(HERE/(short+"-report.json")))
    check(room+" native checks passed",report["passed"] and not report["failures"])
    for name,digest in report["observations"].items():
        if name.endswith(".gd"):check(room+" tested source current "+name,sha(ROOT/"commons/artifacts/regularity"/name)==digest)
    (HERE/(room+".current.md")).write_text(new,encoding="utf-8")
    (HERE/(room+".diff")).write_text("".join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile="before/"+room+"/final.md",tofile="current/"+room+"/final.md")),encoding="utf-8")
    readings.append(f'<article class="reading" id="reading-{short}"><p class="eyebrow">{room} · CURRENT FINAL.MD · <a href="/compose/sources?map={room}&amp;doc=final">Read and comment</a></p>{render(new)}</article>')
    table=difflib.HtmlDiff(wrapcolumn=64).make_table(old.splitlines(),new.splitlines(),"Before","Current final.md",context=True,numlines=2)
    diffs.append(f'<h3>{room}</h3><p>{len(old.split())} → {len(new.split())} words, including captions and code. <a href="{room}.diff">Text diff</a> · <a href="{room}.current.md">Markdown</a></p><div class="diff-scroll">{table}</div>')
check("Unrelated encounter catalogue unchanged",oldcore==core)
wallold=read(HERE/"before/commons/maps/Tutorial_Tiling_Walls/final.md")
wallnew=read(ROOT/"commons/maps/Tutorial_Tiling_Walls/final.md")
check("The entire hinged-wall encounter and ending remain verbatim",wallold.split("<!-- @wall_exception -->")[1]==wallnew.split("<!-- @wall_exception -->")[1])
manifest=json.loads(read(ROOT/"doc/book/captures/array_tutorial/array_tutorial-book.manifest.json"))
check("All five capture sources current",len(manifest["maps"])==5 and all(sha(ROOT/r["path"])==r["sha256"] for r in manifest["maps"]))
check("Full capture hash current",sha(ROOT/"doc/book/captures/array_tutorial/array_tutorial-book.md")==manifest["output_sha256"])
for name in ["array_tutorial-book.md","array_tutorial-book.manifest.json"]:shutil.copy2(ROOT/"doc/book/captures/array_tutorial"/name,HERE/name)
css=re.search(r"<style>(.*?)</style>",read(ROOT/"doc/book/iterations/2026-09-27-rotation-follow-a-turn/index.html"),re.S).group(1)
css+=".native-pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}.native-pair figure{margin:0}.native-pair img{width:100%}figure{margin:2rem 0}figcaption{font-size:16px;color:#53504b}.museum img{width:100%;height:auto}.diff-scroll{overflow:auto}@media(max-width:800px){.native-pair{grid-template-columns:1fr}}"
page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>One instruction, many places</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">FLOOR AND WALL TILING · NATIVE GODOT ENCOUNTERS · 28 SEPTEMBER 2026</p><h1>One instruction, many places.</h1><p>Follow a change through sixteen tiles. Find those tiles in a larger field. Then watch the same pattern approach the limits of what you can distinguish.</p><nav><a href="#museum">Inside the museum</a><a href="#reading-floor">Floor chapter</a><a href="#reading-wall">Wall chapter</a><a href="#changes">Text changes</a><a href="#decisions">Decisions and checks</a><a href="array_tutorial-book.md">Full Arrays capture</a></nav></header>
<section class="museum" id="museum"><h2>Keep the tile. Change the instruction.</h2><div class="native-pair"><figure><a href="floor-rule-before.png"><img src="floor-rule-before.png" alt="Unchanged four-by-four samples inside the museum"></a><figcaption>Before: the same tile repeated at every address.</figcaption></figure><figure><a href="floor-rule-after.png"><img src="floor-rule-after.png" alt="A rule applied to the second sample while the first stays unchanged"></a><figcaption>After: add an address-dependent quarter-turn. The left sample remains available for comparison.</figcaption></figure></div>
<p>NEXT RULE selects one of six instructions. APPLY / UNDO makes the difference reversible. NEXT TILE moves the marked address and shows the rule evaluated there.</p>
<figure><a href="floor-floor-and-rule.png"><img src="floor-floor-and-rule.png" alt="The study and its sixteen-by-sixteen floor field in the museum entrance"></a><figcaption>The matching four-by-four window is outlined within a sixteen-by-sixteen floor field. Both come from one calculation.</figcaption></figure>
<h2>A pattern eye chart</h2><div class="native-pair"><figure><a href="wall-eye-chart.png"><img src="wall-eye-chart.png" alt="Five rows of progressively smaller four-by-four quarter-turn patterns"></a><figcaption>Quarter-turns: 25 copies of exactly one image, arranged at five sizes.</figcaption></figure><figure><a href="wall-eye-chart-reflect.png"><img src="wall-eye-chart-reflect.png" alt="The same eye chart after cycling to reflection"></a><figcaption>Reflection: NEXT RULE changes the chart and the nearby desk together.</figcaption></figure></div><p>These are fresh screenshots from the actual museum. The charts, patterns and controls are live Godot objects. Reload the two halls to see the additions in a running museum.</p></section>
{''.join(readings)}
<section id="changes"><h2>What entered the writing</h2>{''.join(diffs)}</section>
<section class="decisions" id="decisions">{render(read(HERE/"DECISIONS.md"))}<p><a href="floor-report.json">Floor: 24 runtime checks</a> · <a href="wall-report.json">Walls: 30 runtime checks</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a> · <a href="array_tutorial-book.manifest.json">Capture manifest</a></p></section>
</main></body></html>'''
(HERE/"index.html").write_text(page,encoding="utf-8")
(HERE/"checks.json").write_text(json.dumps({"passed":True,"checks":checks},indent=2)+"\n",encoding="utf-8")
print("Review built:",len(checks),"publication checks passed")
