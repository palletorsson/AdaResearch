# Paint Layers

> The biome as a stack of painted layers. One principle, repeated:
> **`element × distribution × density`**. Per map. Eventually VR-editable.
>
> Status (2026-06-05): **Steps 1–4 landed** — schema + distribution engine wired
> into the population spawn layers; walkable `ground` substrate + `shader` colour
> overlay + plant bleed; desktop scrubber + VR Tilt-Brush catalyst stone; and
> **sequence accrual** (a map builds on the maps before it). Opt-in / additive
> throughout — a map with no `paint_layers` is unchanged.

## The model

Every layer is the same shape. Only the `element` changes:

```
element       what it places / modulates          engine (today)
───────────   ─────────────────────────────────   ──────────────────────
ground        heightfield / bump → walkable mesh   ground_substrate    ✅ wired (default-on, flat)
shader        paint a colour into the ground tex    ground_substrate    ✅ wired (paint + plant bleed)
particle      CPU/GPU particle field                — (later)
object        any artifact, by density              biome_paint_dispatcher (infra-heavy, TODO)
flower        flowers                               softbody_flora      ✅ wired
mushroom      earthy/toadstool softbodies           softbody_flora      ✅ wired
tree          L-system trees                        lsystem_trees       ✅ wired
critter       small DNA creatures                   dna_creatures       ✅ wired
large_critter big DNA creatures (≈3× scale)         dna_creatures       ✅ wired
```

9 named layers, but only ~4 distinct **engines**: three substrate fields
(height, shader, particle) and one population engine, parameterised by element.
The population engine is the accrual spawn layers we already have — paint layers
just give them an authored **distribution** instead of the default perimeter ring.

## Where it lives

A map opts in with a top-level `paint_layers` array in its `map_data.json`:

```json
{
  "map_info": { ... },
  "layers": { "structure": [...], "utilities": [...], "interactables": [...] },
  "paint_layers": [
    { "element": "tree",    "mode": "noise",  "scale": 0.18, "threshold": 0.45, "density": 0.6 },
    { "element": "flower",  "mode": "curve",  "axis": "radial", "falloff": "ring", "density": 0.8 },
    { "element": "critter", "mode": "random", "density": 0.3, "max": 24 }
  ]
}
```

**Opt-in & additive:** a map with no `paint_layers` behaves exactly as before
(the population layers use their default ring). A paint layer for an element
*replaces* that element's default placement for this map.

You may have **several layers for the same element** (e.g. a noise grove + a
hand-brushed cluster of trees) — their placements union.

## One layer = one entry

All keys are **flat** on the layer entry (no nested objects — keeps the engine
and the eventual editor simple):

| field | type | meaning |
|-------|------|---------|
| `element` | string | which engine: `tree` `flower` `mushroom` `critter` `large_critter` `object` `ground` `shader` `particle` |
| `mode` | string | distribution: `plane` · `random` · `curve` · `noise` · `brush` |
| `density` | float 0..1 | the master dial — how much |
| `max` | int (optional) | hard ceiling on placements (default 160), scaled by `budget_scale` |
| _mode params_ | — | flat on the entry (`scale`, `threshold`, `axis`, `falloff`, `invert`, `brush`) — see below |
| `params` | dict (optional) | element-specific (e.g. `{ "artifact": "pyramid_edit" }` for `object`) |

### Distribution modes

| mode | extra fields | character |
|------|-------------|-----------|
| `plane` | — | regular lattice; spacing from `density` (dense → step 1, sparse → 5). The grid aesthetic. |
| `random` | — | stochastic scatter; count ∝ `density`. Jittered, natural. |
| `curve` | `axis` (`x`/`z`/`radial`), `falloff` (`smooth`/`linear`/`sharp`/`ring`), `invert` | density varies across the map — gradients, rings, edges. |
| `noise` | `scale` (freq), `threshold` (0..1) | FastNoiseLite field; organic clumps and clearings. |
| `brush` | `brush` (2D `grid_d × grid_w` array, or flat, of 0..1) | the hand-painted field. This is what the desktop painter and the VR brush write. |

All modes are **deterministic** from the map's `rng_seed` — same map, same biome,
every launch. (Brush is data, so trivially deterministic.)

## Engine

`commons/biome_layers/distribution_field.gd` (`class_name DistributionField`).

- `build_field(spec, grid_w, grid_d, rng_seed) → PackedFloat32Array` — the per-cell
  density field [0..1]. Substrate layers (height/shader/particle) will consume
  this directly.
- `placements(spec, grid_w, grid_d, cube_size, rng_seed, budget) → Array[Vector3]`
  — world positions on the grid floor for the population layers.
- `placements_for(ctx, element) → Array[Vector3]` — union across all matching
  paint layers in `ctx.paint_layers`. A spawn layer calls this; non-empty → use
  it instead of the default ring.

## How it threads through

```
map_data.json  paint_layers[]
   → GridDataComponent.get_paint_layers()
   → GridSystem._handle_biome_ring()  (adds "paint_layers" to the accrual ctx)
   → BiomeAccrualManager.apply()      (copies it into each layer's ctx)
   → lsystem_trees / dna_creatures / softbody_flora
        → DistributionField.placements_for(ctx, "<element>")
```

The accrual stack stays the **single populator**; paint layers are per-map
authoring that the existing spawn layers consult. No second populator.

## Inspect (desktop)

The biome scrubber renders paint layers, so you can see a distribution before
committing it to a map. A loaded map's own `paint_layers` render automatically;
or inject one for a quick test:

```
godot --path . res://commons/biome_layers/BiomeScrubberDesktop3D.tscn -- \
  --stage=11 --paint=tree:plane:0.6 --solo=lsystem_trees
```

`--paint=element:mode:density[:scale:threshold]` is repeatable. Solo the layer
(`S`, or `--solo=lsystem_trees`) to see just that distribution.

### The brush (step 3, interactive)

Open the scrubber on a map and paint a density field by hand:

- **`B`** cycles the active paint element (tree → critter → flower → off).
- **left-drag** paints density into that element's field (a live heatmap overlay
  shows it); **`E`** toggles erase; **`C`** clears; **`,` / `.`** size the brush.
- **`W`** saves — the brush field is written into the map's `paint_layers[]` as a
  `mode:"brush"` layer (alongside any `biome_overrides`). Reload and it renders.

The wired spawn layers place by the painted field immediately on mouse-release.
This is the desktop precursor to the VR brush (step 4): the same stamp logic,
driven by a controller raycast instead of the mouse.

## Ground (the bump-map terrain)

`ground` is a **substrate** layer, not a scatter one: its field is a HEIGHT map,
not a placement density. The `ground_substrate` accrual layer is **on by default**
on every biome map (order 1, `always`) — a flat level ground you can raise into
hills. It extends the walkgrids `TopologySpace`, so the deformed mesh is walkable
(trimesh collider follows the bumps).

```json
{ "element": "ground", "mode": "noise", "scale": 0.16, "threshold": 0.0, "density": 1.0, "height": 2.0 }
```

- Any distribution `mode` works (plane = flat raise, curve = a slope/hill, noise =
  rolling terrain, brush = hand-sculpted).
- `height` (metres) scales the field → max bump height. No `ground` layer = flat.
- Toggle the whole thing off per map: `settings.biome_overrides.disable = ["ground_substrate"]`.

## Shader (paint a colour into the ground texture) + plant bleed

The same `ground_substrate` also owns the ground's **colour overlay** — a per-grid
RGBA texture (`biome_ground.gdshader`'s `paint_tex`, composed per-pixel with
bilinear field sampling, so noise/curve/brush read smooth and organic, not gridded).
Two sources feed it:

```json
{ "element": "shader", "mode": "brush", "color": [0.18, 0.62, 0.55], "brush": [[…]] }
```

- **`shader` layers** paint their `color` strongly into the ground texture (a
  chosen colour, hand-brushed or via any distribution `mode`). Colour-only — a
  `shader` layer never spawns geometry (no spawn layer queries `"shader"`).
- **Plant bleed (the *drain*)** — every plant layer (`tree`/`flower`/`mushroom`/
  `critter`/`large_critter`) also seeps its **kingdom colour** softly into the
  ground under it: leaf-green for trees, pink for flowers, earthy red-brown for
  mushrooms, warm for critters. No coupling — the ground just reads the same
  paint-layer fields the spawn layers do, and bleeds their colour. Painting a
  flower grove tints the soil beneath it.

Shader strength is firm (~0.92), bleed is soft (~0.55). Both editors expose a
`shader` brush element (VR Tilt-Brush menu + desktop scrubber).

## Sequence accrual (a map builds on the maps before it)

A map's `paint_layers[]` is its **own** contribution — saved per map (the delta).
But maps live in a sequence, so the biome should *build on what came before*. At
**load time**, a map's effective layers are the union, in sequence order, of every
earlier map's layers **+ its own** (own last, so it sits on top). The biome visibly
thickens as you walk the sequence — and nothing is duplicated on disk: each map_data
still stores only its own delta. Composed fresh every load (`sequence_accrual.gd`,
wired in `GridSystem._handle_biome_ring`).

Maps in a sequence have **different grid sizes**, so nothing copies cell-for-cell:

- **Procedural layers** (`plane`/`random`/`curve`/`noise`) re-evaluate on each map's
  own grid — they're resolution-independent recipes.
- **Brush masks** bilinear-**resample** to the current grid (`DistributionField._read_brush`),
  so a hand-painted stroke re-blooms proportionally on the next map's footprint.

Accrual is **layer-recipe** level, not painted-pixel level. It's additive + safe:
with no sequence, or for the first map in one, a map just gets its own layers. Inherited
layers carry a `_accrued_from` tag (which map they came from) for editor/debug; the
field engine ignores it. Order in `EcosystemManager._sequence_maps` (the sequence
JSON's `maps[]` order) defines "before".

```
Point_One   paints: ground-curve, flower-noise           → renders: [own]
Point_Lines paints: tree-noise                            → renders: [Point_One's 2] + [tree]
Point_Trace paints: shader-wash                           → renders: [Point_One's 2] + [tree] + [shader]
```

## Not yet (next steps)

- **Substrate engines** — `particle` (CPU/GPU particle field). Reuses
  `build_field`; consumes the field, not placements. (`ground` heightfield and
  `shader` colour overlay are now wired.)
- **`object` / `mushroom` / `large_critter`** spawn wiring (same pattern as the
  three already wired).
- **Per-shader colour palette** — `shader` paints one colour at a time (the menu's
  element colour); a palette to pick arbitrary colours mid-stroke is future work.
