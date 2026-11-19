"""Shared floor-frame catalogue and desktop camera for the Encyclopedia editor."""
import argparse
import contextlib
import hashlib
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from uuid import uuid4

from void_native_slot import acquire_native_slot
from void_trial_runtime import ROOT, stage_runtime

DATA = ROOT / "commons/data/encounters"
EDITS = DATA / "opera_frame_placements.json"
OUTPUT = ROOT / "ada_run/opera-frame-editor"
WHEEL = "spine_c2b6fc98a64a37b397"
OPENING = {"Point_Zero", "Point_One", "Point_Coordinates", "Point_Lines", "Point_Trace"}
CUES = {
    "chapter_02_point_held":"Lift the point and carry it before returning to the frame.",
    "chapter_02_coordinate_readout":"Look at both coordinate readings, then frame the world readout.",
    "chapter_03_pairing_point_field":"Join two points to make a new edge, then look through the frame.",
    "chapter_04_draw_dot":"Draw a bend with the bead and release it before framing the trace.",
    "chapter_04_bubble_brush":"Hold the brush still so the same bead grows while it is framed.",
    "spine_e4db2c5f61a607c275":"Choose a word at the end of Two Arrivals, then frame the scene.",
}


def read(file):
    return json.loads(file.read_text(encoding="utf-8-sig"))


def replace_json(file, value):
    temp = file.with_name(file.name + "." + uuid4().hex + ".tmp")
    try:
        temp.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        os.replace(temp, file)
    finally:
        temp.unlink(missing_ok=True)


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()


def photo_receipt(index, song):
    return OUTPUT / f"floor-{index}-{digest(song)[:24]}-photo.json"

POSE_KEYS = ("position", "rotation", "width", "height")

def exposure_key(geometry, item):
    pose = item.get("pose") or {}
    return digest([geometry, item["song"], item["title"], [pose.get(k) for k in POSE_KEYS]])


def catalogue(index):
    rooms = read(ROOT / "commons/void/rooms.json")["floors"]
    if not 0 <= index < len(rooms):
        raise ValueError("Unknown floor")
    floor = rooms[index]
    name = floor["map"]
    trajectory = read(DATA / "trajectory_runtime.json")
    bindings = trajectory["maps"].get(name, {})
    if name in trajectory["managed_maps"]:
        coins = trajectory["coins"]
    else:
        coins = read(ROOT / "commons/data/badges/path.json")["coins"]
        bindings = read(ROOT / "commons/data/opera/tower_bindings.json").get("maps", {}).get(name, {})
    policy = read(DATA / (name.lower() + "_progression.json"))["encounters"] if name in OPENING else []
    authored = {e["song"]: e for e in policy if e.get("view_frame")}
    rules = {e["song"]: e for e in policy}
    edits = read(EDITS).get(name, {})
    anchors = [(c["id"], c.get("at"), c.get("stand"), c.get("position"), c.get("y"), c.get("height"), c.get("song"))
               for c in coins if c.get("floor")==name and c.get("song")]
    geometry = digest([policy,bindings,floor,anchors])
    revision = digest([edits,geometry])
    cache = OUTPUT / f"floor-{index}.json"
    measured = read(cache) if cache.exists() else {}
    poses = measured.get("poses", {}) if measured.get("geometry")==geometry else {}
    enabled = read(ROOT / "commons/data/opera/encounter_lines.json").get("enabled", {})
    items = {}
    for c in coins:
        song = c.get("song")
        if c.get("floor") != name or not song or song not in bindings.values(): continue
        spec = authored.get(song, {})
        record = edits.get(song, {})
        edit = record if "position" in record else {}
        required_badge = edit.get("badge") or spec.get("badge")
        if required_badge and c["id"] != required_badge: continue
        if song in items: continue
        wheel = song == WHEEL
        active = bool(edit or spec or wheel)
        source_pose = edit or poses.get(song)
        pose = {k:source_pose[k] for k in POSE_KEYS} if source_pose else None
        at = c.get("at")
        if not at:
            xz = c.get("stand") or c.get("position") or [0, 0]
            at = [xz[0], c.get("height", c.get("y", 0)) + 1.5, xz[1]]
        rule = rules.get(song, {})
        title = edit.get("title") or spec.get("view_frame", {}).get("title") or ("06 · TWO VISITS" if wheel else c.get("name", song))
        items[song] = {"song":song, "badge":c["id"], "title":title, "active":active,
                       "pose":pose, "start":at, "trigger":rule.get("trigger") or CUES.get(song) or ("Complete the encounter, then look through the frame." if rule.get("timing") == "after" else "Turn the wheel past the same mark rising and falling." if wheel else "Look through the frame."),
                       "voiced":bool(enabled.get(song,[song])), "note":record.get("note","")}
    for key, record in edits.items():
        if record.get("kind") == "encounter":
            items[key] = {"song":key, "kind":"encounter", "title":record["title"], "active":True,
                          "pose":{k:record[k] for k in POSE_KEYS}, "start":record["position"],
                          "note":record.get("note",""), "voiced":False}
    # Old receipts use a floor revision. Strip editorial notes when checking those.
    old_edits = {key:{k:v for k,v in row.items() if k!="note"} for key,row in edits.items()
                 if "position" in row and row.get("kind") != "encounter"}
    legacy_revision = digest([old_edits,geometry])
    for key, item in items.items():
        receipt = photo_receipt(index,key)
        if item["active"] and receipt.exists():
            photo = read(receipt)
            if (photo.get("view")==exposure_key(geometry,item) if "view" in photo
                else photo.get("revision")==legacy_revision): item["photo"] = photo
    return {"map":name, "floor":index, "revision":revision, "geometry":geometry, "items":list(items.values())}


def save(index, request, create=False):
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with contextlib.redirect_stdout(sys.stderr), acquire_native_slot("Save opera frame", 3, lock_name="opera-frame-write.lock"):
        doc = catalogue(index)
        if doc["revision"] != request.get("revision"):
            raise ValueError("The floor changed. Reload before saving.")
        key = request.get("song")
        item = next((v for v in doc["items"] if v["song"] == key), None)
        if create:
            if item or not isinstance(key,str) or not re.fullmatch(r"encounter-[a-f0-9]{32}", key):
                raise ValueError("Choose a new encounter.")
        elif not item:
            raise ValueError("Choose a frame on this floor.")
        pose = request["pose"]
        def finite(n, low, high):
            return type(n) in (int,float) and math.isfinite(n) and low <= n <= high
        if not isinstance(pose,dict): raise ValueError("Choose a frame pose.")
        for axis_group, limit in [("position", 1024), ("rotation", 3600)]:
            values = pose.get(axis_group)
            if not isinstance(values, list) or len(values) != 3 or not all(finite(v,-limit,limit) for v in values):
                raise ValueError("Invalid " + axis_group)
        if not all(finite(pose.get(k), .1, 8) for k in ("width","height")):
            raise ValueError("Use an opening between 0.1 and 8 metres.")
        title = str(request.get("title","")).strip()
        if not 1 <= len(title) <= 100 or not title.isprintable(): raise ValueError("Enter a short frame title.")
        edits = read(EDITS)
        rows = edits.setdefault(doc["map"], {})
        record = rows.get(key, {}).copy()
        note = request.get("note",record.get("note",""))
        if not isinstance(note,str) or len(note)>800 or any(ord(c)<32 and c not in "\r\n\t" for c in note):
            raise ValueError("Use a note of up to 800 characters.")
        if create or not item["active"] or item["title"]!=title or any((item.get("pose") or {}).get(k)!=pose[k] for k in POSE_KEYS):
            if create: record["kind"] = "encounter"
            elif item.get("badge"): record["badge"] = item["badge"]
            record.update(title=title, **{k:pose[k] for k in POSE_KEYS})
        if note.strip(): record["note"] = note.strip()
        else: record.pop("note",None)
        if record: rows[key] = record
        else: rows.pop(key,None)
        replace_json(EDITS, edits)
    return catalogue(index)


def native(index, song=None, revision=None):
    doc = catalogue(index)
    if revision and revision != doc["revision"]: raise ValueError("The floor changed. Reload before photographing.")
    if song and not any(i["song"] == song and i["active"] for i in doc["items"]): raise ValueError("Save this frame first.")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with contextlib.redirect_stdout(sys.stderr), acquire_native_slot("Opera frame desktop camera", 8):
        stage = stage_runtime()
        with tempfile.TemporaryDirectory(dir=OUTPUT) as scratch:
            folder = Path(scratch)
            cmd = [os.environ.get("GODOT_EXE",str(Path.home()/"Desktop/Godot_v4.6-stable_win64.exe")),
                   "--no-window","--rendering-method","gl_compatibility","--xr-mode","off","--resolution","960x640",
                   "--path",str(stage),"--script","res://tools/probes/opera_frame_camera.gd","--",
                   "--no-bridges","--no-opening","--opera-quiet",f"--void-start-floor={index}","--out="+scratch]
            if song: cmd.append("--frame-song="+song)
            with (OUTPUT/f"floor-{index}.log").open("w",encoding="utf-8") as log:
                run = subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,timeout=100)
            # The Windows renderer can exit during teardown after the probe has
            # closed its receipt. Accept that specific exit only with its output.
            if run.returncode not in (0,3221225477) or not (folder/"measured.json").exists():
                raise ValueError(f"Godot could not read these frames (exit {run.returncode}). See ada_run/opera-frame-editor/floor-{index}.log")
            poses = read(folder/"measured.json")
            if song and (song not in poses or not (folder/"view.png").is_file()):
                raise ValueError("The game did not return the saved frame and exposure.")
            if catalogue(index)["revision"] != doc["revision"]: raise ValueError("Floor changed during capture. Please retry.")
            replace_json(OUTPUT/f"floor-{index}.json", {"geometry":doc["geometry"],"poses":poses})
            if song:
                token = uuid4().hex
                os.replace(folder/"view.png", OUTPUT/(token+".png"))
                item = next(i for i in doc["items"] if i["song"]==song)
                item["pose"] = item["pose"] or poses[song]
                photo = {"image":token,"aligned":poses[song]["aligned"],"pose":poses[song],"revision":doc["revision"],
                         "view":exposure_key(doc["geometry"],item)}
                replace_json(photo_receipt(index,song),photo)
                return photo
    return catalogue(index)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["list","measure","capture","save","create"])
    parser.add_argument("floor", type=int)
    args = parser.parse_args()
    try:
        request = json.loads(sys.stdin.buffer.read() or b"{}") if args.action in ("save","create","capture") else {}
        result = (catalogue(args.floor) if args.action == "list" else save(args.floor,request,create=args.action=="create")
                  if args.action in ("save","create") else native(args.floor,request.get("song"),request.get("revision")))
        print(json.dumps(result))
    except (ValueError, KeyError, OSError, TimeoutError, subprocess.TimeoutExpired) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
