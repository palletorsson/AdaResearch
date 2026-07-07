# Interface Overhaul — structured migration onto the canonical board/console

> Goal (Palle, 2026-06-13): *all* artifacts that use interfaces need an overhaul.
> They are many, of different types; each needs a **board** and sometimes a
> **console**, integrated to **fit their artifact** with a good layout.
>
> Decision: **full unification**, with the two existing algorithms systems
> (`ForcesRackPanel`, `RackTemplates`) **converged underneath** the canonical
> primitives rather than rewritten at every call site.

## The canonical primitives

- **`commons/ui/control_panel.gd` (`ControlPanel`)** — THE BOARD. Box-model row
  layout, Dieter-Rams styling, baked/TextMesh labels, 2D-in-3D readout.
  API: `add_slider(label,param) add_dial add_joystick add_button add_readout
  add_screen add_node`, `title`. Smooth slider, never-scale-physics, bidirectional
  clamp, flush seating all live here.
- **`commons/ui/control_console.gd` (`ControlConsole`)** — THE HOUSING. Wraps a
  board in a floor cabinet (door/vent, DNA variants) + the viz **apparatus**
  hosts in front: `add_monitor / add_cube_space / add_plan / add_specimen_jar`
  (held by mast/gantry/pedestal, cables in a bridge duct). Forwards the board API.

**Board vs console rule:** a wall/desk-mounted panel needs only the BOARD. A
floor-standing teaching instrument with a visualization needs the CONSOLE.

## The taxonomy (recipe per type — do NOT flatten all to one template)

| Type | Signature | Recipe | Notes |
|------|-----------|--------|-------|
| **workbench** | sliders + readout + a visualization | console + board + viz host | proven on 5 benches |
| **machine** | mostly buttons / presets / capture | board + button rows | viz host optional |
| **console** | game/control surface, sliders+buttons | console + board, KEEP character | catapult, mortar, control_board CRTs, _toy_console Braun monitor |
| **readout** | Label3D display only | board readout, usually no console | ~398; leave/opportunistic |
| **rack** | Forces / RackTemplates panels | **converge the BASE**, not the callers | ~141 inherit for free |

## The migration recipe (the repeatable unit — proven on the 5 workbenches)

1. Replace the hand-rolled plate with `ControlConsole` (desktop: `face_to_origin=true`,
   `body_height≈0.40`, `set_title(<identity>)`), or bare `ControlPanel` if wall/desk-mounted.
2. Controls via `add_slider/add_button/add_dial`; readout via `add_readout`.
3. Move the visualization onto a viz host (`add_monitor`/`add_cube_space`/`add_plan`).
   Labels authored for open air must be pulled inside screen bounds. Content with
   its own origin adds a local frame Node3D inside the content root.
4. **Slider feel (all four layers — non-negotiable):**
   - use `slider_smooth` (ControlPanel already does);
   - never scale a physics control (ControlPanel `_fit_items_to_cells` skips RigidBody);
   - bidirectional clamp fix lives in `slider_smooth.gd`;
   - **never do heavy work in the grab signal** — `_on_slider_changed` sets
     `_viz_dirty=true`; a `_process` throttle rebuilds at ≤ `VIZ_REFRESH_INTERVAL` (0.12s).
5. Set `viz_floor = -plate_height` so the apparatus stands on the real floor.
6. Capture-verify (front + side); for workbenches, sweep the critical parameter into the DNA gallery.

## Phases

- **Phase 0 — foundations** ✅ `tools/ui_audit.py` (the tracker), this doc.
- **Phase 1 — converge the bases** (highest leverage, ~141 inherit):
  - `ForcesRackPanel` → adapter over `ControlPanel` (9 examples untouched). ← first
  - `RackTemplates.create_panel` → emit ControlPanel-based panels (77 inherit;
    also fixes its lingering `slider_horizontal` jumpy-slider bug at line ~172).
- **Phase 2 — commons by type:** workbench (7 left) → machine → console (keep character).
- **Phase 3 — algorithms direct-instantiation stragglers (~37) + opportunistic readouts.**

Batch within a type only after its recipe is locked; fan out worktree-isolated
subagents per artifact, capture-verify each.

## Tracking

`python tools/ui_audit.py --summary` (counts) · `--todo` (queue) ·
`--type workbench` (filter) · `--json out.json`. Status flips to `done` when a
file references `ControlPanel`/`ControlConsole`. Rack files flip when their base converges.

## The risk to hold (the sieve's "what is foreclosed")

Some interfaces have *character* worth keeping — `control_board`'s Black Mesa CRTs,
`_toy_console`'s Braun monitor. The recipe must integrate them onto the canonical
board **without flattening them into identical kiosks**. Console type = "keep character."
