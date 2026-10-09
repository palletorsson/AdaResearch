# Line Space Workshop

A primary encounter in `Point_Lines`: four count-led studies built from independently grabbable segments.

1. **Two:** parallel → plus → X → skew → rails → drawing. Always two 0.8 m rods.
2. **Three:** closed triangle → opened join → displaced edge. Always three 0.6 m rods.
3. **Four:** square → nonplanar folded loop → four-rod grid. Always four 0.6 m rods.
4. **More:** six-rod grid → lifted grid → tetrahedron → twelve-edge cube. All rods 0.6 m; count explicitly changes only at the cube.

Each station animates automatically: six seconds of rest, five seconds of smooth movement. There are no button panels or control plinths; four count labels remain above the rods, with four live film monitors below. The two-, three- and four-rod stations retain their rods and fixed lengths. Translation and quaternion rotation preserve length during movement. The square's fold follows its actual diagonal hinge, preserving closure throughout; it unfolds again before moving into the four-rod grid. Additional cube rods fade in at full length and become grabbable only when fully present.

Grabbing any visible rod pauses the entire station, without affecting the others. After release, the visitor's arrangement stays for twelve seconds, then smoothly returns to the paused target before the automatic cycle continues. XRTools provides the actual grab driver. No animation pose is written while the station contains a held rod. There are no gameplay collision walls or filled faces in the exhibit.

`line_space_workshop.gd` owns geometry and controls. `workshop_rod.gd` extends the existing XRTools pickable implementation. The scene is registered in `commons/artifacts/registry/primitives.json` and placed at grid `(16,16)`, facing 180°, without an added support plinth. Its 3.8 × 2.3 metre floor marking is visual. The old four control pedestals were removed.

Four camera studies film the actual rods in the shared museum World3D. `camera_study.gd` builds the cameras and 0.80 × 0.60 m monitors, tilted upward by 18 degrees. `study_filter.gdshader` implements four image treatments: luminance monochrome, ink threshold, image contour detection, and tinted scan lines. These filters do not change the geometry and do not claim to display true depth, normals or topology.

The two-line camera is frontal and orthographic. Three and more use fixed oblique perspective views; the four-line camera sweeps ±35 degrees over 36 seconds. A grab changes the real source, so its image changes too. Visual layers 17–20 isolate the four rod groups; monitors remain on layer 1 and cannot film themselves. Camera far distance is 2.7 m. Each feed is 384 × 288 pixels and updates at most twelve times per second while its monitor is on screen. No movie files, duplicate animated meshes or additional controls are involved. Physics pickability remains on layer 3.

`ada_run/line_camera_check.tscn` is a rendered probe: it checks real shared-world feeds after translating and rotating the workshop, nonblank images, camera isolation, and image changes driven by the real XRTools grab driver. It also saves a view of the four filters. The actual museum capture is produced separately by `line_workshop_museum_check.tscn`. These are desktop rendering checks; headset performance and comfort are still unverified.

The book passage is `<!-- @line_space_workshop -->` in `commons/maps/Point_Lines/final.md`. The saved encounter is `combine` in `commons/data/encounter_routes/Point_Lines.json`. Older line studies remain in the hall as comparisons.

The teaching distinction is between an actual spatial relation and its projection. Moving one family of grid lines 0.25 m in depth makes projected crossings into separated segments. Parallel rails retain their direction in space; the drawing really joins endpoints. The frame prepares the later distinction between triangle edges and a filled face.

Validation: `ada_run/line_workshop_check.tscn` exercises animated geometry, continuous fold closure, the real grab driver, whole-station pauses, delayed smooth recovery, fading additions and collision layers. `ada_run/line_workshop_route_check.cjs` checks the production encyclopedia route model and preservation of earlier content. `ada_run/line_workshop_museum_check.tscn` loads the actual endless museum and captures the placement. Headset reach, readability and comfort remain for in-person testing.

Bounded automatic experiment: `python -X utf8 ada_run/research_line_counts.py` exports the production presets, sweeps triangle displacement and four-edge folding, and measures endpoint joins and affine dimension. It writes 29 inspectable cases, source hashes and an HTML report under `doc/book/iterations/2026-09-15-line-counts/`. It does not edit visitor arrangements, the room or the book. Interior crossings, rod thickness and physical clearance are outside this measurement.
