"""Populate the existing Scale arrival; preserve every earlier curated floor."""
from pathlib import Path
import copy, hashlib, json, urllib.request
ROOT=Path(__file__).resolve().parents[1]
REPORT=ROOT/"doc/book/iterations/2026-10-20-carousels-and-scale"
REPORT.mkdir(parents=True,exist_ok=True)
URL="http://localhost:3003/api/void-layout"
state=json.load(urllib.request.urlopen(URL))
rooms=copy.deepcopy(state["rooms"])
floor=rooms["floors"][17]
assert floor["title"]=="Scale / arrival from Rotation", "Review current floor before restaging."
(REPORT/"before-rooms.json").write_text(json.dumps(rooms,indent=2)+"\n")
(REPORT/"text-hashes.json").write_text(json.dumps({
    str(p.relative_to(ROOT)).replace("\\","/"):hashlib.sha256(p.read_bytes()).hexdigest()
    for p in (ROOT/"commons/maps").glob("Trans_*/*.md")},indent=2))
catalog_file=ROOT/"commons/void/catalog.json"
catalog=json.loads(catalog_file.read_text(encoding="utf8"))
catalog["artifacts"]["void_scale_chamber"]={
    "scene":"res://commons/void/scale_chamber.tscn","museum_import":True,
    "label":"Scale / original Drink Me and exterior foundation",
    "footprint":[20.4,14.8,26.9],
    "description":"Original fourfold room, bottle, serving-plate descent and fixed witness doorway. The foundation and return route stay full size."
}
catalog_file.write_text(json.dumps(catalog,indent=2)+"\n",encoding="utf8")
variants=[
    ("cake","cake",[-17,-4.2],.4,1.2,False,"EACH LAYER / 1.2 TIMES FASTER"),
    ("together","cake",[-3,-4.2],.3,1,False,"ALL EIGHT LAYERS / ONE SPEED"),
    ("opposed","cake",[3,-4.2],.4,1.2,True,"NEIGHBOURING LAYERS / OPPOSITE TURNS"),
    ("spindle","spindle",[17,-4.2],.4,1.2,False,"SAME SPEED RULE / CHANGED PROFILE"),
    ("flare","flare",[-17,4.2],.4,1.2,False,"SAME SPEED RULE / WIDENING"),
    ("ziggurat","ziggurat",[0,4.2],.4,1.2,False,"SAME SPEED RULE / NARROWING"),
    ("column","column",[17,4.2],.6,1.2,False,"SAME RADIUS / DIFFERENT SPEEDS"),
]
for key,profile,position,scale,multiplier,opposed,caption in variants:
    floor["artifacts"].append(dict(
        id="carousel-"+key,artifact="carousel_cake",station="NW",position=position,
        facing=0,height=0,scale=scale,config=dict(profile=profile,gallery="clean",
        base_speed=.3,speed_multiplier=multiplier,alternate_direction=opposed,
        motion_caption=caption,editor_label="Carousel / "+key)))
floor["artifacts"].append(dict(
    id="drink-me",artifact="void_scale_chamber",station="SE",position=[0,15],
    facing=0,height=0,scale=1,config={"editor_label":"Drink Me / room, bridge and return path"}))
floor["title"]="Seven carousels / Drink Me"
floor["route"]=[
    dict(label="ROTATION BECOMES A ROOM OF TURNS",position=[4,0]),
    dict(label="SCALE / FOLLOW THE BRIDGE",position=[0,8]),
]
request=urllib.request.Request(URL,data=json.dumps({"rooms":rooms,"revision":state["revision"]}).encode(),
    headers={"Content-Type":"application/json"},method="POST")
try:
    receipt=json.load(urllib.request.urlopen(request))
except urllib.error.HTTPError as error:
    print(error.read().decode());raise
(REPORT/"save-receipt.json").write_text(json.dumps(receipt,indent=2)+"\n")
after=json.load(urllib.request.urlopen(URL))["rooms"]
assert after["floors"][:17]==state["rooms"]["floors"][:17]
assert len(after["floors"])==18
(REPORT/"placed-floor.json").write_text(json.dumps(after["floors"][17],indent=2)+"\n")
print(json.dumps({"saved":receipt.get("saved"),"artifacts":len(floor["artifacts"]),
                  "warnings":[s for s in receipt.get("warnings",[]) if "17" in s]}))
