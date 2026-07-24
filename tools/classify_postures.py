#!/usr/bin/env python3
"""classify_postures.py — assign a staging POSTURE to every artifact.

A posture is how a thing stands in the world: floor / pedestal / table /
platform / float / pit / wall. It's the 3D generalisation of the flat
footprint — the "dressing room" the map composer places as an inviolable
unit (commons/artifacts/dressing_rooms/<name>.json).

Signal priority (most trusted first):
  1. commons/data/posture_overrides.json  — hand decisions, always win
  2. registry spatial_needs.platform       — an EXISTING authored hint
     (pedestal/table/sunken/floor/wall/step) on ~377 artifacts
  3. derived from aabb_size + base_m + category + name keywords
     (flat->floor, field/wave->float, tiny->pedestal, medium->platform…)

Dry-run by default: prints the distribution + samples per posture and how
many current dressing rooms would change. `--write` regenerates the footing
recipe in each room (.bak backup, overrides + hand-authored rooms respected).

  python tools/classify_postures.py                 # dry-run distribution
  python tools/classify_postures.py --show pit      # list every artifact -> pit
  python tools/classify_postures.py --write         # regenerate rooms (backs up)
"""
from __future__ import annotations
import argparse, json, glob, math, os, collections

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REG_DIR = os.path.join(REPO, "commons", "artifacts", "registry")
SIZES = os.path.join(REPO, "commons", "data", "artifact_sizes.json")
OVERRIDES = os.path.join(REPO, "commons", "data", "posture_overrides.json")
ROOMS_DIR = os.path.join(REPO, "commons", "artifacts", "dressing_rooms")

POSTURES = ["floor", "pedestal", "table", "platform", "float", "pit", "wall", "monument"]

# spatial_needs.platform -> our posture vocabulary
PLATFORM_MAP = {
    "pedestal": "pedestal", "table": "table", "sunken": "pit",
    "floor": "floor", "wall": "wall", "step": "platform",
    "backdrop": "wall",
}

FLOAT_KW = ("sphere_field", "floating", "orbit", "celestial", "constellation",
            "particle", "flock", "swarm_field", "galaxy", "star_field", "nebula")
FLOOR_KW = ("mosaic", "carpet", "floor", "terrain", "tiling", "rug", "tartan",
            "pavement", "heightfield", "landscape", "ground")
TABLE_KW = ("slider", "plate", "panel", "screen", "display", "counter", "console",
            "keyboard", "dial", "gauge", "meter", "readout", "board", "desk", "workbench")


MEASURED = os.path.join(REPO, "commons", "data", "artifact_elements.json")


def load_sizes() -> dict:
    """Size oracle for classification — the PROBE-MEASURED floor first.

    Round 8 of the composition research (2026-07-24) found the static
    artifact_sizes.json oracle stale exactly for the largest bodies (an 8 m
    screen typed as a 'table', a 10 m gallery as a 'pedestal'). The measured
    union AABBs from commons/data/artifact_elements.json are the primary
    truth; the old oracle fills artifacts the probe has not measured.
    Probe-derived entries carry source='probe' (visible in --explain).
    """
    sizes = {}
    if os.path.exists(SIZES):
        sizes = json.load(open(SIZES, encoding="utf-8")).get("sizes", {})
    if os.path.exists(MEASURED):
        try:
            arts = json.load(open(MEASURED, encoding="utf-8")).get("artifacts", {})
        except Exception:
            arts = {}
        for name, a in arts.items():
            s = (a.get("union_aabb") or {}).get("size")
            if not s or len(s) < 3:
                continue
            w, h, d = float(s[0]), float(s[1]), float(s[2])
            if max(w, h, d) <= 0:
                continue
            e = dict(sizes.get(name, {}))
            e.update({
                "aabb_size": [w, h, d],
                "base_m": max(w, d),
                "height_m": h,
                "max_dimension_m": max(w, h, d),
                "grid_cells": [max(1, math.ceil(w)), max(1, math.ceil(d))],
                "source": "probe",
            })
            sizes[name] = e
    return sizes


def load_overrides() -> dict:
    if not os.path.exists(OVERRIDES):
        return {}
    try:
        return json.load(open(OVERRIDES, encoding="utf-8"))
    except Exception:
        return {}


def load_registry() -> dict:
    out = {}
    for f in sorted(glob.glob(os.path.join(REG_DIR, "*.json"))):
        try:
            d = json.load(open(f, encoding="utf-8"))
        except Exception:
            continue
        arts = d.get("artifacts", d) if isinstance(d, dict) else {}
        if not isinstance(arts, dict):
            continue
        for k, v in arts.items():
            if isinstance(v, dict):
                lk = v.get("lookup_name") or k
                out.setdefault(lk, v)
    return out


def classify(name: str, entry: dict, size: dict, overrides: dict) -> tuple[str, str]:
    """Return (posture, reason)."""
    if name in overrides:
        return overrides[name], "override"

    sn = entry.get("spatial_needs") or {}
    plat = str(sn.get("platform", "")).lower() if isinstance(sn, dict) else ""
    ppos = str(sn.get("player_position", "")).lower() if isinstance(sn, dict) else ""
    cat = str(entry.get("category", "")).lower()
    tags = entry.get("tags", []) or []
    hay = name.lower() + " " + " ".join(str(t).lower() for t in tags)

    if plat in PLATFORM_MAP:
        # A clearly floor-named thing marked 'sunken' is almost certainly a
        # mis-authored hint — the flatten_carpet precedent says carpets /
        # mosaics / floors LIE on the ground. Name beats the sunken hint here.
        if plat == "sunken" and any(k in hay for k in FLOOR_KW):
            return "floor", "floor-name over sunken hint"
        # Same precedent, measured edition (r8): a table/pedestal hint on a
        # body taller than a person or broader than furniture is mis-authored
        # — an 8 m cube does not sit on a desk. The measured floor overrules
        # the hint; explicit posture_overrides.json still always wins above.
        _mh = float(size.get("height_m", 0) or 0)
        _mb = float(size.get("base_m", 0) or 0)
        if plat in ("table", "pedestal") and (_mh > 2.5 or _mb > 6.0):
            pass  # fall through to the size logic below
        else:
            return PLATFORM_MAP[plat], f"spatial_needs.platform={plat}"

    aabb = size.get("aabb_size")
    base = float(size.get("base_m", 0) or 0)
    h = float(size.get("height_m", 0) or 0)
    max_dim = float(size.get("max_dimension_m", 0) or 0)

    # player views from above -> the thing is laid out FLAT and surveyed
    # top-down (a map / graph / terrain), NOT a sunken well. (Pit comes only
    # from an explicit spatial_needs.platform=sunken hint, handled above.)
    if ppos in ("above", "below"):
        return "floor", f"player_position={ppos}"

    # fields / orbits that hover — require an explicit NAME/tag keyword, not
    # just category=waves (a pipe demo lives under 'waves' but doesn't float).
    if any(k in hay for k in FLOAT_KW):
        return "float", "float keyword"

    # flat things lie on the ground
    if aabb and h > 0.0 and h < 0.4 and base > 0.6:
        return "floor", f"flat (h={h:.2f})"
    if any(k in hay for k in FLOOR_KW):
        return "floor", "floor keyword"
    # super-large / very-long AND not flat: too big for any room — a SPACE, not
    # an object (an 86 m corridor, a tower). Route to the monument treatment.
    if max_dim > 12.0 and h >= 0.5:
        return "monument", f"super-large ({max_dim:.0f}m)"
    if base > 6.0 or max_dim > 9.0:
        return "floor", f"architectural (base={base:.1f})"

    # desktop instruments sit on a table
    if any(k in hay for k in TABLE_KW):
        return "table", "instrument keyword"

    # medium bodies command a stage
    if base >= 2.0:
        return "platform", f"medium (base={base:.1f})"

    # default: a small specimen on a pedestal (the museum pose)
    return "pedestal", "small specimen (default)"


# ── Footing recipes: posture -> (tiles, anchor, artifact_offset) ──────────
# Tile values are height units; DressingRoomBuilder renders 0.5m per unit and
# seats the artifact on the anchor tile's top. So 3 = a 1.5m pedestal, 2 = a
# 1.0m table/stage top, 1 = the 0.5m floor. Float lifts via artifact_offset.y.
PILLAR = [[1, 1, 1], [1, 3, 1], [1, 1, 1]]


def _pad(w: int, d: int, val: int = 1) -> list[list[int]]:
    return [[val] * w for _ in range(d)]


def build_footing(posture: str, footprint, keep_off_x: float = 0.0):
    fw = max(1, int(round(float(footprint[0])))) if footprint else 1
    fd = max(1, int(round(float(footprint[1])))) if footprint and len(footprint) > 1 else 1
    off = [round(keep_off_x, 4), 0.0, 0.0]

    if posture == "floor":
        # a flat pad the footprint lies on — sized to the artifact, min 3x3
        pw, pd = max(3, fw + 2), max(3, fd + 2)
        return _pad(pw, pd, 1), [pd // 2, pw // 2], off
    if posture == "monument":
        # too big to pad — a small placeholder; the BUILDER draws the true
        # extent frame from the size oracle, seats the artifact flush at y=0.
        return _pad(3, 3, 1), [1, 1], off
    if posture == "table":
        # broad low surface: 5x5 pad, raised 3x3 top at 1.0m
        t = _pad(5, 5, 1)
        for r in range(1, 4):
            for c in range(1, 4):
                t[r][c] = 2
        return t, [2, 2], off
    if posture == "platform":
        # a stage you step onto: 7x7 pad, raised 5x5 at 1.0m
        t = _pad(7, 7, 1)
        for r in range(1, 6):
            for c in range(1, 6):
                t[r][c] = 2
        return t, [3, 3], off
    if posture == "float":
        # hovers over a plain floor pad
        return _pad(3, 3, 1), [1, 1], [round(keep_off_x, 4), 1.5, 0.0]
    if posture == "pit":
        # a well: raised rim (1.5m), artifact down at floor centre -> look in
        t = _pad(5, 5, 1)
        for c in range(5):
            t[0][c] = t[4][c] = 3
        for r in range(5):
            t[r][0] = t[r][4] = 3
        return t, [2, 2], off
    if posture == "wall":
        # tall back wall (2.0m), artifact mounted up it, floor in front
        return [[4, 4, 4], [1, 1, 1], [1, 1, 1]], [1, 1], [round(keep_off_x, 4), 1.0, 0.0]
    # pedestal (and any fallthrough): the museum pillar
    return [r[:] for r in PILLAR], [1, 1], off


def is_default_pillar(room: dict) -> bool:
    t = room.get("footing", {}).get("tiles")
    if not isinstance(t, list):
        return False
    norm = [[int(round(float(v))) for v in row] for row in t if isinstance(row, list)]
    return norm == PILLAR


def write_room(name: str, posture: str, existing: dict | None, force: bool) -> str:
    """Write the posture footing into <name>.json. Returns a status word.
    Preserves rotations/approach/exit/footprint/clearance/extras. Backs up to
    .bak on first write. Never clobbers a hand-authored (non-pillar) room
    unless `force` (an override or --only)."""
    room = dict(existing) if isinstance(existing, dict) else {}
    if existing and not is_default_pillar(room) and not force:
        return "skip-authored"
    footprint = room.get("footprint", [1, 1, 1])
    keep_x = 0.0
    ao = room.get("artifact_offset")
    if isinstance(ao, list) and ao and posture in ("pedestal", "floor"):
        try:
            keep_x = float(ao[0])
        except Exception:
            keep_x = 0.0
    tiles, anchor, off = build_footing(posture, footprint, keep_x)

    # pedestal on an already-default pillar = no change worth a write — BUT only
    # skip if the posture field is already recorded. ~35% of rooms predate the
    # posture field; those must still be written (else the builder can't find a
    # template and renders a bare grey cube instead of a plinth).
    if (posture == "pedestal" and is_default_pillar(room) and off[0] == 0.0
            and room.get("posture") == "pedestal"):
        return "noop-pedestal"

    room.setdefault("rotations", ["0", "90", "180", "270"])
    room.setdefault("approach", "south")
    room.setdefault("exit", "north")
    room.setdefault("footprint", footprint)
    room.setdefault("clearance", [3.0, 3.0, 3.0])
    room.setdefault("extras", [])
    room["lookup_name"] = name
    room["posture"] = posture
    room["footing"] = {"anchor": anchor, "tiles": tiles}
    room["artifact_offset"] = off

    path = os.path.join(ROOMS_DIR, f"{name}.json")
    if os.path.exists(path) and not os.path.exists(path + ".bak"):
        import shutil
        shutil.copy2(path, path + ".bak")
    os.makedirs(ROOMS_DIR, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(room, f, indent=2)
    return "written"


def load_room(name: str) -> dict | None:
    path = os.path.join(ROOMS_DIR, f"{name}.json")
    if not os.path.exists(path):
        return None
    try:
        return json.load(open(path, encoding="utf-8"))
    except Exception:
        return None


def scenes_on_disk() -> set:
    import glob as _g
    out = set()
    for f in _g.glob(os.path.join(REPO, "commons", "**", "*.tscn"), recursive=True) + \
             _g.glob(os.path.join(REPO, "algorithms", "**", "*.tscn"), recursive=True):
        out.add(os.path.basename(f)[:-5])
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--show", default="", help="print every artifact assigned to this posture")
    ap.add_argument("--write", action="store_true", help="regenerate footing recipes for all applicable default-pillar rooms")
    ap.add_argument("--sample", action="store_true", help="write ONE default-pillar artifact per non-pedestal posture (validation batch)")
    ap.add_argument("--only", default="", help="comma-separated artifact names to (force-)write")
    ap.add_argument("--explain", default="", help="print a JSON verdict + reason + evidence for ONE artifact (for the web 'auto discover')")
    args = ap.parse_args()

    registry = load_registry()
    sizes = load_sizes()
    overrides = load_overrides()

    # ── Single-artifact explain (JSON) — the web 'auto discover' loop ──────
    if args.explain:
        name = args.explain.strip()
        entry = registry.get(name, {})
        size = sizes.get(name, {})
        posture, reason = classify(name, entry, size, overrides)
        gc = size.get("grid_cells") or []
        fw = int(round(float(gc[0]))) if len(gc) >= 1 else 0
        fd = int(round(float(gc[1]))) if len(gc) >= 2 else 0
        # Suggested pad: measured extent + a walkable cell each side, min 3 (a
        # monument keeps its true extent; the builder draws that frame).
        sw = max(3, fw + 2) if fw else 3
        sd = max(3, fd + 2) if fd else 3
        print(json.dumps({
            "name": name,
            "found": bool(entry) or bool(size),
            "posture": posture,
            "reason": reason,
            "override": name in overrides,
            "size": {
                "aabb": size.get("aabb_size"),
                "base_m": size.get("base_m"),
                "height_m": size.get("height_m"),
                "max_dimension_m": size.get("max_dimension_m"),
                "grid_cells": gc,
            },
            "suggested_pad": [sw, sd],
        }))
        return 0

    dist = collections.Counter()
    reasons = collections.Counter()
    by_posture: dict[str, list] = {p: [] for p in POSTURES}
    assigned: dict[str, str] = {}
    for name, entry in sorted(registry.items()):
        size = sizes.get(name, {})
        posture, reason = classify(name, entry, size, overrides)
        assigned[name] = posture
        dist[posture] += 1
        reasons[reason.split("(")[0].strip()] += 1
        by_posture.setdefault(posture, []).append((name, reason, size.get("base_m")))

    # ── write modes ───────────────────────────────────────────────────
    if args.only or args.sample or args.write:
        targets: list[str] = []
        if args.only:
            targets = [s.strip() for s in args.only.split(",") if s.strip()]
        elif args.sample:
            have_scene = scenes_on_disk()
            print("validation batch — one default-pillar artifact per non-pedestal posture:\n")
            for p in ("floor", "table", "platform", "float", "pit", "wall"):
                pick = None
                for nm, _r, _b in by_posture.get(p, []):
                    room = load_room(nm)
                    if room and is_default_pillar(room) and nm in have_scene:
                        pick = nm
                        break
                if pick:
                    targets.append(pick)
                    print(f"  {p:<10s} -> {pick}")
                else:
                    print(f"  {p:<10s} -> (no default-pillar candidate with a scene)")
            print()
        else:  # --write: everything applicable
            targets = sorted(assigned.keys())

        status = collections.Counter()
        written: list[tuple[str, str]] = []
        for nm in targets:
            posture = assigned.get(nm) or overrides.get(nm) or "pedestal"
            force = args.only != "" or nm in overrides
            st = write_room(nm, posture, load_room(nm), force)
            status[st] += 1
            if st == "written":
                written.append((nm, posture))
        print("write results:", dict(status))
        if args.sample or args.only:
            for nm, p in written:
                print(f"  wrote {nm}  -> {p}")
        return 0

    total = sum(dist.values())
    print(f"classified {total} artifacts\n")
    print("posture       count   share")
    for p in POSTURES:
        c = dist.get(p, 0)
        print(f"  {p:<11s} {c:5d}   {100*c/max(1,total):4.1f}%")
    other = total - sum(dist.get(p, 0) for p in POSTURES)
    if other:
        print(f"  (other)     {other:5d}")

    print("\ntop reasons:")
    for r, c in reasons.most_common(12):
        print(f"  {c:5d}  {r}")

    if args.show:
        rows = by_posture.get(args.show, [])
        print(f"\n--- {len(rows)} artifacts -> {args.show} ---")
        for name, reason, base in rows[:80]:
            print(f"  {name:<40s} {('%.2f'%base) if base else '  -  ':>6s}  [{reason}]")
        if len(rows) > 80:
            print(f"  ... and {len(rows)-80} more")
    else:
        # a couple of samples per posture so we can eyeball sanity
        print("\nsamples per posture:")
        for p in POSTURES:
            rows = by_posture.get(p, [])
            picks = ", ".join(n for n, _, _ in rows[:5])
            print(f"  {p:<11s} {picks}")

    if args.write:
        print("\n[--write is a stub in this dry-run build — recipe generation lands next]")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
