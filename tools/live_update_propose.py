"""live_update_propose.py — file a PROPOSAL on the live update chain, without an AI.

2026-10-22. A proposal is a revision somebody would like to see — an agent, a
script, this CLI — stored as ONE small JSON document under
ada_run/live_proposals/ (never the canonical file). A person reviews it in the
editor that owns the file (/lab-editor?mode=void&floor=N for rooms.json,
/editor for a grid map) and presses Accept or Reject in the Proposals strip.
Accept applies it through that editor's own save path, so the revision check,
the validator and the publish to tools/vr_link.py run exactly as for a hand
edit; the decision becomes a {k:"proposal"} row in ada_run/live_updates.jsonl
beside the update_ack rows of the revision it produced. Nothing is applied by
this tool and nothing is applied by itself.

  # The Void: move an artifact on floor 10 by +1.5 m in x
  python tools/live_update_propose.py --void --floor 10 --move museum-primitives_profiles-15-1 --dx 1.5
  python tools/live_update_propose.py --void --floor 10 --move <id> --dx 0 --dz -2 --facing 90
  python tools/live_update_propose.py --void --floor 10 --set <id> height=0.5 config.editor_label="moved by hand"
  python tools/live_update_propose.py --void --floor 10 --remove <id>
  python tools/live_update_propose.py --void --floor 10 --trial noise --move <id> --dx 1

  # a grid map: move the token at cell x,z to x2,z2; set a cell on a layer
  python tools/live_update_propose.py --map Point_One --move-cell 8,0 7,0
  python tools/live_update_propose.py --map Point_One --set-cell 3,4 "point_corridor_door:90" [--layer interactables]

  # a raw proposal document (the POST body of /api/live-update/proposals)
  python tools/live_update_propose.py --json proposal.json

  python tools/live_update_propose.py --list [--all]       # what is pending (or everything)
  python tools/live_update_propose.py --read <id>

Every proposal carries --note (what and why) and --as (the source, e.g.
agent:fable). The CLI reads the CURRENT file to fill `before` so the strip
can say "from … to …"; it posts to the encyclopedia (ADA_ENC_URL, default
localhost:3003), and when that is down it writes the same document into the
store directly (the encyclopedia reads the folder, not a database).
"""
from __future__ import annotations

import argparse
import json
import os
import secrets
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENC = os.environ.get("ADA_ENC_URL", "http://localhost:3003")
STORE = ROOT / "ada_run" / "live_proposals"


def http(method: str, url: str, body: dict | None = None, timeout: float = 15.0) -> tuple[int, dict]:
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method,
                                 headers={"content-type": "application/json"} if data else {})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, json.loads(r.read().decode("utf-8") or "{}")
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read().decode("utf-8") or "{}")
        except Exception:  # noqa: BLE001
            return e.code, {"error": f"HTTP {e.code}"}
    except Exception as e:  # noqa: BLE001
        return 0, {"error": repr(e)}


# ── reading the current documents (for `before`) ───────────────────────────

def rooms_file(trial: str) -> Path:
    if not trial:
        return ROOT / "commons" / "void" / "rooms.json"
    playable = json.loads((ROOT / "commons" / "void" / "trials" / "playable.json").read_text(encoding="utf-8"))
    item = playable.get("trials", {}).get(trial)
    if not item:
        sys.exit(f"unknown trial {trial!r}")
    return ROOT / item["rooms"].replace("res://", "")


def load_floor(trial: str, floor: int) -> dict:
    doc = json.loads(rooms_file(trial).read_text(encoding="utf-8"))
    floors = doc.get("floors", [])
    if floor < 0 or floor >= len(floors):
        sys.exit(f"floor {floor} does not exist ({len(floors)} floors)")
    return floors[floor]


def find_record(fl: dict, rid: str) -> tuple[str, dict]:
    for coll in ("artifacts", "props"):
        for r in fl.get(coll) or []:
            if isinstance(r, dict) and r.get("id") == rid:
                return coll, r
    ids = [r.get("id") for r in fl.get("artifacts") or []][:12]
    sys.exit(f"{rid!r} is not on this floor; artifacts here: {ids}")


def map_cell(map_id: str, layer: str, x: int, z: int) -> str:
    f = ROOT / "commons" / "maps" / map_id / "map_data.json"
    if not f.exists():
        sys.exit(f"no map {map_id} ({f})")
    rows = (json.loads(f.read_text(encoding="utf-8")).get("layers") or {}).get(layer) or []
    row = rows[z] if z < len(rows) else []
    cells = row.split(",") if isinstance(row, str) else list(row)
    return str(cells[x]).strip() if x < len(cells) else ""


def parse_value(s: str):
    try:
        return json.loads(s)
    except json.JSONDecodeError:
        return s


def set_patch(record: dict, assignments: list[str]) -> tuple[dict, dict]:
    """`key=value` pairs, dotted keys into config; returns (before, after) patches."""
    before: dict = {}
    after: dict = {}
    for a in assignments:
        if "=" not in a:
            sys.exit(f"--set wants key=value, got {a!r}")
        k, v = a.split("=", 1)
        val = parse_value(v)
        if "." in k:
            top, sub = k.split(".", 1)
            cur = dict(record.get(top) or {}) if isinstance(record.get(top), dict) else {}
            before.setdefault(top, dict(cur))
            merged = dict(after.get(top) or cur)
            merged[sub] = val
            after[top] = merged
        else:
            before[k] = record.get(k)
            after[k] = val
    return before, after


# ── the document ────────────────────────────────────────────────────────────

def build(args) -> dict:
    if args.json:
        return json.loads(Path(args.json).read_text(encoding="utf-8"))
    body: dict = {"source": args.as_, "note": args.note or ""}
    if args.void:
        if args.floor is None:
            sys.exit("--void needs --floor N")
        fl = load_floor(args.trial, args.floor)
        ops: list[dict] = []
        if args.move:
            coll, rec = find_record(fl, args.move)
            pos = list(rec.get("position") or [0, 0])
            after = {"position": [round(pos[0] + args.dx, 3), round(pos[1] + args.dz, 3)]}
            before = {"position": pos}
            if args.facing is not None:
                after["facing"] = args.facing
                before["facing"] = rec.get("facing", 0)
            ops.append({"op": "void_item", "collection": coll, "id": args.move, "kind": "transform",
                        "before": before, "after": after})
            body.setdefault("note", "")
            if not body["note"]:
                body["note"] = f"move {rec.get('artifact') or rec.get('kind') or args.move} by [{args.dx}, {args.dz}]"
        if args.set:
            if not args.set_id:
                sys.exit("--set needs --set-id <record id>")
            coll, rec = find_record(fl, args.set_id)
            before, after = set_patch(rec, args.set)
            ops.append({"op": "void_item", "collection": coll, "id": args.set_id, "kind": "parameter",
                        "before": before, "after": after})
        if args.remove:
            coll, rec = find_record(fl, args.remove)
            ops.append({"op": "void_item", "collection": coll, "id": args.remove, "kind": "remove",
                        "before": rec, "after": None})
        if not ops:
            sys.exit("nothing proposed: give --move/--set/--remove")
        body.update({"target": "void", "floor_id": args.floor, "trial": args.trial or "", "operations": ops})
        return body
    if args.map:
        ops = []
        if args.move_cell:
            (fx, fz), (tx, tz) = (tuple(int(v) for v in c.split(",")) for c in args.move_cell)
            token = map_cell(args.map, "interactables", fx, fz)
            if not token:
                sys.exit(f"nothing stands at ({fx}, {fz}) on {args.map}")
            ops.append({"op": "move", "layer": "interactables", "from": [fx, fz], "to": [tx, tz], "token": token})
            if not body["note"]:
                body["note"] = f"move {token.split('#')[0].split(':')[0]} from ({fx}, {fz}) to ({tx}, {tz})"
        if args.set_cell:
            x, z = (int(v) for v in args.set_cell[0].split(","))
            ops.append({"op": "set_cell", "layer": args.layer, "at": [x, z],
                        "before": map_cell(args.map, args.layer, x, z), "after": args.set_cell[1]})
        if not ops:
            sys.exit("nothing proposed: give --move-cell or --set-cell")
        body.update({"target": "map", "map_id": args.map, "operations": ops})
        return body
    sys.exit("give --void --floor N … or --map <Map> …  (or --json file)")


def file_directly(body: dict) -> dict:
    """The encyclopedia is down: write the same document into the store."""
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    pid = f"prop-{stamp}-{secrets.token_hex(3)}"
    doc = {"id": pid, **body, "created_at": time.time(), "status": "pending"}
    if doc.get("target") == "void":
        doc["map_id"] = doc.get("trial") or "void"
    STORE.mkdir(parents=True, exist_ok=True)
    tmp = STORE / f"{pid}.json.tmp"
    tmp.write_text(json.dumps(doc, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp, STORE / f"{pid}.json")
    return doc


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--void", action="store_true", help="propose on The Void (rooms.json)")
    ap.add_argument("--floor", type=int, help="the Void floor index")
    ap.add_argument("--trial", default="", help="a Void trial id instead of the tower")
    ap.add_argument("--move", metavar="ID", help="move this record by --dx/--dz (and --facing)")
    ap.add_argument("--dx", type=float, default=0.0)
    ap.add_argument("--dz", type=float, default=0.0)
    ap.add_argument("--facing", type=float)
    ap.add_argument("--set", nargs="+", metavar="KEY=VALUE", help="patch fields of --set-id (dotted keys go into config)")
    ap.add_argument("--set-id", metavar="ID")
    ap.add_argument("--remove", metavar="ID")
    ap.add_argument("--map", metavar="MAP", help="propose on a grid map (commons/maps/<Map>)")
    ap.add_argument("--move-cell", nargs=2, metavar=("X,Z", "X2,Z2"))
    ap.add_argument("--set-cell", nargs=2, metavar=("X,Z", "VALUE"))
    ap.add_argument("--layer", default="interactables", choices=["structure", "utilities", "interactables"])
    ap.add_argument("--json", metavar="FILE", help="a raw proposal document")
    ap.add_argument("--note", default="", help="what and why, in a line")
    ap.add_argument("--as", dest="as_", default="cli", help="the source (agent:<name>, cli, …)")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--all", action="store_true", help="with --list: decided ones too")
    ap.add_argument("--read", metavar="ID")
    ap.add_argument("--direct", action="store_true", help="write the store directly, do not ask the encyclopedia")
    args = ap.parse_args()

    if args.list:
        code, j = http("GET", f"{ENC}/api/live-update/proposals?all={'1' if args.all else '0'}", timeout=8)
        rows = j.get("proposals") if code == 200 else None
        if rows is None:
            rows = []
            for f in sorted(STORE.glob("*.json")):
                try:
                    p = json.loads(f.read_text(encoding="utf-8"))
                except json.JSONDecodeError:
                    continue
                if args.all or p.get("status") == "pending":
                    rows.append(p)
            print(f"(store read directly: {j.get('error', 'encyclopedia down')})")
        for p in rows:
            place = f"floor {p.get('floor_id')}" if p.get("target") == "void" else p.get("map_id")
            d = p.get("decision") or {}
            print(f"{p['id']}  {p.get('status'):8s}  {p.get('target')} {place}  {len(p.get('operations') or [])} op  "
                  f"by {p.get('source')}  {p.get('note', '')[:60]}"
                  + (f"  -> {d.get('decision')} by {d.get('by')} {d.get('revision_id') or ''}" if d else ""))
            for w in p.get("words") or []:
                print(f"    {w}")
        if not rows:
            print("no proposals")
        return 0

    if args.read:
        code, j = http("GET", f"{ENC}/api/live-update/proposals?id={args.read}", timeout=8)
        if code != 200:
            f = STORE / f"{args.read}.json"
            if not f.exists():
                sys.exit(j.get("error") or f"no proposal {args.read}")
            j = {"proposal": json.loads(f.read_text(encoding="utf-8"))}
        print(json.dumps(j, indent=2))
        return 0

    body = build(args)
    if not args.direct:
        code, j = http("POST", f"{ENC}/api/live-update/proposals", body, timeout=10)
        if code == 201 and j.get("ok"):
            p = j["proposal"]
            print(f"filed {p['id']}  ({p['target']} "
                  f"{'floor ' + str(p.get('floor_id')) if p['target'] == 'void' else p['map_id']}, "
                  f"{len(p['operations'])} op) by {p['source']}")
            for w in j.get("words") or []:
                print(f"  {w}")
            where = (f"{ENC}/lab-editor?mode=void&floor={p.get('floor_id')}" + (f"&trial={p.get('trial')}" if p.get("trial") else "")
                     if p["target"] == "void" else f"{ENC}/editor  (load {p['map_id']})")
            print(f"review: {where}")
            return 0
        if code == 400:
            sys.exit(f"refused: {j.get('error')}")
        print(f"encyclopedia not reachable ({j.get('error') or code}); writing the store directly")
    doc = file_directly(body)
    print(f"filed {doc['id']} directly into {STORE}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
