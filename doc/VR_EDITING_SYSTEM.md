# VR Editing System

> Edit the game world from inside VR, and press a button to write it back to the
> repo on your PC. No desk, no export step. **What you place in the headset is
> what reloads from disk.** Arc: blog `2026-06-03-what-you-see-is-what-you-keep`.

## The tool: the catalyst bracelet

You hold the catalyst in one hand (it shrinks into your palm). A bracelet of
**stones** sits on that wrist — each stone is a **mode**.

**Mode selection is by reach, not rotation.** Reach your other hand toward the
stone you want: the nearest stone previews (grows / brightens) and **commits after
a short settle, with a haptic tick**. No dial, no jog, no cycle — a stone's
position in the ring doesn't matter. (Final design after several iterations;
rotate/jog/cycle all fought the geometry. **Do not reintroduce rotation.**)

### The editing stones

| Stone | What it edits | Data model |
|-------|---------------|------------|
| **Voxel Editor** | structure cubes (floors/walls) | grid |
| **Wedge Placer** | walkable ramp prisms | grid |
| **Edit** | existing grid-map artifacts (1 m-cell curriculum props) | grid |
| **Lab** | lab-room props (free-metre fittings) | lab |
| **off** | dormant — everything interactive | — |

(In code: `becoming_catalyst.gd` → `MODE_DEFS` + `unlocked_modes`; each mode is a
tiny script in `modes/` declaring `get_mode_type()` = `"tool"`/`"projectile"` and a
colour. The *behaviour* lives in `becoming_catalyst.gd`, gated on the current mode.)

## Two things you edit, two data models

1. **The grid** — `commons/maps/<Name>/map_data.json` — 3 layers
   (structure / utilities / interactables), all **cell-based (integer x,z)**.
   Cubes and curriculum artifacts live here, snapped to 1 m cells.
   *(Biome `paint_layers` are also grid/cell-based — they belong to this model.)*
2. **Lab props** — `commons/labs/<name>.lab.json` — `mounted_props` in **free metres**
   (so they can hold 0.1 m positions): wall placards, exit signs, scanners — what
   `LabLoader` spawns inside a `lab_room`.

## The editing modes in detail

- **Voxel Editor** — face a cell, **trigger** adds a cube on top of that column,
  **grip** removes one. A green ghost shows where it'll land.
- **Edit (grid artifacts)** — point the laser at an artifact, **hold trigger** to
  grab (it floats at the laser, follows your hand), **release** → snaps to the cell
  on top of the structure + 90° rotation + upright. Pass through you (no launch).
- **Lab (lab props)** — point + grab a lab prop; **surface magnetism**: free in open
  space, but within ~0.25 m of a wall/floor/ceiling/other-prop-top it sticks flush,
  gridded to 0.1 m along the surface. On a wall it aligns facing to the room and
  offsets by its own thickness (flush); a clamp prevents embedding. Artifacts can
  declare `wall_facing_offset_deg` if authored backward.

## Placing new artifacts: the left-wrist workstation

A panel on the left wrist browses every registered artifact with a live preview.
**PLACE** drops the selected artifact onto the grid cell you're aiming at, on top
of the structure — grabbable, re-snapping, with a hover highlight.

## The save pipeline — press B

`res://` is **read-only on a Quest build**, so the edit has to phone home:

- POST over **`adb reverse tcp:3003 tcp:3003`** (USB tunnel).
- **Map edits → `/api/game/save-layers`** — full structure layer +
  `interactablePlacements`, overlaid onto existing interactables **non-destructively**.
- **Lab edits → `/api/labs/save`** with `propUpdates` (merged by prop id, preserving
  what you didn't touch).
- The encyclopedia (Next.js, port 3003) **writes the repo**. The bracelet flashes
  `SAVED → PC` (or a red reason if the tunnel's down).

Code: `becoming_catalyst.gd._save_map_over_http(map, layout, placements)` →
`MAP_SAVE_URL` / `LAB_SAVE_URL`.

## The web twin: `/lab-net`

The encyclopedia's net editor unfolds the room flat (all six faces at once) and
lets you drag artifacts + the architecture (door, windows, room size), saving to
the **same lab JSON** VR Lab mode reads. One source of truth, two editors.

## Supporting pieces

- Placement ghost (green cell preview) + hover highlight (laser-target glow).
- Collision **pass-through** — placed/edited artifacts never shove the player.
- Grouping/metadata so save knows where each thing goes: `vr_placed_artifact`,
  `vr_editable_artifact`, `vr_lab_prop`, `vr_lab_moved` — each tagged with its
  cell / lookup / lab-json.

---

## Adding the biome brush as a stone (plan)

The biome paint brush (`doc/PAINT_LAYERS.md`) fits this system as a **grid-model
stone**, because `paint_layers` are cell-based:

1. **`modes/mode_biome_brush.gd`** — declares `get_mode_type() == "tool"` + a colour.
   Add to `MODE_DEFS` + `unlocked_modes`.
2. **Brush behaviour in `becoming_catalyst.gd`** (gated on mode) — ray → ground cell;
   **trigger** stamps the active element's radial density field, **grip** erases;
   element sub-selection (tree/critter/flower/mushroom/large_critter); green ghost
   at the target cell. On stroke-release, call **`GridSystem.repaint_biome(layers)`**
   (already built) to rebuild the biome live.
3. **B-save** → extend `/api/game/save-layers` with a `paintLayers` field, written
   to `map_data.json`'s top-level `paint_layers[]` non-destructively (same pattern
   as `interactablePlacements`). `res://` write is editor-only; the headset POSTs.
4. Reuses `DistributionField` + the stamp math proven on the desktop scrubber.

### Status (2026-06-05): stone built, in-headset verify pending

Built + parse-clean (editor import):
- `modes/mode_biome_brush.gd` — the stone (tool mode, green). In `MODE_DEFS` +
  `unlocked_modes`.
- `BiomeBrushController.gd` — the logic (ray→cell→stamp→ghost→`repaint_biome`,
  `paint_layers_payload()`). The catalyst feeds it the controller pose each frame.
- `becoming_catalyst.gd` — additive, mode-gated: `_process` biome branch (poll
  trigger/grip), `_on_controller_button` early-return (Ax cycles element, By saves,
  trigger/grip polled → never fires), `_save_biome` → POSTs `paintLayers`.
- `/api/game/save-layers` accepts `paintLayers` (verified end-to-end) ·
  `GridSystem.repaint_biome` (live rebuild).

**Element sub-selection** is **Ax-cycles-element** for now (the button budget —
trigger/grip/by are taken — forces it off a reach gesture). The left-wrist
workstation is the intended home; revisit in-headset.

> `commons/grid/BiomePaintVR.gd` (the standalone `res://`-writing draft) is
> **removed** — superseded by the stone; its stamp/field logic now lives in
> `BiomeBrushController.gd`.

**Verify in-headset:** enable the `biome_brush` stone, reach-select it, paint the
floor, watch the biome rebuild on release, press B → `SAVED → PC`, reload the map.
Feedback via `ada_run/desktop_feedback.md`.
