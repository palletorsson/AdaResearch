# Paint Layers

> The biome as a stack of painted layers. One principle, repeated:
> **`element × distribution × density`**. Per map. Eventually VR-editable.
>
> Status (2026-06-05): **Steps 1–2 landed** — schema + distribution engine,
> wired into the population spawn layers (tree, critter, flower) as *opt-in*.
> Steps 3 (desktop painter) and 4 (VR brush) are not built yet.

## The model

Every layer is the same shape. Only the `element` changes:

```
element       what it places / modulates          engine (today)
───────────   ─────────────────────────────────   ──────────────────────
ground        heightfield / bump (substrate)       — (step-2b, not wired)
shader        ground-shader drain + paint           — (research jewel, later)
particle      CPU/GPU particle field                — (later)
object        any artifact, by density              biome_paint_dispatcher
flower        flowers                               softbody_flora      ✅ wired
mushroom      fungus / CA surface                   ca_surface
tree          L-system trees                        lsystem_trees       ✅ wired
critter       small DNA creatures                   dna_creatures       ✅ wired
large_critter big creatures                          swarm_creatures
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

## Not yet (next steps)

- **Substrate engines** — `ground` (heightfield), `shader` (the *drain* jewel:
  material seeping from a plant into the ground shader — reaction-diffusion),
  `particle`. They reuse `build_field`; they consume the field, not placements.
- **`object` / `mushroom` / `large_critter`** wiring (same pattern as the three
  already wired).
- **Step 3** — desktop painter (extend the scrubber / map-builder with a brush).
- **Step 4** — the VR brush (catalyst-bracelet-family tool: select layer, paint
  density, grip-erase, rotate to switch mode/element).
