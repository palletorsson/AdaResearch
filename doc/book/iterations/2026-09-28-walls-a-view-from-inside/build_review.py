from pathlib import Path
import difflib,hashlib,json,re,shutil,urllib.request
import markdown
from PIL import Image
from bs4 import BeautifulSoup
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render=lambda s:markdown.markdown(s,extensions=["extra"])
checks=[]
def check(name,passed):
 checks.append({"name":name,"passed":bool(passed)})
 if not passed:raise ValueError(name)
old=read(HERE/"before/commons/maps/Color_Walls/final.md");new=read(ROOT/"commons/maps/Color_Walls/final.md")
changes=json.loads(read(HERE/"changes.json"));expected=old
for c in changes:expected=expected.replace(c["before"],c["after"],1)
check("Only recorded chapter changes",expected==new)
check("All artifact anchors preserved",re.findall(r"<!--.*?-->",old)==re.findall(r"<!--.*?-->",new))
check("All three code excerpts preserved",len(re.findall(r"```.*?```",new,re.S))==3 and re.findall(r"```.*?```",old,re.S)==re.findall(r"```.*?```",new,re.S))
check("Black-corner accommodation retained","Even the black corner has been brightened slightly" in new)
check("Three production artifacts and map unchanged",all((ROOT/f).read_bytes()==(HERE/"before"/f).read_bytes() for f in ["commons/maps/Color_Walls/map_data.json","algorithms/color/color_mixing/color_constellation_office.gd","algorithms/color/gradient_interpolator/gradient_interpolator.gd","commons/artifacts/color_space_navigator/color_space_navigator.gd"]))
report=json.loads(read(HERE/"report.json"))
check("43 native checks pass",report["passed"] and not report["failures"] and len(report["checks"])==43)
log=read(HERE/"stdout.log");check("No script or shader errors","SCRIPT ERROR" not in log and "SHADER ERROR" not in log)
manifest=json.loads(read(HERE/"encounter-sources.json"))
check("Captured sources still current",all(sha(ROOT/f)==h for f,h in manifest["sources"].items()))
core=json.loads(read(ROOT/"commons/data/museum_core_encounters.json"));prior=json.loads(read(HERE/"before/commons/data/museum_core_encounters.json"))
check("Catalogue text hash current",core["rooms"]["Color_Walls"]["text_sha256"]==sha(ROOT/"commons/maps/Color_Walls/final.md"))
for key in ["text_sha256","local_review"]:prior["rooms"]["Color_Walls"][key]=core["rooms"]["Color_Walls"][key]
check("Only Walls reference updated in catalogue",core==prior)
capture=json.loads(read(ROOT/"doc/book/captures/color/color-book.manifest.json"))
check("All eight captured chapters current",len(capture["maps"])==8 and all(sha(ROOT/x["path"])==x["sha256"] for x in capture["maps"]))
check("Colour output hash current",sha(ROOT/"doc/book/captures/color/color-book.md")==capture["output_sha256"])
for name in ["color-book.md","color-book.manifest.json"]:shutil.copy2(ROOT/"doc/book/captures/color"/name,HERE/name)
for name in ["office-approach","office-glass","office-opaque","inside-glass","inside-opaque","colour-coordinates","gradient-rgb","gradient-hsv"]:
 with Image.open(HERE/(name+".png")) as im:im.verify()
check("Native photographs readable",True)
css=re.search(r"<style>(.*?)</style>",read(ROOT/"doc/book/iterations/2026-09-28-paint-aerosol-and-runs/index.html"),re.S).group(1)
rows="".join("<tr><td>"+render(c["before"])+"</td><td>"+render(c["after"])+"</td></tr>" for c in changes if not c["before"].startswith("!["))
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Walls — a view from inside</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">COLOR_WALLS · 28 SEPTEMBER 2026</p><h1>A view from inside.</h1><p>The pane that let you look in also lets a view reach you here.</p><nav><a href="#reading">Read the chapter</a><a href="#museum">Inside the museum</a><a href="#changes">Exact changes</a><a href="#decisions">Decisions and evidence</a></nav></header>
<section id="museum"><div class="pair"><figure><img src="inside-glass.png" alt="View from inside a furnished glass cubicle towards the aisle and the opposite desk."><figcaption>Glass. The ordinary museum controller has entered through the opening. From beside the chair, the aisle and other desks remain in view.</figcaption></figure><figure><img src="inside-opaque.png" alt="The same inside view after the cubicle partitions become opaque."><figcaption>Opaque. The side pane interrupts the view. The same opening remains; the body has the same route out.</figcaption></figure></div><div class="pair"><figure><img src="office-glass.png" loading="lazy" alt="The chair visible from outside through a coloured pane."><figcaption>Looking in through the pane.</figcaption></figure><figure><img src="office-opaque.png" loading="lazy" alt="The same outside view stopped by an opaque coloured pane."><figcaption>The chair is still there, behind the changed material.</figcaption></figure></div><figure><img src="colour-coordinates.png" loading="lazy" alt="RGB cube and HSV cylinder on their museum plinth."><figcaption>Up adds green in the RGB cube. Up changes value in the HSV cylinder, returning to the vertical rule of the Pillar field.</figcaption></figure><div class="pair"><figure><img src="gradient-rgb.png" loading="lazy" alt="Sixteen cubes follow the RGB route from red to blue."><figcaption>RGB: fixed red and blue endpoints, a darker middle.</figcaption></figure><figure><img src="gradient-hsv.png" loading="lazy" alt="The same sixteen cubes follow the HSV route through bright magenta."><figcaption>HSV: the same endpoints, another path between.</figcaption></figure></div></section>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Color_Walls&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="changes"><h2>The view reaches back</h2><p>The existing three encounters carry this pass. The revision gives the visitor time inside the cubicle and connects the coordinate models to the earlier pillar field.</p><p><a href="Color_Walls.diff">Exact manuscript diff</a> · <a href="Color_Walls.current.md">Current chapter</a></p><table><thead><tr><th>Before</th><th>Current</th></tr></thead><tbody>{rows}</tbody></table></section>
<section id="decisions">{render(read(HERE/"DECISIONS.md"))}<p><a href="report.json">43 native checks</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a> · <a href="encounter-sources.json">Source hashes</a> · <a href="color-book.md">Complete Colour capture</a></p><p>Next: <a href="/compose/sources?map=Pattern_Disco&amp;doc=final">Pattern_Disco</a>, where the familiar floor returns in colour.</p></section></main></body></html>"""
soup=BeautifulSoup(page,"html.parser");ids=[x["id"] for x in soup.find_all(id=True)]
check("Unique review section IDs",len(ids)==len(set(ids)))
check("Review section links resolve",all(x["href"][1:] in ids for x in soup.find_all("a",href=True) if x["href"].startswith("#")))
check("Pictures are actual captured files",all((HERE/x["src"]).exists() for x in soup.find_all("img",src=True) if not x["src"].startswith("/")))
(HERE/"index.html").write_bytes(page.encode("utf-8"));(HERE/"checks.json").write_bytes(json.dumps({"passed":True,"checks":checks},indent=2).encode("utf-8"))
served=[]
for name in ["index.html","inside-glass.png","inside-opaque.png","office-glass.png","office-opaque.png","colour-coordinates.png","gradient-rgb.png","gradient-hsv.png","report.json","Color_Walls.diff","color-book.md"]:
 url="http://localhost:3003/book-review/doc/book/iterations/2026-09-28-walls-a-view-from-inside/"+name
 matches=urllib.request.urlopen(url,timeout=10).read()==(HERE/name).read_bytes();assert matches,name;served.append({"file":name,"matches":matches})
(HERE/"http-checks.json").write_bytes(json.dumps({"passed":True,"files":served},indent=2).encode("utf-8"))
print(f"{len(checks)} publication checks and {len(served)} served files passed. Native: 43/43.")
