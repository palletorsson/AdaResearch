from pathlib import Path
import hashlib,json,re,shutil,urllib.request
import markdown
from PIL import Image
from bs4 import BeautifulSoup
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render=lambda s:markdown.markdown(s,extensions=["extra"])
js=lambda p:json.loads(read(p))
checks=[]
def check(name,passed):
 checks.append({"name":name,"passed":bool(passed)})
 if not passed:raise ValueError(name)
old=read(HERE/"before/commons/maps/Pattern_Disco/final.md");new=read(ROOT/"commons/maps/Pattern_Disco/final.md")
check("Three artifact anchors and closing anchor retained",re.findall(r"<!--.*?-->",old)==re.findall(r"<!--.*?-->",new))
check("Exact source excerpt retained",re.findall(r"```.*?```",old,re.S)==re.findall(r"```.*?```",new,re.S))
check("Invitation without force retained","Can an invitation to move be felt without a force being applied?" in new)
check("Current chapter snapshot matches",read(HERE/"Pattern_Disco.current.md")==new)
manifest=js(HERE/"encounter-sources.json")
check("All artifact sources and placement unchanged",all((ROOT/f).read_bytes()==(HERE/"before"/f).read_bytes() for f in manifest["sources"]))
check("Native source hashes current",all(sha(ROOT/f)==v for f,v in manifest["sources"].items()))
report=js(HERE/"report.json");check("40 focused native checks pass",report["passed"] and not report["failures"] and len(report["checks"])==40)
log=read(HERE/"stdout.log");check("No script or shader errors","SCRIPT ERROR" not in log and "SHADER ERROR" not in log)
core=js(ROOT/"commons/data/museum_core_encounters.json");previous=js(HERE/"before/commons/data/museum_core_encounters.json")
entry=core["rooms"]["Pattern_Disco"]
check("Catalogue chapter hash current",entry["text_sha256"]==sha(ROOT/"commons/maps/Pattern_Disco/final.md"))
for k in ["text_sha256","local_review"]:previous["rooms"]["Pattern_Disco"][k]=entry[k]
check("Only Disco chapter reference updated",core==previous)
capture=js(ROOT/"doc/book/captures/tiling/tiling-book.manifest.json")
check("All eight Patterns chapters current",len(capture["maps"])==8 and all(sha(ROOT/x["path"])==x["sha256"] for x in capture["maps"]))
check("Capture output hash current",sha(ROOT/"doc/book/captures/tiling/tiling-book.md")==capture["output_sha256"])
for n in ["tiling-book.md","tiling-book.manifest.json"]:shutil.copy2(ROOT/"doc/book/captures/tiling"/n,HERE/n)
photos=["palette-black-white","palette-navy-pink","palette-teal-yellow","palette-violet-mint","checker-pair","triangle-pair","a-band-to-cross","colour-console","triangle-pink","triangle-yellow","sequencer-beside-floor"]
for n in photos:
 with Image.open(HERE/(n+".png")) as im:im.verify()
check("Native photographs and paired figures readable",True)
css=re.search(r"<style>(.*?)</style>",read(ROOT/"doc/book/iterations/2026-09-28-walls-a-view-from-inside/index.html"),re.S).group(1)
changes=js(HERE/"changes.json")
rows="".join("<tr><td>"+render(c["before"])+"</td><td>"+render(c["after"])+"</td></tr>" for c in changes)
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Disco — colour in step</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">PATTERN_DISCO · 28 SEPTEMBER 2026</p><h1>The same floor, another palette.</h1><p>One colour choice reaches every square carrying the same value. The body can answer the pattern in another rhythm.</p><nav><a href="#reading">Read the chapter</a><a href="#museum">Inside the museum</a><a href="#changes">Before and after</a><a href="#decisions">Decisions and evidence</a></nav></header>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Pattern_Disco&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="museum"><h2>A shared decision, seen from the floor</h2><figure><img src="checker-pair.png" alt="The same held checker seen from standing height in navy and pink, then teal and yellow."><figcaption>Same camera, checker phase and tile geometry. Only the palette changes. The comparison is rendered by the actual museum.</figcaption></figure><figure><img src="triangle-pair.png" loading="lazy" alt="A triangle turn held between poses keeps its geometry as its palette changes."><figcaption>The unfinished turn stays unfinished. The same shader pose receives another pair of colours.</figcaption></figure><div class="pair"><figure><img src="a-band-to-cross.png" loading="lazy" alt="A coloured row crosses the otherwise dark floor ahead of the viewer."><figcaption>Walk with the band or across it. The supporting floor keeps its position.</figcaption></figure><figure><img src="colour-console.png" loading="lazy" alt="The placed pattern controls with a separate colour button."><figcaption>The existing COLOUR control changes the pair without restarting the phase. No additional interface was introduced.</figcaption></figure></div><div class="pair"><figure><img src="palette-black-white.png" loading="lazy" alt="The coloured return can use the earlier black and white palette."><figcaption>The earlier black and white pair remains available.</figcaption></figure><figure><img src="palette-violet-mint.png" loading="lazy" alt="The same checker with violet and mint assigned to its binary values."><figcaption>Another pair, the same addresses.</figcaption></figure></div></section>
<section id="changes"><h2>What changed in the writing</h2><p>Begin on one square; let the technical distinction arrive after the comparison. The shared palette gives the critical question a particular scale. The ending turns towards making a source in the Foundry.</p><p><a href="Pattern_Disco.diff">Exact manuscript diff</a> · <a href="before/commons/maps/Pattern_Disco/final.md">Complete previous chapter</a> · <a href="Pattern_Disco.current.md">Current chapter</a></p><table><thead><tr><th>Before</th><th>Current</th></tr></thead><tbody>{rows}</tbody></table></section>
<section id="decisions">{render(read(HERE/"DECISIONS.md"))}<p><a href="report.json">40 native checks</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a> · <a href="encounter-sources.json">Unchanged production sources</a> · <a href="tiling-book.md">Complete Patterns capture</a></p><p>Next: <a href="/compose/sources?map=Pattern_Foundry&amp;doc=final">Pattern_Foundry</a>.</p></section></main></body></html>"""
soup=BeautifulSoup(page,"html.parser");ids=[x["id"] for x in soup.find_all(id=True)]
check("Unique review IDs",len(ids)==len(set(ids)))
check("Section anchors resolve",all(x["href"][1:] in ids for x in soup.find_all("a",href=True) if x["href"].startswith("#")))
check("All photographs resolve",all((ROOT/x["src"].removeprefix("/book-review/")).is_file() if x["src"].startswith("/book-review/") else (HERE/x["src"]).is_file() for x in soup.find_all("img",src=True)))
(HERE/"index.html").write_bytes(page.encode("utf-8"));(HERE/"checks.json").write_bytes(json.dumps({"passed":True,"checks":checks},indent=2).encode())
served=[]
for n in ["index.html","checker-pair.png","triangle-pair.png","a-band-to-cross.png","colour-console.png","palette-black-white.png","palette-violet-mint.png","report.json","Pattern_Disco.diff","tiling-book.md"]:
 matches=urllib.request.urlopen("http://localhost:3003/book-review/doc/book/iterations/2026-09-28-disco-colour-in-step/"+n,timeout=10).read()==(HERE/n).read_bytes();assert matches,n;served.append({"file":n,"matches":matches})
(HERE/"http-checks.json").write_bytes(json.dumps({"passed":True,"files":served},indent=2).encode())
print(f"{len(checks)} publication checks, {len(served)} served files; native 40/40.")
