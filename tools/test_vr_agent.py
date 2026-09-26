#!/usr/bin/env python3
"""test_vr_agent.py — the python walker's plan and play, proven without Godot.

What is proven here, and what is not. The PLAN (tools/vr_agent.py over
map_pathfinder's graph) is pure and is checked against the real Point_One map.
The PLAY is checked against a FAKE GAME that answers the bridge's protocol the
way commons/bridge/vr_link.gd does — in-process first, then over vr_link.py's
real sockets (the game socket and the browser endpoints), so the whole Python
wire is exercised. The Godot side itself is covered by
commons/testing/probe_vr_link_agent.gd, which needs an engine.

Run:  python tools/test_vr_agent.py        exit 0 iff every check holds
"""
from __future__ import annotations

import copy
import json
import queue
import socket
import sys
import tempfile
import threading
import time
import urllib.request
from http.server import ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import map_pathfinder as mp  # noqa: E402
import vr_agent as va  # noqa: E402

FAILS: list[str] = []


def check(cond: bool, what: str) -> None:
    print(("  ok   " if cond else "  FAIL ") + what)
    if not cond:
        FAILS.append(what)


# ─────────────────────────────────────────────────────────────────────────────
# A game that speaks the protocol
# ─────────────────────────────────────────────────────────────────────────────

class FakeGame:
    """Answers commands the way vr_link.gd does, from a table of affordances per
    token instead of a scene. Records every command it was sent, in order."""

    def __init__(self, g: mp.MapGraph, affordances: dict | None = None) -> None:
        self.g = g
        self.cube, self.gutter = va.cell_size(g.data)
        self.aff = affordances or {}
        self.commands: list[dict] = []
        self.teleported = 0
        self.walked: list = []

    def scene(self) -> dict:
        arts = []
        for i, a in enumerate(self.g.artifacts):
            if a["name"] in va.TEXT_TOKENS:
                continue
            w = va.cell_world(a["row"], a["col"], self.cube, self.gutter, 0.5)
            arts.append({"index": i, "token": a["name"],
                         "name": a["name"].replace("_", " ").title(), "type": "probe",
                         "pos": w, "centre": [w[0], 1.0, w[2]], "size": [1.0, 1.0, 1.0],
                         "affordances": list(self.aff.get(a["name"], ["interact"])),
                         "cell": [a["row"], a["col"]],
                         "path": "/root/Scene/%s" % a["name"], "placeholder": False})
        tp = self.g.teleports[0] if self.g.teleports else (0, 0)
        return {"k": "scene", "map": self.g.name, "artifacts": arts,
                "utilities": [{"name": "Teleporter", "teleporter": True, "destination": "next",
                               "pos": va.cell_world(tp[0], tp[1], self.cube, self.gutter)}],
                "cell": {"cube": self.cube, "gutter": self.gutter, "source": "grid"},
                "ghost": [0.0, 0.5, 0.0]}

    def handle(self, cmd: dict) -> list[dict]:
        self.commands.append(cmd)
        tag = cmd.get("tag")

        def tagged(d: dict) -> dict:
            if tag is not None:
                d["tag"] = tag
            return d

        k = cmd.get("cmd")
        if k == "ping":
            return [tagged({"k": "pong"})]
        if k == "walker":
            pts = cmd.get("cells") or cmd.get("path") or []
            self.walked.append(pts)
            if cmd.get("report"):
                return [tagged({"k": "walker_done", "pos": [0.0, 0.5, 0.0], "waypoints": len(pts)})]
            return [{"k": "log", "msg": "walker: %d waypoints" % len(pts)}]
        if k == "scan":
            return [tagged(self.scene())]
        if k == "look":
            tok = cmd.get("token")
            rec = next((a for a in self.scene()["artifacts"] if a["token"] == tok), None)
            if rec is None:
                return [tagged({"k": "seen", "ok": False, "detail": "no such artifact", "token": tok})]
            r = dict(rec)
            r.update({"k": "seen", "ok": True, "distance": 1.3, "bearing": 12.0, "line_of_sight": True})
            return [tagged(r)]
        if k == "interact":
            verb = cmd.get("verb", "auto")
            if verb == "drop":
                return [tagged({"k": "acted", "ok": True, "verb": "drop", "detail": "put down it"})]
            if cmd.get("utility"):
                if verb == "teleport":
                    self.teleported += 1
                    return [tagged({"k": "acted", "ok": True, "verb": "teleport",
                                    "detail": "_start_teleport_sequence"})]
                return [tagged({"k": "acted", "ok": False, "verb": verb,
                                "detail": "a teleporter — verb 'teleport' takes it"})]
            tok = cmd.get("token")
            aff = self.aff.get(tok, ["interact"])
            chosen = next((v for v in ["interact", "activate", "signal", "press", "touch", "grab"]
                           if v in aff), None)
            if chosen is None:
                return [tagged({"k": "acted", "ok": False, "verb": "auto", "token": tok,
                                "detail": "nothing to do"})]
            return [tagged({"k": "acted", "ok": True, "verb": chosen, "token": tok,
                            "detail": "%s on %s" % (chosen, tok)}),
                    {"k": "activated", "token": tok, "pos": [0, 0, 0], "name": tok}]
        return [tagged({"k": "log", "msg": "unknown cmd %s" % k})]


class FakeLink:
    """In-process stand-in for vr_link.Link: send() is answered synchronously."""

    def __init__(self, game: FakeGame) -> None:
        self.game = game
        self.subs: list[queue.Queue] = []
        self.notes: list[str] = []
        self.pose = {"map": game.g.name}

    def subscribe(self) -> queue.Queue:
        q: queue.Queue = queue.Queue()
        self.subs.append(q)
        return q

    def unsubscribe(self, q: queue.Queue) -> None:
        self.subs.remove(q)

    def send(self, cmd: dict) -> None:
        for ev in self.game.handle(json.loads(json.dumps(cmd))):
            for q in self.subs:
                q.put(ev)

    def note(self, msg: str) -> None:
        self.notes.append(msg)


# ─────────────────────────────────────────────────────────────────────────────
# The plan
# ─────────────────────────────────────────────────────────────────────────────

def adjacent(a, b) -> bool:
    return abs(a[0] - b[0]) + abs(a[1] - b[1]) == 1


def test_plan_is_a_walk() -> None:
    print("plan: Point_One")
    tour, g = va.plan_map("Point_One")
    check(tour is not None and len(tour.legs) >= 2, "a tour with legs")
    prev = tuple(tour.spawn)
    visited: list[str] = []
    for leg in tour.legs:
        check(tuple(leg.path[0]) == prev, "leg to %s starts where the last ended" % leg.token)
        ok_steps = all(tuple(b) in g.neighbors(tuple(a)) for a, b in zip(leg.path, leg.path[1:]))
        check(ok_steps, "every step of the leg to %s is a MapGraph.neighbors step" % leg.token)
        check(tuple(leg.path[-1]) == tuple(leg.stand), "the leg ends on its stand cell")
        if leg.kind == "artifact":
            check(adjacent(leg.stand, leg.target) or leg.stand == leg.target,
                  "stands beside %s" % leg.token)
            visited.append(leg.token)
        prev = tuple(leg.stand)
    check(tour.legs[-1].kind == "exit" and tuple(tour.legs[-1].stand) == tuple(g.teleports[0]),
          "the last leg ends on the teleporter")
    wanted = [t["token"] for t in va.artifact_targets(g)]
    check(sorted(visited) == sorted(wanted) and len(set(visited)) == len(visited),
          "every artifact visited exactly once (%d)" % len(wanted))
    check(any(s["token"] == "3t" for s in tour.skipped), "the floating text is skipped and says so")
    # legs go round other works, not through them
    occupied = {tuple(t["cell"]) for t in va.artifact_targets(g)}
    for leg in tour.legs:
        inner = [tuple(c) for c in leg.path[1:-1]]
        crossed = [c for c in inner if c in occupied]
        check(not crossed, "the leg to %s crosses no other work %s" % (leg.token, crossed or ""))
    decs = va.tour_decisions(tour)
    check(sum(1 for d in decs if d["action"] == "look") == len(visited), "one `look` decision per work")
    check(tour.cells()[0] == list(tour.spawn), "the drawn path starts at spawn")


def test_walled_off_is_reported() -> None:
    print("plan: a walled-off work is reported, not silently dropped")
    p = mp.resolve_map_path("Point_One")
    data = mp.load_map(p)
    g0 = mp.MapGraph(copy.deepcopy(data))
    token, cell = "drag_point_target", (10, 6)
    base = va.plan_tour(g0, "Point_One")
    check(any(l.token == token for l in base.artifact_legs()), "unwalled, %s is in the tour" % token)
    walled = copy.deepcopy(data)
    for dr in (-1, 0, 1):
        for dc in (-1, 0, 1):
            if dr or dc:
                walled["layers"]["structure"][cell[0] + dr][cell[1] + dc] = "w"
    g1 = mp.MapGraph(walled)
    tour = va.plan_tour(g1, "Point_One")
    check(not any(l.token == token for l in tour.artifact_legs()), "walled in, it is not visited")
    sk = [s for s in tour.skipped if s["token"] == token]
    check(bool(sk) and "unreachable" in sk[0]["reason"], "…and the skip says unreachable: %s"
          % (sk[0]["reason"] if sk else "MISSING"))
    check(tour.legs[-1].kind == "exit", "the tour still ends at the teleporter")
    check(g0.walkable == mp.MapGraph(copy.deepcopy(data)).walkable,
          "planning leaves the graph's walkable set as it found it")


def test_plan_from_scene() -> None:
    print("plan: the museum fallback walks the scan in z order")
    scene = {"artifacts": [
        {"token": "b", "pos": [2.0, 0.5, 5.0]},
        {"token": "a", "pos": [0.0, 0.5, 2.0]},
        {"token": "c", "pos": [4.0, 0.5, 9.0]},
        {"token": "ph", "pos": [4.0, 0.5, 9.5], "placeholder": True},
    ]}
    tour = va.plan_from_scene(scene, "SomeHall", [0.0, 0.5, 0.0])
    check([l.token for l in tour.legs] == ["a", "b", "c"], "z order, placeholders left out")
    for leg in tour.legs:
        stand = leg.world[-1]
        art = next(x for x in scene["artifacts"] if x["token"] == leg.token)["pos"]
        d = ((stand[0] - art[0]) ** 2 + (stand[2] - art[2]) ** 2) ** 0.5
        check(abs(d - 1.2) < 1e-6, "stands 1.2 m short of %s" % leg.token)
    check(tour.source == "scene", "the tour says it came from a scan")


def test_describe() -> None:
    print("registry: describe")
    d = va.describe("origin")
    check(d["known"] and bool(d.get("description")), "origin has a description")
    check(not va.describe("no_such_thing_xyz")["known"], "an unknown token says so")


# ─────────────────────────────────────────────────────────────────────────────
# The play — in process
# ─────────────────────────────────────────────────────────────────────────────

def test_play_in_process() -> None:
    print("play: over an in-process fake game")
    tour, g = va.plan_map("Point_One")
    arts = [l.token for l in tour.artifact_legs()]
    inert, grabbable, doorish = arts[0], arts[1], arts[2]
    game = FakeGame(g, {inert: [], grabbable: ["grab"], doorish: ["teleporter"]})
    link = FakeLink(game)
    tmp = Path(tempfile.mkdtemp())
    va.RUN_DIR = tmp
    wire = va.QueueWire(link)
    report = va.run("Point_One", wire, interact=True, exit_=False, speed=100.0, dwell=0.0)
    wire.close()
    check(report.get("aborted") is None, "the play was not aborted")
    check(len(report["legs"]) == len(tour.legs), "one report entry per leg")
    check(all(e["arrived"] for e in report["legs"]), "every leg arrived (walker_done)")
    kinds = [c["cmd"] for c in game.commands]
    check(kinds[0] == "scan", "it scans first")
    # per work: walker, then look, then (maybe) interact — in that order
    for leg in tour.artifact_legs():
        idx = [i for i, c in enumerate(game.commands) if c.get("token") == leg.token]
        seq = [game.commands[i]["cmd"] for i in idx]
        if leg.token == inert:
            check(seq == ["look"], "%s (affords nothing): looked at, never touched %s" % (leg.token, seq))
        elif leg.token == doorish:
            check(seq == ["look"], "%s (a teleporter): looked at, never taken %s" % (leg.token, seq))
        elif leg.token == grabbable:
            check(seq == ["look", "interact"], "%s: looked, grabbed" % leg.token)
        else:
            check(seq == ["look", "interact"], "%s: looked, then interacted %s" % (leg.token, seq))
        w = [game.commands[i - 1]["cmd"] for i in idx[:1]]
        check(w == ["walker"], "%s: the walk came before the look" % leg.token)
    drops = [c for c in game.commands if c.get("verb") == "drop"]
    check(len(drops) == 1, "the grabbed thing was put down once")
    check(game.teleported == 0, "the teleporter was NOT taken without --exit")
    ex = report["legs"][-1]
    check(ex["kind"] == "exit" and "--exit" in ex.get("note", ""), "the exit entry says how to take it")
    done = [e for e in report["legs"] if e["kind"] == "artifact" and (e.get("acted") or {}).get("ok")]
    check(all(e.get("confirmed") for e in done), "the grid's `activated` was heard for every act")
    check(all(e["seen"]["ok"] for e in report["legs"] if e["kind"] == "artifact"), "every work was seen")
    md = (tmp / "vr_agent_Point_One.md").read_text(encoding="utf-8")
    check("## origin" in md and "**Did:** interact" in md, "the markdown report names the work and the verb")
    check(any("looking at origin" in n for n in link.notes), "narration went to the link's log")
    # cells were sent, not world points — the game converts with its own grid
    check(all("cells" in c for c in game.commands if c["cmd"] == "walker"), "walks are sent as cells")

    game2 = FakeGame(g)
    wire2 = va.QueueWire(FakeLink(game2))
    r2 = va.run("Point_One", wire2, interact=False, exit_=True, speed=100.0, dwell=0.0, limit=2)
    wire2.close()
    check(game2.teleported == 1, "with --exit the teleporter is taken")
    check(not any(c["cmd"] == "interact" and not c.get("utility") for c in game2.commands),
          "--no-interact touches nothing")
    check(len([e for e in r2["legs"] if e["kind"] == "artifact"]) == 2, "--limit 2 visits two works")
    check(any("beyond --limit" in s["reason"] for s in r2["skipped"]), "the rest are listed as skipped")


def test_play_aborts_without_scene() -> None:
    print("play: a game that never answers a scan aborts cleanly")

    class Mute(FakeGame):
        def handle(self, cmd: dict) -> list[dict]:
            self.commands.append(cmd)
            return []

    tour, g = va.plan_map("Point_One")
    game = Mute(g)
    wire = va.QueueWire(FakeLink(game))
    t0 = time.time()
    report = va.play(tour, wire, speed=100.0, dwell=0.0)
    wire.close()
    check(report["aborted"] and "scan" in report["aborted"], "aborted with the reason")
    check(len(game.commands) == 1, "nothing was sent after the missing scene")
    check(time.time() - t0 < 12, "…within the timeout")


# ─────────────────────────────────────────────────────────────────────────────
# The play — over vr_link.py's real sockets
# ─────────────────────────────────────────────────────────────────────────────

def free_port() -> int:
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    p = s.getsockname()[1]
    s.close()
    return p


def fake_game_socket(game: FakeGame, port: int, stop: threading.Event) -> None:
    """A game on the wire: hello, a pose every 0.2 s, and an answer to every
    command — exactly what vr_link.gd does, minus the room."""
    s = socket.create_connection(("127.0.0.1", port), timeout=5)
    s.settimeout(0.05)
    f = s.makefile("rwb")

    def send(d: dict) -> None:
        f.write((json.dumps(d) + "\n").encode("utf-8"))
        f.flush()

    send({"k": "hello", "role": "game"})
    last_pose = 0.0
    buf = b""
    while not stop.is_set():
        if time.time() - last_pose > 0.2:
            send({"k": "pose", "seq": 1, "t": time.time(), "map": game.g.name, "pos": [0, 0.5, 0]})
            last_pose = time.time()
        try:
            chunk = s.recv(65536)
        except socket.timeout:
            continue
        except OSError:
            break
        if not chunk:
            break
        buf += chunk
        while b"\n" in buf:
            line, buf = buf.split(b"\n", 1)
            if not line.strip():
                continue
            try:
                cmd = json.loads(line.decode("utf-8"))
            except json.JSONDecodeError:
                continue
            if cmd.get("cmd"):
                for ev in game.handle(cmd):
                    send(ev)
    s.close()


def test_play_over_sockets() -> None:
    print("play: over vr_link.py's game socket and browser endpoints")
    import vr_link
    gport, wport = free_port(), free_port()
    vr_link.GAME_PORT = gport
    threading.Thread(target=vr_link.game_server, args=(vr_link.LINK,), daemon=True).start()
    httpd = ThreadingHTTPServer(("127.0.0.1", wport), vr_link.Handler)
    httpd.daemon_threads = True
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    time.sleep(0.2)

    tour, g = va.plan_map("Point_One")
    game = FakeGame(g)
    stop = threading.Event()
    threading.Thread(target=fake_game_socket, args=(game, gport, stop), daemon=True).start()
    t0 = time.time()
    while time.time() - t0 < 5 and not vr_link.LINK.connected:
        time.sleep(0.05)
    check(vr_link.LINK.connected, "the fake game is attached (a pose arrived)")

    # the browser endpoint plans without touching the game
    req = urllib.request.Request("http://127.0.0.1:%d/agent" % wport,
                                 data=json.dumps({"map": "Point_One", "dry_run": True}).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=10) as r:
        d = json.loads(r.read())
    check(d.get("ok") and len(d["plan"]["legs"]) == len(tour.legs), "POST /agent dry_run returns the plan")
    check(not any(c["cmd"] != "ping" for c in game.commands), "…and sent the game nothing")

    # a separate process would do this: HttpWire against the server
    tmp = Path(tempfile.mkdtemp())
    va.RUN_DIR = tmp
    wire = va.HttpWire(wport)
    time.sleep(0.3)   # the SSE listener attaches
    check(wire.current_map() == "Point_One", "HttpWire reads the live map from /state")
    report = va.run("", wire, interact=True, exit_=False, speed=100.0, dwell=0.0, limit=3)
    wire.close()
    check(report.get("aborted") is None, "the play over sockets was not aborted")
    legs = report.get("legs", [])
    check(len(legs) == 4, "3 works + the exit = 4 legs (got %d)" % len(legs))
    check(all(e["arrived"] for e in legs), "every leg's walker_done came back over the socket")
    acts = [e for e in legs if e["kind"] == "artifact"]
    check(all((e.get("acted") or {}).get("ok") for e in acts), "every work was acted on")
    check(all(e.get("confirmed") for e in acts), "the `activated` confirmations crossed the wire too")
    check((tmp / "vr_agent_Point_One.json").exists(), "the report was written")

    # the in-server agent (what --agent and the browser button do), refused while one runs
    req = urllib.request.Request("http://127.0.0.1:%d/agent" % wport,
                                 data=json.dumps({"map": "Point_One", "limit": 1, "speed": 100,
                                                  "dwell": 0}).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=10) as r:
        d = json.loads(r.read())
    check(d.get("ok") and d.get("legs") == 2, "POST /agent starts a tour in the server (limit 1: a work and the exit)")
    t0 = time.time()
    while time.time() - t0 < 10 and vr_link.AGENT_STATE["running"]:
        time.sleep(0.05)
    check(not vr_link.AGENT_STATE["running"], "…and it finishes")
    stop.set()
    httpd.shutdown()


def main() -> int:
    test_plan_is_a_walk()
    test_walled_off_is_reported()
    test_plan_from_scene()
    test_describe()
    test_play_in_process()
    test_play_aborts_without_scene()
    test_play_over_sockets()
    print()
    if FAILS:
        print("FAILED %d:" % len(FAILS))
        for f in FAILS:
            print("  - " + f)
        return 1
    print("OK — every check holds")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
