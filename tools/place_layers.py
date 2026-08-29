"""place_layers.py — run any placement strategy over a map-builder DRAFT.

2026-08-27, Palle: "explore other algorithms for placement of artifact like
crystallization, stickyness, colonization" — the strategies exist (twenty in
placement_research.STRATEGIES, the nature trio landed with `the museum places by
the algorithms it teaches`), but every entry point wanted a SAVED map. The
map-builder edits layers in memory, so this is the layers-in / layers-out lane:

  python tools/place_layers.py --in draft.json            # place, print result JSON
  python tools/place_layers.py --list                     # strategy names, one per line

Input JSON: { "layers": {structure, utilities, interactables}, "strategy": "...",
  "seed": 0, "tokens": ["a","b"]? }
- tokens omitted -> the draft's own placed artifacts are lifted and RE-placed by
  the strategy (the builder's "re-place what I have" flow).
- tokens given   -> those are placed INSTEAD (the "fill this room" flow); the
  draft's interactables are cleared first.

Output JSON: { "ok": true, "strategy": ..., "interactables": grid,
  "placements": [{token,row,col}], "skipped": [tokens the room refused],
  "unknown": [tokens absent from the registry] }

The Room is built by place_artifacts.room_from_map on a SYNTHESIZED map_data —
one implementation of the room reading, not a second one that drifts (the
long_museum scar). Artifacts come from artifact_from_registry, so footprints and
clearances are the registry's word, not a guess.
"""
from __future__ import annotations
import json
import random
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from placement_research import STRATEGIES, Artifact  # noqa: E402
from place_artifacts import room_from_map, artifact_from_registry  # noqa: E402

_TOKEN_REG: dict | None = None


def _token_registry() -> dict:
    """Token-keyed registry scan. place_artifacts.load_registry collects entries
    that CARRY a lookup_name field - the older convention - so 2026-08 entries
    (token-keyed, no lookup_name inside) come back None from it. This is the
    fallback that reads the registries the way they are actually keyed."""
    global _TOKEN_REG
    if _TOKEN_REG is not None:
        return _TOKEN_REG
    import glob
    reg: dict = {}
    base = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                        "commons", "artifacts", "registry")
    for f in glob.glob(os.path.join(base, "*.json")):
        try:
            d = json.load(open(f, encoding="utf-8"))
        except Exception:
            continue
        for t, e in (d.get("artifacts") or {}).items():
            if isinstance(e, dict) and t not in reg:
                reg[t] = e
    _TOKEN_REG = reg
    return reg


def artifact_any(token: str):
    a = artifact_from_registry(token)
    if a is not None:
        return a
    e = _token_registry().get(token)
    if not e:
        return None
    sn = e.get("spatial_needs", {}) or {}
    return Artifact(lookup_name=token,
                    footprint_cells=int(sn.get("footprint_cells", 1)),
                    clearance_front=1, clearance_back=1,
                    clearance_left=1, clearance_right=1,
                    player_position=str(sn.get("player_position", "front")),
                    wall_backing=bool(sn.get("wall_backing", False)),
                    orientation=str(sn.get("orientation", "face_approach")),
                    isolation=int(sn.get("isolation", 0)))


def draft_to_map_data(layers: dict) -> dict:
    """Wrap builder layers in the minimal map_data shape room_from_map reads."""
    structure = layers.get("structure") or []
    depth = len(structure)
    width = len(structure[0]) if depth else 0
    return {
        # room_from_map reads dimensions.DEPTH; the builder and most maps say
        # "height". Emit both, or a 34-row draft becomes a 6-deep room and the
        # strategies place onto what they believe is interior (measured: a wall).
        "map_info": {"name": "_draft", "dimensions": {"width": width, "height": depth, "depth": depth}},
        "layers": {
            "structure": structure,
            "utilities": layers.get("utilities") or [["" for _ in range(width)] for _ in range(depth)],
            "interactables": layers.get("interactables") or [["" for _ in range(width)] for _ in range(depth)],
        },
    }


def tokens_in_draft(layers: dict) -> list[str]:
    out: list[str] = []
    for row in layers.get("interactables") or []:
        for cell in row:
            cell = str(cell).strip()
            if cell and cell != "0":
                out.append(cell.split(":")[0].split("#")[0])
    return out


def main() -> int:
    if "--list" in sys.argv:
        for name in sorted(STRATEGIES.keys()):
            print(name)
        return 0
    in_path = None
    for a in sys.argv[1:]:
        if a.startswith("--in="):
            in_path = a.split("=", 1)[1]
    if not in_path:
        print(__doc__)
        return 2
    req = json.load(open(in_path, encoding="utf-8"))
    layers = req.get("layers") or {}
    strategy = str(req.get("strategy") or "hybrid")
    seed = int(req.get("seed") or 0)
    if strategy not in STRATEGIES:
        print(json.dumps({"ok": False, "error": f"unknown strategy {strategy}",
                          "strategies": sorted(STRATEGIES.keys())}))
        return 1

    tokens = req.get("tokens") or tokens_in_draft(layers)
    map_data = draft_to_map_data(layers)
    room, _sp, _tp = room_from_map(map_data)

    artifacts = []
    unknown: list[str] = []
    for t in tokens:
        a = artifact_any(t)
        if a is None:
            unknown.append(t)
        else:
            artifacts.append(a)

    rng = random.Random(seed)
    placements = STRATEGIES[strategy](room, artifacts, rng)

    depth = len(map_data["layers"]["structure"])
    width = len(map_data["layers"]["structure"][0]) if depth else 0
    grid = [["" for _ in range(width)] for _ in range(depth)]
    placed_tokens: list[str] = []
    rows_out = []
    for p in placements:
        r, c = int(p.row), int(p.col)
        if 0 <= r < depth and 0 <= c < width and not grid[r][c]:
            grid[r][c] = f"{p.artifact.lookup_name}:0:1"
            placed_tokens.append(p.artifact.lookup_name)
            rows_out.append({"token": p.artifact.lookup_name, "row": r, "col": c})
    skipped = [a.lookup_name for a in artifacts if a.lookup_name not in placed_tokens]

    print(json.dumps({"ok": True, "strategy": strategy, "seed": seed,
                      "interactables": grid, "placements": rows_out,
                      "skipped": skipped, "unknown": unknown}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
