# SoftBodies_Carusell — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## Read before written

Written 2026-09-02 from an agent's reading of every placed script and scene,
with a skeptic pass behind it. Nothing in the text predates the sheet.

- **You spawn inside the machine**: 3.80 m from the axis, inside the 4.5 m
  obstacle ring, 0.55 m outside the 2.75-3.25 m sweep of the soft bodies.
- **The soft bodies never reach the obstacles.** They sweep at 2.75-3.25 m and the
  twelve posts stand at 4.5 m, so the registry's "colliding with obstacles" never
  happens. The text does not claim it does.
- **Two arms sweep through solid wall pillars** at cells (6,7) and (10,7) on every
  revolution.
- The posts are 5.0 m against 2.0 m walls, sunk 0.5 m below the floor.
- **`pick_up_cube` cancels its own grounding**: `_process` writes
  `global_position.y = original_y + bob` from a value cached in `_ready`, before
  the deferred grounding lands.
- **A utility in the same cell lifts an artifact**: `soft_mushroom` shares (10,12)
  with `sp`, so it is bumped a level.
- `flex_cloth_pad` rebuilds its mesh and allocates a fresh material every frame.
- `grab_long_stick` is the only properly grabbable object.
- **`an:softbodies` is parsed as a rotation** — float of a word is 0.0 —
  overwriting the authored 180-degree yaw.

## Open

- The ride was built for a bigger room: 5 m posts, 2 m walls, two arms through pillars every turn. Worth either a bigger hall or a smaller ride.
