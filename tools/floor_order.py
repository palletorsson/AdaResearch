"""THE ROOM AS A TIMELINE — the ruled order beside the order the floor delivers.

2026-09-07, Palle: "we can think of the 3d layout as a timeline of learning and
the book as well ... focus on the primary artifact path".

A room carries two orders over the same artifacts and nothing has ever shown
them together:

  RULED   commons/data/artifact_roles.json — order[<map>][<role>], what the
          room is supposed to teach, in what sequence.
  FLOOR   what a body actually meets, walking from the spawn. That order is a
          fact about the geometry and nobody authored it.

Measured across the spine on the day this was written: where the ruling was
genuinely authored (it differs from the grid read row-major) the two orders
DISAGREE — mean Kendall tau -0.07 over 11 rooms, five of them negative. Where
they agree it is because the ruling was transcribed off the grid in the first
place (mean +0.58, 6 rooms). So every room where somebody made a real decision
about order decided against the geometry, and the floor was never moved to
match. `ruling_is_rowmajor` in the output is the flag that tells the two apart;
a reader that ignores it will average two populations and learn nothing.

THE WALK IS NOT RE-IMPLEMENTED HERE. It comes from map_pathfinder.MapGraph,
whose `.walkable` already carries the bridge cells, the jp landings, the
teleport destinations and the hazard rules. tools/long_museum.py once re-derived
one grid rule in a second language and drifted 16% with its own gate green; that
is why this tool exists as the single producer of the number and the encyclopedia
draws what it says rather than computing its own.

  python tools/floor_order.py --map=VFM_05_Launch
  python tools/floor_order.py --map=VFM_05_Launch --json
  python tools/floor_order.py --seq=forces
"""
from __future__ import annotations

import argparse
import io
import json
import sys
from collections import deque
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from map_pathfinder import MapGraph, load_map  # noqa: E402

ROLES = ROOT / "commons" / "data" / "artifact_roles.json"


# ── the walk ──────────────────────────────────────────────────────────────
def _bfs(walkable: set, start: tuple) -> tuple[dict, dict]:
    """Steps from start over walkable cells, plus each cell's predecessor."""
    dist = {start: 0}
    prev: dict = {}
    q = deque([start])
    while q:
        p = q.popleft()
        for dz, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (p[0] + dz, p[1] + dx)
            if n in walkable and n not in dist:
                dist[n] = dist[p] + 1
                prev[n] = p
                q.append(n)
    return dist, prev


def _approach(dist: dict, cell: tuple):
    """An artifact stands ON a cell a walker may not enter, so it is met from
    beside. Returns (steps, the cell you stand in), or (None, None)."""
    if cell in dist:
        return dist[cell], cell
    best = None
    for dz in (-1, 0, 1):
        for dx in (-1, 0, 1):
            n = (cell[0] + dz, cell[1] + dx)
            if n in dist and (best is None or dist[n] < dist[best]):
                best = n
    return (dist[best], best) if best else (None, None)


def _trace(prev: dict, start: tuple, end: tuple) -> list:
    out, cur = [end], end
    while cur != start and cur in prev:
        cur = prev[cur]
        out.append(cur)
    out.reverse()
    return out


def walk(graph: MapGraph, at: dict) -> tuple[list, list, list]:
    """Greedy-nearest from the spawn: the order a body meets them, the cell path
    it takes, and anything it can never reach."""
    cur, seen, order, path = graph.spawn, set(), [], [graph.spawn]
    while len(seen) < len(at):
        dist, prev = _bfs(graph.walkable, cur)
        best, bd, bcell = None, None, None
        for token, cell in at.items():
            if token in seen:
                continue
            d, stand = _approach(dist, cell)
            if d is not None and (bd is None or d < bd):
                best, bd, bcell = token, d, stand
        if best is None:
            break
        seen.add(best)
        order.append(best)
        path.extend(_trace(prev, cur, bcell)[1:])
        cur = bcell
    return order, path, [t for t in at if t not in seen]


def inversions(a: list, b: list) -> int:
    """Pairs the two orders disagree about. 0 = the same order."""
    ia = {t: i for i, t in enumerate(a)}
    return sum(1 for i in range(len(b)) for j in range(i + 1, len(b))
               if b[i] in ia and b[j] in ia and ia[b[i]] > ia[b[j]])


# ── one room ──────────────────────────────────────────────────────────────
def read_room(name: str, role: str = "primary") -> dict:
    path = ROOT / "commons" / "maps" / name / "map_data.json"
    if not path.exists():
        return {"ok": False, "map": name, "error": "no map_data.json"}
    data = load_map(path)
    layers = data.get("layers", data)
    struct = layers.get("structure") or []
    utils = layers.get("utilities") or []
    inter = layers.get("interactables") or []
    graph = MapGraph(data)

    roles_doc = json.loads(io.open(ROLES, encoding="utf-8").read())
    role_of = (roles_doc.get("roles") or {}).get(name) or {}
    ruled_source = "all"
    if role == "all":
        # EVERY placement, whatever its role. This is what the spine thread walks:
        # a body meets the decorations too, and dropping them here would silently
        # shorten the manifest the museum deals from.
        ruled = []
        for row in inter:
            for cell in row:
                t = str(cell).split(":")[0].split("#")[0].strip()
                if t and t not in ruled:
                    ruled.append(t)
    else:
        ruled = list(((roles_doc.get("order") or {}).get(name) or {}).get(role) or [])
        ruled_source = "order" if ruled else ""
        if not ruled:
            # NO EXPLICIT ORDER. The role set still tells us which artifacts are
            # on the thread, but the roles dict's key order is generated, not
            # decided — so this is scored as a DEFAULT, never as a ruling.
            # VFM_03_Motion carries `order: {}` and 17 roles; reading its key
            # order as a ruling scored it +1.00 against the floor and pulled the
            # whole transcribed bucket up with it.
            ruled = [t for t, r in role_of.items() if r == role]
            ruled_source = "roles" if ruled else "none"

    at: dict = {}
    for z, row in enumerate(inter):
        for x, cell in enumerate(row):
            token = str(cell).split(":")[0].split("#")[0].strip()
            if token in ruled and token not in at:
                at[token] = (z, x)

    order, path, unreached = walk(graph, at) if at else ([], [graph.spawn], [])
    common = [t for t in ruled if t in at]
    reached = [t for t in common if t in order]
    n = len(reached)
    pairs = n * (n - 1) // 2
    inv = inversions(order, reached)
    tau = (1.0 - 2.0 * inv / pairs) if pairs else None

    # IS THE RULING AN INDEPENDENT WITNESS? On 7 of 18 ordered rooms it is
    # byte-identical to the grid read top-left to bottom-right, which means it
    # was transcribed off the floor rather than decided. Averaging those in with
    # the authored ones hides the finding.
    rowmajor = [t for t, _ in sorted(at.items(), key=lambda kv: (kv[1][0], kv[1][1]))]

    floor_i = {t: i for i, t in enumerate(order)}
    ruled_i = {t: i for i, t in enumerate(common)}

    subs = data.get("subtitles") or {}
    captions = []
    for z, row in enumerate(utils):
        for x, cell in enumerate(row):
            spec = str(cell).strip()
            if spec.startswith("sub:"):
                key = spec.split(":", 1)[1]
                # a subtitles entry is usually {text, speaker, level} but some
                # maps store a bare string (Point_Lines) — both are legal on disk
                entry = subs.get(key)
                if not isinstance(entry, dict):
                    entry = {"text": str(entry)} if entry else {}
                captions.append({
                    "row": z, "col": x, "key": key,
                    "text": str(entry.get("text", "")),
                    "speaker": str(entry.get("speaker", "")),
                    # endless_museum.gd:718 — UTIL_ALLOWED is {rc,sc,tc,br,jp,wp}.
                    # A sub: cell is refused in silence, so in the lane the menu
                    # opens these panels do not exist. Authored, not spoken.
                    "museum_refused": True,
                })

    teleporters = [{"row": z, "col": x, "to": str(c).split(":", 1)[1] if ":" in str(c) else ""}
                   for z, row in enumerate(utils) for x, c in enumerate(row)
                   if str(c).strip().startswith("t:") or str(c).strip() == "t"]

    return {
        "ok": True,
        "map": name,
        "role": role,
        "grid": {"w": max((len(r) for r in struct), default=0), "h": len(struct)},
        "structure": [[str(c) for c in row] for row in struct],
        "spawn": list(graph.spawn),
        "teleporters": teleporters,
        "captions": captions,
        "walkable": len(graph.walkable),
        "ruled": common,
        "floor": order,
        "path": [list(c) for c in path],
        "unreached": unreached,
        "artifacts": [{
            "token": t, "row": at[t][0], "col": at[t][1],
            "ruled": ruled_i.get(t), "floor": floor_i.get(t),
            "reachable": t in floor_i,
        } for t in common],
        "tau": (round(tau, 3) if tau is not None else None),
        "inversions": inv,
        "pairs": pairs,
        "ruling_is_rowmajor": rowmajor == common,
        # "order" = a real ruling somebody wrote. "roles" = roles exist but no
        # order, so `ruled` here is a DEFAULT and tau is not a verdict on anyone.
        # "none" = nothing ruled at all. "all" = --role=all, every placement.
        "ruled_source": ruled_source,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--map", default="")
    ap.add_argument("--seq", default="")
    ap.add_argument("--role", default="primary",
                    help="primary | secondary | decoration | all (every placement, whatever its role)")
    ap.add_argument("--json", action="store_true", help="machine-readable, one object")
    a = ap.parse_args()

    names: list[str] = []
    if a.map:
        names = [a.map]
    elif a.seq:
        for f in sorted((ROOT / "commons" / "maps" / "sequences").glob("*.json")):
            try:
                doc = json.loads(io.open(f, encoding="utf-8").read())
            except Exception:
                continue
            raw = doc.get("sequences") or {}
            items = raw.items() if isinstance(raw, dict) else [
                ((s.get("id") or s.get("name") or ""), s) for s in raw if isinstance(s, dict)]
            for sid, sq in items:
                # sequence_index.json carries every id with an EMPTY maps list and
                # sorts after the real file, so the first non-empty match wins and
                # the sweep stops there.
                if sid == a.seq and isinstance(sq, dict) and not names:
                    names = list(sq.get("maps") or [])
    else:
        ap.error("give --map=<Name> or --seq=<id>")

    rooms = [read_room(n, a.role) for n in names]
    if a.json:
        print(json.dumps(rooms[0] if a.map else {"seq": a.seq, "rooms": rooms}, ensure_ascii=False))
        return 0

    print("THE ROOM AS A TIMELINE — ruled order vs the order the floor delivers")
    print()
    print("%-32s %4s %5s %7s  %s" % ("room", "n", "inv", "tau", "ruled opener -> what you meet first"))
    print("-" * 108)
    for r in rooms:
        if not r.get("ok"):
            print("%-32s  %s" % (r["map"], r.get("error", "unreadable")))
            continue
        tau = r["tau"]
        flag = "  (the ruling IS the grid, row-major)" if r["ruling_is_rowmajor"] else ""
        if r.get("ruled_source") == "roles":
            flag = "  (NO ruling — roles only, so this is a default, not a verdict)"
        elif r.get("ruled_source") == "none":
            flag = "  (nothing ruled)"
        opener = ""
        if r["ruled"] and r["floor"]:
            opener = (r["ruled"][0] + "  ->  " + r["floor"][0]) if r["ruled"][0] != r["floor"][0] else "(same opener)"
        print("%-32s %4d %5d %7s  %s%s" % (
            r["map"], len(r["ruled"]), r["inversions"],
            ("%+.2f" % tau) if tau is not None else "  —", opener, flag))
        if r["unreached"]:
            print("%-32s        NEVER REACHED from the spawn: %s" % ("", ", ".join(r["unreached"])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
