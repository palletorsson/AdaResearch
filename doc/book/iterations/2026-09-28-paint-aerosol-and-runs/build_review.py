from pathlib import Path
import json,hashlib,difflib,re,shutil
import markdown
from PIL import Image
from bs4 import BeautifulSoup
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render=lambda s:markdown.markdown(s,extensions=["extra"])
checks=[]
def check(name,ok):
 checks.append({"name":name,"passed":bool(ok)})
 if not ok:raise ValueError(name)
old=read(HERE/"before/commons/maps/Color_Paint/final.md");new=read(ROOT/"commons/maps/Color_Paint/final.md")
changes=json.loads(read(HERE/"changes.json"));expected=old
for c in changes:expected=expected.replace(c["before"],c["after"],1)
check("Only recorded chapter changes",expected==new)
check("Albers encounter and footnote preserved",old[old.index("<!-- @albers_wall_gallery -->"):]==new[new.index("<!-- @albers_wall_gallery -->"):])
check("Chapter anchors preserved",re.findall(r"<!--.*?-->",old)==re.findall(r"<!--.*?-->",new))
for prefix,count in [("",25),("regression-",55)]:
 report=json.loads(read(HERE/(prefix+"report.json")))
 check(prefix+"native checks pass",report["passed"] and not report["failures"] and len(report["checks"])==count)
 log=read(HERE/(prefix+"stdout.log"));check(prefix+"no script or shader errors","SCRIPT ERROR" not in log and "SHADER ERROR" not in log)
manifest=json.loads(read(HERE/"encounter-sources.json"))
check("Current sources match captured evidence",all(sha(ROOT/f)==h for f,h in manifest["sources"].items()))
core=json.loads(read(ROOT/"commons/data/museum_core_encounters.json"));before=json.loads(read(HERE/"before/commons/data/museum_core_encounters.json"))
check("Catalogue chapter hash current",core["rooms"]["Color_Paint"]["text_sha256"]==sha(ROOT/"commons/maps/Color_Paint/final.md"))
for field in ["text_sha256","local_review"]:before["rooms"]["Color_Paint"][field]=core["rooms"]["Color_Paint"][field]
check("Only Paint reference updated in catalogue",before==core)
m=json.loads(read(ROOT/"doc/book/captures/color/color-book.manifest.json"))
check("All eight Colour chapters current",len(m["maps"])==8 and all(sha(ROOT/x["path"])==x["sha256"] for x in m["maps"]))
check("Book capture current",sha(ROOT/"doc/book/captures/color/color-book.md")==m["output_sha256"])
for name in ["color-book.md","color-book.manifest.json"]:shutil.copy2(ROOT/"doc/book/captures/color"/name,HERE/name)
for name in ["shared-aerosol.png","spray-close-up.png","speed-and-coverage.png","before-shared-canvas.png","aerosol-edge-texture.png","held-too-long-texture.png"]:
 with Image.open(HERE/name) as im:im.verify()
check("Published native captures readable",True)
css=re.search(r"<style>(.*?)</style>",read(ROOT/"doc/book/iterations/2026-09-28-paint-spray-cans/index.html"),re.S).group(1)
rows="".join("<tr><td>"+render(c["before"])+"</td><td>"+render(c["after"])+"</td></tr>" for c in changes if not c["before"].startswith("!["))
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Paint — the hand stops first</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">COLOR_PAINT · 28 SEPTEMBER 2026</p><h1>The hand stops first.</h1><p>A finer mist, a slower pass, a little too much paint.</p><nav><a href="#museum">Inside the museum</a><a href="#reading">Read the chapter</a><a href="#changes">Text changes</a><a href="#evidence">What was checked</a></nav></header>
<section id="museum"><figure><img src="shared-aerosol.png" alt="Actual museum studio with purple spray passes, a misted patch and a small paint run crossing the automatic painter's coloured line."><figcaption>The same canvas and thirty cans. Two continuous passes at different speeds, a distant burst on the left, and a close stationary spray on the right. The automatic painter keeps working.</figcaption></figure><figure><img src="spray-close-up.png" alt="Closer view of the actual spray deposits and cans in the museum."><figcaption>Fine specks escape the dense centre. A close lingering spray can leave a narrow run below its patch.</figcaption></figure><p>Grab a can, aim and hold the trigger. On desktop, right-click to carry and hold the left mouse button to spray. Move closer, pull back, sweep, wait. Release stops the nozzle; accumulated paint can keep moving briefly.</p><details><summary>The earlier version and native texture details</summary><figure><img loading="lazy" src="before-shared-canvas.png" alt="Earlier version of the same shared museum painting installation."><figcaption>Earlier native museum capture. Different gestures were made in this session; this is a record of the previous appearance, not a controlled comparison.</figcaption></figure><p><a href="aerosol-edge-texture.png">Actual GPU texture: two speeds and an overspray edge</a> · <a href="held-too-long-texture.png">Actual GPU texture: a concentrated deposit and run</a></p></details></section>
<article id="reading" class="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Color_Paint&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="changes"><h2>A gesture becomes a sentence</h2><p><a href="Color_Paint.diff">Exact manuscript diff</a> · <a href="Color_Paint.current.md">Current chapter</a></p><table><thead><tr><th>Before</th><th>Current</th></tr></thead><tbody>{rows}</tbody></table></section>
<section id="evidence"><h2>What changes in the hand</h2><ul><li>A concentrated core and separate overspray droplets build up on repeated passes.</li><li>One time budget is distributed along a moving stroke. Moving faster leaves less pigment per place.</li><li>Too much local paint starts a narrow gravity run. It slows and stops, and reset clears its wet-load history.</li><li>The nozzle depresses and releases a quiet spatial hiss and mist, including when aimed into empty space.</li><li>Intermediate rays check obstruction; release and lost targets break the stroke.</li></ul><p>55 existing museum checks and 25 focused aerosol checks pass. The slower continuous pass produced approximately 2.39 times the sampled darkness of the faster pass. Native texture measurements find separate outer specks, clean gaps between released gestures, and a run below the held deposit. Counts include camera checks.</p><p>The local wet-load model is an approximation. Paint still participates in this canvas's deliberately changing, gently fading image. The current surface is the canvas; mist does not paint arbitrary walls or objects. Tracked trigger pressure, headset performance and the perceived sound balance still need a headset session.</p><p><a href="report.json">Aerosol checks</a> · <a href="regression-report.json">Existing spray checks</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a> · <a href="encounter-sources.json">Source hashes</a> · <a href="color-book.md">Full Colour capture</a></p></section></main></body></html>"""
soup=BeautifulSoup(page,"html.parser");ids=[n["id"] for n in soup.find_all(id=True)]
check("Unique HTML IDs",len(ids)==len(set(ids)))
check("Local anchors resolve",all(n["href"][1:] in ids for n in soup.find_all("a",href=True) if n["href"].startswith("#")))
check("Footnote renders",soup.select_one(".footnote-backref") is not None)
(HERE/"index.html").write_bytes(page.encode("utf-8"))
(HERE/"checks.json").write_bytes(json.dumps({"passed":True,"checks":checks},indent=2).encode("utf-8"))
print(f"{len(checks)} publication checks passed")
