#!/usr/bin/env python3
"""check_hang.py — verify that a museum room actually hangs the variants it claims to.

Wave 23 hangs DNA families in maps using the `token:rot:yoff#axis:value` placement syntax.
It has exactly one silent failure mode, and it is the one this programme keeps losing passes
to: a misspelled axis name or value does not error. Godot's Object.set() on a typed property
of the wrong type is REFUSED IN SILENCE, and the artifact falls back to its default. A botched
hang therefore ships a room of N identical objects that looks exactly like a room of N variants
— in a map, unlike in a sweep, there is no contact sheet to notice it on.

So this asserts, against the registry rather than against anybody's intention:
  · every placed token exists
  · every #axis names an axis that token DECLARES
  · every value is one that axis DECLARES
  · no value is numeric (a bare number in the key:value slot is read as rotation shorthand
    by GridInteractablesComponent, so a numeric-looking enum silently becomes a transform)
  · the room places more than one distinct value per axis — a "hang" that sets one value
    everywhere is a specimen row with extra steps, and passes every other check here
  · the registry's designed_nulls, if any, are both placed — the walkable null

Usage:  python tools/check_hang.py Museum_AAA_Remainder [More_Maps ...]
        python tools/check_hang.py --all          (every Museum_AAA_* map)
Exit code is the number of failures, so it gates.
"""
from __future__ import annotations
import json, pathlib, re, sys, collections

REPO = pathlib.Path(__file__).resolve().parents[1]
REG = REPO / "commons" / "artifacts" / "registry"
MAPS = REPO / "commons" / "maps"
_CPN: list[str] = []


def config_param_names() -> list[str]:
    """The parser's allow-list, read from the source rather than copied.

    A key in this list is treated as a real config parameter; a key outside it whose value
    parses as a float is swallowed as positional shorthand (see the shorthand trap below).
    """
    global _CPN
    if not _CPN:
        import re as _re
        src = (REPO / "commons" / "grid" / "GridInteractablesComponent.gd").read_text(encoding="utf-8")
        m = _re.search(r"const CONFIG_PARAM_NAMES\s*=\s*\[(.*?)\]", src, _re.S)
        _CPN = [x.strip().strip("\"'").lower() for x in m.group(1).split(",") if x.strip()] if m else []
    return _CPN


def load_registry() -> dict:
    out = {}
    for f in REG.glob("*.json"):
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        for t, e in (d.get("artifacts") or {}).items():
            out[t] = e
    return out


def declared_axes(entry: dict) -> dict:
    ax = ((entry.get("dna") or {}).get("axes") or {})
    out = {}
    for a, spec in ax.items():
        vals = spec.get("values") if isinstance(spec, dict) else spec
        out[a] = [str(v) for v in (vals or [])]
    return out


def check_map(name: str, entries: dict, hang: bool = False) -> list[str]:
    faults: list[str] = []
    p = MAPS / name / "map_data.json"
    if not p.exists():
        return [f"{name}: no map_data.json"]
    d = json.loads(p.read_text(encoding="utf-8"))
    rows = ((d.get("layers") or {}).get("interactables")) or []
    placed = [(y, x, str(c).strip())
              for y, r in enumerate(rows)
              for x, c in enumerate(r if isinstance(r, list) else [])
              if str(c).strip()]
    if not placed:
        return [f"{name}: no interactables placed"]

    seen_vals: dict[tuple[str, str], set] = collections.defaultdict(set)
    configured = 0
    for y, x, cell in placed:
        head, *cfg = cell.split("#")
        tok = head.split(":")[0]
        # NOT EVERY PLACEMENT IS A REGISTRY TOKEN. GridInteractablesComponent expands several
        # prefixed forms before it ever looks a token up — cluster:<name>:<rot> goes through
        # cluster_resolver.gd, and mc:/gridagent:/criticalinfo: are handled the same way. The
        # first version of this checker did not know that and reported thirteen "token is in no
        # registry file" faults against three museums that were entirely correct. Which is the
        # fault this whole programme keeps finding: a confident verdict that is a fact about the
        # instrument. Skip the prefixed forms rather than convicting them.
        if any(head.startswith(p) for p in ("cluster:", "mc:", "gridagent:", "criticalinfo:")):
            continue
        e = entries.get(tok)
        if e is None:
            faults.append(f"{name} ({y},{x}): token '{tok}' is in no registry file")
            continue
        if not cfg:
            continue
        configured += 1
        ax = declared_axes(e)
        for part in cfg:
            if ":" not in part:
                faults.append(f"{name} ({y},{x}): config fragment '{part}' has no colon")
                continue
            k, v = part.split(":", 1)
            k, v = k.strip(), v.strip()
            if k not in ax:
                # not necessarily fatal — could be a plain export — but on a promoted
                # artifact it is almost always a typo'd axis name, so say so loudly.
                if ax:
                    faults.append(
                        f"{name} ({y},{x}): {tok} has no DECLARED axis '{k}' "
                        f"(declares {sorted(ax)}) — if this is a plain export it is fine, "
                        f"if it was meant as an axis the sweep and the gate will never see it")
                continue
            if v not in ax[k]:
                faults.append(
                    f"{name} ({y},{x}): {tok}.{k} = '{v}' is NOT a declared value "
                    f"— declared: {ax[k]}. This will fall back to the default IN SILENCE.")
                continue
            if re.fullmatch(r"-?\d+(\.\d+)?", v) and k.lower() not in config_param_names():
                # THE SHORTHAND TRAP, read off GridInteractablesComponent.gd:1545-1576. When the
                # key is NOT in CONFIG_PARAM_NAMES and the value parses as a float, the parser
                # decides the whole fragment is positional shorthand: it sets config_data[key] =
                # TRUE and writes the number into overrides["rotation_y_degrees"]. So
                # `#tier:3` does not set tier to 3 — it sets tier to true and rotates the work
                # 3 degrees, in silence, and the artifact renders its default at a funny angle.
                # 46 promoted axes across 44 artifacts have numeric values and a key outside that
                # list, ca_bridge.rule (30|90|110|250) among them; none of them can be hung with
                # this syntax at all. Found by the mixing_jar room, which probed it rather than
                # assuming its seed would take.
                faults.append(
                    f"{name} ({y},{x}): {tok}.{k} = '{v}' is numeric and '{k}' is not in "
                    f"CONFIG_PARAM_NAMES — this is parsed as SHORTHAND: {k}=true and "
                    f"rotation_y_degrees={v}. The axis is not set at all.")
            seen_vals[(tok, k)].add(v)

    if configured == 0:
        faults.append(f"{name}: {len(placed)} placements, NONE configured — "
                      f"this is a default-only room, not a hang")

    # IS THE WORK BIG ENOUGH TO BE A WORK? Added after wave 23 was WALKED. All six rooms
    # validated clean on every rule above and every one of them renders its works as specks:
    # measured against the hall's longest side, mixing_jar is 1.5%, ground_layer 2.0%,
    # posture_bench 3.3%, remainder_box and constant_dispute 3.6%, recession_hall 5.3% — and in
    # the captures the 5.3% room is the only one where the variants read at a glance. Grid cells
    # are 1 m (GridSystem.cube_size), so a 0.40 m jar in a 27 m hall is exactly as small as it
    # sounds. The builders worked from cell coordinates and never compared the artifact's
    # measured body to the room's extent; nothing in the pipeline asked them to. This is the
    # project's own "bodies, not gauges" correction arriving in a new form — the architecture is
    # at human scale and the works are tabletop objects.
    dims = ((d.get("map_info") or {}).get("dimensions") or {})
    span = max(float(dims.get("width") or 0), float(dims.get("depth") or 0))
    if hang and span:
        for tok in sorted({c.split("#")[0].split(":")[0] for _, _, c in placed}):
            aabb = ((entries.get(tok) or {}).get("measurements") or {}).get("aabb_size")
            if not aabb:
                continue
            longest = max(float(aabb[0]), float(aabb[2]))
            frac = longest / span
            if frac < 0.03:
                faults.append(
                    f"{name}: {tok} is {longest:.2f} m across in a {span:.0f} m hall "
                    f"({frac:.1%}) — at that ratio the works photograph as specks and the axis "
                    f"is not legible from anywhere a visitor stands. Shrink the room, scale the "
                    f"work (the placement syntax's 4th positional field is uniform_scale), or "
                    f"give it a plinth (synthesis_stand).")
    # A ROOM THAT SETS ONE VALUE IS NOT WRONG — it is just not a hang. Museum_AAA_Featured_Pass
    # showing lambda_slider at `dispute` alone is a curator's choice, not a defect, and flagging
    # it as one made this checker report seven faults against maps that never claimed to vary
    # anything. The rule applies only when the map is being checked AS a hang.
    for (tok, k), vs in (sorted(seen_vals.items()) if hang else []):
        if len(vs) < 2:
            faults.append(f"{name}: {tok}.{k} is set to only one value ({sorted(vs)}) — "
                          f"a hang needs at least two for a visitor to compare")

    # the walkable null: both sides of each registered designed_null should be on the wall
    for tok in {c.split("#")[0].split(":")[0] for _, _, c in placed}:
        e = entries.get(tok) or {}
        nulls = ((e.get("dna") or {}).get("designed_nulls") or []) if hang else []
        if not nulls:
            continue
        cells = []
        for _, _, c in placed:
            if c.split("#")[0].split(":")[0] != tok:
                continue
            cells.append({p.split(":", 1)[0]: p.split(":", 1)[1]
                          for p in c.split("#")[1:] if ":" in p})
        # AT LEAST ONE walkable null, not all of them. A family with three registered nulls does
        # not owe the room three; the requirement is that a visitor can walk between one pair that
        # is identical by construction. Demanding all of them flagged a room that had hung two of
        # three deliberately — the checker inventing a standard nobody set, which is the same
        # overreach as the cluster false positives above.
        def hung(side):
            return any(all(str(cc.get(k)) == str(v) for k, v in side.items()) for cc in cells)
        pairs = [(nd.get("a") or {}, nd.get("b") or {}) for nd in nulls]
        pairs = [(a, b) for a, b in pairs if a and b]
        if pairs and not any(hung(a) and hung(b) for a, b in pairs):
            faults.append(f"{name}: {tok} has {len(pairs)} designed null(s) and NONE is both-hung "
                          f"— the strongest thing a room can show is missing")
    print(f"  {name:<34}{len(placed):>3} placed, {configured:>3} configured, "
          f"{len(seen_vals)} axes varied, {len(faults)} fault(s)")
    return faults


def main() -> int:
    entries = load_registry()
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if "--all" in sys.argv:
        args = sorted(p.parent.name for p in MAPS.glob("Museum_AAA_*/map_data.json"))
    if not args:
        print(__doc__); return 2
    all_faults = []
    print(f"checking {len(args)} room(s) against the registry\n")
    for name in args:
        all_faults += check_map(name, entries, hang=("--hang" in sys.argv))
    print()
    for f in all_faults:
        print("  FAULT " + f)
    print(f"\n{len(all_faults)} fault(s) across {len(args)} room(s)")
    return len(all_faults)


if __name__ == "__main__":
    raise SystemExit(main())
