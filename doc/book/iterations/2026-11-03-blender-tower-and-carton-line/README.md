# The tower from outside, and a line that fills its room

3 November 2026, the Blender session (tools/blender/ada_void). Palle opened with the toolchain: *"So we have a
godot - three.js - blender - agent pipeline. Can you render five floor void tower outside view in blender."* The day
went from the tower's outside to the sorting line's cartons. Blog with eight pictures and the film:
[/blog/2026-11-03-the-tower-from-outside](http://localhost:3003/blog/2026-11-03-the-tower-from-outside).

## The tower

`tools/blender/ada_void/tower.py` imports floors with the add-on's own `build_floor`, hangs each under an empty at its
storey from `commons/void/layout.json` (`levels[i]`: 0, −6, −12 … m) and photographs the stack.

| picture | how | committed |
|---|---|---|
| floors 0–4, raised three-quarter view, 1920×1080 | `--floors 0-4`; ~2.5 min import, 31 s render on OptiX | `0329abf6a` |
| floors 0–12 in portrait, framed on 0–9 ("a tower without an end") | `--reframe` and `--append` on a saved scene, `--frame-floors 0-9` | `4dfa40366` |
| the whole tower from below, 211 floors, two drafts | `--structure-floors` (slab, halls, ceiling, lamps only) for 0–202 and 210, works on 203–209, `--from-below` | this commit |
| the randomness floors looking up (76–91) | works on 76–79 and 81–91; 0–75 and 80 as structure; 47 min import | this commit |

Findings for the tower's owner (nothing under `commons/void/` was edited; it was only read):

- **Floor 78 (Random_Entropy): `f1_signal_room_12_48` reaches 26 m out of the tower.** A closed room 14 × 24 m
  (Blender x −6…8, y −36…−12) standing on a slab 18 m deep. It is the black box in the randomness picture. I did
  not check whether it also sticks out in the game.
- **Floor 80 (Randomness_10_PRINT_Algorithm) holds one model of more than 1,100 tiles.** The first randomness import
  died on it, Blender's allocator returning null at 1.7 GB with the machine's commit limit nearly full. As structure
  only it imports in seconds.
- **Floor 210 holds 1,564 glbs.** Importing it whole crashed Blender; the from-below picture takes it as structure.
- The works of all 211 floors would need about 8 GB in Blender; `--structure-floors` is the way to frame the whole
  tower.

## The cartons

`tools/blender/ada_void/carton_pile.py` (new). Palle sent two screenshots of the sorting line's heap on floor 7 and
asked for it in a *"super glossy cool format"*.

1. **The heap**: the AGAIN and YET cartons redrawn pixel for pixel from `carton_skins.gd`, 90 dropped with Blender's
   rigid bodies, lacquered on a dark mirror floor. A Blender image written from Python with `foreach_set` renders
   black until `img.update()` is called.
2. **The line (`--line`)**: floor 7's exported `cube_sorting_line` glb and the `prefab_box_library` shelf from the
   ReturnToTheBoxLibrary hall's glb, a jam on the belt, the missed cartons spilled off its end. Imported meshes are
   unparented into world space first, because a rigid body ignores its parent's transform.
3. **The film (`--line --wall --fill 4800`)**: the line running, 26 s at 1280×720, from Palle's *"could we make a
   video starting that gradually show how the space fills up?"* and the four turns after it: the works side, the shelf
   swapped behind the line, *"can we remove the interface with buttons"* (the control stand is left out of the
   render only), *"maybe L shaped 1 m wall around the work front of the conveyor"*. Final run: the feeder placed 264
   cartons and held 1,622 times; none ended more than 15 m from the line; a scan of all 622 frames found nothing
   crossing the empty sky.

The six ways the film lied before it was honest are listed in `tools/blender/ada_void/README.md`: kinematic carrying
(infinite force), the mesh collider's outside margin, the speed a kinematic body keeps after a jump, a location set
from Python not moving a kinematic body, cartons placed into a backed-up queue, and the rigid-body cache reset by
building the studio after the simulation.

Renders live in `ada_run/blender/` (ignored); the published pictures and the mp4 are in the encyclopedia's
`public/the-tower-from-outside/`.

## Also today, not built

The honest-terms sweep (26 Oct) finished its judging: batch A's judge, lost to a server overload, ran, and the other
batches were judged a second time. 39 terms were kept by both judges, 13 of batch A by its one judge, and 4 were dropped
(three rejected by both, one split). An integration workflow started on Palle's "continue" and was stopped by him
after 14 of its agents had finished; nothing was written to `commons/modular/terms.json`. The cached results can
resume it.
