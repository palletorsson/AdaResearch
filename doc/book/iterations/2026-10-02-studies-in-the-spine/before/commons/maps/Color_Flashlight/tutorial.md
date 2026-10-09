# Move a condition of appearance

Primary encounters: `flashlight_demo`, then `colour_light_rooms`. Read `final.md` for the book voice and `technical.md` for the implementation.

1. Find the boundary of one coloured pool on the board. Identify the lamp responsible by aiming it aside, then back.
2. Leave that lamp aimed at the board. Move another so the pools separate and overlap. Describe the change before naming additive colour.
3. Bring the white lamp into the comparison. If the overlap becomes hard to distinguish, separate the beams again.
4. Aim onto the floor or side cube. Carry the same light across the faceted sphere; compare neighbouring faces before naming their normals. No face has been repainted.
5. After following the light between these receivers, inspect `spot.light_color = light_color` in `flashlight_color.gd`. The assignment stays fixed while position and direction change.
6. Enter the side white room. Keep one corner in view while the central light changes. Compare this fixed lamp/changing value with the handheld lamps' fixed values/changing positions. Approach the pink recess, then move sideways to find its return walls. Its two sources keep their pink value while the surrounding room changes.
7. Enter the taller room and look through the stepped light well. Wait for its light to change, then walk up the ramp and compare the lips from the raised landing. Separate these observations: first change time while holding the viewpoint, then change viewpoint. The room's script does not recolour the museum sky.
8. Carry light-versus-material into Color_Nails, where a colour choice addresses a surface resembling part of a body.

The lamp's grab and orientation are the interaction. Do not instruct the visitor to switch it off, choose a hue, spawn a prism or select a receiving-ground variant: this placement provides none of those controls. Ask what the RGB model can show and what it leaves unrepresented, without treating this renderer as a spectral optics laboratory.

## Making score: a room receives a value

After reading the encounter, return to the supplied `colour_light_rooms` scene. Its `set_phase()` method includes the same kind of assignment used by the handheld lamp:

```gdscript
central_light.light_color = c
```

First give `c` one fixed RGB value, run the scene, then substitute another. Keep the white receiving material and camera position. This reuses the light assignment already introduced in this hall; building all the room geometry is a separate exercise. The luminous reveal has its own material and is not the source that lights the walls.

Then inspect `_process(delta)`: Point Zero's repeating callback advances the phase of a 110-second cycle. Pause the cycle with `running = false` and call `set_phase(0.16)` or `set_phase(0.38)` to compare two moments. Those are authoring changes in the script, not controls installed in the hall. The transferable operations are assigning a light colour, changing it over time, and holding conditions fixed to read a difference.
