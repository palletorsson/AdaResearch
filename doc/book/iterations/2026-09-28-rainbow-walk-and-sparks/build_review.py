from pathlib import Path
import difflib, hashlib, json, re, shutil
import markdown
from bs4 import BeautifulSoup
from PIL import Image
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render=lambda s:markdown.markdown(s,extensions=["extra"])
checks=[]
def check(name,ok):
 checks.append({"name":name,"passed":bool(ok)})
 if not ok:raise ValueError(name)
rel="commons/maps/Color_Rainbow/final.md"
old=read(HERE/"before"/rel);new=read(ROOT/rel)
changes=json.loads(read(HERE/"changes.json"));expected=old
for c in changes:
 if c["before"]:expected=expected.replace(c["before"],c["after"])
 else:expected=expected.rstrip()+"\n\n"+c["after"]
check("Only the recorded chapter changes",expected==new)
check("Existing code and encounter anchors preserved",re.findall(r"```.*?```|<!--.*?-->",old,re.S)==re.findall(r"```.*?```|<!--.*?-->",new,re.S))
check("Deferred footnote has one reference and definition",new.count("[^colour-boundaries]")==2)
core=json.loads(read(ROOT/"commons/data/museum_core_encounters.json"));before=json.loads(read(HERE/"before/commons/data/museum_core_encounters.json"));entry=core["rooms"]["Color_Rainbow"]
check("Catalogue text hash matches current chapter",entry["text_sha256"]==sha(ROOT/rel))
for key in ["text_sha256","local_review"]:before["rooms"]["Color_Rainbow"][key]=entry[key]
check("Only this hall catalogue reference changed",core==before)
manifest=json.loads(read(ROOT/"doc/book/captures/color/color-book.manifest.json"))
check("Eight current Colour chapters captured",len(manifest["maps"])==8 and all(sha(ROOT/m["path"])==m["sha256"] for m in manifest["maps"]))
check("Current capture content matches manifest",sha(ROOT/"doc/book/captures/color/color-book.md")==manifest["output_sha256"])
for name in ["color-book.md","color-book.manifest.json"]:shutil.copy2(ROOT/"doc/book/captures/color"/name,HERE/name)
report=json.loads(read(HERE/"report.json"))
check("89 native encounter checks pass",report["passed"] and len(report["checks"])==89)
sources=json.loads(read(HERE/"encounter-sources.json"))
check("Tested encounter sources still match",all(sha(ROOT/name)==value for name,value in sources.items()))
log=read(HERE/"stdout.log")
check("No script or shader error in completed run","SCRIPT ERROR" not in log and "SHADER ERROR" not in log)
for name in ["walk-before.png","walk-sparks.png","finish-banner.png"]:
 with Image.open(HERE/name) as im:im.verify()
check("All new native figures readable",True)
(HERE/"Color_Rainbow.current.md").write_text(new,encoding="utf-8")
(HERE/"Color_Rainbow.diff").write_text("".join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile="before/Color_Rainbow/final.md",tofile="current/Color_Rainbow/final.md")),encoding="utf-8")
rows=""
for c in changes:
 previous=c["before"] or "No footnote."
 current=c["after"].replace("[^colour-boundaries]: ","").replace("[^colour-boundaries]", " (see the footnote in the chapter)")
 rows+="<tr><td><h3>"+c["label"]+"</h3>"+render(previous)+"</td><td>"+render(current)+"</td></tr>"
css=re.search(r"<style>(.*?)</style>",read(ROOT/"doc/book/iterations/2026-09-28-rainbow-room-for-a-choice/index.html"),re.S).group(1)
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Rainbow — The walk releases sparks</title><style>{css}
figure img {{width:100%;height:auto;display:block}} .footnote {{font-size:.9em}} .passages td {{vertical-align:top}}
</style></head><body><main><header><p class="eyebrow">COLOR_RAINBOW · 28 SEPTEMBER 2026 · INSIDE THE MUSEUM</p><h1>The walk releases sparks.</h1><p>A familiar cube returns. Walk through it and its place opens into long coloured tails. Two slender poles carry a rainbow banner at the far end.</p><nav><a href="#museum">See the encounter</a><a href="#reading">Read the chapter</a><a href="#changes">Text changes</a><a href="#decisions">Decisions and evidence</a></nav></header>
<section id="museum"><figure><img src="walk-sparks.png" alt="Long curved multicoloured spark tails rising where a cube was collected, inside the Rainbow hall."><figcaption>Native Godot museum render. The second collected cube releases the burst; existing welcome confetti remains visible. Particle updates paused at the reached instant for this capture.</figcaption></figure><figure><img src="walk-before.png" loading="lazy" alt="Five familiar wire cubes spaced along the level coloured walk through the rainbow arch."><figcaption>Five cubes along the centre walk. Each can be collected once per hall load. The side aisles remain available.</figcaption></figure><figure><img src="finish-banner.png" loading="lazy" alt="Six coloured cloth stripes sag gently between two slender poles above the museum path."><figcaption>The banner at the far end: six stripes, two poles, 2.85 metres of clearance beneath the lowest part of the cloth.</figcaption></figure></section>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Color_Rainbow&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="changes"><h2>The new encounter in the chapter</h2><p>The earlier code explanation and passage into Pillar remain. The footnote holds the question of queer colour, boundaries and possible continuous controls for a later pass.</p><p><a href="Color_Rainbow.diff">Exact text difference</a> · <a href="Color_Rainbow.current.md">Current chapter</a></p><table class="passages"><thead><tr><th>Before this pass</th><th>Current final.md</th></tr></thead><tbody>{rows}</tbody></table></section>
<section id="decisions" class="decisions">{render(read(HERE/'DECISIONS.md'))}<p><a href="report.json">89 native checks</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served files</a> · <a href="encounter-sources.json">Tested sources</a> · <a href="color-book.md">Current Colour capture</a> · <a href="stdout.log">Engine log</a></p></section><footer><p>Next in the reading sequence: <a href="/compose/sources?map=Color_Pillar&amp;doc=final">Color_Pillar</a>.</p></footer></main></body></html>"""
soup=BeautifulSoup(page,"html.parser");ids=[n["id"] for n in soup.find_all(id=True)]
check("Rendered IDs unique",len(ids)==len(set(ids)))
check("Internal links and footnote backlinks resolve",all(n["href"][1:] in ids for n in soup.find_all("a",href=True) if n["href"].startswith("#")))
check("Footnote rendered as a linked note",bool(soup.select(".footnote")) and len(soup.select("sup a.footnote-ref"))==1)
(HERE/"index.html").write_text(page,encoding="utf-8")
(HERE/"checks.json").write_text(json.dumps({"passed":True,"checks":checks},indent=2),encoding="utf-8")
print(f"{len(checks)} publication checks passed.")
