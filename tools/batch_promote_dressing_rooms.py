#!/usr/bin/env python3
"""
Batch capture + promote dressing rooms.

For a list of artifacts, hit the encyclopedia's /api/dressing-room
endpoint to render mirrors via Godot, then promote the top shot to
the canonical poster slot at public/captures/artifacts/<lookup>/front.png.

Run:
    python tools/batch_promote_dressing_rooms.py --list pompeii_mosaic_floor persian_rug
    python tools/batch_promote_dressing_rooms.py --recently-flattened
    python tools/batch_promote_dressing_rooms.py --all-flattened   # uses .bak presence as signal

Each artifact takes ~10s. The script reports per-artifact pass/fail
and skips ones that fail to capture or promote.
"""
from __future__ import annotations
import argparse
import json
import sys
import time
from pathlib import Path
from urllib import request, error

REPO = Path(__file__).resolve().parents[1]
ROOMS_DIR = REPO / "commons" / "artifacts" / "dressing_rooms"
ENCYC = "http://localhost:3003"


def post_json(url: str, body: dict, timeout: int = 120) -> dict | None:
    data = json.dumps(body).encode("utf-8")
    req = request.Request(url, data=data, headers={"Content-Type": "application/json"}, method="POST")
    try:
        with request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except error.HTTPError as e:
        try:
            return json.loads(e.read().decode("utf-8"))
        except Exception:
            return {"error": f"HTTP {e.code}"}
    except Exception as e:
        return {"error": str(e)}


def put_json(url: str, body: dict, timeout: int = 30) -> dict | None:
    data = json.dumps(body).encode("utf-8")
    req = request.Request(url, data=data, headers={"Content-Type": "application/json"}, method="PUT")
    try:
        with request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except error.HTTPError as e:
        try:
            return json.loads(e.read().decode("utf-8"))
        except Exception:
            return {"error": f"HTTP {e.code}"}
    except Exception as e:
        return {"error": str(e)}


def list_recently_flattened() -> list[str]:
    """Names of dressing rooms with a .bak alongside (recent batch-flatten signal)."""
    out: list[str] = []
    for bak in sorted(ROOMS_DIR.glob("*.json.bak")):
        out.append(bak.stem.removesuffix(".json"))
    return out


def capture_and_promote(artifact: str, role: str = "front", shot: str = "top") -> dict:
    """Capture mirrors for the artifact, then promote the chosen shot."""
    cap = post_json(f"{ENCYC}/api/dressing-room", {"artifact": artifact}, timeout=120)
    if not cap or "error" in cap:
        return {"artifact": artifact, "step": "capture", "error": (cap or {}).get("error", "no response")}
    shots = cap.get("shots") or []
    chosen = next((s for s in shots if s.get("name") == shot and s.get("image")), None)
    if not chosen:
        # Fall back to first available shot
        chosen = next((s for s in shots if s.get("image")), None)
    if not chosen:
        return {"artifact": artifact, "step": "capture", "error": "no shots produced"}

    prom = put_json(
        f"{ENCYC}/api/dressing-room?action=promote",
        {"artifact": artifact, "src_image": chosen["image"], "role": role},
        timeout=30,
    )
    if not prom or "error" in prom:
        return {"artifact": artifact, "step": "promote",
                "error": (prom or {}).get("error", "no response"),
                "shot_used": chosen["name"], "src_image": chosen["image"]}
    return {"artifact": artifact, "ok": True,
            "shot_used": chosen["name"], "promoted_to": prom.get("promoted_to")}


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--list", nargs="*", help="Specific artifacts to process.")
    p.add_argument("--recently-flattened", action="store_true",
                   help="Use the .bak files from the flatten script as the list.")
    p.add_argument("--role", default="front", choices=["front", "left", "right", "top", "hero", "thumbnail"])
    p.add_argument("--shot", default="top", help="Which dressing-room shot to promote (default: top).")
    p.add_argument("--limit", type=int, default=0, help="Only process the first N artifacts (0 = all).")
    args = p.parse_args()

    if args.list:
        names = args.list
    elif args.recently_flattened:
        names = list_recently_flattened()
    else:
        print("Need --list <names...> or --recently-flattened.")
        return 1

    if args.limit > 0:
        names = names[: args.limit]

    print(f"Batch promote: {len(names)} artifacts -> public/captures/artifacts/<x>/{args.role}.png")
    print(f"Source shot: {args.shot}   Encyclopedia: {ENCYC}")
    print("-" * 60)
    t0 = time.time()
    ok, fail = [], []
    for i, name in enumerate(names, 1):
        ts = time.time()
        result = capture_and_promote(name, role=args.role, shot=args.shot)
        dt = time.time() - ts
        if result.get("ok"):
            ok.append(name)
            print(f"  [{i}/{len(names)}] [ok] {name}  ({dt:.1f}s -> {result.get('promoted_to')})")
        else:
            fail.append((name, result.get("error", "?")))
            print(f"  [{i}/{len(names)}] [FAIL] {name}  ({dt:.1f}s) step={result.get('step')} err={result.get('error')}")
    print("-" * 60)
    print(f"Done in {time.time()-t0:.1f}s.  {len(ok)} ok, {len(fail)} failed.")
    if fail:
        print("Failures:")
        for n, e in fail:
            print(f"  - {n}: {e}")
    return 0 if not fail else 2


if __name__ == "__main__":
    sys.exit(main())
