# Utility-layer operators — the alphabet for auto-derived structure

> **What this is.** The utility layer carries more than teleporters and spawn
> markers. `@`-prefixed tokens in the utility layer are **operators** that
> modify the structure layer when it's auto-derived. Together with artifact
> footprints and spawn/teleporter pathfinding, they form the inputs the
> auto-structure pipeline uses to compute the heightmap.
>
> **Why.** Hand-painted structure is fragile — move an artifact and the
> walls are now wrong; switch a map's recipe and the floor is arbitrary.
> Declarative operators let the structure layer be a **function of the
> semantic inputs**, not a manually maintained artifact.

## Mental model

```
USER EDITS (semantic)              DERIVED
─────────────────────              ──────────
Utilities layer:                   Structure layer
  sp                       ───►    (heightmap that
  t                                 satisfies every
  @pit:3                            constraint and
  @platform:2                       applies every
Interactables:                      operator)
  each with footprint
```

The user never paints structure directly. They paint:
- **spawn (`sp`) and teleporter (`t`)** — path endpoints
- **artifacts** — each with a declared footprint (via `spine_hints()`)
- **operators** — optional `@`-prefixed utility tokens for local modification

The pipeline computes the structure heightmap from these inputs.

## The operator alphabet

All operators are utility-layer tokens starting with `@`. The general form is:

```
@code:param1:param2:...:W:D
```

Where the trailing two numeric args (when present) are the footprint width and
depth the operator claims. If absent, footprint defaults to `1×1`.

### Existing operators (implemented today)

These are consumed by `enforceAnnotations()` in `/api/game/auto-structure`:

| Token        | Effect |
|--------------|--------|
| `@void`      | Forces cells in footprint to `"0"` (empty, non-walkable). Creates negative space. |
| `@hold`      | Preserves pre-generation value for cells in footprint. Shields them from the generator. |
| `@sample`    | Same as `@hold` — locked reference cell. |
| `@signature` | Forces cells to walkable `"1"`. Declares "an artifact lives here regardless of recipe." |
| `@must`      | Same as `@signature` — hard walkability constraint. |

### New operators (proposed — to ship next)

These extend the alphabet so the structure layer can be **fully derived** from
semantic inputs:

| Token           | Effect |
|-----------------|--------|
| `@pit:D`        | Subtract `D` units of height. Creates a depression; if current cell is `"1"` and D≥1, becomes `"0"` (void). |
| `@platform:H`   | Set cells to exactly height `H` (floor value `"H"`). Creates a raised walkable platform. |
| `@wall:H`       | Set to height `H` (≥2), marked non-walkable. Creates a blocker. |
| `@floor`        | Set to height `"1"`. Explicit "make walkable" — redundant with `@must` but reads clearer. |
| `@h:N`          | Set to exactly height `"N"`. Escape hatch for arbitrary heights. |
| `@bridge`       | Carve walkable across void. Used by `island_chain` recipe to connect islands. |
| `@path`         | Hint to pathfinder: prefer routing through these cells. Doesn't force walkability on its own. |

### Operator ordering

Operators apply **after** the recipe fills the baseline floor, so they can
override the recipe locally. Apply order within the same pass:

1. `@must` / `@signature` (force walkable — protect artifact cells)
2. `@floor` / `@h:N` (set heights)
3. `@platform:H` (set specific heights for platforms)
4. `@wall:H` (raise walls)
5. `@pit:D` (subtract)
6. `@bridge` (carve walkable over void, applied last so it can punch through walls)
7. `@void` (force empty — highest priority)
8. `@hold` / `@sample` (restore pre-generation state)

Then a validation pass re-runs pathfinder: if sp→t is no longer reachable,
the result is flagged as invalid and the UI warns.

### Motion utilities → synthetic operators

Utility codes that move things through space have **implicit clearance
requirements** — the cells the thing travels through must exist as the right
kind of cell, or the runtime won't work. Rather than special-case these in
the generator, they translate to synthetic `@`-operators at parse time:

| Utility     | Meaning                                   | Translates to                               |
|-------------|-------------------------------------------|---------------------------------------------|
| `tc:N:axis` | Transport cube travels `N` cells along `axis` | `N × @void` along the transit path — the cube needs empty space to slide through |
| `br:N:axis` | Bridge spans `N` cells along `axis`       | `N × @floor` along the path — bridge creates walkway |

Axis is one of `x`, `-x`, `z`, `-z` for horizontal, or `y` for vertical.
Vertical motion (`y`) produces no horizontal footprint and is skipped.

Example: `tc:3:z` placed at `(5,1)` emits synthetic `@void` annotations at
`(5,2)`, `(5,3)`, `(5,4)` — the corridor the cube traverses stays void and
the generator can't fill it with floor or wall. This is how
`Trans_Translation` gets its long void channels for free.

## Full pipeline (what runs when you edit)

```
1. START       empty grid — structure all ""

2. FOOTPRINTS  for each interactable, read its spine_hints().footprint,
               claim those cells as walkable ("1")

3. PATH        BFS/A* from sp to t through currently-walkable cells;
               if no path exists, widen the lane to connect claims

4. RECIPE      fill remaining cells per the sequence's structure_recipe
               (flat_corridor, platform_over_pit, island_chain, etc.)

5. OPERATORS   apply @-prefixed utility tokens in the order above

6. VALIDATE    re-run pathfinder. If sp→t still walkable AND every
               footprint cell still walkable: commit. Else: flag issue.
```

At every step an invariant holds: **every cell required by a footprint or
the path is walkable, regardless of recipe or operators**.

## Why these operators, and not others

The alphabet is small on purpose. Each operator answers a specific local
question about the map:

- "Do I want this cell to be impassable?" → `@void` or `@wall:H`
- "Do I want this cell higher?" → `@platform:H` or `@h:N`
- "Do I want this cell lower?" → `@pit:D`
- "Do I want this cell walkable even though the recipe says otherwise?" → `@must`
- "Do I want to cross a void the recipe created?" → `@bridge`

If you need something beyond these, the right answer is usually a different
**recipe**, not a new operator.

## UI implications

With derived structure as the default:

- The **Structure tab** becomes a read-only preview showing the computed
  heightmap, with optional overlay of which cells came from which operator.
- **Painting happens on the Utilities and Interactables tabs.** That's where
  semantic meaning lives.
- The **Structure recipe** is a top-level map setting (or inherited from
  `spine_styles.json`), not a per-cell choice.
- A **"Manual structure override"** toggle exists for the legacy case — maps
  that were hand-painted before the operator system — but is off by default.

## Relationship to `spine_hints()`

`spine_hints()` declares what an artifact needs (footprint, approach, reading
distance). Operators declare what the **map** needs (a pit here, a platform
there). Together with the sequence-level recipe, they fully describe the map
in a human-authorable, machine-computable form.

Artifact contract:
```gdscript
func spine_hints() -> Dictionary:
    return {
        "footprint":   Vector2i(2, 2),
        "approach":    "south",
        ...
    }
```

Map contract (utilities + interactables JSON):
```json
"utilities": [
  ["","sp","","","","","",""],
  ...
  ["","@pit:3:3:2","","","","","",""],     ← 2×2 pit 3 deep
  ...
  ["","@platform:2:1:1","","","","","",""] ← 1×1 platform at height 2
]
```

Structure layer: **derived**, not authored.

## Migration path

Today's maps use the existing `@void` / `@hold` / `@sample` / `@signature` /
`@must` set. That keeps working. New operators (`@pit`, `@platform`, `@wall`,
`@bridge`, `@h:N`, `@floor`) are additive — maps that don't use them see no
change.

The incremental rollout:

1. **Today**: add the new operator cases to `enforceAnnotations()` in the
   auto-structure API. (~1 hour)
2. **Next**: surface them in the voxel-editor's palette as authorial codes.
3. **Next**: refactor `autoStructure()` into the named pipeline steps
   (footprints → path → recipe → operators → validate), each testable alone.
4. **Next**: flip the voxel-editor's Structure tab to read-only "derived"
   mode by default, with a manual-override escape hatch.
5. **Next**: spine_corridor_generate.py emits these operators instead of
   cell-by-cell structure. The perturbation step of evolution becomes "add
   / remove / move an operator" — a semantically meaningful search space.

## Open questions (for later)

- Should operators compose? (e.g. `@platform:2` inside `@pit:3` — who wins?)
  Current proposal: by order of application, last one wins. The UI should
  visualize this.
- Should operators have a "soft" variant? (e.g. `@prefer_pit` — the generator
  tries to honor it but can relax if pathfinding fails.) Tempting, but
  complicates reasoning. Defer until we see real cases.
- Should the operator list live on the utility layer or its own 4th layer?
  Current proposal: utility layer, with the `@` prefix keeping the namespace
  clean. Simpler.
