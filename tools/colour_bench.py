"""colour_bench.py — the server behind /spatial-lab's colour family.

Palle, 2026-10-27: "we should use a system like this for fast color test" and "one lab".
The page posts a request (a recipe from commons/modular/lab_colour.json + parameters); this
server answers it with a native Godot picture on the Mobile renderer (the Quest's), plus a
pixel oracle where the recipe declares one. It keeps ONE Godot process warm
(commons/testing/colour_bench.gd) in a staged runtime with its own user://, so a request costs
about a second instead of a 10-25 s cold boot, and it takes tools/void_native_slot.py for each
render so it never draws alongside another native run.

This file is the single owner of the cache key: hash of (recipe id, parameters, views) and of
the files the picture depends on (the recipe's watched scripts, the bench, the oracle's probe,
lab_colour.json). Change any of them and the next request renders fresh.

  python tools/colour_bench.py serve                      # normally started by the route
  python tools/colour_bench.py request albers_glass medium=cubes palette_seed=7   # CLI test
  python tools/colour_bench.py stop

Files, all under ada_run/colour-lab/ (ignored by git):
  requests/<job>.json   written by the route or `request`
  jobs/<job>.json       status: queued | waiting_slot | rendering | complete | failed
  cache/<key>.json      a finished receipt; out/<key>-<view>.png its pictures
  bench/inbox, outbox   the warm Godot's mailbox
"""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import time
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from void_native_slot import acquire_native_slot  # noqa: E402
from void_trial_runtime import stage_runtime  # noqa: E402

GODOT = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
LAB = ROOT / "ada_run" / "colour-lab"
REQ, JOBS, CACHE, OUT = LAB / "requests", LAB / "jobs", LAB / "cache", LAB / "out"
INBOX, OUTBOX = LAB / "bench" / "inbox", LAB / "bench" / "outbox"
SPEC = ROOT / "commons" / "modular" / "lab_colour.json"
BENCH_GD = "commons/testing/colour_bench.gd"
ORACLE_GD = "commons/testing/probe_albers_glass_render.gd"
IDLE_S = 600.0
RENDER_TIMEOUT_S = 120.0
BOOT_TIMEOUT_S = 90.0


def now() -> float:
    return time.time()


def write(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(value, indent=1), encoding="utf-8")
    os.replace(tmp, path)


def read(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def spec() -> dict:
    return read(SPEC)


def validate(s: dict, recipe_id: str, params: dict) -> tuple[dict, dict]:
    recipe = next((r for r in s["recipes"] if r["id"] == recipe_id), None)
    if recipe is None:
        raise ValueError(f"unknown recipe {recipe_id!r}")
    clean = {k: v["default"] for k, v in recipe["parameters"].items()}
    for k, v in params.items():
        p = recipe["parameters"].get(k)
        if p is None:
            raise ValueError(f"unknown parameter {k!r}")
        if p["type"] == "enum":
            if v not in p["values"]:
                raise ValueError(f"{k} must be one of {p['values']}")
        elif p["type"] == "int":
            v = int(v)
            if not p["min"] <= v <= p["max"]:
                raise ValueError(f"{k} out of range")
        elif p["type"] == "float":
            v = round(float(v), 4)
            if not p["min"] <= v <= p["max"]:
                raise ValueError(f"{k} out of range")
        elif p["type"] == "json":
            # a modular expression: data the builder reads, never code; canonical, so one
            # expression is one cache key however the browser spaced it
            if not isinstance(v, str) or len(v) > 120000:
                raise ValueError(f"{k} must be a JSON string under 120000 characters")
            parsed = json.loads(v)
            if not isinstance(parsed, dict):
                raise ValueError(f"{k} must be a JSON object")
            v = json.dumps(parsed, sort_keys=True, separators=(",", ":"))
        clean[k] = v
    return recipe, clean


def fingerprint(recipe: dict) -> str:
    h = hashlib.sha256()
    for rel in [*recipe.get("watch", []), BENCH_GD, ORACLE_GD, "commons/modular/lab_colour.json"]:
        p = ROOT / rel
        h.update(rel.encode())
        h.update(p.read_bytes() if p.exists() else b"missing")
    return h.hexdigest()


def cache_key(recipe: dict, params: dict, views: list) -> str:
    body = json.dumps({"recipe": recipe["id"], "params": params, "views": views}, sort_keys=True)
    return hashlib.sha256((body + fingerprint(recipe)).encode()).hexdigest()[:24]


def alive(pid: int) -> bool:
    if pid <= 0:
        return False
    if os.name == "nt":
        out = subprocess.run(["tasklist", "/FI", f"PID eq {pid}", "/NH"], capture_output=True, text=True)
        return str(pid) in out.stdout
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


# --------------------------------------------------------------------------- the warm bench

class Bench:
    def __init__(self) -> None:
        self.proc: subprocess.Popen | None = None
        self.stage: Path | None = None
        self.prints: dict[str, str] = {}

    def running(self) -> bool:
        return self.proc is not None and self.proc.poll() is None

    def stale(self, recipe: dict) -> bool:
        """A warm Godot keeps the scripts it loaded: restart it when one changed."""
        files = [*recipe.get("watch", []), BENCH_GD, ORACLE_GD]
        for rel in files:
            p = ROOT / rel
            mt = str(p.stat().st_mtime_ns) if p.exists() else "missing"
            if rel in self.prints and self.prints[rel] != mt:
                return True
        return False

    def start(self, recipe: dict) -> float:
        t0 = now()
        self.stop()
        for d in (INBOX, OUTBOX):
            d.mkdir(parents=True, exist_ok=True)
            for f in d.iterdir():
                f.unlink()
        if self.stage is None:
            self.stage = stage_runtime()
        log = (LAB / "bench" / "godot.log").open("w", encoding="utf-8")
        cmd = [GODOT, "--path", str(self.stage), "--xr-mode", "off", "--rendering-method", "mobile",
               "--resolution", "640x400", "--position", "40,40", "--script", f"res://{BENCH_GD}", "--",
               "--no-bridges", f"--inbox={INBOX}", f"--outbox={OUTBOX}", f"--idle={IDLE_S + 60}"]
        self.proc = subprocess.Popen(cmd, cwd=str(self.stage), stdout=log, stderr=subprocess.STDOUT,
                                     creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        ready = OUTBOX / "_ready.json"
        while not ready.exists():
            if not self.running():
                raise RuntimeError("the bench exited during boot: see ada_run/colour-lab/bench/godot.log")
            if now() - t0 > BOOT_TIMEOUT_S:
                self.stop()
                raise TimeoutError("the bench did not report ready in time")
            time.sleep(0.1)
        self.prints = {}
        for rel in [*recipe.get("watch", []), BENCH_GD, ORACLE_GD]:
            p = ROOT / rel
            self.prints[rel] = str(p.stat().st_mtime_ns) if p.exists() else "missing"
        return now() - t0

    def remember(self, recipe: dict) -> None:
        for rel in recipe.get("watch", []):
            p = ROOT / rel
            self.prints.setdefault(rel, str(p.stat().st_mtime_ns) if p.exists() else "missing")

    def render(self, request: dict) -> dict:
        target = OUTBOX / f"{request['id']}.json"
        write(INBOX / f"{request['id']}.json", request)
        t0 = now()
        while not target.exists():
            if not self.running():
                raise RuntimeError("the bench died while rendering: see ada_run/colour-lab/bench/godot.log")
            if now() - t0 > RENDER_TIMEOUT_S:
                raise TimeoutError("the bench did not answer in time")
            time.sleep(0.03)
        result = read(target)
        target.unlink()
        return result

    def stop(self) -> None:
        if self.running():
            INBOX.mkdir(parents=True, exist_ok=True)
            (INBOX / "quit").write_text("quit")
            try:
                self.proc.wait(timeout=10)
            except subprocess.TimeoutExpired:
                self.proc.kill()
        self.proc = None


# --------------------------------------------------------------------------- the server

def handle(bench: Bench, req_path: Path) -> None:
    job = req_path.stem
    request = read(req_path)
    req_path.unlink()
    status_path = JOBS / f"{job}.json"
    t0 = now()
    status = {"status": "queued", "job": job, "submitted": request.get("submitted", t0)}
    try:
        s = spec()
        recipe, params = validate(s, request["recipe"], request.get("params", {}))
        views = request.get("views") or recipe.get("views", ["front"])
        key = cache_key(recipe, params, views)
        status.update({"recipe": recipe["id"], "params": params, "key": key})
        cached = CACHE / f"{key}.json"
        if cached.exists():
            receipt = read(cached)
            receipt["cache_hit"] = True
            receipt["timing"]["server_seconds"] = round(now() - t0, 3)
            write(status_path, {**status, "status": "complete", "receipt": receipt})
            return
        status["status"] = "waiting_slot"
        write(status_path, status)
        slot_t = now()
        slot = acquire_native_slot("colour lab " + recipe["id"], timeout=300)
        try:
            slot_wait = now() - slot_t
            status["status"] = "rendering"
            write(status_path, status)
            boot = 0.0
            cold = False
            if not bench.running() or bench.stale(recipe):
                boot = bench.start(recipe)
                cold = True
            bench.remember(recipe)
            t_r = now()
            result = bench.render({"id": job, "recipe": recipe, "params": params, "views": views,
                                   "out_dir": str(OUT), "prefix": key,
                                   "tolerance_255": s.get("tolerance_255", 3.0)})
            render_s = now() - t_r
        finally:
            slot.close()
        if not result.get("ok"):
            raise RuntimeError(result.get("error") or "the bench reported failure")
        receipt = {"key": key, "recipe": recipe["id"], "label": recipe["label"], "params": params,
                   "views": result["views"], "oracle": result.get("oracle"),
                   "readback": result.get("readback"), "renderer": result.get("renderer"),
                   "adapter": result.get("adapter"), "note": recipe.get("note"),
                   "rendered_at": time.strftime("%Y-%m-%d %H:%M:%S"), "cache_hit": False,
                   "timing": {"slot_wait_seconds": round(slot_wait, 3), "cold_boot_seconds": round(boot, 3),
                              "cold": cold, "render_seconds": round(render_s, 3),
                              "bench": result.get("timing"),
                              "server_seconds": round(now() - t0, 3)}}
        write(cached, receipt)
        write(status_path, {**status, "status": "complete", "receipt": receipt})
    except Exception as e:  # noqa: BLE001 — every failure is reported to the page
        write(status_path, {**status, "status": "failed", "error": f"{type(e).__name__}: {e}"})


def serve() -> int:
    for d in (REQ, JOBS, CACHE, OUT):
        d.mkdir(parents=True, exist_ok=True)
    lock_handle = (LAB / "server.lock").open("a+b")
    try:
        if os.name == "nt":
            import msvcrt
            if (LAB / "server.lock").stat().st_size == 0:
                lock_handle.write(b"0")
                lock_handle.flush()
            lock_handle.seek(0)
            msvcrt.locking(lock_handle.fileno(), msvcrt.LK_NBLCK, 1)
    except OSError:
        print("colour_bench: a server is already running")
        return 0
    write(LAB / "server.json", {"pid": os.getpid(), "started": now()})
    bench = Bench()
    last = now()
    print(f"colour_bench: serving {REQ}", flush=True)
    try:
        while True:
            if (LAB / "stop").exists():
                (LAB / "stop").unlink()
                break
            pending = sorted(REQ.glob("*.json"), key=lambda p: p.stat().st_mtime)
            if pending:
                # only the newest request matters when sliders move fast: older ones are
                # superseded, answered as such, and not rendered
                for old in pending[:-1]:
                    write(JOBS / f"{old.stem}.json", {"status": "superseded", "job": old.stem})
                    old.unlink()
                handle(bench, pending[-1])
                last = now()
            elif now() - last > IDLE_S:
                print("colour_bench: idle, stopping", flush=True)
                break
            time.sleep(0.05)
    finally:
        bench.stop()
        (LAB / "server.json").unlink(missing_ok=True)
    return 0


def ensure_server() -> None:
    info = LAB / "server.json"
    if info.exists() and alive(int(read(info).get("pid", 0))):
        return
    LAB.mkdir(parents=True, exist_ok=True)
    flags = (subprocess.CREATE_NO_WINDOW | subprocess.DETACHED_PROCESS) if os.name == "nt" else 0
    subprocess.Popen([sys.executable, str(Path(__file__).resolve()), "serve"], cwd=str(ROOT),
                     stdout=(LAB / "server.log").open("a", encoding="utf-8"), stderr=subprocess.STDOUT,
                     creationflags=flags)


def request_cli(recipe_id: str, pairs: list[str]) -> int:
    params = {}
    for pair in pairs:
        k, _, v = pair.partition("=")
        params[k] = v
    s = spec()
    recipe = next(r for r in s["recipes"] if r["id"] == recipe_id)
    for k, v in list(params.items()):
        t = recipe["parameters"][k]["type"]
        params[k] = int(v) if t == "int" else float(v) if t == "float" else v
    job = uuid.uuid4().hex
    REQ.mkdir(parents=True, exist_ok=True)
    write(REQ / f"{job}.json", {"recipe": recipe_id, "params": params, "submitted": now()})
    ensure_server()
    t0 = now()
    while True:
        p = JOBS / f"{job}.json"
        if p.exists():
            st = read(p)
            if st["status"] in ("complete", "failed", "superseded"):
                print(json.dumps(st, indent=1)[:4000])
                print(f"round trip {now() - t0:.2f} s")
                return 0 if st["status"] == "complete" else 1
        if now() - t0 > 400:
            print("timed out")
            return 1
        time.sleep(0.1)


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    cmd = sys.argv[1]
    if cmd == "serve":
        return serve()
    if cmd == "request":
        return request_cli(sys.argv[2], sys.argv[3:])
    if cmd == "stop":
        LAB.mkdir(parents=True, exist_ok=True)
        (LAB / "stop").write_text("stop")
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
