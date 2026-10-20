"""Place every Trans_Rotation encounter on the existing tower storey."""
from pathlib import Path
import copy, hashlib, json, urllib.request

ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / "doc/book/iterations/2026-10-20-rotation-full-floor"
REPORT.mkdir(parents=True, exist_ok=True)
URL = "http://localhost:3003/api/void-layout"

def fetch():
    return json.load(urllib.request.urlopen(URL))

current = fetch()
before = current["rooms"]
if not (REPORT / "before-rooms.json").exists():
    (REPORT / "before-rooms.json").write_text(json.dumps(before, indent=2)+"\n", encoding="utf8")
    (REPORT / "before-layout.json").write_bytes((ROOT / "commons/void/layout.json").read_bytes())
    hashes = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
              for p in (ROOT / "commons/maps").glob("Trans_*/*.md")}
    (REPORT / "text-hashes.json").write_text(json.dumps(hashes, indent=2)+"\n")
floor = copy.deepcopy(before["floors"][16])
assert floor["map"] == "Trans_Rotation"
floor["title"] = "Rotation / axes, paths, order and return"
floor["artifacts"] = []
floor["route"] = []
floor["construction"] = [v for v in floor["construction"] if v["id"] in
                        ["cube-1", "cube-3", "cube-5", "cube-7", "wedge-6", "wedge-8", "rotating_platform-9"]]

def cell(name, kind, x, y, z, facing=0):
    floor["construction"].append(dict(id=name, kind=kind, position=[x,y,z], facing=facing))

def cube_bank(name, xs, zs, levels=2):
    for x in xs:
        for z in zs:
            for y in range(levels):
                cell(f"{name}-{x}-{y}-{z}".replace(".", "p"), "cube", x, y, z)

def artifact(name, kind, x, z, facing=0, scale=1, height=0, **config):
    floor["artifacts"].append(dict(id=name, artifact=kind, position=[x,z],
                                  station=("N" if z<0 else "S")+("W" if x<0 else "E"),
                                  facing=facing, height=height, scale=scale, config=config))

def caption(label, x, z, height=0):
    floor["route"].append(dict(label=label, position=[x,z], height=height))

# Keep the original marked Y ride. Approach from its north bank, clear of the tunnel.
cell("YApproach", "wedge", 14.5, 0, -2, 0)
artifact("axis-x", "rotation_wall_crossings", -16.8, -.5,
         single_axis="X", ride_rise=2, ride_run=4, editor_label="X / upright end-platform")
artifact("axis-z", "rotation_wall_crossings", -10, 1.8,
         single_axis="Z", ride_rise=2, ride_run=4, editor_label="Z / upright end-platform")
cube_bank("XBank", [-19.5,-18.5], [3,4])
cell("XUpperRamp","wedge",-19,1,5.5,180)
cell("XLowerRamp","wedge",-19,0,7.5,180)
cube_bank("ZBank", [-6.5], [-.5,.5])
cell("ZUpperRamp","wedge",-6.5,1,2,180)
cell("ZLowerRamp","wedge",-6.5,0,4,180)

# Same four bands, two columns and six angles as the museum.
# Their cubes halve in size; the two test-body widths do not.
artifact("angle-bands", "rotation_array_compare", 0, -3.3,
         columns=2, rows=6, band_spacing=7, row_angle_step=18,
         tower_bands=True, editor_label="X / Y / Z / XYZ - walk and replay")
cube_bank("ArrayStart", [i+.5 for i in range(-6,6)], [-5.5,-4.5])
cube_bank("ArrayEnd", [i+.5 for i in range(-6,6)], [3.5,4.5])
for name,z in [("North",-5),("South",4.5)]:
    cell(name+"ArrayUpper","wedge",7,1,z,270)
    cell(name+"ArrayStep","cube",8.5,0,z)
cell("NorthArrayLower","wedge",10,0,-5,270)

# Every original carousel profile. A narrow perimeter gallery leaves the routes open.
for profile,x,scale in [("cake",-17,.3),("column",-11,.4),("ziggurat",-1.5,.3),
                        ("spindle",2.3,.3),("flare",10,.3)]:
    artifact("carousel-"+profile,"carousel_cake",x,-7,scale=scale,
             profile=profile,gallery="clean",editor_label=profile+" / eight speeds")
    caption(profile.upper()+" / SAME SPEED RULE",x,-5.7)

artifact("turn-order-film","film_transformation_order",5.8,6,270,
         editor_label="Film / transformation order")
artifact("axial-sweep","axial_sweep",-6.3,6.5,180,editor_label="A face sweeps a boundary")
artifact("composition","transform_composition_workbench",-11,5.8,0,
         initial_pair=4,workings="trace",editor_label="X then Y / Y then X")
artifact("twisting-tunnel","boolean_tunnel",18.1,-8,0,
         segment_vertical_offset=-.65,num_segments=5,rotation_per_segment=18,
         accrual="ramp",editor_label="Walk through five accumulated turns")
artifact("hinge","hinge_release",-1,6,90,tower_floor=True,
         editor_label="Hinge / KEEP, RETURN, RELEASE, TRACE")
caption("01 / Y - KEEP THE CENTRE",14.4,-3.8)
caption("02 / SAME BODY - FOUR ROTATION RULES",0,-4.5,2)
caption("03 / X AND Z - RIDE THE UPRIGHT END",-15,-3.9)
caption("04 / DOES THE ORDER MATTER?",-11,8.2)
caption("05 / SWEEP - KEEP - RETURN",2.7,7.7)
caption("06 / WALK THROUGH THE TURN",18.1,-7.5)

rooms = copy.deepcopy(before)
rooms["floors"][16] = floor
request = urllib.request.Request(URL, data=json.dumps(dict(rooms=rooms,revision=current["revision"])).encode(),
                                 headers={"Content-Type":"application/json"}, method="POST")
with urllib.request.urlopen(request) as response:
    receipt = json.load(response)
after = fetch()["rooms"]
assert after["floors"][:16] == before["floors"][:16], "Other curated floors changed during save"
assert after["floors"][16] == floor
(REPORT / "save-receipt.json").write_text(json.dumps(receipt,indent=2)+"\n")
(REPORT / "placed-floor.json").write_text(json.dumps(floor,indent=2)+"\n")
print(json.dumps(dict(artifacts=len(floor["artifacts"]),construction=len(floor["construction"]),
                      revision=receipt["revision"],warnings=receipt.get("warnings",[]))))
