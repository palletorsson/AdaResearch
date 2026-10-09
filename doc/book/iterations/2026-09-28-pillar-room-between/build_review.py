from pathlib import Path
import difflib,hashlib,json,re,shutil
import markdown
from bs4 import BeautifulSoup
from PIL import Image
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render=lambda s:markdown.markdown(s,extensions=["extra"])
checks=[]
def check(name,ok):
 checks.append({"name":name,"passed":bool(ok)})
 if not ok:raise ValueError(name)
rel="commons/maps/Color_Pillar/final.md";old=read(HERE/"before"/rel);new=read(ROOT/rel);changes=json.loads(read(HERE/"changes.json"));expected=old
for c in changes:expected=expected.replace(c["before"],c["after"])
check("Only four recorded passage revisions",expected==new)
check("Code, figure and artifact anchors preserved",re.findall(r"```.*?```|<!--.*?-->|!\[[^\]]*\]\([^\n]*\)",old,re.S)==re.findall(r"```.*?```|<!--.*?-->|!\[[^\]]*\]\([^\n]*\)",new,re.S))
check("Opening walk unchanged",old[:old.index("Value stays")]==new[:new.index("Value stays")])
check("Closing and Grid handoff unchanged",old[old.index("The wall does not finish"):]==new[new.index("The wall does not finish"):])
comparison=json.loads(read(HERE/"source-comparison.json"))
for item in comparison["files"]:check("Source match: "+item["path"],item["match"] and sha(ROOT/item["path"])==item["current_sha256"])
core=json.loads(read(ROOT/"commons/data/museum_core_encounters.json"));before=json.loads(read(HERE/"before/commons/data/museum_core_encounters.json"));e=core["rooms"]["Color_Pillar"]
check("Catalogue chapter hash current",e["text_sha256"]==sha(ROOT/rel))
for key in ["text_sha256","local_review"]:before["rooms"]["Color_Pillar"][key]=e[key]
check("Only Pillar catalogue reference changed",core==before)
m=json.loads(read(ROOT/"doc/book/captures/color/color-book.manifest.json"))
check("Eight current Colour chapter sources",len(m["maps"])==8 and all(sha(ROOT/x["path"])==x["sha256"] for x in m["maps"]))
check("Capture content matches its manifest",sha(ROOT/"doc/book/captures/color/color-book.md")==m["output_sha256"])
for name in ["color-book.md","color-book.manifest.json"]:shutil.copy2(ROOT/"doc/book/captures/color"/name,HERE/name)
for name in ["within-the-field.png","carried-colour.png","named-collections.png"]:
 with Image.open(HERE/name) as im:im.verify()
check("Native museum images readable",True)
report=json.loads(read(HERE/"report.json"));check("Dated native report preserved",report["passed"] and len(report["checks"])==32)
(HERE/"Color_Pillar.current.md").write_text(new,encoding="utf-8")
(HERE/"Color_Pillar.diff").write_text("".join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile="before/Color_Pillar/final.md",tofile="current/Color_Pillar/final.md")),encoding="utf-8")
rows="".join("<tr><td><h3>"+c["label"]+"</h3>"+render(c["before"])+"</td><td>"+render(c["after"])+"</td></tr>" for c in changes)
css=re.search(r"<style>(.*?)</style>",read(ROOT/"doc/book/iterations/2026-09-28-rainbow-room-for-a-choice/index.html"),re.S).group(1)
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Pillar — Room between the colours</title><style>{css} figure img {{width:100%;height:auto}} .passages td {{vertical-align:top}}</style></head><body><main>
<header><p class="eyebrow">COLOR_PILLAR · 28 SEPTEMBER 2026 · FIELD, SAMPLE, COMPANY</p><h1>Room between the colours.</h1><p>A colour can have a place in the field without a pillar to stand for it. You can stand there instead.</p><nav><a href="#reading">Read the chapter</a><a href="#changes">Compare passages</a><a href="#museum">Inside the museum</a><a href="#decisions">Decisions and evidence</a></nav></header>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Color_Pillar&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="changes"><h2>Four small changes</h2><p>{len(old.split())} → {len(new.split())} words, including code and caption. <a href="Color_Pillar.diff">Exact text difference</a> · <a href="Color_Pillar.current.md">Current Markdown</a></p><table class="passages"><thead><tr><th>Before</th><th>Current final.md</th></tr></thead><tbody>{rows}</tbody></table></section>
<section id="museum"><h2>The field leaves room for a body.</h2><figure><img src="within-the-field.png" loading="lazy" alt="A view between tall coloured pillars, with the gradient floor visible in the gaps."><figcaption>Native Godot museum capture, 23 September 2026. The camera stands at the ordinary walker's reached position plus eye height. Reused for this writing pass.</figcaption></figure><figure><img src="carried-colour.png" loading="lazy" alt="A labelled colour swatch held among the pillars after leaving its named collection."><figcaption>Native capture, 23 September 2026. A real swatch follows the supplied grabber into the field; its material and label remain. Its code is #B87333 and the artifact's nearest-name list calls it Peru.</figcaption></figure><figure><img src="named-collections.png" loading="lazy" alt="Twelve named palette sets mounted on a wall in the museum."><figcaption>Native capture, 23 September 2026. The titles name associations chosen by the collection's author.</figcaption></figure></section>
<section id="decisions" class="decisions">{render(read(HERE/'DECISIONS.md'))}<p><a href="source-comparison.json">Relevant source comparison</a> · <a href="report.json">23 September native report</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a> · <a href="color-book.md">Current Colour capture</a></p></section>
<footer><p>Previous: <a href="/book-review/doc/book/iterations/2026-09-28-rainbow-walk-and-sparks/index.html">Rainbow — The walk releases sparks</a>. Next: <a href="/compose/sources?map=Color_Grid_Pallet&amp;doc=final">Color_Grid_Pallet</a>.</p></footer></main></body></html>"""
soup=BeautifulSoup(page,"html.parser");ids=[n["id"] for n in soup.find_all(id=True)]
check("Rendered IDs unique",len(ids)==len(set(ids)))
check("Internal navigation resolves",all(n["href"][1:] in ids for n in soup.find_all("a",href=True) if n["href"].startswith("#")))
(HERE/"index.html").write_text(page,encoding="utf-8")
(HERE/"checks.json").write_text(json.dumps({"passed":True,"scope":"Publication and selected source checks; dated native evidence reused. No fresh runtime test.","checks":checks},indent=2),encoding="utf-8")
print(f"{len(checks)} checks passed; {len(old.split())} -> {len(new.split())} words.")
