# SoftBodies_Obsticals — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## Read before written

Written 2026-09-02 from an agent's reading of every placed script and scene,
with a skeptic pass behind it. Nothing in the text predates the sheet.

- **The room's centrepiece does not do what it is named for.** `breathing_room`
  loads `breathing_room_scene.gd`, which has no `_process` and no tween; the
  sinusoidal pressure loop lives in a sibling script the scene does not load. Two
  static slabs 4.87 m apart, one of them outside the room behind the north wall.
  The text says so and uses it.
- **`flagdancer` has no physics at all**: 17 bones on sine waves, no SoftBody3D,
  no cloth solver, no forces, no collider. Its bottom is 2 m below the floor and
  2 m of its width is inside the wall. The text uses it as the animated-versus-
  simulated control.
- **Pressing the jump key reloads the map** — `softbody_gallery_part2` binds
  `ui_accept` to `reload_current_scene`.
- The gallery is far bigger than the room: 12 cells, spheres dropping every 2 s,
  six stiffness columns. It is the room's real argument.
- `pick_up_cube` is walk-into, not grab, despite the registry.
- `grab_long_stick` is the only graspable object.
- **The teleporter is in a hole**, y 0.0 in a 3-cell gap.
- **Auto-ground silently skips three of the five**, because `_compute_local_aabb`
  walks only the root's direct children.

## Open

- breathing_room loading the wrong script is a one-line fix in the .tscn and would give this room its hard case back.
