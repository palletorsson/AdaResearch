#!/usr/bin/env python3
"""Capture scene-catalog images for every registry artifact that is missing one.

Registry-driven and resumable: computes the missing set live (map_ready artifacts with a scene
file but no ada_encyclopedia/public/scene-catalog/<lookup>.png), captures each via
capture_artifact_config.gd, and skips any that already exist — so it can be re-run / resumed.

  python tools/capture_missing_catalog.py [--size=512] [--limit=N] [--all]

--all also captures non-map_ready artifacts that have a scene. Default = map_ready only.
"""
import json, glob, os, subprocess, sys, time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT = r"C:\Users\palle\Desktop\Godot_v4.6-stable_win64.exe"
CAT = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public", "scene-catalog"))
TMP = os.path.join(os.environ.get("TEMP", "/tmp"), "catalog_fill")
os.makedirs(TMP, exist_ok=True)

size = 512
limit = None
want_all = False
cap_timeout = 45
for a in sys.argv[1:]:
    if a.startswith("--size="): size = int(a.split("=", 1)[1])
    elif a.startswith("--limit="): limit = int(a.split("=", 1)[1])
    elif a.startswith("--timeout="): cap_timeout = int(a.split("=", 1)[1])
    elif a == "--all": want_all = True


def missing():
    out = []
    seen = set()
    for p in sorted(glob.glob(os.path.join(ROOT, "commons", "artifacts", "registry", "*.json"))):
        try:
            d = json.load(open(p, encoding="utf-8"))
        except Exception:
            continue
        for k, v in (d.get("artifacts", {}) or {}).items():
            if not isinstance(v, dict):
                continue
            lk = v.get("lookup_name", k)
            scene = v.get("scene", "")
            if lk in seen or not scene:
                continue
            if not want_all and not v.get("map_ready"):
                continue
            if os.path.exists(os.path.join(CAT, lk + ".png")):
                continue
            seen.add(lk)
            out.append((lk, scene))
    return sorted(out)


def capture(lk, scene):
    cfg = os.path.join(TMP, lk + ".json")
    open(cfg, "w", encoding="utf-8").write(json.dumps({"scene": scene, "dna": {}}))
    out = os.path.join(CAT, lk + ".png")
    cmd = [GODOT, "--path", ROOT, "--xr-mode", "off", "--no-window",
           "--script", "res://commons/testing/capture_artifact_config.gd",
           "--", f"--config={cfg}", f"--out={out}", f"--size={size}"]
    try:
        subprocess.run(cmd, capture_output=True, text=True, timeout=cap_timeout, cwd=ROOT)
    except subprocess.TimeoutExpired:
        subprocess.run(["taskkill", "/f", "/im", "Godot_v4.6-stable_win64.exe"], capture_output=True)
        time.sleep(1)
        return "timeout"
    if os.path.exists(out) and os.path.getsize(out) > 3000:
        return "ok"
    return "fail"


def main():
    todo = missing()
    if limit:
        todo = todo[:limit]
    print(f"missing scene-catalog images to capture: {len(todo)}", flush=True)
    res = {"ok": 0, "fail": 0, "timeout": 0}
    fails = []
    for i, (lk, scene) in enumerate(todo):
        st = capture(lk, scene)
        res[st] = res.get(st, 0) + 1
        if st != "ok":
            fails.append(lk)
        if (i + 1) % 10 == 0 or i + 1 == len(todo):
            print(f"  [{i+1}/{len(todo)}] ok={res['ok']} fail={res['fail']} timeout={res['timeout']}  last={lk}:{st}", flush=True)
    print(f"DONE: {res['ok']} ok, {res['fail']} fail, {res['timeout']} timeout of {len(todo)}", flush=True)
    if fails:
        print("failed:", ", ".join(fails[:40]) + (" ..." if len(fails) > 40 else ""), flush=True)


if __name__ == "__main__":
    main()
