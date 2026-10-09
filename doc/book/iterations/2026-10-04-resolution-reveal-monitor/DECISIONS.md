# Resolution / how many parts make a curve?

This monitor compares native Godot **CylinderMesh, CapsuleMesh and SphereMesh** side by side. Its place is **Primitives_Ignorance**, where the museum already asks how a primitive's apparent smoothness depends on finite geometry.

## What the film shows

The approximately 50-second film first varies radial segments while rings stay at 4. It then varies rings while segments stay at 12, before visiting selected combinations. The camera films the actual 3D meshes rendered by Godot. The review uses `resolution-film.mp4` in a native video element, with playback controls and scrubbing.

The film is a finite set of examples, not an exhaustive traversal. The exhibit's independent S− / S+ and R− / R+ controls reach every integer segment count from **4 to 64** and every ring count from **0 to 32**, with **SphereMesh clamped to its native minimum of 1 ring**. The sphere's displayed count must show that difference at the lower bound. All combinations within these ranges are available manually.

These are exhibit bounds, not engine limits. Godot's setters impose lower bounds, but do not impose corresponding explicit upper bounds of 64 segments or 32 rings.

## A ring does different work in each generator

- **Cylinder:** R additional cuts along the straight wall make R + 1 vertical bands. More rings increase surface subdivision without changing the cylinder's outline.
- **Capsule:** each hemispherical cap and the straight middle use R + 1 bands. Changing rings changes the approximation of the caps and subdivides the straight middle as well.
- **Sphere:** R + 1 bands span pole to pole. Rings refine the vertical approximation; radial segments refine the circumference.

The black edges expose the actual mesh triangles. SURFACE hides or restores this overlay without changing the underlying native mesh. Resolution, visible edge presentation and aesthetic judgment remain separate decisions. More triangles do not automatically make a better work.

The engine implementation is the authority for these counts: [Godot 4.6 `primitive_meshes.cpp`](https://github.com/godotengine/godot/blob/4.6-stable/scene/resources/3d/primitive_meshes.cpp). The illustration uses the same engine generators used by the existing gallery, with independent mesh resources. It does not reconstruct or replace the gallery artifacts.

## Interaction and playback

Changing a segment or ring count pauses the automatic film and retains the selected combination. PLAY then rotates those selected forms while keeping their counts fixed. REPLAY restores the automatic comparison from its beginning. PAUSE, STEP and SURFACE support inspection without requiring a new mesh edit in the original hall.

The shared monitor checks whether the player's camera is directed at the physical screen. Looking away pauses playback; returning resumes it unless the player has paused manually. This is head/camera direction rather than hardware eye tracking.

## Relationship to the original museum

The monitor's SubViewport contains its own world, meshes, camera and lighting. Existing primitive generators, gallery artifacts, manuscript and tutorial logic remain outside the illustration's control. The new scene supplies a visual comparison alongside those works.

`comparison.png`, `low.png`, `rings.png`, `dense.png`, `smooth.png` and `preview.png` are intended as captures of the working Godot illustration. `museum.png` documents placement inside the actual Endless Museum. The film and stills should be regenerated from the scene when its geometry or presentation changes.

## Verification scope

128 checks passed: 96 native mesh checks and 32 monitor/museum checks. The mesh probe generated all 5,978 legal combinations in the exhibit range and checked 6,481,616 vertices. Playback, independent controls, sphere minimum, surface toggle, four screen-corner sightlines and all eight physical button sightlines passed. The 596-frame MP4 decodes successfully at 1024 x 576 and 12 fps (49.67 seconds). Physical headset readability, reach and performance remain to be checked.

Only cell (1,16) was added to Primitives_Ignorance; all 26 existing artifact entries remain intact. Only this hall row was derived in the active and shipped museum plans. Existing hall dimensions remain unchanged. The existing wider hall produces its pre-existing width-rule warning; it is not resized by this addition.

Reports: `report.json`, `mesh-report.json`, `film-report.json`, `placement.json`. Run `python tools/run_resolution_reveal_monitor.py --film` to regenerate the movie and museum captures, and the probe `tools/probes/resolution_meshes.gd` for the complete mesh range.
