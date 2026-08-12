#!/usr/bin/env python3
"""How high things hang — one reader for the wall's horizontal bands.

I said three times this session that the repo declares "three incompatible band
schemes". Laid side by side, that was wrong, and the correction matters:

  * `commons/data/museum_contract_pilot.json` -> wall_system
  * `commons/data/museum_prop_placement_rules.json` -> bands
        These two AGREE, exactly: low 0-1.1, eye 1.1-2.3, upper 2.3-4.
        Together they are the MUSEUM scheme, and they are the declaration.

  * `tools/build_wall_faces.py` -> BANDS
        dado 0.0-0.9, hang 0.9-2.1, frieze 2.1-3.2. Different numbers AND
        different names, but not a stale copy: it derives them from a viewing-
        distance rule (d ~ 1.4 + 0.21 x sqrt(area)) for the wall-hangar
        corridor. A considered alternative for another context.

So this does not merge them. Merging would silently change the output of a
system that drives real maps, on the strength of a tidiness argument. It
publishes both, says which is which and what each is for, and `check()` reports
the disagreements that are REAL rather than the ones that are only cosmetic.

    python tools/wall_bands.py            # print both schemes
    python tools/wall_bands.py --check    # report real inconsistencies
"""
from __future__ import annotations

import argparse
import json
from functools import lru_cache
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PILOT = REPO / "commons" / "data" / "museum_contract_pilot.json"
PROP_RULES = REPO / "commons" / "data" / "museum_prop_placement_rules.json"
KIT = REPO / "commons" / "data" / "museum_module_kit.json"

#: The certified wall the kit actually builds. Any band that reaches past this
#: is describing a wall nobody has made.
CERTIFIED_WALL_M = 4.0

#: The wall-hangar corridor's own scheme, quoted from build_wall_faces.py.
#: Kept here so both schemes are visible in one place; that file remains its
#: author and its derivation stays with it.
HANGAR_BANDS = {
    "dado":   [0.0, 0.9],
    "hang":   [0.9, 2.1],
    "frieze": [2.1, 3.2],
}

_MUSEUM_FALLBACK = {
    "low": [0.0, 1.1], "eye": [1.1, 2.3], "upper": [2.3, 4.0],
    "interactive": [0.75, 1.35],
}


def _load(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


@lru_cache(maxsize=1)
def museum() -> dict[str, list[float]]:
    """The declared museum bands: low, eye, upper, interactive."""
    ws = _load(PILOT).get("wall_system", {})
    out: dict[str, list[float]] = {}
    for name, key in (("low", "low_band_m"), ("eye", "eye_band_m"),
                      ("upper", "upper_band_m")):
        if isinstance(ws.get(key), list):
            out[name] = [float(v) for v in ws[key]]
    bands = _load(PROP_RULES).get("bands", {})
    if isinstance(bands.get("interactive"), dict):
        out["interactive"] = [float(v) for v in bands["interactive"]["vertical_m"]]
    for k, v in _MUSEUM_FALLBACK.items():
        out.setdefault(k, list(v))
    return out


@lru_cache(maxsize=1)
def feature_field() -> tuple[list[float], list[float]]:
    """The protected artwork field: (horizontal fractions, vertical metres)."""
    ff = _load(PILOT).get("wall_system", {}).get("feature_field", {})
    h = ff.get("horizontal_percent", [20, 80])
    v = ff.get("vertical_m", [1.1, 2.7])
    return ([float(p) / 100.0 for p in h], [float(x) for x in v])


@lru_cache(maxsize=1)
def prop_rails() -> tuple[list[list[float]], list[float]]:
    """The side rails props may use: (horizontal fraction pairs, vertical m)."""
    pr = _load(PILOT).get("wall_system", {}).get("prop_rails", {})
    h = pr.get("horizontal_percent", [[0, 18], [82, 100]])
    v = pr.get("vertical_m", [0.75, 2.3])
    return ([[float(a) / 100.0, float(b) / 100.0] for a, b in h],
            [float(x) for x in v])


def band_for(v_centre: float) -> str:
    """Which museum band a height falls in."""
    for name in ("low", "eye", "upper"):
        lo, hi = museum()[name]
        if lo <= v_centre < hi:
            return name
    return "upper" if v_centre >= museum()["upper"][1] else "low"


def check() -> int:
    """Report the disagreements that are real. Returns the count."""
    faults = 0
    m = museum()

    # 1. The declaration against itself: the feature field runs 1.1-2.7 while
    #    the eye band stops at 2.3, so the protected artwork field spills
    #    0.4 m into the upper band that signage and lighting are told to own.
    _, fv = feature_field()
    if fv[1] > m["eye"][1] + 1e-6:
        faults += 1
        print(f"  the feature field tops at {fv[1]:g} m but the eye band ends at "
              f"{m['eye'][1]:g} m — artwork and signage are both promised "
              f"{m['eye'][1]:g}-{fv[1]:g} m")

    # 2. Either scheme against the wall the kit certifies.
    kit_h = CERTIFIED_WALL_M
    kit = _load(KIT)
    for w in (kit.get("wall_kit", {}).get("height_m"), kit.get("height_m")):
        if isinstance(w, (int, float)):
            kit_h = float(w)
            break
    if m["upper"][1] > kit_h + 1e-6:
        faults += 1
        print(f"  museum upper band tops at {m['upper'][1]:g} m on a "
              f"{kit_h:g} m certified wall")
    top = HANGAR_BANDS["frieze"][1]
    if top < kit_h - 1e-6:
        faults += 1
        print(f"  hangar frieze stops at {top:g} m on a {kit_h:g} m wall — "
              f"{kit_h - top:g} m of certified wall the corridor never uses, "
              f"and nothing says whether that is a reveal or an oversight")

    # 3. Contiguity: a scheme with a gap hides a height nothing may occupy.
    for label, bands in (("museum", [m["low"], m["eye"], m["upper"]]),
                         ("hangar", [HANGAR_BANDS["dado"], HANGAR_BANDS["hang"],
                                     HANGAR_BANDS["frieze"]])):
        for a, b in zip(bands, bands[1:]):
            if abs(a[1] - b[0]) > 1e-6:
                faults += 1
                print(f"  {label} bands leave a gap between {a[1]:g} and {b[0]:g} m")

    if not faults:
        print("both schemes are internally consistent and fit the certified wall")
    return faults


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    if args.check:
        return 1 if check() else 0
    print("MUSEUM scheme (museum_contract_pilot + museum_prop_placement_rules,")
    print("               which agree exactly):")
    for name, (lo, hi) in museum().items():
        print(f"  {name:12s} {lo:>5.2f} - {hi:.2f} m")
    fh, fv = feature_field()
    print(f"  feature      {fv[0]:>5.2f} - {fv[1]:.2f} m, "
          f"horizontally {fh[0]:.0%}-{fh[1]:.0%} of the span")
    rh, rv = prop_rails()
    print(f"  rails        {rv[0]:>5.2f} - {rv[1]:.2f} m, "
          f"horizontally {rh[0][0]:.0%}-{rh[0][1]:.0%} and {rh[1][0]:.0%}-{rh[1][1]:.0%}")
    print()
    print("HANGAR scheme (build_wall_faces.py — the corridor's viewing-distance")
    print("               derivation, a different context, not a stale copy):")
    for name, (lo, hi) in HANGAR_BANDS.items():
        print(f"  {name:12s} {lo:>5.2f} - {hi:.2f} m")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
