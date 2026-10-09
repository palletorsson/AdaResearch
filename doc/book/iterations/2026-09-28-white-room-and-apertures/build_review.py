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
def js(p):return json.loads(read(p))
old=read(HERE/"before/commons/maps/Color_Flashlight/final.md");new=read(ROOT/"commons/maps/Color_Flashlight/final.md")
addition=read(HERE/"addition.md")
without=new.replace(addition,"");without=without[:without.index("\n[^apertures]:")]
check("Established chapter retained, with one new encounter and footnote",without==old)
check("Both primary anchors present",all(f"<!-- @{t} -->" in new for t in ["flashlight_demo","colour_light_rooms"]))
check("Existing source excerpt preserved",re.findall(r"```.*?```",old,re.S)==re.findall(r"```.*?```",new,re.S))
prior=js(HERE/"before/commons/maps/Color_Flashlight/map_data.json");current=js(ROOT/"commons/maps/Color_Flashlight/map_data.json")
changes=[]
for layer,rows in prior["layers"].items():
 for z,row in enumerate(rows):
  for x,cell in enumerate(row):
   if cell!=current["layers"][layer][z][x]:changes.append((layer,x,z,cell,current["layers"][layer][z][x]))
check("Only five old boundary cells opened",changes==[("structure",18,z,"8","1") for z in range(8,13)])
check("All layers rectangular at 42 by 20",all(len(rows)==20 and all(len(row)==42 for row in rows) for rows in current["layers"].values()))
check("New native artifact present",current["layers"]["interactables"][10][25].startswith("colour_light_rooms:"))
reg=js(ROOT/"commons/artifacts/registry/commons_artifacts.json");prev=js(HERE/"before/commons/artifacts/registry/commons_artifacts.json")
check("New scene resolves",(ROOT/reg["artifacts"]["colour_light_rooms"]["scene"].replace("res://","")).is_file())
reg["artifacts"].pop("colour_light_rooms");check("Only the new registry entry added",reg==prev)
for f in ["ada_run/em_plan.json","commons/data/museum/em_plan.json"]:
 a=js(HERE/"before"/f);b=js(ROOT/f)
 changed=[i for i,(x,y) in enumerate(zip(a["plans"],b["plans"])) if x!=y]
 check(f+" only one plan row changed",len(a["plans"])==len(b["plans"]) and len(changed)==1 and b["plans"][changed[0]].get("map")=="Color_Flashlight")
 b["plans"]=a["plans"];check(f+" other metadata preserved",a==b)
old_engine=read(HERE/"before/commons/scenes/endless_museum.gd");engine=read(HERE/"museum-before-parallel-alignment.gd.txt")
start=engine.index('\t# Walk-in architecture may report');end=engine.index('\t# An approach-opening threshold',start)
check("Our engine change is only the opt-in footprint hook",engine[:start]+engine[end:]==old_engine)
core=js(ROOT/"commons/data/museum_core_encounters.json");previous=js(HERE/"before/commons/data/museum_core_encounters.json")
entry=core["rooms"]["Color_Flashlight"]
check("Current chapter and map hashes",entry["text_sha256"]==sha(ROOT/"commons/maps/Color_Flashlight/final.md") and entry["map_sha256"]==sha(ROOT/"commons/maps/Color_Flashlight/map_data.json"))
check("Two encounters promoted",entry["primary_tokens"]==["flashlight_demo","colour_light_rooms"])
core["rooms"]["Color_Flashlight"]=previous["rooms"]["Color_Flashlight"];check("Other catalogue entries unchanged",core==previous)
report=js(HERE/"report.json");check("40 native checks pass",report["passed"] and not report["failures"] and len(report["checks"])==40)
log=read(HERE/"stdout.log");check("No script or shader errors","SCRIPT ERROR" not in log and "SHADER ERROR" not in log)
manifest=js(HERE/"encounter-sources.json");check("Native production sources current",all(sha(ROOT/f)==h for f,h in manifest["sources"].items()))
capture=js(ROOT/"doc/book/captures/color/color-book.manifest.json");check("Eight captured chapters current",len(capture["maps"])==8 and all(sha(ROOT/x["path"])==x["sha256"] for x in capture["maps"]))
check("Capture output current",sha(ROOT/"doc/book/captures/color/color-book.md")==capture["output_sha256"])
for n in ["color-book.md","color-book.manifest.json"]:shutil.copy2(ROOT/"doc/book/captures/color"/n,HERE/n)
photos=["white-room-rose","white-room-blue","white-room-pair","white-room-source-off","apertures-from-floor","aperture-room","apertures-from-landing"]
for n in photos:
 with Image.open(HERE/(n+".png")) as im:im.verify()
check("All seven native photographs/figure readable",True)
for f in ["commons/maps/Color_Flashlight/map_data.json","commons/scenes/endless_museum.gd"]:
 before=read(HERE/"before"/f);after=read(HERE/"museum-before-parallel-alignment.gd.txt") if f=="commons/scenes/endless_museum.gd" else read(ROOT/f)
 (HERE/(Path(f).stem+".diff")).write_bytes(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile="before/"+f,tofile="current/"+f)).encode())
addition_for_review=addition.replace("[^apertures]",'<sup><a href="#fn:apertures">1</a></sup>')
css=re.search(r"<style>(.*?)</style>",read(ROOT/"doc/book/iterations/2026-09-28-walls-a-view-from-inside/index.html"),re.S).group(1)
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>White room / open light</title><style>{css}
.hero img{{width:100%}}.lead{{max-width:65ch}}details{{margin:2rem 0}}summary{{cursor:pointer}}.addition{{max-width:76ch;margin:auto;padding:2rem 0}}
</style></head><body><main>
<header><p class="eyebrow">COLOR_FLASHLIGHT · 28 SEPTEMBER 2026</p><h1>White room / open light.</h1><p class="lead">One light changes the room around you. Beyond its doorway, three openings draw the view upwards.</p><nav><a href="#museum">Inside the museum</a><a href="#addition">The new passage</a><a href="#reading">Complete chapter</a><a href="#decisions">Decisions and checks</a></nav></header>
<section id="museum"><figure class="hero"><img src="white-room-pair.png" alt="The same white room and central suspended light, first in rose and then pale cyan."><figcaption>One white receiver, two moments. Same camera, geometry and surface colour; the central light changes. These are native Godot museum views.</figcaption></figure>
<figure class="hero"><img src="apertures-from-floor.png" alt="Three illuminated rectangular openings above the museum visitor, with the sky beyond."><figcaption>Three ceilings, three real openings. Concealed light washes their white surfaces; narrow luminous reveals mark the lips. The rendered museum sky remains visible beyond.</figcaption></figure>
<div class="pair"><figure><img src="aperture-room.png" loading="lazy" alt="A ramp rises along the right wall to a landing under layered luminous openings."><figcaption>Enter at floor level. The ramp on the right leads to a landing 1.2 metres higher.</figcaption></figure><figure><img src="apertures-from-landing.png" loading="lazy" alt="The ceiling layers overlap differently from the raised landing."><figcaption>After the climb. This camera follows the actual walking body's position at the landing.</figcaption></figure></div>
<p>Find both rooms through the new east-wall opening in <strong>Color_Flashlight</strong>. The original four lamps and faceted sphere remain in the first hall. The light cycles slowly without a panel. Reload the hall in an already running museum to see the addition.</p>
<details><summary>What happens when the central light is hidden?</summary><figure><img src="white-room-source-off.png" loading="lazy" alt="The same room looks neutral when the central coloured light is hidden during the test."><figcaption>A test-only comparison. Removing the source removes its coloured contribution. Other museum illumination remains. The exhibit offers a continuous cycle, not this test switch.</figcaption></figure></details></section>
<article class="reading" id="addition"><p class="eyebrow">ADDED TO FINAL.MD</p>{render(addition_for_review)}<p><a href="Color_Flashlight.diff">Exact chapter diff</a> · <a href="/compose/sources?map=Color_Flashlight&amp;doc=final">Read and comment</a></p></article>
<article class="reading" id="reading"><p class="eyebrow">COMPLETE CURRENT CHAPTER</p>{render(new)}</article>
<section id="decisions">{render(read(HERE/"DECISIONS.md"))}<p><a href="report.json">40 native checks</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served files</a> · <a href="encounter-sources.json">Source hashes</a> · <a href="map_data.diff">Map diff</a> · <a href="endless_museum.diff">Museum footprint hook</a> · <a href="color-book.md">Complete Colour capture</a></p></section></main></body></html>"""
soup=BeautifulSoup(page,"html.parser");ids=[x["id"] for x in soup.find_all(id=True)]
check("Unique review IDs",len(ids)==len(set(ids)))
check("Review anchors resolve",all(a["href"][1:] in ids for a in soup.find_all("a",href=True) if a["href"].startswith("#")))
check("Review photographs resolve",all((ROOT/x["src"].removeprefix("/book-review/")).exists() if x["src"].startswith("/book-review/") else (HERE/x["src"]).exists() for x in soup.find_all("img",src=True)))
(HERE/"index.html").write_bytes(page.encode());(HERE/"checks.json").write_bytes(json.dumps({"passed":True,"checks":checks},indent=2).encode())
served=[]
for n in ["index.html"]+[x+".png" for x in photos]+["report.json","Color_Flashlight.diff","color-book.md"]:
 url="http://localhost:3003/book-review/doc/book/iterations/2026-09-28-white-room-and-apertures/"+n
 matches=urllib.request.urlopen(url,timeout=10).read()==(HERE/n).read_bytes();assert matches,n;served.append({"file":n,"matches":matches})
(HERE/"http-checks.json").write_bytes(json.dumps({"passed":True,"files":served},indent=2).encode())
print(f"{len(checks)} publication checks, {len(served)} served files, 40 native checks passed.")
