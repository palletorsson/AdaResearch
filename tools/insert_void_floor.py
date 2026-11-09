"""Insert one floor into the main Void tower and renumber everything that names a floor BY INDEX.

    python tools/insert_void_floor.py --after Trans_Carousel --map Trans_Scale --title "Scale / Drink Me" --storey 12 \
        [--sequence transformation] [--role "..."] [--apply] [--stage-head]

Without --apply it only prints what it would change (a dry run). With --apply it writes the working tree; with
--stage-head it also writes the same change onto each tracked file's staged (index) version and stages that blob (so a commit
carries this insert and nothing of another session's uncommitted work in the same files - the tower files usually have
some). Floors are found by MAP NAME in each version, so a version with an extra uncommitted floor renumbers correctly.

What names a floor by index (found 2026-11-09; the Logic and Trans_Playground inserts had to remap the same set):
  rooms.json             the new floor (after --after), every config.editor_source.floor
  layout.json            levels (the new floor takes the old level; everything below drops by --storey), floor_roles,
                         floor_styles / spawn_points / floor_sign_positions / floor_sources / floor_columns keys,
                         descent.pad_shafts / pad_x_sides keys, descent.pad_disabled_floors, spine[].floors
  spine.json             floors[].floor and source.floor (main-tower sources), a new row; sequences = layout.spine
  primitive-prefabs.json placement.source_floor
  artifact_timeline.json main and environment rows' floor
  ada_encyclopedia/public/void-models/manifest.json  floors keys
  user://void_space_build_<n>.json (the glass-box editor's saves on this machine) are renamed
NOT renumbered (reported instead): probes and tools that hard-code a floor number. Find floors by map name.
The new floor starts with the previous floor's spawn point, descent shaft and style; edit them after."""
import argparse, copy, json, os, re, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT.parent / "ada_encyclopedia"
VOID = ROOT / "commons/void"
ROOMS = VOID / "rooms.json"
LAYOUT = VOID / "layout.json"
SPINE = VOID / "spine.json"
PREFABS = VOID / "primitive-prefabs.json"
TIMELINE = ROOT / "commons/data/artifact_timeline.json"
MANIFEST = WEB / "public/void-models/manifest.json"
USERDATA = Path(os.environ.get("APPDATA", "")) / "Godot/app_userdata/Ada Research Zero One"


def git_head(path: Path):
    rel = path.relative_to(ROOT).as_posix() if ROOT in path.parents else None
    cwd = ROOT if rel else WEB
    rel = rel or path.relative_to(WEB).as_posix()
    # the INDEX version: HEAD plus whatever is already staged, so staged edits stack under the insert
    r = subprocess.run(["git", "show", ":" + rel], cwd=cwd, capture_output=True)
    return (r.stdout if r.returncode == 0 else None), cwd, rel


def stage_bytes(cwd, rel, data: bytes):
    sha = subprocess.run(["git", "hash-object", "-w", "--no-filters", "--stdin"], cwd=cwd, input=data,
                         capture_output=True, check=True).stdout.decode().strip()
    subprocess.run(["git", "update-index", "--cacheinfo", "100644,%s,%s" % (sha, rel)], cwd=cwd, check=True)


def dump(doc, nl="\n", indent=2, ascii=False) -> bytes:
    s = json.dumps(doc, indent=indent, ensure_ascii=ascii) + "\n"
    return (s.replace("\n", nl) if nl != "\n" else s).encode("utf-8")


def newline_of(raw: bytes) -> str:
    return "\r\n" if b"\r\n" in raw else "\n"


# ---------- per-file transforms (pure: a parsed document in, the same document changed) ----------

def moved_fn(at):
    return lambda i: i + 1 if isinstance(i, int) and i >= at else i


def rooms_doc(doc, after, new_floor):
    maps = [f["map"] for f in doc["floors"]]
    assert new_floor["map"] not in maps, "map %s already in the tower" % new_floor["map"]
    at = maps.index(after) + 1
    mv = moved_fn(at)
    for f in doc["floors"]:
        for a in f.get("artifacts", []) + f.get("copies", []):
            src = (a.get("config") or {}).get("editor_source")
            if isinstance(src, dict) and isinstance(src.get("floor"), int):
                src["floor"] = mv(src["floor"])
    doc["floors"].insert(at, new_floor)
    return at


def rooms_text(raw: str, after, new_floor):
    """The working rooms.json is hand-formatted in places: insert the new floor as text and renumber editor_source
    floors with a regex, then check the result parses to exactly what the structural transform gives."""
    expect = json.loads(raw)
    at = rooms_doc(expect, after, copy.deepcopy(new_floor))
    mv = moved_fn(at)
    nl = "\r\n" if "\r\n" in raw else "\n"
    pat = re.compile(r'("editor_source"\s*:\s*\{[^{}]*?"floor"\s*:\s*)(\d+)')
    raw = pat.sub(lambda m: m.group(1) + str(mv(int(m.group(2)))), raw)
    # the end of the --after floor's block
    m = re.search(r'"map":\s*"%s"' % re.escape(after), raw)
    i = m.start(); depth = 0
    while True:
        i -= 1
        if raw[i] == "}": depth += 1
        elif raw[i] == "{":
            if depth == 0: break
            depth -= 1
    start = i; depth = 0; j = start; ins = False; esc = False
    while True:
        c = raw[j]
        if ins:
            if esc: esc = False
            elif c == "\\": esc = True
            elif c == '"': ins = False
        elif c == '"': ins = True
        elif c == "{": depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0: end = j + 1; break
        j += 1
    indent = raw[raw.rfind("\n", 0, start) + 1:start]
    block = json.dumps(new_floor, indent=2, ensure_ascii=False).replace("\n", "\n" + indent)
    if nl == "\r\n": block = block.replace("\n", "\r\n")
    raw = raw[:end] + "," + nl + indent + block + raw[end:]
    assert json.loads(raw) == expect, "text insert disagrees with the structural transform"
    return raw, at


def layout_doc(doc, at, title, storey):
    mv = moved_fn(at)
    levels = doc["levels"]
    doc["levels"] = levels[:at] + [levels[at] if at < len(levels) else levels[-1] - doc["storey_height"]] + \
        [round(l - storey, 6) for l in levels[at:]]
    if "floor_roles" in doc:
        doc["floor_roles"].insert(at, title)
    for key in ["floor_styles", "spawn_points", "floor_sign_positions", "floor_sources", "floor_columns"]:
        if key in doc:
            old = doc[key]
            doc[key] = {str(mv(int(k))): v for k, v in old.items()}
            if key in ("floor_styles", "spawn_points") and str(at - 1) in old:
                doc[key][str(at)] = copy.deepcopy(old[str(at - 1)])
    d = doc.get("descent", {})
    for key in ["pad_shafts", "pad_x_sides"]:
        if key in d:
            old = d[key]
            d[key] = {str(mv(int(k))): v for k, v in old.items()}
            if str(at - 1) in old:
                d[key][str(at)] = copy.deepcopy(old[str(at - 1)])
    if "pad_disabled_floors" in d:
        d["pad_disabled_floors"] = [mv(i) for i in d["pad_disabled_floors"]]
    for group in doc.get("spine", []):
        had = (at - 1) in group["floors"]
        group["floors"] = [mv(i) for i in group["floors"]]
        if had:
            group["floors"] = sorted(group["floors"] + [at])


def spine_doc(doc, at, map_name, title, sequence, layout):
    mv = moved_fn(at)
    for f in doc["floors"]:
        f["floor"] = mv(f["floor"])
        src = f.get("source", {})
        if not src.get("trial") and isinstance(src.get("floor"), int):
            src["floor"] = mv(src["floor"])
    i = next((k for k, f in enumerate(doc["floors"]) if f["floor"] > at), len(doc["floors"]))
    doc["floors"].insert(i, {"floor": at, "map": map_name, "sequence": sequence, "title": title,
                             "source": {"trial": "", "floor": at}})
    if layout is not None and "spine" in layout:
        doc["sequences"] = copy.deepcopy(layout["spine"])


def prefabs_doc(doc, at):
    mv = moved_fn(at)
    for p in doc.get("prefabs", []):
        pl = p.get("placement")
        if isinstance(pl, dict) and isinstance(pl.get("source_floor"), int):
            pl["source_floor"] = mv(pl["source_floor"])


def timeline_doc(doc, at):
    mv = moved_fn(at)
    n = 0
    for track in ("main", "environment", "removed"):
        for r in doc.get(track, []):
            if isinstance(r.get("floor"), int) and r["floor"] >= at:
                r["floor"] = mv(r["floor"]); n += 1
    return n


def manifest_doc(doc, at):
    mv = moved_fn(at)
    if "floors" in doc:
        doc["floors"] = {str(mv(int(k))): v for k, v in doc["floors"].items()}


def hardcoded_refs(at):
    pat = re.compile(r"(FLOOR|floor|requested_floor|start-floor=|--floor)\s*(:?=|==)?\s*(\d{2,3})\b")
    hits = []
    for base in [ROOT / "tools", ROOT / "commons/testing"]:
        for p in base.rglob("*"):
            if p.suffix not in (".gd", ".py") or p.name == Path(__file__).name: continue
            try: text = p.read_text(encoding="utf-8")
            except Exception: continue
            for ln, line in enumerate(text.splitlines(), 1):
                for m in pat.finditer(line):
                    if int(m.group(3)) >= at:
                        hits.append("%s:%d" % (p.relative_to(ROOT).as_posix(), ln))
    return hits


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--after", required=True, help="map name of the floor the new one follows")
    ap.add_argument("--map", required=True)
    ap.add_argument("--title", required=True)
    ap.add_argument("--role", help="layout.floor_roles text (default: the title)")
    ap.add_argument("--storey", type=float, default=6.0, help="the new floor's height in metres (6 single, 12 double)")
    ap.add_argument("--sequence", default="")
    ap.add_argument("--floor-json", help="a JSON file holding the new floor record (artifacts etc.); default empty")
    ap.add_argument("--floor-json-head", help="the record for the staged version, when it must differ (e.g. leave out a "
                    "placement that exists only uncommitted in the working tree)")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--stage-head", action="store_true")
    args = ap.parse_args()
    floor = {"map": args.map, "title": args.title, "origin": False, "walls": [], "artifacts": [], "props": [],
             "impact_cells": [], "route": [], "supply_leads": False}
    if args.floor_json:
        floor.update(json.loads(Path(args.floor_json).read_text(encoding="utf-8")))
        floor["map"] = args.map; floor["title"] = args.title
    role = args.role or args.title

    # ---- working tree
    raw_rooms = ROOMS.read_bytes().decode("utf-8")
    new_rooms, at = rooms_text(raw_rooms, args.after, floor)
    print("insert %s at index %d (after %s); floors >= %d move down one" % (args.map, at, args.after, at))
    outputs = {ROOMS: new_rooms.encode("utf-8")}
    lay_raw = LAYOUT.read_bytes(); lay = json.loads(lay_raw)
    layout_doc(lay, at, role, args.storey)
    outputs[LAYOUT] = dump(lay, newline_of(lay_raw))
    sp_raw = SPINE.read_bytes(); sp = json.loads(sp_raw)
    spine_doc(sp, at, args.map, args.title, args.sequence, lay)
    outputs[SPINE] = dump(sp, newline_of(sp_raw))
    pf_raw = PREFABS.read_bytes(); pf = json.loads(pf_raw)
    prefabs_doc(pf, at)
    outputs[PREFABS] = dump(pf, newline_of(pf_raw))
    sys.path.insert(0, str(ROOT / "tools"))
    import artifact_timeline as atl
    tl = atl.read(atl.AUTHORED)
    n_rows = timeline_doc(tl, at)
    if MANIFEST.exists():
        mf_raw = MANIFEST.read_bytes(); mf = json.loads(mf_raw)
        manifest_doc(mf, at)
        outputs[MANIFEST] = dump(mf, newline_of(mf_raw))
    print("layout: %d levels; spine rows %d; timeline rows renumbered %d" % (len(lay["levels"]), len(sp["floors"]), n_rows))
    saves = sorted([p for p in USERDATA.glob("void_space_build_*.json") if p.stem.rsplit("_", 1)[1].isdigit()
                    and int(p.stem.rsplit("_", 1)[1]) >= at], key=lambda p: -int(p.stem.rsplit("_", 1)[1])) if USERDATA.exists() else []
    print("glass-box saves to rename:", [p.name for p in saves])
    refs = hardcoded_refs(at)
    print("hard-coded floor numbers >= %d in probes/tools (NOT changed, %d lines):" % (at, len(refs)))
    for r in refs[:400]: print("   ", r)
    if not args.apply:
        print("dry run: nothing written"); return
    for p, data in outputs.items():
        tmp = p.with_name(p.name + ".insert-next"); tmp.write_bytes(data); os.replace(tmp, p)
    atl.write_authored(tl)
    for p in saves:
        n = int(p.stem.rsplit("_", 1)[1])
        p.rename(p.with_name("void_space_build_%d.json" % (n + 1)))
    print("written")

    if not args.stage_head:
        return
    # ---- HEAD versions, staged as blobs (LF, indent 2: how these files are stored)
    raw, cwd, rel = git_head(ROOMS)
    head_floor = copy.deepcopy(floor)
    if args.floor_json_head:
        head_floor.update(json.loads(Path(args.floor_json_head).read_text(encoding="utf-8")))
        head_floor["map"] = args.map; head_floor["title"] = args.title
    hd = json.loads(raw); hat = rooms_doc(hd, args.after, head_floor)
    stage_bytes(cwd, rel, dump(hd))
    raw, cwd, rel = git_head(LAYOUT); hl = json.loads(raw); layout_doc(hl, hat, role, args.storey); stage_bytes(cwd, rel, dump(hl))
    raw, cwd, rel = git_head(SPINE); hs = json.loads(raw); spine_doc(hs, hat, args.map, args.title, args.sequence, hl); stage_bytes(cwd, rel, dump(hs))
    raw, cwd, rel = git_head(PREFABS); hp = json.loads(raw); prefabs_doc(hp, hat); stage_bytes(cwd, rel, dump(hp))
    subprocess.run(["git", "add", TIMELINE.relative_to(ROOT).as_posix()], cwd=ROOT, check=True)
    if MANIFEST.exists():
        raw, cwd, rel = git_head(MANIFEST)
        if raw is not None:
            hm = json.loads(raw); manifest_doc(hm, hat); stage_bytes(cwd, rel, dump(hm))
    print("HEAD versions staged (insert at HEAD index %d)" % hat)


if __name__ == "__main__":
    main()
