"""Apply the explicitly requested regularity progression, preserving legacy snapshots."""
from pathlib import Path
import copy
import json

ROOT = Path(__file__).resolve().parents[1]

def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))

def dump(path, data):
    dest = ROOT / path
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

for name, colour in [("Tutorial_Disco", False), ("Pattern_Disco", True)]:
    data = copy.deepcopy(read("commons/maps/Array/map_data.json"))
    w, depth = 19, 23
    data["map_info"].update(name=name, lookup_name=name, title="The floor returns in colour" if colour else "A grid with a clock", dimensions={"width": w, "depth": depth, "max_height": 6})
    data["map_info"]["museum"]["sculpture_clear_rects"] = [[1, 1, w-2, depth-2]]
    data["layers"] = {k: [["6" if k == "structure" and (x in [0,w-1] or z in [0,depth-1]) else ("1" if k == "structure" else "") for x in range(w)] for z in range(depth)] for k in ["structure", "interactables", "utilities"]}
    for x in [8,9,10]: data["layers"]["structure"][0][x] = data["layers"]["structure"][-1][x] = "1"
    data["layers"]["utilities"][1][9] = "s#player_rotation:180"
    data["layers"]["utilities"][-2][9] = "t"
    for x,z,v in [(9,4,"disco_controls#mode:" + ("colour" if colour else "mono")), (3,5,"step_sequencer:180:1.2:1.2#sound_preset:90s_house"), (9,13,"standalone_disco#width:12#depth:12#tile_size:0.8#floor_y_offset:0#walkable:true")]:
        data["layers"]["interactables"][z][x] = v
    dump(f"commons/maps/{name}/map_data.json", data)

data = read("commons/maps/Pattern_Foundry/map_data.json")
data["layers"]["interactables"][5][10] = "pattern_architecture"
if [8,3,12,7] not in data["map_info"]["museum"]["sculpture_clear_rects"]:
    data["map_info"]["museum"]["sculpture_clear_rects"].append([8,3,12,7])
dump("commons/maps/Pattern_Foundry/map_data.json", data)

primaries = {"Array": ["row_3_x", "grid_2d_4x4"], "Tutorial_3D": ["array_flight_lab"], "Tutorial_Tiling_Floor": ["tiling_principles"], "Tutorial_Tiling_Walls": ["tiling_principles"], "Tutorial_Disco": ["disco_controls", "standalone_disco", "step_sequencer"], "Pattern_Disco": ["disco_controls", "standalone_disco", "step_sequencer"]}
data = read("commons/maps/sequences/array_tutorial.json")
s = data["sequences"]["array_tutorial"]
s["maps"] = list(primaries)[:-1]
s["name"] = "Arrays and Regularity"
s["truth"] = "A familiar body becomes addressable copies, a plane, a volume, a repeated surface and a score. The rule and its appearance remain separate things to examine."
s["description"] = "One- and two-dimensional arrays, a flyable three-dimensional lattice, black and white floor and wall tiling, then rhythm on a monochrome disco floor. Color comes next; coloured pattern control returns in tiling."
s["prerequisites"] = ["transformation"]
s["estimated_time"] = "25-35 minutes"
for k in ["retired", "retired_into", "retired_reason"]: s.pop(k, None)
s["deferred_maps"] = [m for m in s.get("deferred_maps",[]) if m != "Tutorial_3D"]
note = "2026-09-17: Tutorial_3D explicitly revived with a Menger-style flight enclosure. New monochrome floor and wall studies precede Disco; coloured Disco returns after Color."
if note not in s["deferred_reason"]: s["deferred_reason"] += " | " + note
s["learning_objectives"] = ["Distinguish index, stored value and displayed position.", "Address a plane with two indices and explore a volume with three.", "Compare the same monochrome tiling rules on floors and walls.", "Distinguish a repeated motif from one local exception.", "Compare stored rhythm with a clock reading it."]
s["content"] = [m + ": " + read(f"commons/maps/{m}/map_data.json")["map_info"]["title"] for m in s["maps"]]
s["artifact_groups"] = [{"map":m, "position":"intro" if i==0 else "development", "artifacts":primaries[m], "rationale":s["content"][i], "size_budget":"environment"} for i,m in enumerate(s["maps"])]
dump("commons/maps/sequences/array_tutorial.json", data)

data = read("commons/maps/sequences/tiling.json")
s = data["sequences"]["tiling"]
s["maps"] = ["Pattern_Disco"] + [m for m in s["maps"] if m != "Pattern_Disco"]
s["name"] = "Patterns: Dress the Architecture"
s["description"] = "Return to the familiar disco with independent pattern and palette controls, then let the foundry machines supply live pattern and colour to architectural walls and floors. Continue through motif operations, symmetry, volume, appearance, shaders and dressed bodies."
s["prerequisites"] = ["array_tutorial", "color"]
s["content"] = ["Pattern_Disco: The familiar floor gains independent colour control"] + [x for x in s["content"] if not x.startswith("Pattern_Disco:")]
s["artifact_groups"] = [g for g in s.get("artifact_groups", []) if g.get("map") != "Pattern_Disco"]
s["artifact_groups"].insert(0, {"map":"Pattern_Disco", "position":"intro", "artifacts":primaries["Pattern_Disco"], "size_budget":"environment", "rationale":"The monochrome lesson returns after Color with a separate palette control."})
for g in s["artifact_groups"]:
    if g.get("map") == "Pattern_Foundry" and "pattern_architecture" not in g["artifacts"]: g["artifacts"].append("pattern_architecture")
dump("commons/maps/sequences/tiling.json", data)

roles = read("commons/data/artifact_roles.json")
for m, tokens in primaries.items():
    placed = [v.split(":")[0].split("#")[0] for row in read(f"commons/maps/{m}/map_data.json")["layers"]["interactables"] for v in row if v.strip()]
    roles["roles"][m] = {t: "primary" if t in tokens else "secondary" for t in placed}
    roles["order"][m] = {"primary":tokens, "secondary":[t for t in placed if t not in tokens], "decoration":[]}
    roles["groups"][m] = []
roles["roles"].setdefault("Pattern_Foundry", {})["pattern_architecture"] = "primary"
if "pattern_architecture" not in roles["order"]["Pattern_Foundry"]["primary"]: roles["order"]["Pattern_Foundry"]["primary"].insert(0,"pattern_architecture")
dump("commons/data/artifact_roles.json", roles)
for seq, maps in [("array_tutorial", list(primaries)[:-1]), ("tiling", ["Pattern_Disco"])]:
    data = read(f"commons/data/book/{seq}.json")
    for m in maps:
        pearl = next((p for p in data["pearls"] if p.get("map") == m), None)
        if pearl is None:
            pearl = {"map":m, "pearl":m.replace("_", " ")}
            data["pearls"].append(pearl)
        pearl["hero"] = primaries[m][0]
        pearl["lines"] = [{"token":t, "text":read(f"commons/maps/{m}/map_data.json")["map_info"]["title"], "by":"draft"} for t in primaries[m]]
        pearl.pop("drop", None)
    if seq == "tiling":
        pearl = next(p for p in data["pearls"] if p.get("map") == "Pattern_Foundry")
        if not any(l.get("token") == "pattern_architecture" for l in pearl["lines"]):
            pearl["lines"].insert(0,{"token":"pattern_architecture", "text":"Four machines can supply the whole architectural surface; source, target, live output, held image, scale and tint are explicit choices.", "by":"draft"})
    dump(f"commons/data/book/{seq}.json", data)
print("Saved the source order, maps, primary roles and book encounters.")
