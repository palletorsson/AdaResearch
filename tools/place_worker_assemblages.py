"""Void Tower Worker Form & Endless Museum Dream-Body Assemblage placement tool.

Adds, inspects, updates, or removes `worker_assemblage` installations across any
of the 210 floors in commons/void/rooms.json, ALWAYS writing through
tools/rooms_door.py::edit() with automatic clearance checking against shafts,
structural columns, spawn points, walls, props, and existing artifacts.

Usage:
    python tools/place_worker_assemblages.py list
    python tools/place_worker_assemblages.py check --floor 19 --x 10.0 --z 5.2
    python tools/place_worker_assemblages.py add --floor 19 --id worker-assemblage-f19 --x 10.0 --z 5.2 --facing 215 --formation trio --figure hadid_shell --secondary pierced_screen
    python tools/place_worker_assemblages.py install-curated
"""
import argparse
import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import rooms_door  # noqa: E402

ROOMS_PATH = ROOT / "commons/void/rooms.json"
LAYOUT_PATH = ROOT / "commons/void/layout.json"

CURATED_TOWER_PLACEMENTS = [
    {
        "floor": 13,
        "id": "worker-assemblage-trans-pre",
        "station": "SW",
        "position": [-17.2, 5.2],
        "facing": 40,
        "config": {
            "formation": "assemblage",
            "stage": "transformation",
            "figure": "panel_robot",
            "secondary_figure": "stijl_robot",
            "opts": {"panelling": "shed", "assembly": "twinned"},
            "monochrome": "auto",
            "interactive": True,
            "tower_services": False,
            "title": "TRANSFORMATION ASSEMBLAGE",
            "editor_label": "Worker Assemblage / Trans Pre monochrome formation",
        },
    },
    {
        "floor": 19,
        "id": "worker-assemblage-trans-body",
        "station": "SE",
        "position": [10.0, 5.2],
        "facing": 215,
        "config": {
            "formation": "trio",
            "stage": "transformation",
            "figure": "hadid_shell",
            "secondary_figure": "pierced_screen",
            "monochrome": "auto",
            "interactive": True,
            "tower_services": False,
            "title": "THE BODY · WORKER TRIO",
            "editor_label": "Worker Assemblage / Trans Body monochrome trio",
        },
    },
    {
        "floor": 28,
        "id": "worker-assemblage-color-arrival",
        "station": "SW",
        "position": [-9.5, 5.2],
        "facing": 155,
        "config": {
            "formation": "dyad",
            "stage": "color",
            "figure": "stijl_robot",
            "secondary_figure": "masked_dancer",
            "palette": "bauhaus",
            "monochrome": "auto",
            "interactive": True,
            "tower_services": False,
            "title": "COLOUR FORMATION · STIJL WORKER",
            "editor_label": "Worker Assemblage / Color arrival dyad",
        },
    },
    {
        "floor": 209,
        "id": "worker-assemblage-atelier",
        "station": "SE",
        "position": [2.8, 0.6],
        "facing": 65,
        "config": {
            "formation": "assemblage",
            "stage": "color",
            "figure": "stijl_robot",
            "secondary_figure": "asawa_wire",
            "palette": "bauhaus",
            "monochrome": "auto",
            "interactive": True,
            "tower_services": False,
            "title": "ATELIER ASSEMBLAGE · CORD TO SLAB",
            "editor_label": "Worker Assemblage / F209 Atelier monument",
        },
    },
]


def load_data():
    rooms = json.loads(ROOMS_PATH.read_text(encoding="utf-8"))
    layout = json.loads(LAYOUT_PATH.read_text(encoding="utf-8"))
    return rooms, layout


def check_clearance(rooms, layout, floor_idx: int, x: float, z: float, radius: float = 1.65, ignore_id: str = ""):
    issues = []
    half_w = float(layout.get("width", 42)) * 0.5 - 1.2
    half_d = float(layout.get("depth", 18)) * 0.5 - 1.2
    if abs(x) > half_w or abs(z) > half_d:
        issues.append(f"near slab edge ({x}, {z}) vs limits (+/-{half_w:.1f}, +/-{half_d:.1f})")

    # Open shafts (A at x=-10, B at x=10, 6x6 m). F209 is bottom library deck with solid floor.
    if floor_idx < 209:
        sw = float(layout.get("shaft_width", 6.0)) * 0.5
        sd = float(layout.get("shaft_depth", 6.0)) * 0.5
        for sh in layout.get("shafts", []):
            sx = float(sh.get("x", 0.0))
            if abs(x - sx) < sw + radius * 0.65 and abs(z) < sd + radius * 0.65:
                issues.append(f"overlaps Shaft {sh.get('name')} at x={sx}")

    # Structural columns.
    cw = float(layout.get("column_width", 0.9)) * 0.5
    for cx in layout.get("column_x", []):
        for cz in layout.get("column_z", []):
            if math.hypot(x - float(cx), z - float(cz)) < cw + radius * 0.7:
                issues.append(f"too close to column ({cx}, {cz})")

    # Spawn point.
    sp = layout.get("spawn_points", {}).get(str(floor_idx))
    if isinstance(sp, list) and len(sp) >= 3:
        if math.hypot(x - float(sp[0]), z - float(sp[2])) < 2.0:
            issues.append(f"too close to floor spawn ({sp[0]}, {sp[2]})")

    fl = rooms["floors"][floor_idx]
    for a in fl.get("artifacts", []):
        if a.get("id") == ignore_id:
            continue
        pos = a.get("position")
        if not pos:
            continue
        d = math.hypot(x - float(pos[0]), z - float(pos[1]))
        if d < radius + 0.6:
            issues.append(f"artifact {a.get('id')} ({a.get('artifact')}) at {pos} (dist={d:.2f}m)")
    for p in fl.get("props", []):
        pos = p.get("position")
        if not pos:
            continue
        d = math.hypot(x - float(pos[0]), z - float(pos[1]))
        if d < radius + 0.4:
            issues.append(f"prop {p.get('id')} ({p.get('kind')}) at {pos} (dist={d:.2f}m)")
    return issues


def station_for(x: float, z: float) -> str:
    ns = "N" if z < 0 else "S"
    ew = "W" if x < 0 else "E"
    return ns + ew


def upsert_placements(entries):
    rooms, layout = load_data()
    for e in entries:
        fidx = int(e["floor"])
        x, z = float(e["position"][0]), float(e["position"][1])
        issues = check_clearance(rooms, layout, fidx, x, z, ignore_id=e["id"])
        if issues:
            raise ValueError(f"Clearance failed for {e['id']} on F{fidx:03d}: " + "; ".join(issues))

    def _apply(text: str) -> str:
        doc = json.loads(text)
        for e in entries:
            fidx = int(e["floor"])
            fl = doc["floors"][fidx]
            arts = fl["artifacts"]
            row = {
                "id": e["id"],
                "artifact": "worker_assemblage",
                "station": e.get("station") or station_for(e["position"][0], e["position"][1]),
                "position": [round(float(e["position"][0]), 3), round(float(e["position"][1]), 3)],
                "height": float(e.get("height", 0)),
                "facing": float(e.get("facing", 0)),
                "scale": float(e.get("scale", 1)),
                "config": e.get("config", {}),
            }
            replaced = False
            for idx, existing in enumerate(arts):
                if existing.get("id") == row["id"]:
                    arts[idx] = row
                    replaced = True
                    break
            if not replaced:
                arts.append(row)
        return json.dumps(doc, indent=2, ensure_ascii=False) + "\n"

    return rooms_door.edit(_apply)


def cmd_list():
    rooms, _ = load_data()
    print("=== Standalone worker_assemblage placements in rooms.json ===")
    count = 0
    for idx, fl in enumerate(rooms["floors"]):
        for a in fl.get("artifacts", []):
            if a.get("artifact") == "worker_assemblage":
                cfg = a.get("config", {})
                print(
                    f"  F{idx:03d} {fl['map']:26s} id={a['id']:32s} "
                    f"pos={a.get('position')} facing={a.get('facing')} "
                    f"formation={cfg.get('formation','dyad')} fig={cfg.get('figure','auto')}"
                )
                count += 1
    if count == 0:
        print("  (none yet)")
    print("\n=== Studio Workbenches carrying integrated workbench_arc assemblages ===")
    for idx, fl in enumerate(rooms["floors"]):
        for a in fl.get("artifacts", []):
            if "scaffold_workstation" in str(a.get("artifact", "")) and a.get("config", {}).get("studio"):
                print(
                    f"  F{idx:03d} {fl['map']:26s} id={a['id']:24s} "
                    f"pos={a.get('position')} facing={a.get('facing')} tier={a.get('config',{}).get('tier')}"
                )


def main():
    ap = argparse.ArgumentParser(description="Manage worker_assemblage formations across the Void Tower.")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list")

    chk = sub.add_parser("check")
    chk.add_argument("--floor", type=int, required=True)
    chk.add_argument("--x", type=float, required=True)
    chk.add_argument("--z", type=float, required=True)
    chk.add_argument("--radius", type=float, default=1.65)

    add = sub.add_parser("add")
    add.add_argument("--floor", type=int, required=True)
    add.add_argument("--id", required=True)
    add.add_argument("--x", type=float, required=True)
    add.add_argument("--z", type=float, required=True)
    add.add_argument("--facing", type=float, default=0.0)
    add.add_argument("--formation", default="dyad", choices=["solo", "dyad", "trio", "assemblage"])
    add.add_argument("--stage", default="auto")
    add.add_argument("--figure", default="")
    add.add_argument("--secondary", default="")
    add.add_argument("--palette", default="bauhaus")
    add.add_argument("--title", default="")

    sub.add_parser("install-curated")

    args = ap.parse_args()
    if args.cmd == "list":
        cmd_list()
    elif args.cmd == "check":
        rooms, layout = load_data()
        issues = check_clearance(rooms, layout, args.floor, args.x, args.z, args.radius)
        fl = rooms["floors"][args.floor]
        if issues:
            print(f"BLOCKED on F{args.floor:03d} {fl['map']} ({args.x}, {args.z}):")
            for i in issues:
                print("  -", i)
            sys.exit(1)
        print(f"CLEAR on F{args.floor:03d} {fl['map']} ({args.x}, {args.z})")
    elif args.cmd == "add":
        cfg = {
            "formation": args.formation,
            "stage": args.stage,
            "palette": args.palette,
            "monochrome": "auto",
            "interactive": True,
            "tower_services": False,
        }
        if args.figure:
            cfg["figure"] = args.figure
        if args.secondary:
            cfg["secondary_figure"] = args.secondary
        if args.title:
            cfg["title"] = args.title
        how = upsert_placements([{
            "floor": args.floor,
            "id": args.id,
            "position": [args.x, args.z],
            "facing": args.facing,
            "config": cfg,
        }])
        print("OK:", how)
    elif args.cmd == "install-curated":
        how = upsert_placements(CURATED_TOWER_PLACEMENTS)
        print(f"Installed {len(CURATED_TOWER_PLACEMENTS)} curated tower worker_assemblage monuments: {how}")


if __name__ == "__main__":
    main()
