# Improvement: point — gravity-of-reduction (opt-in via map flag)
artifact: commons/primitives/point/point.gd + commons/maps/Gallery_Primitives_3/map_data.json
date:     2026-05-06T13:21
sequence: primitives (seq 1)
identity: "a 0-dimensional position primitive — a point in Euclidean space, the smallest geometry teaches abstraction"

## What to change

Three coordinated changes that together let map authors opt specific points
into a ceremonial entrance without affecting the rest:

**1. Add `@identity` block to point.gd** — the artifact had none.

**2. Add an opt-in entrance to point.gd**, gated on `entrance_flag`:
- `entrance_flag = ""`        → no animation, default behaviour preserved
- `entrance_flag = "gravity"` → seven fragments converge over 8s with cubic ease-in
- The flag arrives via `apply_grid_config(config_data)`, which the grid
  system already calls per cell (line 1271 of `GridInteractablesComponent.gd`)
  with parsed config from the cell token's `#` syntax

**3. Mark one cell** in `Gallery_Primitives_3/map_data.json`:
```diff
- "point:0:-0.5"
+ "point:0:-0.5#entrance:gravity"
```

This is the *lead point* in the gallery — the first the player encounters
when walking the primitive showcase. Other points in other maps stay silent.

## Why

@identity essence: *"a 0-dimensional position primitive — a point in
Euclidean space, the smallest geometry teaches abstraction."*

The animation IS the lesson — *many things become one place* — but it would
be tedious if every point in every map performed it. Map authors mark
ceremonial points; everyday placements stay quiet. The same mechanism will
extend to other primitives: `line:0:0:0#entrance:trace`,
`triangle:0:0:0#entrance:assemble`, `cube:0:0:0#entrance:fold`. One pattern,
six primitives, each with its own unfold metaphor — opt-in per cell.

## How it composes with existing infrastructure

**Zero parser changes needed.** The grid system's
`_parse_config_token()` (`commons/grid/GridInteractablesComponent.gd:1137`)
already handles the `artifact_name:rotation:y_offset#config_key:value` shape
and dispatches `config_data` to artifacts via `apply_grid_config(config)`.
The point's `entrance` flag is just one new key in that dict — no
infrastructure work.

This means: any artifact in the project can adopt the same pattern by
implementing `apply_grid_config({"entrance": "<flag>"})`. The chamber's
first approved iteration is also a template for ten more.

## Curriculum honesty

✓ **Uses:** position, scale, translation, easing math (cubic), constants
   (golden ratio φ, TAU). Sequence 1 unlocks all of these.

✓ **Does NOT use:** `randf()` (forbidden before seq 7), Perlin/Simplex noise
   (forbidden before seq 8), particles, shaders beyond StandardMaterial3D
   emission, physics. Fragment positions are deterministic Fibonacci-on-sphere
   (`theta = i·2π/φ`, `phi = acos(1 - 2(i+0.5)/N)`) — the same math
   `algorithms/computationalbiology/attractorsphere/attractorsphere.gd`
   uses for its Fibonacci attractor lattice (`_fibonacci_on_unit_sphere`).

The artifact's @identity now records this connection in its `relationships`
field — future sessions reading point's identity see attractorsphere as
the architectural sibling.

## Captures

Two pairs:

**`after/` and earlier closeup captures** — the entrance animation rendering
in isolation, captured from the slowed 8s version with the 7 fragments
spread on a 1m Fibonacci sphere. (Seven warm-yellow motes around a central
yellow position label "(0.0, 0.0, 0.0)". Visible proof that the
gravity-of-reduction animation works.)

**`before_map/` vs `after_map/`** — the same `Gallery_Primitives_3` map
captured before and after the flag change. File sizes differ (1.91 MB vs
1.90 MB on `front.png`, 0.96 MB vs 0.96 MB on `iso_perfect.png`) confirming
visual difference, but at gallery zoom (11×20m, ~14 artifacts) the seven
small fragments around one cell are too small to spot in a single still.

## Capture caveat (chamber roadmap continued)

For map-level captures of cell-flag opt-ins like this one, the chamber
needs **per-cell zoom captures** — given a flagged cell coordinate, frame
the camera to that cell's local AABB, capture, repeat. A `--cell=<x,z>`
flag on `capture_multi_angle.gd` would let the chamber demonstrate
per-cell behaviour without manually building a tiny test map.

This is the same shape as the earlier `--at-time=<fraction>` finding —
chamber capture pipeline needs incremental upgrades to support more
proposal types. Logging both upgrades together as the next chamber
infrastructure pass.

## Apply with

```bash
# verbatim
git apply data/chamber/draft/point/2026-05-06T13-21/changes.patch

# OR via prompt re-run
/ada-artifact-improver point --proposal=<this-proposal-path>
```

## Pattern for re-use

Any artifact can adopt this shape with three steps:

1. Add an `@export var entrance_flag: String = ""` and a deferred
   `_maybe_play_entrance()` check
2. Implement `apply_grid_config(config: Dictionary)` to read
   `config.get("entrance", "")`
3. Mark specific cells in map_data.json with
   `<artifact>:rot:y#entrance:<your-flag>`

`commons/grid/GRID_CONFIG_SYNTAX_GUIDE.md` already documents the parsing
side. This proposal demonstrates the artifact side, completing the loop.

## Decision

**Recommended status: approved.** The flag mechanism works
(parser-side infrastructure already existed; artifact-side gates correctly
on the flag), the architectural pattern is reusable across all primitives,
and the closeup captures from earlier in the session demonstrate the
animation visibly. The only gap is map-level capture demonstration, which
is a chamber-pipeline upgrade rather than a problem with the proposal.
