# Task: Tweak Interactable Demo Element Sizing

## What Needs to Happen
The `interactable_demo.tscn` has three rows of elements. The compound layouts (Row 3) and passive elements (Row 2) need to be the **same physical height** as the single elements in Row 1, and compounds should take up double/triple footprint width while maintaining that height.

## Current State
- **Row 1** (single controls): Each element has a black frame of `0.12 x 0.28m` — this is the reference size
- **Row 2** (passive + monitors): Frame height is `0.28m` (correct), width scales by `width` key (1-3 slots)
- **Row 3** (compounds): Frame height is `0.28m` (correct), width scales by `width` key (1-2 slots)

## The Problem
The actual CONTENT inside each frame doesn't fill the frame properly:
- Procedural speakers/meters are `0.10m` (EL_S constant) — smaller than the `0.28m` frame
- Compound sliders are scaled down (`0.5x`) making them tiny
- Monitors use SubViewport which adds complexity

## What to Fix

### 1. Scale passive elements to fill their frames
In `RackPassiveElements.gd`, the `EL_S = 0.10` constant makes elements too small for the `0.28m` frame.
- Either increase `EL_S` to `0.22` (fills 0.28m frame with margin)
- Or scale the Node3D container when spawning

### 2. Scale compound content to fill frames
In `InteractableDemo.gd` `_build_compound()`:
- `sliders_v`: spawns sliders at `scale = 0.5` — increase to `0.8` or remove scaling
- `sliders_h`: spawns at `scale = 0.5` — same
- `monitor_sliders`: monitor at default, sliders at `0.4` — increase
- The gap between sliders in compounds should be proportional to frame width

### 3. Monitor sizing
`RackPassiveElements.build_monitor_grid()` calculates: `w = slots * 0.28 - 0.02`, `h = 0.18`
- The screen fills width correctly but height could match the frame better
- The SubViewport adds children that aren't Node3D — any code iterating children needs `if child is Node3D` guard

## Key Files
| File | What to Change |
|------|----------------|
| `commons/interactables/InteractableDemo.gd` | Element definitions (width), compound builder, passive spawner |
| `commons/interactables/RackPassiveElements.gd` | `EL_S` constant, `build_monitor_grid()` sizing |

## Reference Sizes
- Single element frame: `0.12 x 0.28m` (width x height)
- Double frame: `0.58 x 0.28m`
- Triple frame: `0.88 x 0.28m`
- Back panel height: `0.45m`
- Grid spacing: `SPACING = 0.30m` between slot centers
- Row 1 Y: `1.1m`, Row 2 Y: `0.65m`, Row 3 Y: `0.20m`

## Important: SubViewport Guard
Any code that iterates `container.get_children()` and accesses `.transform` MUST check `if child is Node3D` first — `SubViewport` nodes don't have `transform`.
