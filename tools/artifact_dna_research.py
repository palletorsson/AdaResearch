#!/usr/bin/env python3
"""
artifact_dna_research.py — the auto-research runner over an ARTIFACT's DNA.

Stage 2. Its sibling map_dna_research.py is Stage 1 and says why in its own
docstring: it closes the OBSERVATION gap, because "an entry you can SEE is an entry
you can evaluate and vary; observation precedes variation." Stage 1 is 98.7% done
across the 2154 map-placed artifacts. This tool is the variation it was clearing
the ground for.

WHAT IT ACTUALLY DOES, and what it deliberately does not.

It does not invent DNA. Choosing what an artifact's axes SHOULD be is a design act
(see request_note, promoted by hand: mode = float/plate/stake/decal). What this tool
does is cheaper and, across 1554 artifacts, worth more: it finds the knobs that are
ALREADY THERE and nobody has ever turned. Most artifacts in this project expose
@export parameters that have never been varied from their defaults even once. Sweeping
them answers a question you cannot answer by reading source — which knobs actually
change what you see, and which are decoration.

So: discover axes from the registry's declared `dna` block if there is one, otherwise
from the @export lines themselves; pick at most two; render every combination in ONE
Godot boot via cabinet_sweep.py; publish a per-artifact manifest so each artifact has
a tracking URL the way each map does; and record the run in a ledger so --auto can
walk the agenda weakest-first.

Usage:
  python tools/artifact_dna_research.py --artifact=info_board
  python tools/artifact_dna_research.py --auto --count=3
  python tools/artifact_dna_research.py --status
"""
from __future__ import annotations
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ENC = REPO.parent / "ada_encyclopedia" / "public"
OUT = ENC / "artifact-dna"
LEDGER = OUT / "index.json"
LOCK = REPO / "ada_run" / "artifact_dna_research.lock"
AGENDA = REPO / "doc" / "reports" / "artifact_dna_agenda.json"
SWEEP_SHEET = REPO / "doc" / "reports"

# Axis kinds, best first. A declared axis beats a guessed one; an enum beats a bool;
# a bool beats a numeric spread, because true/false is a real distinction the author
# already drew, while 0.5x/1x/1.6x is a guess about what "different" means.
PRIORITY = {"declared": 0, "enum": 1, "bool": 2, "range": 3, "number": 4}

RE_ENUM = re.compile(r'@export_enum\(([^)]*)\)\s*var\s+(\w+)')
RE_RANGE = re.compile(r'@export_range\(\s*([-\d.]+)\s*,\s*([-\d.]+)[^)]*\)\s*var\s+(\w+)')
RE_BOOL = re.compile(r'@export\s+var\s+(\w+)\s*:\s*bool\s*=\s*(true|false)')
RE_NUM = re.compile(r'@export\s+var\s+(\w+)\s*:\s*(float|int)\s*=\s*([-\d.]+)')
# knobs that describe the machine's own plumbing, not its appearance or behaviour
SKIP = re.compile(r'path|_path$|nodepath|seed$|debug|verbose|enabled$|^auto_', re.I)
# TIME-DOMAIN knobs. The evidence this tool produces is a STILL, and a still cannot
# show the difference between 7.5 and 15 characters per second. Swept blind they
# yield a sheet of identical tiles that looks like a finished experiment and answers
# nothing — which is exactly what the first run on info_board produced. They are not
# excluded (they are real axes) but they sort last, so an artifact with any spatial
# knob varies that instead. Varying them honestly needs a timed probe, not a portrait.
TIME_AXIS = re.compile(
    r'(^|_)(time|duration|speed|rate|hz|fps|delay|interval|per_second|cooldown|lifetime|bpm)($|_)',
    re.I)


def registry() -> dict:
    out: dict = {}
    for rp in (REPO / "commons" / "artifacts" / "registry").glob("*.json"):
        try:
            data = json.loads(rp.read_text(encoding="utf-8"))
        except Exception:
            continue
        items = data.get("artifacts", data) if isinstance(data, dict) else data
        if isinstance(items, dict):
            for tok, e in items.items():
                if isinstance(e, dict):
                    out[tok] = e
        elif isinstance(items, list):
            for e in items:
                if isinstance(e, dict) and e.get("lookup_name"):
                    out[e["lookup_name"]] = e
    return out


def gd_for(entry: dict) -> Path | None:
    """The script behind an artifact's scene.

    The sibling guess (foo.tscn -> foo.gd) covers most of the project but not
    all of it: commons/interface/line.tscn loads its script from
    commons/primitives/line/line.gd, so line_interface reported "no .gd
    resolvable" and its declared axis stayed unreachable. Fall back to reading
    the scene's own Script ext_resource, which is where the truth is.
    """
    sc = entry.get("scene") or entry.get("scene_path") or ""
    if not sc:
        return None
    rel = sc.replace("res://", "")
    sibling = REPO / rel.replace(".tscn", ".gd")
    if sibling.exists():
        return sibling
    tscn = REPO / rel
    if not tscn.exists():
        return None
    try:
        text = tscn.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None
    for m in re.finditer(r'\[ext_resource[^\]]*type="Script"[^\]]*path="res://([^"]+)"', text):
        p = REPO / m.group(1)
        if p.exists():
            return p
    return None


def discover_axes(entry: dict, src: str) -> list[tuple[str, list, str]]:
    """Return [(name, values, kind)] — the knobs worth turning, best first."""
    found: list[tuple[str, list, str]] = []

    declared = ((entry.get("dna") or {}).get("axes") or {})
    for name, vals in declared.items():
        if isinstance(vals, list) and len(vals) >= 2:
            found.append((name, list(vals), "declared"))

    have = {n for n, _, _ in found}

    for m in RE_ENUM.finditer(src):
        name = m.group(2)
        if name in have or SKIP.search(name):
            continue
        vals = [v.strip().strip('"\'') for v in m.group(1).split(",") if v.strip()]
        # @export_enum on an int var yields indices, but names round-trip for strings;
        # either way two distinct values is enough to see whether it bites.
        if len(vals) >= 2:
            found.append((name, vals[:4], "enum"))
            have.add(name)

    for m in RE_BOOL.finditer(src):
        name = m.group(1)
        if name in have or SKIP.search(name):
            continue
        found.append((name, [True, False], "bool"))
        have.add(name)

    for m in RE_RANGE.finditer(src):
        name = m.group(3)
        if name in have or SKIP.search(name):
            continue
        lo, hi = float(m.group(1)), float(m.group(2))
        if hi <= lo:
            continue
        found.append((name, [round(lo, 3), round((lo + hi) / 2, 3), round(hi, 3)], "range"))
        have.add(name)

    for m in RE_NUM.finditer(src):
        name, _, dv = m.group(1), m.group(2), float(m.group(3))
        if name in have or SKIP.search(name) or dv == 0:
            continue
        found.append((name, [round(dv * 0.5, 3), dv, round(dv * 1.6, 3)], "number"))
        have.add(name)

    # spatial/appearance axes first; time-domain axes last, for the reason at TIME_AXIS
    found.sort(key=lambda a: (1 if TIME_AXIS.search(a[0]) else 0, PRIORITY.get(a[2], 9)))
    return found


def plan(axes: list[tuple[str, list, str]], max_variants: int) -> list[tuple[str, list]]:
    """At most two axes, and never more than max_variants renders."""
    chosen: list[tuple[str, list]] = []
    total = 1
    for name, vals, _kind in axes:
        if len(chosen) == 2:
            break
        v = list(vals)
        while len(v) > 1 and total * len(v) > max_variants:
            v = v[:-1]
        if len(v) < 2:
            continue
        chosen.append((name, v))
        total *= len(v)
    return chosen


def sweep(token: str, chosen: list[tuple[str, list]], max_variants: int) -> Path | None:
    args = [sys.executable, str(REPO / "tools" / "cabinet_sweep.py"), token,
            f"--max={max_variants}"]
    for name, vals in chosen:
        args += ["--set", f"{name}=" + ",".join(str(v).lower() if isinstance(v, bool) else str(v)
                                                for v in vals)]
    r = subprocess.run(args, cwd=REPO, capture_output=True, text=True, timeout=600)
    sys.stdout.write(r.stdout[-700:] if r.stdout else "")
    sheet = SWEEP_SHEET / f"sweep_{token}.png"
    return sheet if sheet.exists() else None


def publish(token: str, entry: dict, chosen: list, axes: list, sheet: Path | None) -> dict:
    d = OUT / token
    d.mkdir(parents=True, exist_ok=True)
    if sheet and sheet.exists():
        shutil.copy2(sheet, d / "sweep.png")
    rec = {
        "token": token,
        "name": entry.get("name", token),
        "researched_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "declared_dna": bool(entry.get("dna")),
        "axes_swept": [{"name": n, "values": [str(x) for x in v]} for n, v in chosen],
        "axes_available": [{"name": n, "kind": k, "n_values": len(v),
                            "time_domain": bool(TIME_AXIS.search(n))} for n, v, k in axes],
        "time_domain_only": all(bool(TIME_AXIS.search(n)) for n, _ in chosen) if chosen else False,
        "variants": max(1, _product([len(v) for _, v in chosen])),
        "sheet": f"/artifact-dna/{token}/sweep.png" if sheet else None,
        "url": f"/artifact-dna/{token}",
    }
    (d / "manifest.json").write_text(json.dumps(rec, indent=1), encoding="utf-8")
    return rec


def _product(xs: list[int]) -> int:
    n = 1
    for x in xs:
        n *= x
    return n


def load_ledger() -> dict:
    if LEDGER.exists():
        try:
            return json.loads(LEDGER.read_text(encoding="utf-8"))
        except Exception:
            pass
    return {"generated_at": "", "total": 0, "artifacts": []}


def save_ledger(led: dict) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    led["generated_at"] = time.strftime("%Y-%m-%dT%H:%M:%S")
    led["total"] = len(led["artifacts"])
    LEDGER.write_text(json.dumps(led, indent=1), encoding="utf-8")


def research(token: str, reg: dict, max_variants: int) -> int:
    entry = reg.get(token)
    if not entry:
        print(f"  {token}: not in any registry")
        return 1
    gd = gd_for(entry)
    if not gd:
        print(f"  {token}: no .gd resolvable from its scene")
        return 1
    src = gd.read_text(encoding="utf-8", errors="ignore")
    axes = discover_axes(entry, src)
    if not axes:
        print(f"  {token}: NO TURNABLE KNOBS — needs a promotion by hand, like request_note")
        led = load_ledger()
        led["artifacts"] = [a for a in led["artifacts"] if a.get("token") != token]
        led["artifacts"].append({"token": token, "name": entry.get("name", token),
                                 "researched_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
                                 "axes_swept": [], "needs_promotion": True,
                                 "url": f"/artifact-dna/{token}"})
        save_ledger(led)
        return 0
    chosen = plan(axes, max_variants)
    if not chosen:
        print(f"  {token}: axes found but none fit under --max-variants={max_variants}")
        return 1
    desc = ", ".join(f"{n}({len(v)})" for n, v in chosen)
    print(f"  {token}: sweeping {desc}  [{len(axes)} axis candidate(s) found]")
    sheet = sweep(token, chosen, max_variants)
    rec = publish(token, entry, chosen, axes, sheet)
    led = load_ledger()
    led["artifacts"] = [a for a in led["artifacts"] if a.get("token") != token]
    led["artifacts"].append(rec)
    save_ledger(led)
    if rec.get("time_domain_only"):
        # A still cannot hold a rate, so a sweep of duration knobs is guaranteed to
        # produce identical tiles. That used to be reported as a dead end. It is not one
        # any more: photograph the artifact at N moments instead and let the strip say
        # whether anything happens over time.
        print(f"  {token}: TIME-DOMAIN ONLY — every knob is a rate or a duration."
              f" Sweeping cannot answer this; running the temporal probe instead.")
        strip = _time_strip(token)
        rec["time_strip"] = str(strip) if strip else None
        if strip:
            print(f"  {token}: time strip -> {strip}")
        else:
            print(f"  {token}: temporal probe produced nothing — see the Godot log")
    else:
        print(f"  {token}: {'sheet published' if sheet else 'SWEEP PRODUCED NO SHEET'} -> {rec['url']}")
    return 0 if sheet else 1


## The way out of the time-domain dead end: same artifact, same camera, N moments.
## A strip that comes back identical is a FINDING about the artifact — it means nothing
## is animating — rather than a limitation of the instrument, which is the distinction
## the sweep alone could never draw.
def _time_strip(token: str, frames: int = 6, window: float = 12.0) -> str | None:
    r = subprocess.run(
        [sys.executable, str(REPO / "tools" / "time_strip.py"), token,
         f"--frames={frames}", f"--window={window}"],
        cwd=REPO, capture_output=True, text=True, timeout=int(window) + 300)
    out = REPO / "doc" / "reports" / f"strip_{token}.png"
    if out.exists():
        return f"doc/reports/strip_{token}.png"
    sys.stdout.write((r.stdout or r.stderr or "")[-300:])
    return None


def agenda_tokens() -> list[str]:
    if not AGENDA.exists():
        return []
    d = json.loads(AGENDA.read_text(encoding="utf-8"))
    return [r["token"] for r in d.get("agenda", []) if r.get("gd") and r.get("has_capture")]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--artifact")
    ap.add_argument("--auto", action="store_true", help="take the weakest un-researched from the agenda")
    ap.add_argument("--count", type=int, default=1)
    ap.add_argument("--max-variants", type=int, default=8)
    ap.add_argument("--status", action="store_true")
    a = ap.parse_args()

    led = load_ledger()
    if a.status:
        done = {x["token"] for x in led["artifacts"]}
        toks = agenda_tokens()
        need = [x["token"] for x in led["artifacts"] if x.get("needs_promotion")]
        print(f"stage 2 — artifact DNA research")
        print(f"  agenda (ready)     : {len(toks)}")
        print(f"  researched         : {len(done)}")
        print(f"  need hand promotion: {len(need)}")
        print(f"  remaining          : {len([t for t in toks if t not in done])}")
        return 0

    # one Godot at a time — the 16-second rule. Stale locks older than 20 min clear.
    if LOCK.exists() and (time.time() - LOCK.stat().st_mtime) < 1200:
        print(f"another run holds {LOCK}; wait or delete it")
        return 1
    LOCK.parent.mkdir(parents=True, exist_ok=True)
    LOCK.write_text(str(os.getpid()), encoding="utf-8")
    try:
        reg = registry()
        if a.artifact:
            targets = [a.artifact]
        elif a.auto:
            done = {x["token"] for x in led["artifacts"]}
            targets = [t for t in agenda_tokens() if t not in done][:max(1, a.count)]
            if not targets:
                print("agenda exhausted — every ready artifact has been researched")
                return 0
        else:
            print(__doc__.strip().splitlines()[-4])
            return 1
        print(f"researching {len(targets)} artifact(s), max {a.max_variants} variants each")
        rc = 0
        for t in targets:
            rc |= research(t, reg, a.max_variants)
        return rc
    finally:
        if LOCK.exists():
            LOCK.unlink()


if __name__ == "__main__":
    raise SystemExit(main())
