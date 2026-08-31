#!/usr/bin/env python3
"""VR LINK — the headset and the PC on one wire, over the USB cable.

2026-08-31, Palle: "Can we play the game in vr send the coordinate over usb to
the desktop app showing the 3d view a top down view and a text one the pc
screen. And visa versa. Have the python walker walk around in vr?"

Yes to all four, and the reason it is cheap is that THE CABLE IS ALREADY A
NETWORK. `adb reverse tcp:8771 tcp:8771` makes the headset's own 127.0.0.1:8771
come out on the PC's 127.0.0.1:8771 — no wifi, no IP to configure, nothing to
discover. Godot's editor already does exactly this for its remote debugger on
port 6007, so the mechanism is the one the toolchain uses on itself.

Two consequences worth stating plainly:

  * There is no Android-specific code anywhere in this. The same socket is
    loopback on the desktop and a USB tunnel on the Quest, so the desktop game
    exercises the identical path with no adb involved. That is the dev loop.
  * The APK already on the device carries android.permission.INTERNET (checked
    with `adb shell dumpsys package`), so none of this needs a rebuild.

Every other bridge in this project — em_control.json, mapsim_control.json,
desktop_feedback.md — is a FILE poll, and a file poll cannot reach a headset at
all: user:// on the Quest is on the Quest. This is the first one that crosses.

    python tools/vr_link.py                      # serve; open localhost:8772
    python tools/vr_link.py --arm                # also arm the headset, then serve
    python tools/vr_link.py --walker=Point_Tests # send a walk into VR and serve
    python tools/vr_link.py --calibrate          # which cell-to-world rule is true?

The browser page at :8772 shows the three views asked for — 3D, top-down, and
text — and can send the player somewhere by clicking the top-down map.
"""

from __future__ import annotations

import argparse
import json
import os
import queue
import random
import socket
import subprocess
import sys
import threading
import time
from collections import deque
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from pathlib import Path
from urllib.parse import urlparse, parse_qs

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
GAME_PORT = 8771
WEB_PORT = 8772
PKG = "com.example.adaresearchzeroone"
ADB = os.environ.get(
    "ADA_ADB",
    r"C:\Users\palle\AppData\Local\Android\Sdk\platform-tools\adb.exe",
)


# ─────────────────────────────────────────────────────────────────────────────
# Shared state
# ─────────────────────────────────────────────────────────────────────────────

class Client:
    """One socket. A `game` sends pose and takes commands; a `viewer` only
    watches. The role arrives in a `hello` line; anything that starts sending
    pose is treated as the game regardless, because a client that forgets to
    introduce itself should still work."""

    def __init__(self, conn, addr) -> None:
        self.conn = conn
        self.addr = f"{addr[0]}:{addr[1]}"
        self.role = "unknown"
        self.q: queue.Queue = queue.Queue(maxsize=400)


class Link:
    """What the game last said, who is listening, and what to say back."""

    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.pose: dict = {}
        self.log: deque = deque(maxlen=400)
        self.subs: list[queue.Queue] = []
        self.out: queue.Queue = queue.Queue()
        self.clients: list[Client] = []
        self.connected = False
        self.peer = ""
        self.rate = 0.0
        self.last_pose_at = 0.0
        self._stamps: deque = deque(maxlen=40)

    def viewers(self) -> int:
        with self.lock:
            return sum(1 for c in self.clients if c.role == "viewer")

    ## Pose goes to every viewer as well as to every browser. A Godot viewer is
    ## just another client on the same socket — it reads the museum's geometry
    ## off disk itself (same machine) and only needs the moving part.
    def to_viewers(self, d: dict) -> None:
        with self.lock:
            vs = [c for c in self.clients if c.role == "viewer"]
        for c in vs:
            try:
                c.q.put_nowait(d)
            except queue.Full:
                pass

    # fan out one event to every open browser
    def publish(self, ev: dict) -> None:
        with self.lock:
            subs = list(self.subs)
        for q in subs:
            try:
                q.put_nowait(ev)
            except queue.Full:
                pass  # a browser that cannot keep up is dropped, not waited for

    def note(self, msg: str) -> None:
        row = {"k": "log", "t": time.time(), "msg": msg}
        with self.lock:
            self.log.append(row)
        self.publish(row)
        print(f"[vr-link] {msg}")

    def on_pose(self, d: dict) -> None:
        now = time.time()
        with self.lock:
            self.pose = d
            self.last_pose_at = now
            self._stamps.append(now)
            if len(self._stamps) > 2:
                span = self._stamps[-1] - self._stamps[0]
                self.rate = (len(self._stamps) - 1) / span if span > 0 else 0.0
        self.publish(d)
        self.to_viewers(d)

    def send(self, cmd: dict) -> None:
        self.out.put(cmd)


LINK = Link()


# ─────────────────────────────────────────────────────────────────────────────
# The game socket
# ─────────────────────────────────────────────────────────────────────────────

def game_server(link: Link) -> None:
    """Accept the game (headset over USB, or desktop over loopback) and pump
    NDJSON both ways. One client at a time — there is one player."""
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        srv.bind(("127.0.0.1", GAME_PORT))
    except OSError as e:
        print(f"[vr-link] cannot bind {GAME_PORT}: {e}")
        print("          another vr_link.py is probably already running.")
        os._exit(1)
    srv.listen(1)
    print(f"[vr-link] listening for the game on 127.0.0.1:{GAME_PORT}")

    while True:
        conn, addr = srv.accept()
        threading.Thread(target=serve_client, args=(link, conn, addr),
                         daemon=True).start()


def serve_client(link: Link, conn, addr) -> None:
    """One connection, whatever it turns out to be.

    Threaded per client so a Godot viewer and the game can be attached at the
    same time — the whole point of the viewer is to watch while someone plays.
    """
    conn.settimeout(0.05)
    c = Client(conn, addr)
    with link.lock:
        link.clients.append(c)
    buf = ""
    became_game = False
    try:
        while True:
            # anything queued for this client (viewers get pose; the game gets
            # commands) goes out first
            while True:
                try:
                    msg = c.q.get_nowait()
                except queue.Empty:
                    break
                conn.sendall((json.dumps(msg) + "\n").encode("utf-8"))
            if c.role == "game":
                while True:
                    try:
                        cmd = link.out.get_nowait()
                    except queue.Empty:
                        break
                    conn.sendall((json.dumps(cmd) + "\n").encode("utf-8"))

            try:
                chunk = conn.recv(65536)
            except socket.timeout:
                continue
            if not chunk:
                break
            buf += chunk.decode("utf-8", "replace")
            while "\n" in buf:
                line, buf = buf.split("\n", 1)
                line = line.strip()
                if not line:
                    continue
                try:
                    d = json.loads(line)
                except json.JSONDecodeError:
                    continue
                kind = d.get("k")

                if kind == "hello":
                    c.role = str(d.get("role", "viewer"))
                    link.note(f"{c.role} connected from {c.addr}")
                    # PRIME A VIEWER ONLY FROM A LIVE GAME. This used to hand
                    # every new viewer `link.pose` unconditionally so it "draws
                    # immediately" — which meant a viewer opened with no game
                    # attached drew a pose from a previous session and sat
                    # there, still, on a hall nobody was in. That is exactly the
                    # "no movement, wrong map" it was reported as: not a dead
                    # link, a CONFIDENTLY STALE one.
                    if c.role == "viewer" and link.pose and link.connected:
                        c.q.put_nowait(link.pose)
                    continue

                if kind == "pose":
                    if not became_game:
                        became_game = True
                        c.role = "game"
                        # A NEW GAME INHERITS NOTHING. Commands queued while
                        # nothing was attached used to sit in `out` and fire at
                        # whoever turned up next — measured: a goto sent to a
                        # game that had already quit teleported the NEXT launch
                        # on arrival, which reads as the map spawning you in the
                        # wrong place. The rate window goes for the same reason:
                        # stamps from the previous session made the first Hz
                        # reading meaningless (0.3).
                        dropped = 0
                        while True:
                            try:
                                link.out.get_nowait()
                                dropped += 1
                            except queue.Empty:
                                break
                        with link.lock:
                            link.connected = True
                            link.peer = c.addr
                            link._stamps.clear()
                        if dropped:
                            link.note(f"dropped {dropped} command(s) queued "
                                      "before this game connected")
                        link.note(f"game is {c.addr}")
                        link.publish({"k": "status", "connected": True})
                    link.on_pose(d)
                elif kind == "log":
                    link.note(f"game: {d.get('msg','')}")
                elif kind == "cmd" or d.get("cmd"):
                    # a viewer driving the game (click-to-teleport from Godot)
                    link.send(d)
                    link.note(f"{c.role} -> game: {json.dumps(d)[:100]}")
                else:
                    link.publish(d)
    except OSError:
        pass
    finally:
        conn.close()
        with link.lock:
            if c in link.clients:
                link.clients.remove(c)
            if became_game:
                link.connected = False
        if became_game:
            link.note("game disconnected")
            link.publish({"k": "status", "connected": False})
        else:
            link.note(f"{c.role} disconnected ({c.addr})")


# ─────────────────────────────────────────────────────────────────────────────
# adb — the cable
# ─────────────────────────────────────────────────────────────────────────────

def adb(*args: str, quiet: bool = False) -> tuple[int, str]:
    if not Path(ADB).exists():
        return 127, f"adb not found at {ADB}"
    try:
        p = subprocess.run([ADB, *args], capture_output=True, text=True, timeout=30)
        out = (p.stdout + p.stderr).strip()
        if not quiet and out:
            print(f"    adb {' '.join(args)}: {out}")
        return p.returncode, out
    except subprocess.TimeoutExpired:
        return 1, "timeout"


def device_present() -> bool:
    rc, out = adb("devices", quiet=True)
    if rc != 0:
        return False
    return any(l.strip().endswith("\tdevice") for l in out.splitlines()[1:])


def setup_reverse() -> bool:
    """Point the headset's localhost at ours. Idempotent."""
    if not device_present():
        print("[vr-link] no Quest attached — desktop-only mode "
              "(the desktop game can still connect over plain loopback).")
        return False
    rc, _ = adb("reverse", f"tcp:{GAME_PORT}", f"tcp:{GAME_PORT}")
    if rc == 0:
        print(f"[vr-link] adb reverse tcp:{GAME_PORT} — the headset's localhost is now ours")
        return True
    print("[vr-link] adb reverse failed; is the headset authorised for debugging?")
    return False


def arm_headset() -> bool:
    """Drop user://vr_link.on into the app's private dir so the link arms.

    Same run-as route push_map_to_quest.ps1 uses: adb push to /data/local/tmp
    (world-writable), then `run-as <pkg> cp` into files/, which is user://.
    Scoped storage makes the direct path impossible; this one works on the
    debuggable build and is already proven in this repo.
    """
    if not device_present():
        print("[vr-link] --arm needs a connected Quest.")
        return False
    tmp = "/data/local/tmp/_ada_vr_link.on"
    local = ROOT / "ada_run" / "_vr_link_on.tmp"
    local.parent.mkdir(parents=True, exist_ok=True)
    local.write_text("1", encoding="ascii")
    adb("push", str(local), tmp, quiet=True)
    rc, _ = adb("shell", f"run-as {PKG} cp {tmp} files/vr_link.on", quiet=True)
    adb("shell", f"rm -f {tmp}", quiet=True)
    local.unlink(missing_ok=True)
    if rc == 0:
        print("[vr-link] headset armed (user://vr_link.on) — restart the app to pick it up")
        return True
    print("[vr-link] could not arm the headset (run-as refused; is this the debuggable build?)")
    return False


def headset_doctor() -> int:
    """Why is the headset not showing up? Answer it with evidence, not memory.

    The one genuinely confusing failure in this whole feature is a headset that
    connects to nothing because the APK it is running predates the autoload —
    push_map_to_quest.ps1 ships map LAYOUT only, so a build can be hours old in
    code while its maps are current. That is invisible from the headset and
    invisible from here unless something checks.
    """
    print("\n  VR LINK — headset check\n  " + "-" * 46)
    ok = True

    if not Path(ADB).exists():
        print("  adb            NOT FOUND at %s" % ADB)
        return 1
    if not device_present():
        print("  device         none attached")
        print("\n  Plug the Quest in over USB and accept the debugging prompt.")
        return 1
    print("  device         attached")

    rc, out = adb("shell", f"dumpsys package {PKG}", quiet=True)
    if rc != 0 or "versionName" not in out:
        print("  app            NOT INSTALLED (%s)" % PKG)
        return 1
    installed = ""
    debuggable = False
    for line in out.splitlines():
        s = line.strip()
        if s.startswith("lastUpdateTime="):
            installed = s.split("=", 1)[1].strip()
        if "DEBUGGABLE" in s:
            debuggable = True
    print("  app            installed %s%s" % (installed,
          "  (debuggable)" if debuggable else "  (NOT debuggable — --arm will fail)"))

    # Is the build older than the code it would need? git first, mtime as a
    # fallback so this still answers in a dirty tree.
    src = ROOT / "commons" / "bridge" / "vr_link.gd"
    code_when = ""
    try:
        p = subprocess.run(["git", "log", "-1", "--format=%ai", "--", str(src)],
                           cwd=str(ROOT), capture_output=True, text=True, timeout=10)
        code_when = p.stdout.strip()
    except Exception:
        pass
    if not code_when and src.exists():
        code_when = time.strftime("%Y-%m-%d %H:%M:%S",
                                  time.localtime(src.stat().st_mtime))
    if installed and code_when:
        stale = installed[:19] < code_when[:19]
        print("  vr_link.gd     %s" % code_when[:19])
        if stale:
            ok = False
            print("  BUILD          STALE — the headset is running code from before VR Link.")
            print("                 push_map_to_quest.ps1 ships map LAYOUT only; a new")
            print("                 autoload needs a full export + install.")
        else:
            print("  BUILD          newer than vr_link.gd — the autoload should be present")

    rc, out = adb("shell", f"run-as {PKG} ls files/vr_link.on", quiet=True)
    armed = rc == 0 and "vr_link.on" in out and "No such file" not in out
    print("  armed          %s" % ("yes (user://vr_link.on)" if armed
                                   else "no — run: python tools/vr_link.py --arm"))
    if not armed:
        ok = False

    rc, out = adb("reverse", "--list", quiet=True)
    tunnelled = f"tcp:{GAME_PORT}" in out
    print("  usb tunnel     %s" % ("tcp:%d reversed" % GAME_PORT if tunnelled
                                   else "not set (vr_link.py sets it on start)"))

    print("  " + "-" * 46)
    if ok:
        print("  Looks ready. Start the app on the headset; it dials in on boot.\n")
    else:
        print("  Next: export + install a fresh APK, then --arm, then launch the app.")
        print("    godot --headless --path . --export-debug \"adaresearchonexy\" <out.apk>")
        print("    adb install -r <out.apk>")
        print("    python tools/vr_link.py --arm\n")
    return 0 if ok else 1


def disarm_headset() -> None:
    if device_present():
        adb("shell", f"run-as {PKG} rm -f files/vr_link.on", quiet=True)
        print("[vr-link] headset disarmed")


# ─────────────────────────────────────────────────────────────────────────────
# Maps — so the views can draw the room the player is standing in
# ─────────────────────────────────────────────────────────────────────────────

def map_path(name: str) -> Path | None:
    if not name:
        return None
    p = ROOT / "commons" / "maps" / name / "map_data.json"
    return p if p.exists() else None


def load_map(name: str) -> dict | None:
    p = map_path(name)
    if p is None:
        return None
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return None


def cell_size(map_data: dict) -> tuple[float, float]:
    s = map_data.get("settings", {}) if isinstance(map_data, dict) else {}
    return float(s.get("cube_size", 1.0)), float(s.get("gutter", 0.0))


def cell_to_world(row: int, col: int, cube: float, gutter: float,
                  centre: bool = False) -> list[float]:
    """Grid cell -> world metres.

    THIS PROJECT HAS SIX RIVAL SPACE VOCABULARIES and two of them disagree here.
    GridCommon.grid_to_world_position is `Vector3(x,y,z) * (cube+gutter)` — the
    cell's CORNER. ArtifactPlacementEditor2D uses `(x+0.5)*CELL_SIZE` — the cell's
    CENTRE. Both are live code.

    The default follows GridCommon, because that is what the running GridSystem
    uses to place the cubes the player actually walks on. It is a choice, not a
    measurement, so `--calibrate` exists: it reads the LIVE player position from
    the headset and reports which rule reproduces it. Do not trust this line
    until that has been run against a real map.
    """
    total = cube + gutter
    off = 0.5 if centre else 0.0
    return [(col + off) * total, 0.0, (row + off) * total]


# ─────────────────────────────────────────────────────────────────────────────
# The python walker, given a body
# ─────────────────────────────────────────────────────────────────────────────

def walker_path(map_name: str, seed: int = 0) -> tuple[list, list]:
    """Run the humanoid_walker on a real map; return (world_path, decisions).

    place.py's humanoid_walker decides placements by WALKING the room, and until
    now that walk has only ever been an SVG (tools/placement_trajectory.py). The
    same trace, converted to metres, is a path something can walk while you
    stand in the room.
    """
    sys.path.insert(0, str(ROOT / "tools"))
    from placement_research import strategy_humanoid_walker  # noqa: E402
    from place_artifacts import existing_placements, room_from_map  # noqa: E402

    md = load_map(map_name)
    if md is None:
        raise SystemExit(f"no map_data.json for '{map_name}'")
    room, _, _ = room_from_map(md)
    placements = existing_placements(md, room)
    artifacts = [p.artifact for p in placements]
    if not artifacts:
        raise SystemExit(f"'{map_name}' has no artifacts for the walker to place")

    trace: list = []
    strategy_humanoid_walker(room, list(artifacts), random.Random(seed), trace=trace)

    cube, gutter = cell_size(md)
    path: list = []
    decisions: list = []
    for action, pos, art, score in trace:
        if pos is None:
            continue
        r, c = int(pos[0]), int(pos[1])
        w = cell_to_world(r, c, cube, gutter)
        if action in ("start", "move"):
            path.append(w)
        decisions.append({"action": action, "cell": [r, c], "world": w,
                          "artifact": art, "score": score})
    return path, decisions


# ─────────────────────────────────────────────────────────────────────────────
# The web side — three views, one page
# ─────────────────────────────────────────────────────────────────────────────

VIEW = ROOT / "tools" / "vr_link_view.html"


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a) -> None:  # quiet
        pass

    def _send(self, code: int, body: bytes, ctype: str) -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _json(self, obj, code: int = 200) -> None:
        self._send(code, json.dumps(obj).encode("utf-8"), "application/json")

    def do_GET(self) -> None:
        u = urlparse(self.path)
        q = parse_qs(u.query)

        if u.path in ("/", "/index.html"):
            if not VIEW.exists():
                self._send(500, b"vr_link_view.html is missing", "text/plain")
                return
            self._send(200, VIEW.read_bytes(), "text/html; charset=utf-8")
            return

        if u.path == "/state":
            with LINK.lock:
                age = (time.time() - LINK.last_pose_at) if LINK.last_pose_at else None
                self._json({"connected": LINK.connected, "peer": LINK.peer,
                            "hz": round(LINK.rate, 1), "pose": LINK.pose,
                            # HOW OLD IS THAT POSE. Without this every consumer
                            # has to guess, and they all guessed "current".
                            "pose_age": round(age, 2) if age is not None else None,
                            "log": list(LINK.log)[-60:]})
            return

        if u.path == "/map":
            name = (q.get("name") or [""])[0]
            md = load_map(name)
            if md is None:
                self._json({"error": f"no map '{name}'"}, 404)
                return
            cube, gutter = cell_size(md)
            self._json({
                "name": name,
                "cube": cube, "gutter": gutter,
                "structure": md.get("layers", {}).get("structure", []),
                "utilities": md.get("layers", {}).get("utilities", []),
                "interactables": md.get("layers", {}).get("interactables", []),
            })
            return

        if u.path == "/events":
            self.sse()
            return

        self._send(404, b"not found", "text/plain")

    def do_POST(self) -> None:
        u = urlparse(self.path)
        n = int(self.headers.get("Content-Length", 0))
        raw = self.rfile.read(n) if n else b"{}"
        try:
            body = json.loads(raw.decode("utf-8"))
        except json.JSONDecodeError:
            self._json({"error": "bad json"}, 400)
            return

        if u.path == "/cmd":
            LINK.send(body)
            LINK.note(f"-> game: {json.dumps(body)[:120]}")
            self._json({"ok": True})
            return

        if u.path == "/walker":
            name = body.get("map") or (LINK.pose.get("map") if LINK.pose else "")
            try:
                path, decisions = walker_path(name, int(body.get("seed", 0)))
            except SystemExit as e:
                self._json({"error": str(e)}, 400)
                return
            LINK.send({"cmd": "walker", "path": path,
                       "speed": float(body.get("speed", 1.4)),
                       "loop": bool(body.get("loop", True))})
            LINK.note(f"walker on '{name}': {len(path)} steps, {len(decisions)} decisions")
            self._json({"ok": True, "steps": len(path), "decisions": decisions})
            return

        self._json({"error": "unknown endpoint"}, 404)

    def sse(self) -> None:
        """Server-sent events. One-way push is all the views need, and the reply
        path is a plain POST — which is why there is no WebSocket handshake or
        frame codec in this file."""
        q: queue.Queue = queue.Queue(maxsize=200)
        with LINK.lock:
            LINK.subs.append(q)
            first = {"k": "status", "connected": LINK.connected,
                     "hz": round(LINK.rate, 1)}
        try:
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "keep-alive")
            self.end_headers()
            self.wfile.write(b": open\n\n")
            self.wfile.write(f"data: {json.dumps(first)}\n\n".encode("utf-8"))
            self.wfile.flush()
            while True:
                try:
                    ev = q.get(timeout=10.0)
                except queue.Empty:
                    self.wfile.write(b": ping\n\n")   # keep the proxy-less socket warm
                    self.wfile.flush()
                    continue
                self.wfile.write(f"data: {json.dumps(ev)}\n\n".encode("utf-8"))
                self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError, OSError):
            pass
        finally:
            with LINK.lock:
                if q in LINK.subs:
                    LINK.subs.remove(q)


# ─────────────────────────────────────────────────────────────────────────────
# Calibration — measure the cell-to-world rule instead of believing it
# ─────────────────────────────────────────────────────────────────────────────

def calibrate(timeout: float = 30.0) -> int:
    """Ask the live game where it is, and check that against both conventions.

    A rule that has never been compared against a running game is a guess with
    a comment on it. This turns cell_to_world into a measurement.
    """
    print(f"[vr-link] waiting up to {timeout:.0f}s for a pose from the game...")
    t0 = time.time()
    while time.time() - t0 < timeout:
        with LINK.lock:
            p = dict(LINK.pose)
        if p.get("pos") and p.get("map"):
            break
        time.sleep(0.25)
    else:
        print("[vr-link] no pose arrived. Is the game running and armed?")
        return 1

    name = p["map"]
    md = load_map(name)
    if md is None:
        print(f"[vr-link] the game is in '{name}', which has no map_data.json here.")
        print("          (a museum hall or a generated room — stand in an authored map)")
        return 1
    cube, gutter = cell_size(md)
    x, _y, z = p["pos"]
    total = cube + gutter
    col_corner, row_corner = x / total, z / total
    print(f"\n  map            {name}   cube={cube} gutter={gutter}")
    print(f"  player world   x={x:.3f}  z={z:.3f}")
    print(f"  as CORNER rule col={col_corner:.3f}  row={row_corner:.3f}")
    print(f"  as CENTRE rule col={col_corner - 0.5:.3f}  row={row_corner - 0.5:.3f}")
    d_corner = abs(col_corner - round(col_corner)) + abs(row_corner - round(row_corner))
    d_centre = abs(col_corner - 0.5 - round(col_corner - 0.5)) + \
               abs(row_corner - 0.5 - round(row_corner - 0.5))
    print(f"\n  distance to a whole cell: corner {d_corner:.3f} | centre {d_centre:.3f}")
    print("  NOTE: a player standing anywhere lands between cells, so ONE sample")
    print("  proves nothing. Stand deliberately on a spawn or teleporter cell and")
    print("  compare against that cell's index in map_data.json.\n")
    return 0


# ─────────────────────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--arm", action="store_true",
                    help="write user://vr_link.on to the headset (needs an app restart)")
    ap.add_argument("--disarm", action="store_true", help="remove it again")
    ap.add_argument("--headset", action="store_true",
                    help="why is the headset not showing up? checks build age, arming, tunnel")
    ap.add_argument("--walker", metavar="MAP",
                    help="send the humanoid_walker's path into VR on startup")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--speed", type=float, default=1.4, help="walker m/s")
    ap.add_argument("--calibrate", action="store_true",
                    help="check the cell-to-world rule against the live player")
    ap.add_argument("--no-adb", action="store_true", help="skip adb entirely")
    args = ap.parse_args()

    if args.headset:
        return headset_doctor()

    if args.disarm:
        disarm_headset()
        return 0

    if not args.no_adb:
        setup_reverse()
    if args.arm:
        # ARM AND STOP. This used to arm and then fall through into the serve
        # loop, so `--arm` looked like it had hung — you arm a headset once,
        # ever, and almost never at the moment you want a server.
        ok_arm = arm_headset()
        print("\n  Now RESTART the app on the headset — the link is read at boot.")
        print("  Then: python tools/vr_link.py\n")
        return 0 if ok_arm else 1

    threading.Thread(target=game_server, args=(LINK,), daemon=True).start()

    httpd = ThreadingHTTPServer(("127.0.0.1", WEB_PORT), Handler)
    httpd.daemon_threads = True
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    print(f"[vr-link] views on http://localhost:{WEB_PORT}  (3D · top-down · text)")

    if args.calibrate:
        return calibrate()

    if args.walker:
        print(f"[vr-link] waiting for the game before sending the walker...")
        t0 = time.time()
        while time.time() - t0 < 60 and not LINK.connected:
            time.sleep(0.25)
        path, decisions = walker_path(args.walker, args.seed)
        LINK.send({"cmd": "walker", "path": path, "speed": args.speed, "loop": True})
        placed = sum(1 for d in decisions if d["action"] == "place")
        LINK.note(f"walker on '{args.walker}': {len(path)} steps, {placed} placements")

    print("[vr-link] ctrl-c to stop.")
    try:
        while True:
            time.sleep(1.0)
    except KeyboardInterrupt:
        print("\n[vr-link] bye")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
