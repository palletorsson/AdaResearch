"""live_update_oscillate.py — move one Void artifact back and forth, live, every N seconds.

Palle, 2026-10-22: "start the bridge so I can edit live oscillate every 5 sec".
Each tick saves rooms.json through the editor's own route (POST /api/void-layout,
revision-checked), so the running desktop and headset get the revision from
tools/vr_link.py exactly as an editor save would. The last tick puts the
artifact back where it started.

  python tools/live_update_oscillate.py [--floor 10] [--dx 1.5] [--every 5] [--minutes 5] [--id <artifact id>]
"""
from __future__ import annotations

import argparse
import json
import os
import time
import urllib.request

ENC = os.environ.get("ADA_ENC_URL", "http://localhost:3003")
BRIDGE = os.environ.get("ADA_VR_LINK_URL", "http://127.0.0.1:8772")


def http(method: str, url: str, body: dict | None = None, timeout: float = 60.0) -> dict:
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method,
                                 headers={"content-type": "application/json"} if data else {})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8") or "{}")


def acks(rid: str) -> str:
    try:
        rows = http("GET", f"{BRIDGE}/revisions?id={rid}", timeout=3).get("rows", [])
    except Exception:
        return "bridge?"
    out = {}
    for r in rows:
        if r.get("k") == "update_ack":
            out[r.get("name") or r.get("device")] = f"{r.get('status')}{(' ' + str(r.get('mode'))) if r.get('mode') else ''}"
    return " · ".join(f"{k}: {v}" for k, v in out.items()) or "no ack yet"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--floor", type=int, default=10)
    ap.add_argument("--id", default="", help="artifact id on that floor (default: the floor's last artifact)")
    ap.add_argument("--dx", type=float, default=1.5, help="metres along x to swing")
    ap.add_argument("--every", type=float, default=5.0, help="seconds between moves")
    ap.add_argument("--minutes", type=float, default=5.0, help="how long; ends at the start position")
    args = ap.parse_args()

    layout = http("GET", f"{ENC}/api/void-layout")
    rooms, rev = layout["rooms"], layout["revision"]
    floor = rooms["floors"][args.floor]
    items = floor.get("artifacts", [])
    item = next((a for a in items if a.get("id") == args.id), None) if args.id else (items[-1] if items else None)
    if item is None:
        print("no such artifact on floor", args.floor)
        return 1
    home = list(item.get("position", [0, 0]))
    away = [home[0] + args.dx, home[1]]
    print(f"oscillating {item['id']} ({item.get('artifact')}) on floor {args.floor}: {home} <-> {away}, every {args.every}s for {args.minutes} min")
    ticks = max(2, int(args.minutes * 60 / args.every))
    if ticks % 2:
        ticks += 1   # even: end at home
    t_end = time.time()
    for i in range(ticks):
        item["position"] = away if i % 2 == 0 else home
        t0 = time.time()
        try:
            r = http("POST", f"{ENC}/api/void-layout", {"rooms": rooms, "revision": rev})
        except Exception as e:  # noqa: BLE001
            print(f"[{time.strftime('%H:%M:%S')}] save failed: {e} — reloading the layout")
            layout = http("GET", f"{ENC}/api/void-layout")
            rooms, rev = layout["rooms"], layout["revision"]
            floor = rooms["floors"][args.floor]
            item = next(a for a in floor["artifacts"] if a["id"] == item["id"])
            continue
        rev = r.get("revision", rev)
        live = [l for l in (r.get("live") or []) if l.get("floor") == args.floor]
        rid = live[0]["revision_id"] if live else ""
        time.sleep(1.5)
        print(f"[{time.strftime('%H:%M:%S')}] -> {item['position']}  {rid[-20:] if rid else 'not live'}  {acks(rid) if rid else (live[0].get('error') if live else '')}")
        wait = args.every - (time.time() - t0)
        if wait > 0:
            time.sleep(wait)
    print("done — back at", home)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
