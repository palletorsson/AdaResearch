# Rotation / one-metre courses and transport-cube gantry

Implemented on main Void floor 16, following the user's revised dimensions and lift request. The earlier 2.04 m proposal is historical; the live experiment uses actual 1 m cube meshes and colliders on 1 m centres. The single-column Z control and two-column Z trial retain the same six rotations: 0, 18, 36, 54, 72 and 90 degrees. Their nominal course height is 3.5 m. Both approaches run west to east, with a safe return around the gantry. X, Y and combined-axis studies also use the revised dimensions.

The black steel gantry frames the courses, with pink rails, safe banks and end crosswalks. The separate electric bed sits at 2 m under the courses, with cyan conductors and pink edges. Contact causes the normal Void electrical death and floor-16 recovery. This is a contact hazard, not an inactivity timer: remaining on a valid cube is safe. Existing shafts remain open.

The cyan `tc` at the west bank reuses the existing transport cube and passenger-carrying driver. Its 2 x 2 m boarding deck consists of four one-metre blocks. It rises 3.5 m, pauses at the gantry and returns for another trip. It carries the desktop player and synthetic XR origin without double-moving the tracked head. The label and opaque cyan finish make it visible from below.

The Z trial, gantry, electrical bed and lift are separate catalogue objects, with real exported Godot models in the Three.js editor. Copy/move/rotate validation preserves their configuration. Main desktop and VR read the same rooms.json. The original 135 construction pieces remain individually editable. The standard floor dimensions and Museum map data were not changed. All writes preserved other floors as fetched immediately before saving, including concurrent work from other chats.

## Verification

- `tools/test_rotation_electric.py`: 60 passing checks in the actual Jolt game, covering scripted desktop and synthetic XR. Checks include matching cube meshes/colliders/angles, safe standing and natural movement below the bed, real electrical contact/death/recovery, TC boarding, 3.5 m passenger carry, return and safe exit.
- `tools/capture_rotation_electric.py`: final native visual receipt passes after the cyan finish; same TC collider and route.
- Native floor export succeeds with no export failures; all 17 floor placements have models.
- `tools/check_rotation_z_width_editor.cjs`: actual editor model loading, copy/move/rotate draft validation, desktop-backup parity, plan/orbit views, no page errors or accidental saves.

These checks are not a physical-headset acceptance or a claim that every angle is traversable. Walking over difficult rotations is the intended experiment.

Evidence is in `doc/ports/2026-10-26-rotation-z-width/electric/`: native checks, editor checks, export receipt and five screenshots. Before/save/route receipts are retained there as well.

![Single and double Z courses](../ports/2026-10-26-rotation-z-width/electric/02-one-metre-pair.png)

![Transport cube at the upper gantry](../ports/2026-10-26-rotation-z-width/electric/03-tc-gantry.png)
