# Point Lines — two ends, one changing relation

3 October 2026. One tutorial pilot after Point One, at Palle's request.

## Keep the curriculum edge visible

Point Coordinates still sits between Point One and Lines in the museum spine. It introduces holding and reference frames. Its current tutorial has not yet received the new shared-starter writing pass. This Lines pilot explicitly supplies the handles, states the common parent frame and creates all lesson objects in code. It does not pretend the older Coordinates tutorial has already been rewritten, nor reorder the spine.

## New work

Read two current positions in the same frame. Subtract them to obtain a displacement; call `length()` to obtain its length. Turn without lengthening, reverse the subtraction without changing distance, and let `_process()` read the relation as either end moves. A zero separation gives no direction; a detour is not retained by its endpoints.

## Explicit borrowed parts

- `PointHandle`: the sphere mesh and collision construction from Point One, with the prepared XR Tools pickup. The two instances stay under the same parent and freeze where released. Desktop aim/E and synthetic near-grip input are tested separately.
- `Segment`: creates its own finite cylinder and handles midpoint, orientation, thickness and degenerate separation. The learner calls its two-position interface. Quaternion rotation and renderer tolerances remain supplied.
- Day Zero: room, player, lights and input. The backdrop provides contrast; it has no collision and is not a reproduction of the museum's black-box architecture.

These helpers are scripts instantiated with `.new()`, not node-path lookups or preauthored teaching meshes. `preload()` and `const` are explained as the way the lesson names its dependencies. They are not silently treated as prior knowledge. Each readout is a new Label3D, reusing Point Zero's construction.

The learner uses direct references. The complete `line.gd` is downloadable and shown below the reading copy; the main reading foregrounds only the placement, subtraction and repeated update. The full constructor code remains available for inspection.

## Keep separate

The museum's barrier, walking line, signs, break/reset tools and varied line bodies remain available to final.md and the hall. They do not all become prerequisite programming exercises here. No change to the critical manuscript or live museum map is made by this tutorial pass.

The earlier fixed-camera Point Lines download remains an older companion. The current route is `point_lines.tscn` in the shared starter. Point Trace can inherit two-position drawing and add an ordered list of positions; we do not introduce that list here.

Actual-headset ergonomics and beginner comprehension remain untested. Synthetic controller input checks the code connection, not a person's reach or comfort.
