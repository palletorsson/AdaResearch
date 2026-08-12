#!/usr/bin/env python3
"""One palette for every spatial diagnostic — the encyclopedia's own.

`/template-pattern-editor`, `/template-gallery`, `/template-maps` and
`/template-lab` all colour cells from ONE table:
`ada_encyclopedia/src/lib/template-patterns.ts -> ROLES`. A Python diagnostic
that invents its own scheme makes the same room look like two different rooms
depending on which tool drew it — which is the same fault this whole pass has
been chasing in the data, only in pixels.

So this READS the TypeScript at run time and falls back to a mirror of it when
the sibling checkout is absent. `check()` reports drift rather than letting the
two quietly diverge.

The overlay hues on top are the ones `doc/PLACEMENT_NEGOTIATION.md` declares —
magenta body, cyan hard zone, amber preferred — lifted for a dark ground.

    python tools/spatial_palette.py            # print the palette
    python tools/spatial_palette.py --check    # drift against the TypeScript
"""
from __future__ import annotations

import argparse
import re
from functools import lru_cache
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
ROLES_TS = (REPO.parent / "ada_encyclopedia" / "src" / "lib"
            / "template-patterns.ts")

#: Mirror of ROLES, used when the encyclopedia checkout is not beside us.
#: Kept in the same order the editor lists them.
FALLBACK_ROLES: dict[str, str] = {
    "":   "#0b0b0e",   # void
    "1":  "#3d4451",   # floor
    "1s": "#4d6b4d",   # floor slot
    "2":  "#5a5a66",   # platform
    "2s": "#7a5c2e",   # podium slot
    "3s": "#8a5c7a",   # high podium slot — the hero
    "4":  "#565672",   # wall
    "1f": "#3f7a44",   # floor + flora seed
    "1u": "#5f4a7a",   # floor + fungus seed
    "1m": "#26262e",   # floor + mute
}

#: Ground the tiles sit on, and the two text greys the corpus sheet uses.
GROUND = "#101114"
INK = "#c8cad2"
INK_DIM = "#787a82"

#: The declared negotiation overlay, brightened to read on a dark ground.
#: Semantics are fixed by doc/PLACEMENT_NEGOTIATION.md; only the values move.
BODY = "#e83fb8"        # magenta — occupied body
CIRCULATION = "#2ad4e2"  # cyan — hard zone, must stay reachable
PRESENTATION = "#f0a83c"  # amber — preferred zone, may be traded
ROUTE = "#2f4f74"        # the protected through-route
SIGHT = "#2ad4e2"        # a line of sight is a claim about reachability
DOOR = "#f0a83c"
ACCENT = "#8a5c7a"       # the hero mauve, for anything singular


@lru_cache(maxsize=1)
def roles() -> dict[str, str]:
    """ROLES as the encyclopedia defines it, or the mirror."""
    if not ROLES_TS.exists():
        return dict(FALLBACK_ROLES)
    try:
        text = ROLES_TS.read_text(encoding="utf-8")
    except Exception:
        return dict(FALLBACK_ROLES)
    out: dict[str, str] = {}
    for code, colour in re.findall(
            r'code:\s*"([^"]*)"\s*,\s*label:\s*"[^"]*"\s*,\s*color:\s*"(#[0-9a-fA-F]{6})"',
            text):
        out[code] = colour
    return out or dict(FALLBACK_ROLES)


def cell_colour(code: str) -> str:
    """Colour for one map cell-role token."""
    return roles().get(str(code), FALLBACK_ROLES.get(str(code), "#1a1a20"))


def check() -> int:
    """Report drift between the TypeScript and the mirror."""
    live = roles()
    if not ROLES_TS.exists():
        print(f"encyclopedia not beside this checkout ({ROLES_TS}) — using the mirror")
        return 0
    drift = [(k, FALLBACK_ROLES.get(k), v) for k, v in live.items()
             if FALLBACK_ROLES.get(k) != v]
    missing = [k for k in FALLBACK_ROLES if k not in live]
    for k, was, now in drift:
        print(f"  DRIFT {k!r}: mirror {was} -> encyclopedia {now}")
    for k in missing:
        print(f"  GONE  {k!r} is in the mirror but not in ROLES any more")
    if not drift and not missing:
        print(f"palette agrees with {ROLES_TS.name} ({len(live)} roles)")
    return len(drift) + len(missing)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    if args.check:
        return 1 if check() else 0
    src = "encyclopedia" if ROLES_TS.exists() else "mirror"
    print(f"cell roles (from the {src}):")
    for code, colour in roles().items():
        print(f"  {code!r:6s} {colour}")
    print("\noverlay (doc/PLACEMENT_NEGOTIATION.md, lifted for dark ground):")
    for name, colour in (("body", BODY), ("circulation", CIRCULATION),
                         ("presentation", PRESENTATION), ("route", ROUTE),
                         ("door", DOOR), ("ground", GROUND)):
        print(f"  {name:13s} {colour}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
