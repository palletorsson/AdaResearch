"""Enclose the original three transformations on floor 14, with revision checks."""
import copy,json,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"ada_run/transformation14-enclosed-route-2026-10-26"
URL="http://localhost:3003/api/void-layout"

def main():
    OUT.mkdir(exist_ok=True)
    assert not (OUT/"change.json").exists(),"Already applied: preserve later edits."
    payload=json.load(urllib.request.urlopen(URL));rooms=payload["rooms"];before=copy.deepcopy(rooms)
    f=rooms["floors"][14];assert f["map"]=="Trans_Introduction"
    (OUT/"before-rooms.json").write_text(json.dumps(before,indent=2),encoding="utf8")
    # Replace the original west-shaft rim with an enclosure. Retain pyramids
    # the user moved or copied around the east shaft, and all ground studies.
    old_pyramids=[a for a in f["artifacts"] if a["id"].startswith("shaft-rim-pyramid-") and a["position"][0]<0]
    f["artifacts"]=[a for a in f["artifacts"] if a not in old_pyramids]
    old_cells=[c for c in f["construction"] if c["id"].startswith("Leave") or c["id"].startswith("ShaftRim-Plinth-")]
    f["construction"]=[c for c in f["construction"] if c not in old_cells]
    for name,x0,x1,z0,z1 in [("A",-13.75,-6.25,-2.7,2.7),("B",7.65,12.35,-2.85,2.85)]:
        for side,a,b in [("north",[x0,z0],[x1,z0]),("south",[x0,z1],[x1,z1]),("east",[x1,z0],[x1,z1]),("west",[x0,z0],[x0,z1])]:
            f["walls"].append({"id":"trans14-route-"+name+"-"+side,"from":a,"to":b,"height":2,"base":0,"finish":"concrete"})
    sequence=next(a for a in f["artifacts"] if a["id"]=="sequence")
    sequence.setdefault("config",{})["exit_route"]="enclosed_scale_drop"
    f["route"]=[r for r in f["route"] if not any(s in r["label"] for s in ["OVER THE PYRAMIDS","A SOUTH-WEST","THRESHOLDS / AROUND THE WEST RAMP"])]
    f["route"] += [{"label":"03 SCALE / ENTER THE ENCLOSED EXIT","position":[-6.8,0],"height":3},
                   {"label":"LAND ON THE INNER RIM / THEN DROP","position":[-12.95,1.9],"height":0}]
    for i in range(len(rooms["floors"])):
        if i!=14:assert rooms["floors"][i]==before["floors"][i]
    for a in before["floors"][14]["artifacts"]:
        if a["id"]!="sequence" and a not in old_pyramids:assert a in f["artifacts"]
    assert f.get("copies")==before["floors"][14].get("copies")
    request=urllib.request.Request(URL,data=json.dumps({"rooms":rooms,"revision":payload["revision"]}).encode(),headers={"Content-Type":"application/json"},method="POST")
    try:receipt=json.load(urllib.request.urlopen(request))
    except urllib.error.HTTPError as exc:raise RuntimeError(exc.read().decode()) from exc
    (OUT/"change.json").write_text(json.dumps({"receipt":receipt,"floor":14,"new_walls":8,"replaced_west_rim_pyramids":old_pyramids,"removed_west_ramp_and_plinth_cells":old_cells,"preserved":"All other floors, source mechanisms, ground studies, moved east-shaft pyramids and user copies; standard shafts/fall rules."},indent=2),encoding="utf8")
    print("Saved floor 14: ramp, ferry, turning plank, scale chamber and inner-rim descent.")

if __name__=="__main__":main()
