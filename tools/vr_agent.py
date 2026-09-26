#!/usr/bin/env python3
"""vr_agent.py — the python walker PLAYS the room: path finding, looking, interacting.

2026-09-26, Palle: "We have a python program that can walk through the halls but
can we make that agent look at the artifact, use path finding and interact with
the artifacts?"

WHAT THE WALKER WAS. `tools/vr_link.py --walker=<Map>` replays the humanoid_walker's
placement trace as a polyline: a diagram of how the placement engine crossed the
room, handed to a capsule in VR. It did not choose where it was going, it could
not see, and it touched nothing.

WHAT IT IS NOW. Three parts, each put where the knowledge already lives:

  PATH FINDING   tools/map_pathfinder.py's MapGraph — the step relation every gate
                 in this project already trusts (heights, ramps, transport cubes,
                 lifts, jump pads, wall segments, hazards). A tour is spawn → the
                 nearest artifact's approach cell → the next nearest → … → the
                 teleporter, and every leg is a least-cost path from where the
                 last leg ended (bfs_path(target, start=here), added for this).
                 Other artifacts' cells are taken out of the walkable set for the
                 length of a leg, so the walker goes round a work, not through it.
  LOOKING        the game's own eyes (commons/bridge/vr_link.gd): `scan` lists
                 what stands in the room NOW with its affordances; `look` turns
                 the ghost, casts a ray from its eye, and says whether the thing
                 is in view, how far, and behind what. The registry supplies what
                 it IS — description, qfep_connection — for the report.
  INTERACTING    DesktopPlayer's ladder, one rung per verb (interact, activate,
                 signal, press, touch, grab), chosen by the game from the
                 affordances it measured — never from the registry's word for
                 it, which is a claim. The teleporter is taken only with --exit:
                 it moves the PERSON in the headset to the next map.

The plan is made here from map_data.json; the walk, the seeing and the touching
happen in the game over the VR link's socket; the report is written here. With
no game attached, --dry-run prints the plan and the map with the tour drawn on
it — which is what tools/test_vr_agent.py exercises.

Usage:
  python tools/vr_agent.py Point_One --dry-run      # plan only, no game needed
  python tools/vr_agent.py Point_One                # play, through a running vr_link.py
  python tools/vr_agent.py --live                   # play whatever map the game is in
  python tools/vr_link.py --agent=Point_One         # the same, started with the link

Flags:
  --no-interact   look, but do not touch
  --exit          take the teleporter at the end (moves the person; off by default)
  --limit N       only the first N artifacts of the tour
  --speed M       walking speed in m/s (1.4)
  --dwell S       seconds spent in front of each work (2.0)
  --port P        vr_link.py's web port (8772)
  --json          print the plan as JSON (with --dry-run)

Report: ada_run/vr_agent_<Map>.json and .md — a play report in the shape
/ada-test-player writes, but from a body that was in the room.

THE MUSEUM. A hall has no map_data.json the engine will vouch for (the museum
builds its halls through its own copies of the grid's rules), so there is no
graph to path on. In the museum the agent falls back to what `scan` reports:
straight legs to each live artifact in z order, floor found by the game's ray.
It says so in the log; it is a walk, not a path.
"""
from __future__ import annotations

import argparse
import json
import queue
import sys
import threading
import time
import urllib.request
from contextlib import contextmanager
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Optional

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import map_pathfinder as mp  # noqa: E402

RUN_DIR = ROOT / "ada_run"
WEB_PORT = 8772

#: interactables-layer tokens that are text, not things: a walker does not visit
#: a floating label. `find_interactables` strips the token to its first field.
TEXT_TOKENS = {"3t", "3d", "text", "label"}

Cell = tuple  # (row, col)


# ─────────────────────────────────────────────────────────────────────────────
# The plan — pure, testable, no game
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class Leg:
    kind: str                       # "artifact" | "exit"
    token: str                      # lookup name, or "teleport"
    target: Optional[list]          # [row, col] of the thing itself
    stand: list                     # [row, col] where the walker stops
    path: list                      # [[row, col], ...] from the previous stand, inclusive
    cost: int = 0
    world: Optional[list] = None    # [[x,y,z], ...] when the leg is in world space (museum)


@dataclass
class Tour:
    map: str
    spawn: list
    legs: list = field(default_factory=list)
    skipped: list = field(default_factory=list)
    cube: float = 1.0
    gutter: float = 0.0
    source: str = "map"             # "map" (path finding) | "scene" (museum fallback)

    def artifact_legs(self) -> list:
        return [l for l in self.legs if l.kind == "artifact"]

    def cells(self) -> list:
        """Every cell of every leg, in order — what the dry run draws."""
        out: list = []
        for leg in self.legs:
            for c in leg.path:
                if not out or out[-1] != c:
                    out.append(c)
        return out


def load_graph(map_name: str) -> Optional[mp.MapGraph]:
    p = mp.resolve_map_path(map_name)
    if p is None:
        return None
    return mp.MapGraph(mp.load_map(p))


def cell_size(data: dict) -> tuple[float, float]:
    s = data.get("settings", {}) if isinstance(data, dict) else {}
    return float(s.get("cube_size", 1.0)), float(s.get("gutter", 0.0))


def cell_world(row: int, col: int, cube: float, gutter: float, y: float = 0.0) -> list:
    """GridCommon's rule: the cell's cube is centred at integer multiples of
    cube+gutter. Only for DRAWING on the PC — the game converts the cells it is
    sent with the grid that built the room, and drops each onto the floor."""
    total = cube + gutter
    return [col * total, y, row * total]


def artifact_targets(g: mp.MapGraph, skipped: Optional[list] = None) -> list[dict]:
    """The things a walker visits: every placed artifact that is not text and
    not view-only, once per cell. What is left out is written to `skipped`
    with its reason, so the report never quietly shortens the room."""
    seen: set = set()
    out: list[dict] = []
    for a in g.artifacts:
        name = a["name"]
        key = (name, a["row"], a["col"])
        if key in seen or not name:
            continue
        seen.add(key)
        if name in TEXT_TOKENS:
            if skipped is not None:
                skipped.append({"token": name, "cell": [a["row"], a["col"]], "reason": "text, not a thing"})
            continue
        if mp.is_view_only(name):
            if skipped is not None:
                skipped.append({"token": name, "cell": [a["row"], a["col"]], "reason": "view_only in the registry"})
            continue
        out.append({"token": name, "cell": (a["row"], a["col"])})
    return out


@contextmanager
def _without(g: mp.MapGraph, cells: set):
    """Take cells out of the walkable set for the length of a search, so a leg
    goes round other works. MapGraph.neighbors() consults exactly this set —
    the step relation is not restated, only its domain narrowed."""
    removed = {c for c in cells if c in g.walkable}
    g.walkable -= removed
    try:
        yield
    finally:
        g.walkable |= removed


NEIGHBOURS = ((-1, 0), (1, 0), (0, -1), (0, 1))


def approach_cells(g: mp.MapGraph, cell: Cell, blocked: set) -> list:
    """Where a body can stand next to a work: its walkable 4-neighbours that no
    other work occupies."""
    r, c = cell
    out = []
    for dr, dc in NEIGHBOURS:
        nb = (r + dr, c + dc)
        if nb in g.walkable and nb not in blocked:
            out.append(nb)
    return out


def leg_to(g: mp.MapGraph, start: Cell, cell: Cell, blocked: set, token: str,
           kind: str = "artifact") -> Optional[Leg]:
    """The shortest way from `start` to a cell beside `cell` (or onto it, when
    nothing beside it can be stood on), avoiding `blocked`. None if unreachable."""
    best: Optional[list] = None
    best_stand: Optional[Cell] = None
    with _without(g, blocked - {start}):
        cands = approach_cells(g, cell, blocked)
        for cand in cands:
            path = g.bfs_path(cand, start=start)
            if path is not None and (best is None or len(path) < len(best)
                                     or (len(path) == len(best) and cand < best_stand)):
                best, best_stand = path, cand
    if best is None:
        # nothing to stand on beside it — stand on it, if it can be stood on
        with _without(g, blocked - {start, cell}):
            if cell in g.walkable:
                path = g.bfs_path(cell, start=start)
                if path is not None:
                    best, best_stand = path, cell
    if best is None:
        return None
    return Leg(kind=kind, token=token, target=list(cell), stand=list(best_stand),
               path=[list(p) for p in best], cost=len(best) - 1)


def plan_tour(g: mp.MapGraph, map_name: str, limit: Optional[int] = None,
              cube: float = 1.0, gutter: float = 0.0) -> Tour:
    """Greedy nearest-next by real path length, the encounter order
    walk_evaluator scores; then the teleporter."""
    tour = Tour(map=map_name, spawn=list(g.spawn), cube=cube, gutter=gutter)
    targets = artifact_targets(g, tour.skipped)
    occupied = {t["cell"] for t in targets}
    here: Cell = tuple(g.spawn)
    remaining = list(targets)
    visited = 0
    while remaining and (limit is None or visited < limit):
        best_leg: Optional[Leg] = None
        best_t: Optional[dict] = None
        for t in remaining:
            leg = leg_to(g, here, t["cell"], occupied - {t["cell"]}, t["token"])
            if leg is None:
                continue
            if best_leg is None or leg.cost < best_leg.cost or \
                    (leg.cost == best_leg.cost and t["cell"] < best_t["cell"]):
                best_leg, best_t = leg, t
        if best_leg is None:
            for t in remaining:
                tour.skipped.append({"token": t["token"], "cell": list(t["cell"]),
                                     "reason": "unreachable from %s" % (list(here),)})
            remaining = []
            break
        tour.legs.append(best_leg)
        remaining.remove(best_t)
        here = tuple(best_leg.stand)
        visited += 1
    if limit is not None:
        for t in remaining:
            tour.skipped.append({"token": t["token"], "cell": list(t["cell"]),
                                 "reason": "beyond --limit %d" % limit})
    if g.teleports:
        tp = tuple(g.teleports[0])
        with _without(g, occupied - {here}):
            path = g.bfs_path(tp, start=here)
        if path is None:
            tour.skipped.append({"token": "teleport", "cell": list(tp),
                                 "reason": "teleporter unreachable from %s" % (list(here),)})
        else:
            tour.legs.append(Leg(kind="exit", token="teleport", target=list(tp), stand=list(tp),
                                 path=[list(p) for p in path], cost=len(path) - 1))
    return tour


def plan_from_scene(scene: dict, map_name: str, start: Optional[list],
                    limit: Optional[int] = None) -> Tour:
    """The museum fallback: no graph, so straight legs in world space to each
    live artifact in z order (the museum's own order), stopping 1.2 m short."""
    tour = Tour(map=map_name, spawn=list(start or [0, 0, 0]), source="scene")
    arts = [a for a in scene.get("artifacts", []) if not a.get("placeholder")]
    arts.sort(key=lambda a: (a["pos"][2], a["pos"][0]))
    if limit is not None:
        for a in arts[limit:]:
            tour.skipped.append({"token": a["token"], "cell": a.get("cell"),
                                 "reason": "beyond --limit %d" % limit})
        arts = arts[:limit]
    here = list(start or [0, 0, 0])
    for a in arts:
        p = a["pos"]
        dx, dz = p[0] - here[0], p[2] - here[2]
        d = (dx * dx + dz * dz) ** 0.5
        if d > 1.2:
            stand = [p[0] - dx / d * 1.2, here[1], p[2] - dz / d * 1.2]
        else:
            stand = list(here)
        tour.legs.append(Leg(kind="artifact", token=a["token"], target=a.get("cell"),
                             stand=a.get("cell") or [], path=[], cost=int(round(d)),
                             world=[list(here), stand]))
        here = stand
    return tour


# ─────────────────────────────────────────────────────────────────────────────
# What the registry says a thing is — for the report, not for the decision
# ─────────────────────────────────────────────────────────────────────────────

DESCRIBE_KEYS = ("name", "description", "qfep_connection", "qfep", "theory",
                 "interaction", "interactions", "category", "artifact_type", "tags")


def describe(token: str) -> dict:
    regs = mp._load_registries()
    entry = regs.get(token)
    if not entry:
        return {"token": token, "known": False}
    out: dict = {"token": token, "known": True}
    for k in DESCRIBE_KEYS:
        v = entry.get(k)
        if v in (None, "", [], {}):
            continue
        if isinstance(v, str) and len(v) > 400:
            v = v[:400] + "…"
        out[k] = v
    return out


# ─────────────────────────────────────────────────────────────────────────────
# The wire — how the agent talks to the game
# ─────────────────────────────────────────────────────────────────────────────
##
## The agent never opens the game socket itself. vr_link.py owns it (one game,
## one server); the agent either runs INSIDE vr_link.py (QueueWire, a
## subscriber queue on its Link) or beside it (HttpWire: the same browser
## endpoints — POST /cmd to send, GET /events to listen). Both give the same
## three verbs, so play() cannot tell them apart and the tests use a fake.

class Wire:
    def send(self, cmd: dict) -> None:
        raise NotImplementedError

    def wait(self, kind: str, timeout: float, tag: Optional[str] = None) -> Optional[dict]:
        raise NotImplementedError

    def drain(self) -> list:
        """Events that arrived but were not waited for (e.g. `activated`)."""
        return []

    def note(self, msg: str) -> None:
        print(f"[agent] {msg}")

    def current_map(self) -> str:
        return ""

    def close(self) -> None:
        pass


class _QueueWireBase(Wire):
    """Shared: a queue of incoming events, wait() with a side buffer so nothing
    that arrives out of turn is lost."""

    def __init__(self) -> None:
        self.q: queue.Queue = queue.Queue()
        self.buffer: list = []
        self._tag_n = 0

    def next_tag(self) -> str:
        self._tag_n += 1
        return "a%d" % self._tag_n

    def wait(self, kind: str, timeout: float, tag: Optional[str] = None) -> Optional[dict]:
        deadline = time.time() + timeout
        while True:
            left = deadline - time.time()
            if left <= 0:
                return None
            try:
                ev = self.q.get(timeout=min(left, 0.25))
            except queue.Empty:
                continue
            if not isinstance(ev, dict):
                continue
            if ev.get("k") == kind and (tag is None or ev.get("tag") == tag):
                return ev
            if ev.get("k") not in ("pose", "status", "log"):
                self.buffer.append(ev)

    def drain(self) -> list:
        out, self.buffer = self.buffer, []
        while True:
            try:
                ev = self.q.get_nowait()
            except queue.Empty:
                break
            if isinstance(ev, dict) and ev.get("k") not in ("pose", "status", "log"):
                out.append(ev)
        return out


class QueueWire(_QueueWireBase):
    """Inside vr_link.py: `link` is its Link (send, subscribe, note, pose)."""

    def __init__(self, link) -> None:
        super().__init__()
        self.link = link
        self.q = link.subscribe()

    def send(self, cmd: dict) -> None:
        self.link.send(cmd)

    def note(self, msg: str) -> None:
        self.link.note(f"agent: {msg}")

    def current_map(self) -> str:
        pose = getattr(self.link, "pose", {}) or {}
        return str(pose.get("map", ""))

    def close(self) -> None:
        self.link.unsubscribe(self.q)


class HttpWire(_QueueWireBase):
    """Beside vr_link.py: its web port. Server-sent events in, POST /cmd out."""

    def __init__(self, port: int = WEB_PORT) -> None:
        super().__init__()
        self.base = f"http://127.0.0.1:{port}"
        self._stop = False
        self._thread = threading.Thread(target=self._listen, daemon=True)
        self._thread.start()

    def _listen(self) -> None:
        try:
            with urllib.request.urlopen(self.base + "/events", timeout=30) as r:
                while not self._stop:
                    line = r.readline()
                    if not line:
                        break
                    line = line.decode("utf-8", "replace").strip()
                    if line.startswith("data: "):
                        try:
                            self.q.put(json.loads(line[6:]))
                        except json.JSONDecodeError:
                            pass
        except Exception as e:  # the server went away, or was never there
            self.q.put({"k": "status", "connected": False, "error": str(e)})

    def _post(self, path: str, body: dict) -> dict:
        data = json.dumps(body).encode("utf-8")
        req = urllib.request.Request(self.base + path, data=data,
                                     headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=10) as r:
            return json.loads(r.read().decode("utf-8"))

    def send(self, cmd: dict) -> None:
        self._post("/cmd", cmd)

    def note(self, msg: str) -> None:
        print(f"[agent] {msg}")
        try:
            self._post("/cmd", {"cmd": "say", "msg": msg})
        except Exception:
            pass

    def state(self) -> dict:
        with urllib.request.urlopen(self.base + "/state", timeout=10) as r:
            return json.loads(r.read().decode("utf-8"))

    def current_map(self) -> str:
        try:
            return str((self.state().get("pose") or {}).get("map", ""))
        except Exception:
            return ""

    def close(self) -> None:
        self._stop = True


# ─────────────────────────────────────────────────────────────────────────────
# The play — walk, look, act, one leg at a time
# ─────────────────────────────────────────────────────────────────────────────

def _walk_timeout(leg: Leg, speed: float, total: float) -> float:
    if leg.world:
        a, b = leg.world[0], leg.world[-1]
        d = ((a[0] - b[0]) ** 2 + (a[2] - b[2]) ** 2) ** 0.5
        return d / max(0.2, speed) + 8.0
    return leg.cost * total / max(0.2, speed) + 8.0


def play(tour: Tour, wire: Wire, interact: bool = True, exit_: bool = False,
         speed: float = 1.4, dwell: float = 2.0, scene: Optional[dict] = None) -> dict:
    """Drive the ghost through the tour. Returns the play report as a dict."""
    total = tour.cube + tour.gutter
    report: dict = {"map": tour.map, "source": tour.source, "started": time.time(),
                    "legs": [], "skipped": list(tour.skipped), "aborted": None}

    if scene is None:
        tag = wire.next_tag() if isinstance(wire, _QueueWireBase) else None
        wire.send({"cmd": "scan", "tag": tag})
        scene = wire.wait("scene", 6.0, tag)
        if scene is None:
            report["aborted"] = ("no `scene` reply to `scan` in 6 s — is a game attached, "
                                 "and does it run the upgraded bridge (commons/bridge/vr_link.gd "
                                 "with scan/look/interact)?")
            wire.note(report["aborted"])
            return report
    live: dict = {}
    for rec in scene.get("artifacts", []):
        live.setdefault(rec.get("token"), []).append(rec)
    report["scene"] = {"map": scene.get("map"), "artifacts": len(scene.get("artifacts", [])),
                       "cell": scene.get("cell")}
    wire.note("scan: %d artifacts standing in %s (cell rule from %s)" % (
        len(scene.get("artifacts", [])), scene.get("map", "?"),
        (scene.get("cell") or {}).get("source", "?")))

    for i, leg in enumerate(tour.legs):
        entry: dict = {"i": i, "kind": leg.kind, "token": leg.token, "target": leg.target,
                       "stand": leg.stand, "cost": leg.cost}
        report["legs"].append(entry)
        if leg.kind == "exit" and not exit_:
            # walk to the door and stop there; the door is the person's to open
            pass

        # 1. WALK — the game converts the cells with its own grid and drops each
        #    onto the floor; `report` makes it answer walker_done on arrival.
        tag = wire.next_tag() if isinstance(wire, _QueueWireBase) else None
        cmd: dict = {"cmd": "walker", "speed": speed, "loop": False, "body": True,
                     "report": True, "tag": tag}
        if leg.world:
            cmd["path"] = leg.world
        else:
            cmd["cells"] = leg.path
            cmd["cube"] = tour.cube
            cmd["gutter"] = tour.gutter
        wire.send(cmd)
        where = "%s at %s" % (leg.token, leg.target) if leg.kind == "artifact" else "the teleporter"
        wire.note("leg %d/%d: %d steps to %s" % (i + 1, len(tour.legs),
                                                   max(0, leg.cost), where))
        done = wire.wait("walker_done", _walk_timeout(leg, speed, total), tag)
        entry["arrived"] = done is not None
        if done is None:
            entry["note"] = "no walker_done — the walk timed out"
            wire.note("leg %d: the walk did not report arrival; going on" % (i + 1))
        else:
            entry["pos"] = done.get("pos")

        if leg.kind == "exit":
            if exit_:
                tag = wire.next_tag() if isinstance(wire, _QueueWireBase) else None
                wire.send({"cmd": "interact", "utility": True, "verb": "teleport", "tag": tag})
                acted = wire.wait("acted", 5.0, tag)
                entry["acted"] = acted
                wire.note("exit: %s" % ((acted or {}).get("detail", "no reply")))
            else:
                entry["note"] = "stood at the teleporter; --exit would take it"
                wire.note("at the teleporter. Not taking it (no --exit).")
            continue

        # 2. LOOK — the ghost turns to it; the game says what it can see.
        tag = wire.next_tag() if isinstance(wire, _QueueWireBase) else None
        look: dict = {"cmd": "look", "token": leg.token, "dwell": dwell, "tag": tag}
        if leg.target and not leg.world:
            look["cell"] = leg.target
        wire.send(look)
        seen = wire.wait("seen", 6.0, tag)
        entry["seen"] = seen
        entry["registry"] = describe(leg.token)
        if seen is None or not seen.get("ok"):
            entry["note"] = "not seen: %s" % ((seen or {}).get("detail", "no reply"))
            wire.note("%s: %s" % (leg.token, entry["note"]))
            time.sleep(min(dwell, 1.0))
            continue
        aff = seen.get("affordances", [])
        wire.note("looking at %s (%s): %.1f m, %s%s; can: %s" % (
            leg.token, seen.get("name") or entry["registry"].get("name", "?"),
            float(seen.get("distance", 0.0)),
            "in view" if seen.get("line_of_sight") else "hidden behind %s" % seen.get("blocked_by", "?"),
            "" if leg.token in live else " (NOT in the scan)",
            ", ".join(aff) if aff else "nothing"))
        desc = entry["registry"].get("description")
        if desc:
            wire.note("  it is: %s" % desc)

        # 3. ACT — the game picks the first rung the thing actually has.
        if interact and aff and not (set(aff) <= {"teleporter"}):
            tag = wire.next_tag() if isinstance(wire, _QueueWireBase) else None
            act: dict = {"cmd": "interact", "token": leg.token, "verb": "auto", "tag": tag}
            if leg.target and not leg.world:
                act["cell"] = leg.target
            wire.send(act)
            acted = wire.wait("acted", 6.0, tag)
            entry["acted"] = acted
            time.sleep(0.4)
            confirms = [e for e in wire.drain() if e.get("k") == "activated"]
            if confirms:
                entry["confirmed"] = confirms
            if acted is None:
                wire.note("  interact: no reply")
            else:
                wire.note("  %s: %s%s" % (
                    "did" if acted.get("ok") else "could not",
                    acted.get("detail", ""),
                    " — the grid confirmed `%s` activated" % confirms[0].get("token")
                    if confirms else ""))
            if acted and acted.get("ok") and acted.get("verb") == "grab":
                time.sleep(min(dwell, 1.5))
                tag = wire.next_tag() if isinstance(wire, _QueueWireBase) else None
                wire.send({"cmd": "interact", "verb": "drop", "tag": tag})
                dropped = wire.wait("acted", 4.0, tag)
                entry["dropped"] = dropped
                wire.note("  %s" % ((dropped or {}).get("detail", "drop: no reply")))
        elif interact:
            wire.note("  nothing here answers to a hand")
        time.sleep(dwell)

    report["finished"] = time.time()
    return report


# ─────────────────────────────────────────────────────────────────────────────
# Reports
# ─────────────────────────────────────────────────────────────────────────────

def plan_text(tour: Tour) -> str:
    lines = ["tour of %s — %d legs, %d skipped (%s)" % (
        tour.map, len(tour.legs), len(tour.skipped), tour.source)]
    for i, leg in enumerate(tour.legs):
        if leg.kind == "exit":
            lines.append("  %2d. %3d steps  -> teleporter at %s" % (i + 1, leg.cost, leg.target))
        else:
            lines.append("  %2d. %3d steps  -> %-32s at %s, stand %s" % (
                i + 1, leg.cost, leg.token, leg.target, leg.stand))
    for s in tour.skipped:
        lines.append("  --  skipped %-32s at %s: %s" % (s["token"], s.get("cell"), s["reason"]))
    return "\n".join(lines)


def report_markdown(report: dict) -> str:
    out = ["# Python walker — %s" % report.get("map", "?"), ""]
    if report.get("aborted"):
        out.append("**Aborted:** %s" % report["aborted"])
        out.append("")
    sc = report.get("scene") or {}
    if sc:
        out.append("Scanned %s artifacts standing in the room (cell rule: %s)." % (
            sc.get("artifacts"), (sc.get("cell") or {}).get("source")))
        out.append("")
    for e in report.get("legs", []):
        if e["kind"] == "exit":
            out.append("## Exit — %s" % (e.get("note") or (e.get("acted") or {}).get("detail", "")))
            out.append("")
            continue
        reg = e.get("registry") or {}
        seen = e.get("seen") or {}
        out.append("## %s — %s" % (e["token"], reg.get("name") or seen.get("name") or ""))
        out.append("")
        out.append("- **Walked:** %s steps to stand at %s (%s)" % (
            e.get("cost"), e.get("stand"), "arrived" if e.get("arrived") else "did not arrive"))
        if seen:
            if seen.get("ok"):
                out.append("- **Seen:** %.1f m away, %s; affordances: %s" % (
                    float(seen.get("distance", 0.0)),
                    "in view" if seen.get("line_of_sight") else "hidden behind %s" % seen.get("blocked_by"),
                    ", ".join(seen.get("affordances", [])) or "none"))
                if seen.get("size"):
                    out.append("- **Extent:** %s m" % (" × ".join("%.2f" % v for v in seen["size"])))
            else:
                out.append("- **Seen:** %s" % seen.get("detail"))
        if reg.get("description"):
            out.append("- **Registry says:** %s" % reg["description"])
        if reg.get("qfep_connection") or reg.get("qfep"):
            out.append("- **QFEP:** %s" % (reg.get("qfep_connection") or reg.get("qfep")))
        acted = e.get("acted")
        if acted:
            out.append("- **Did:** %s%s — %s" % (
                acted.get("verb"), "" if acted.get("ok") else " (failed)", acted.get("detail")))
        if e.get("confirmed"):
            out.append("- **The grid confirmed:** %s activated" % e["confirmed"][0].get("token"))
        if e.get("note"):
            out.append("- **Note:** %s" % e["note"])
        out.append("")
    if report.get("skipped"):
        out.append("## Skipped")
        out.append("")
        for s in report["skipped"]:
            out.append("- %s at %s: %s" % (s["token"], s.get("cell"), s["reason"]))
        out.append("")
    return "\n".join(out)


def write_report(report: dict) -> tuple[Path, Path]:
    RUN_DIR.mkdir(parents=True, exist_ok=True)
    stem = "vr_agent_%s" % (report.get("map") or "unknown")
    pj = RUN_DIR / (stem + ".json")
    pm = RUN_DIR / (stem + ".md")
    pj.write_text(json.dumps(report, indent=1, ensure_ascii=False), encoding="utf-8")
    pm.write_text(report_markdown(report), encoding="utf-8")
    return pj, pm


def tour_dict(tour: Tour) -> dict:
    d = asdict(tour)
    return d


def tour_decisions(tour: Tour) -> list:
    """The shape tools/vr_link_view.html already draws for the humanoid_walker:
    a `move` per cell and a `look` per work, each with a world point."""
    out: list = []
    for leg in tour.legs:
        if leg.world:
            for p in leg.world:
                out.append({"action": "move", "world": p, "cell": None, "artifact": None})
            out.append({"action": "look", "world": leg.world[-1], "cell": None, "artifact": leg.token})
            continue
        for c in leg.path:
            out.append({"action": "move", "cell": c,
                        "world": cell_world(c[0], c[1], tour.cube, tour.gutter), "artifact": None})
        if leg.target:
            out.append({"action": "look" if leg.kind == "artifact" else "exit", "cell": leg.target,
                        "world": cell_world(leg.target[0], leg.target[1], tour.cube, tour.gutter),
                        "artifact": leg.token})
    return out


# ─────────────────────────────────────────────────────────────────────────────
# Entry points
# ─────────────────────────────────────────────────────────────────────────────

def plan_map(map_name: str, limit: Optional[int] = None) -> tuple[Optional[Tour], Optional[mp.MapGraph]]:
    g = load_graph(map_name)
    if g is None:
        return None, None
    cube, gutter = cell_size(g.data)
    return plan_tour(g, map_name, limit=limit, cube=cube, gutter=gutter), g


def run(map_name: str, wire: Wire, interact: bool = True, exit_: bool = False,
        speed: float = 1.4, dwell: float = 2.0, limit: Optional[int] = None) -> dict:
    """Plan and play one map over a wire. The map may be '' (whatever the game
    is in). Writes the report; returns it."""
    if not map_name:
        map_name = wire.current_map()
        if not map_name:
            wire.note("no map: the game has not sent a pose yet")
            return {"map": "", "aborted": "no map", "legs": []}
    tour, g = plan_map(map_name, limit)
    scene = None
    if tour is None:
        # a hall of the museum, or a generated room: nothing to path on
        tag = wire.next_tag() if isinstance(wire, _QueueWireBase) else None
        wire.send({"cmd": "scan", "tag": tag})
        scene = wire.wait("scene", 6.0, tag)
        if scene is None:
            wire.note("'%s' has no map_data.json and the game did not answer a scan" % map_name)
            return {"map": map_name, "aborted": "no map and no scan", "legs": []}
        tour = plan_from_scene(scene, map_name, scene.get("ghost"), limit=limit)
        wire.note("'%s' has no map to path on — walking the %d artifacts the scan found, in z order"
                  % (map_name, len(tour.legs)))
    else:
        wire.note(plan_text(tour))
    report = play(tour, wire, interact=interact, exit_=exit_, speed=speed, dwell=dwell, scene=scene)
    report["plan"] = tour_dict(tour)
    pj, pm = write_report(report)
    try:
        shown = str(pm.relative_to(ROOT))
    except ValueError:      # a report directory outside the repo (the tests use one)
        shown = str(pm)
    wire.note("report: %s" % shown)
    return report


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("map", nargs="?", default="", help="map name (commons/maps/<Map>)")
    ap.add_argument("--live", action="store_true", help="play the map the game is in")
    ap.add_argument("--dry-run", action="store_true", help="plan only; no game")
    ap.add_argument("--json", action="store_true", help="with --dry-run: print the plan as JSON")
    ap.add_argument("--no-color", action="store_true")
    ap.add_argument("--no-interact", action="store_true")
    ap.add_argument("--exit", action="store_true", help="take the teleporter at the end")
    ap.add_argument("--limit", type=int, default=None)
    ap.add_argument("--speed", type=float, default=1.4)
    ap.add_argument("--dwell", type=float, default=2.0)
    ap.add_argument("--port", type=int, default=WEB_PORT)
    args = ap.parse_args()

    if args.dry_run:
        if not args.map:
            print("a map name is needed for --dry-run")
            return 2
        tour, g = plan_map(args.map, args.limit)
        if tour is None:
            print("no map_data.json for '%s'" % args.map)
            return 1
        if args.json:
            print(json.dumps(tour_dict(tour), indent=1))
            return 0
        print(plan_text(tour))
        print()
        print(mp.render_ascii(g, g.bfs_flood(), path=[tuple(c) for c in tour.cells()],
                              use_color=not args.no_color))
        return 0

    if not args.map and not args.live:
        print("give a map name, or --live for the map the game is in")
        return 2
    wire = HttpWire(args.port)
    try:
        report = run(args.map, wire, interact=not args.no_interact, exit_=args.exit,
                     speed=args.speed, dwell=args.dwell, limit=args.limit)
    finally:
        wire.close()
    return 0 if not report.get("aborted") else 1


if __name__ == "__main__":
    raise SystemExit(main())
