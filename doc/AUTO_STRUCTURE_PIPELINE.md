# Auto-structure pipeline

> What `/api/game/auto-structure` actually does when you click "auto-structure"
> in the voxel editor. Enumerated so the rules are visible and debuggable.

## Inputs

| Input | Source | Role |
|---|---|---|
| `width`, `depth` | map layer dimensions | grid size (cells) |
| `artifacts[]` | interactables layer | positions + `spatial_needs` per artifact |
| `spawn` | utilities layer `sp` | start of required path |
| `teleporter` | utilities layer `t` | end of required path |
| `anchors[]` | utilities layer `A` | "must be reachable" cells |
| `annotations[]` | utilities layer `@...` **plus** synthetic ops from motion utilities | operator overrides (see UTILITY_OPERATORS.md) |

**Synthetic annotations from motion utilities.** Before sending the request,
the voxel editor parses `tc:N:axis` and `br:N:axis` utilities and emits
synthetic `@void` / `@floor` annotations along each transit path. This keeps
the pipeline ignorant of utility semantics — everything is an `@`-operator
by the time the server sees it. See UTILITY_OPERATORS.md § "Motion
utilities → synthetic operators".
| `mode` | UI dropdown | `corridor` \| `room` \| `ring` \| `branch` \| `grid` \| `open` \| `astar` |
| `padding`, `corridorWidth`, `temperature` | UI | tuning knobs |

## Rule #1 (pre-pipeline): preserve authored cells

The structure layer is authored too. Where the author drew a non-default
cell, and nothing else claims it, that cell stays. Two sub-rules:

- **1a — Preserve void.** Every `"0"` cell not otherwise claimed gets a
  synthetic `@void` annotation. Stops the corridor carver from tunneling
  through handcrafted void channels (e.g. Trans_Translation rows 17-18,
  the transport-cube crossing).

- **1b — Preserve heights ≥ 2.** Every cell with value `N ≥ 2` not
  otherwise claimed gets a synthetic `@h:N` annotation. Preserves
  threshold walls, rhythm rows, and other architectural features not
  tied to an artifact's `wall_backing` (e.g. Point_Lines rows 6-7 H4
  gate towers, row 12 H3/H2 rhythm).

Height `1` (default floor) is **not** preserved — it's the recipe's
normal output and locking it would make re-generation a no-op.

"Claimed" means: artifact footprint, utility code (spawn, teleporter,
anchor, `tc:N:axis`, `br:N:axis`, `wp`, etc.), or a positive `@`-operator
(`@must`, `@floor`, `@platform:N`, `@h:N`, `@wall:N`, `@bridge`, `@path`,
`@sample`, `@hold`). Where something else claims the cell, that claim
takes precedence over preservation.

The existing annotation-enforcement pass (step 7) applies the synthetic
ops at the correct priority (`@void` = 7, `@h` = 2), so the generator
runs freely through intermediate steps and authored features are
restored at the end.

**Request flags:**
- `preserveOriginalVoid: true` (default) — master switch for the whole rule
- `utilityCells: Point[]` — positions of all utility codes, so rule #1
  knows what's claimed

Pass `preserveOriginalVoid: false` for blank-slate generation. The rule
is also skipped automatically when the original structure has < 5%
non-void cells.

**Response field:** `preserved_void_cells: number` — total synthetic
annotations emitted (both @void and @h combined).

## Pipeline — corridor/room mode (default)

```
1. ZONE PADDING
   For spawn, teleporter, and each A anchor, set cells in a
   ±padding square around them to walkable "1".

2. MST + CARVE (the "corridor connects" step)
   positions = [spawn, teleporter, ...artifacts, ...anchors]
   Build a minimum spanning tree connecting every position.
   For each tree edge, carve a corridor of width `corridorWidth` between
   the two endpoints using walkable "1" cells.
   → after this step, spawn is guaranteed reachable from teleporter
     through the artifacts.

3. BORDERS
   Set perimeter cells (row=0, col=0, row=depth-1, col=width-1) to "2"
   (non-walkable wall). Players stay inside the map frame.

4. SEED PADS (per artifact)
   For each artifact with `spatial_needs`:
     - Footprint (radius from footprint_cells): stamp walkable "1"
       (or "2" for table/pedestal platforms, "0" for sunken).
     - Clearance (front/back/left/right): force "1" on cells in those
       directions, but SKIP cells that are already "1" or "0".
     - Wall backing: place a wall at (art.z - radius - 1). Height comes
       from `spatial_needs.wall_backing`:
         • `false` (default) → no wall
         • `true`            → height 2 (standard backdrop)
         • `number ≥ 2`      → exact height (e.g. 3 for an extra-tall
                               gallery wall, useful for oversized artifacts)
       Still SKIPS cells already "1" (carved corridor) to avoid capping
       the player's path.

5. TELEPORTER VOID
   Force `grid[teleporter.z][teleporter.x] = "0"` — the teleporter renders
   as a portal over void; the player walks into it from an adjacent cell.

6. SPAWN WALKABLE
   Force `grid[spawn.z][spawn.x] = "1"` — player spawns here.

7. RE-CARVE spawn→teleporter (2026-04-22 fix)
   After step 4 may have reshaped the grid, carve a direct corridor from
   spawn to the cell adjacent to the teleporter. Width = max(1, corridorWidth - 1).
   Guarantees the player can walk from spawn to teleporter even after
   wall_backing / seedPads interference.

8. ENFORCE ANNOTATIONS (see UTILITY_OPERATORS.md)
   Apply user's @-prefixed operator overrides last:
     @void, @hold, @sample, @signature, @must, @floor, @h, @platform,
     @wall, @pit, @bridge. Order matters — see the alphabet doc.
```

## Pipeline — other modes

- **open**: fill interior with "1", perimeter with "2". No MST, no corridors.
  Everywhere-walkable except the border.
- **ring**: MST replaced with ring — connects positions in a loop.
- **branch**: tree topology from spawn outward.
- **grid**: regular 3-cell spaced grid points, then connect anchors to
  nearest grid point.
- **astar**: completely different algorithm — cost grid + A* search with
  attractors (anchors) and repellers (artifact zones).

## Things you should expect to see

- **Every artifact has a visible footprint platform** (step 4)
- **Spawn and teleporter are connected** (step 2 + 7 after fix)
- **Map is enclosed by walls** (step 3)
- **Teleporter cell reads as void**, not walkable (step 5) — player walks
  onto adjacent cell, which triggers the teleport area
- **Sunken platforms (e.g. pits) are void** under the artifact anchor
- **Your @-operators always win** (step 8)

## Known behaviors that can look like bugs

- **Tiny corridors (`corridorWidth=1`) feel claustrophobic.** Raise in the UI
  slider if the default reads too tight.
- **Wall backing on an artifact between spawn and teleport used to block the
  path.** Fixed via two mechanisms: skip-if-walkable in step 4, re-carve
  in step 7.
- **Teleporter on row 0 or near a border**: step 3 adds a perimeter wall.
  Place the teleporter at least one cell inside the border, or use
  `@signature` to override.
- **Artifact with `footprint_cells: 5` and asymmetric clearance**: the
  artifact claims up to 7×7 cells. If that doesn't fit in your map, content
  spills into adjacent zones. Shrink the footprint or expand the map.

## How to debug what the generator did

The API response includes:
```json
{
  "structure": [[...]],
  "stats": { "floor": N, "wall": M, "void": V },
  "mode": "corridor",
  "annotations_enforced": { ... }
}
```

For richer tracing (per-step snapshot), add `?trace=1` to the POST body.
(See also `/api/voxel-editor?action=validate` for post-hoc analysis.)

## Surfacing in the editor UI

Each step corresponds to a rule a human would want to see:

| Step | Surface in editor |
|---|---|
| 1 | hidden — minor floor prep |
| 2 | hidden — the core "corridor carve" |
| 3 | visible — perimeter walls |
| 4 | **visible via per-artifact footprint preview** (Inspector tab) |
| 5 | visible — teleporter cell shows as void + portal |
| 6 | visible — spawn shows green marker |
| 7 | hidden — the corridor-preserving re-carve |
| 8 | **visible — every @-operator in the utility layer** |

## Related docs

- [`UTILITY_OPERATORS.md`](./UTILITY_OPERATORS.md) — the `@`-prefixed alphabet
- [`SPINE_HINTS_CONTRACT.md`](./SPINE_HINTS_CONTRACT.md) — artifact-level declarations
- [`MAP_BUILDING_GUIDE.md`](./MAP_BUILDING_GUIDE.md) — authoring conventions
