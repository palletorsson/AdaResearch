"""Apply the user's two-shaft descent arrangement to Rotation only."""
from pathlib import Path
import copy, json, urllib.request
ROOT=Path(__file__).resolve().parents[1]
REPORT=ROOT/"doc/book/iterations/2026-10-20-rotation-full-floor"
URL="http://localhost:3003/api/void-layout"
state=json.load(urllib.request.urlopen(URL))
rooms=copy.deepcopy(state["rooms"])
floor=rooms["floors"][16]
catalog_path=ROOT/"commons/void/catalog.json"
catalog=json.loads(catalog_path.read_text(encoding="utf8"))
for key,scene,label,footprint in [
    ("void_rotation_wheel","rotation_descent_wheel","Rotation / wheel to next floor",[5,6,6]),
    ("void_rotation_boolean_descent","rotation_boolean_descent","Rotation / downward Boolean passage",[4.3,3.6,4.3]),
    ("void_rotation_landing","rotation_landing","Rotation / receiving platform",[4.5,.25,3])]:
    catalog["artifacts"][key]=dict(scene="res://commons/void/"+scene+".tscn",label=label,
                                  footprint=footprint,museum_import=True)
catalog_path.write_text(json.dumps(catalog,indent=2)+"\n",encoding="utf8")
for item in floor["artifacts"]:
    if item["id"]=="axis-x":
        item.update(artifact="void_rotation_wheel",position=[-10,0])
        item["config"]={"connects_next_floor":True,"turn_speed":12,"pause":8,
                        "editor_label":"X / wheel down to the next floor"}
    elif item["id"]=="axis-z":
        item["position"]=[-16.5,4.5]
    elif item["id"]=="twisting-tunnel":
        item.update(artifact="void_rotation_boolean_descent",position=[10,0])
        item["config"]={"connects_next_floor":True,"editor_label":"Five hollow cubes / turn down into the shaft"}
    elif item["id"]=="turn-order-film":
        item["position"]=[15.5,6]

# Keep each painted cube/wedge independently editable.
floor["construction"]=[v for v in floor["construction"]
                       if v["id"].startswith(("Array","North","South"))]
floor["construction"]=[v for v in floor["construction"] if not v["id"].startswith("South")]
def cell(name,kind,x,y,z,facing=0,**settings):
    floor["construction"].append(dict(id=name,kind=kind,position=[x,y,z],facing=facing,**settings))
cell("rotating_platform-9","rotating_platform",17,1,1,angle=-90,turn_speed=9,pause=6,length=4)
cell("YBank","cube",19.5,0,1)
cell("YApproach","wedge",19.5,0,-.5)
cell("YExitBank","cube",17,0,3.5)
cell("YExitRamp","wedge",17,0,5,180)
for x in [-13.5,-12.5]:
    # Keep the shaft edge at x=-12.5 free: dock entirely west of that edge.
    x-=.5
    for z in [2,3]:
        for y in [0,1]:
            cell(f"ZDock-{x}-{y}-{z}".replace(".","p"),"cube",x,y,z)
cell("ZUpperRamp","wedge",-13,1,4.5,180)
cell("ZLowerRamp","wedge",-13,0,6.5,180)
cell("SouthArrayUpper","wedge",7,1,4.5,270)
cell("SouthArrayStep","cube",8.5,0,4.5)
cell("SouthArrayLower","wedge",10,0,4.5,270)
floor["route"]=[r for r in floor["route"] if not r["label"].startswith(("01","03","06"))]
floor["route"] += [
    {"label":"Y / THE CENTRE STAYS","position":[19.5,-2]},
    {"label":"X / BOARD WEST - RIDE DOWN","position":[-13.5,-.6]},
    {"label":"Z / THE UPRIGHT END","position":[-19,2.3]},
    {"label":"TURN THE CORRIDOR DOWN / LAND BELOW","position":[10,-3.8]},
]
floor["title"]="Rotation / build, compare, descend"
landing=dict(map="Trans_Scale",title="Scale / arrival from Rotation",origin=False,
             supply_leads=False,artifacts=[
                 dict(id="rotation-landing",artifact="void_rotation_landing",station="NE",
                      position=[10,0],facing=0,height=0,scale=1,
                      config={"editor_label":"Landing below the rotated Boolean passage"})],
             props=[],walls=[],construction=[],impact_cells=[],
             route=[dict(label="ARRIVAL / SCALE IS NEXT",position=[4,0])])
if len(rooms["floors"])==17: rooms["floors"].append(landing)
else: assert rooms["floors"][17]["title"]==landing["title"]
frame_path=ROOT/"commons/void/layout.json"
frame=json.loads(frame_path.read_text(encoding="utf8"))
old_frame=frame_path.read_bytes()
if len(frame["levels"])==17:
    frame["levels"].append(-102)
    frame["floor_roles"].append("Floor 17 / Scale arrival")
frame["floor_styles"]["17"]="abstract"
frame["spawn_points"]["17"]=[4,.06,0]
frame["status"]="Rotation contains the museum studies and two routes to the Scale arrival; 18 floors."
frame_path.write_text(json.dumps(frame,indent=2)+"\n",encoding="utf8")
try:
    req=urllib.request.Request(URL,data=json.dumps(dict(rooms=rooms,revision=state["revision"])).encode(),
                               headers={"Content-Type":"application/json"},method="POST")
    with urllib.request.urlopen(req) as res: receipt=json.load(res)
except Exception:
    frame_path.write_bytes(old_frame)
    raise
after=json.load(urllib.request.urlopen(URL))["rooms"]
assert after["floors"][:16]==state["rooms"]["floors"][:16]
(REPORT/"save-receipt.json").write_text(json.dumps(receipt,indent=2)+"\n")
(REPORT/"placed-floor.json").write_text(json.dumps(floor,indent=2)+"\n")
print(json.dumps({"floors":len(after["floors"]),"rotation_artifacts":len(floor["artifacts"]),
                  "warnings":[w for w in receipt.get("warnings",[]) if w.startswith(("Floor 16:","Floor 17:"))]}))
