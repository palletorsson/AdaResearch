# VR Editing System — principles

> Ada has three in-VR world editors. They share one idiom. This doc extracts
> that idiom so new editors (the biome paint brush, future tools) fit it.
>
> (Created 2026-06-05 — the principles already lived in code; this names them.)

## The three editors

| Editor | File | Edits |
|--------|------|-------|
| **Voxel editor** | `commons/grid/VoxelEditVR.gd` | the structure grid — add/remove cubes |
| **Catalyst bracelet** | `commons/hazards/becoming_catalyst/` | places blocks/wedges; the player's evolving tool |
| **Artifact mover** ("Off the floor") | in-VR gravity-gun | grab/move/rotate placed artifacts, snap to grid height |

## The shared idiom

1. **The tool is a component on the controller (or wrist).**
   `VoxelEditVR extends Node3D`, added as a child of an `XRController3D`. It reads
   the controller's pose directly (`_controller.global_position`,
   `-_controller.global_transform.basis.z`). The bracelet lives on the wrist.

2. **`enable()` / `disable()` toggle the mode.** An editor is a *mode* you turn
   on, not always-on. While on, it shows its ray + HUD; while off, nothing.

3. **One button vocabulary, everywhere:**
   - **trigger** → the primary act (add cube / place block / **paint**)
   - **grip** → the inverse (remove / erase / remove-last)
   - **ax_button** → **save**
   - **by_button** → undo
   - **bracelet rotation (other hand)** → **switch mode/sub-tool** (the bracelet's
     way of cycling voxel ↔ wedge ↔ off; a paint brush cycles *element* the same way)

4. **A ray + a ghost + a Label3D.** A thin cylinder ray from the controller
   (`top/bottom_radius 0.002`, unshaded, alpha ~0.4), a ghost/preview of what will
   land, and a small `Label3D` near the controller showing the current target and
   the control hints. All hidden when the tool is disabled.

5. **Raycast in `_process`, act on button.** Every frame: cast from the controller,
   resolve the target (a grid cell, a surface point), update the ghost + label.
   The button handler just commits whatever the ray currently targets.

6. **Edit logic is separate from VR I/O.** `VoxelEditVR` (input/visuals) delegates
   to `VoxelEditController` (add/remove/undo on the structure). Keeps the VR layer
   thin and the logic testable on the desktop.

7. **Persistence: in-memory now, disk on demand.** Edits survive map transitions
   within a session (in-memory). A deliberate **save** (ax) writes to disk
   (`VoxelSaveManager.save(map_name, structure)`). Fresh each launch unless saved.

8. **Find the world by walking the tree.** Editors locate `GridStructureComponent` /
   `GridDataComponent` / `GridSystem` via a recursive name search from the root —
   no hard wiring, so the same component drops into any map.

## Enabling an editor (from `vrStaging.gd`)

```gdscript
var tool := SomeEditVR.new()
right_controller.add_child(tool)
tool.enable()      # …and disable() to leave the mode
```

## The biome paint brush within this idiom

`commons/grid/BiomePaintVR.gd` (the desktop scrubber's brush, ported to VR):

- Component on the right `XRController3D`; `enable()/disable()`.
- Ray → the **ground plane** → grid cell (not a structure voxel — the floor).
- **trigger** stamps the active element's density field (radial brush); **grip**
  erases; held-drag paints continuously (raycast each `_process` while held).
- **by_button** (or bracelet rotation) cycles the element:
  tree → critter → flower → mushroom → large_critter.
- **ax_button** saves: the runtime field → the map's `paint_layers[]`
  (`mode:"brush"`), exactly like the scrubber's `W`.
- Label3D shows the active element + brush radius; a cell overlay shows the field.
- On stroke-release it asks `GridSystem.repaint_biome(layers)` to rebuild the
  biome live with the painted field (additive runtime override; empty = the
  map's own paint_layers, so default behaviour is unchanged).
- Reuses `DistributionField` + the same `_stamp` math the scrubber proved — the
  desktop brush and the VR brush are the same logic, two input devices.

**Could later become a bracelet mode** (`biome_brush`) alongside voxel/wedge —
the bracelet's mode list is the natural home once it's proven standalone.

## Verifying VR work

VR can't be captured headlessly (no headset in CLI). The loop:
1. Parse-check the component (headless preload).
2. Enable it in `vrStaging.gd`, walk a map in the headset.
3. Feedback comes back via the bridge — `ada_run/desktop_feedback.md`
   (`/ada-bridge-listener`). Iterate from there.
