# Array — current encounter notes

Updated 23 September 2026. The chapter remains in final.md; these notes describe the new Molnár-inspired cube study and its evidence.

## Three encounters

The active primary order is row_3_x → grid_2d_4x4 → molnar_cube_study. The row and grid retain their collection/absence behavior and code. The added study separates indexed identity from displayed position, orientation and size, and prepares Tutorial_3D without replacing its full-scale flight encounter.

## Transparent cube study

Source: commons/artifacts/molnar_cube_study/molnar_cube_study.gd and .tscn. Registry: commons/artifacts/registry/molnar_cube_study.json. Array placement: (10,16), yaw 180 degrees, no automatic plinth.

The array contains 4×4×4 sites, 0.56 m apart, with four nested frames per site. Their ordered outer edge is 0.44 m; nested fractions are 1, 0.76, 0.52 and 0.28. A repeatable per-site seed assigns a displacement, three Euler angles and a uniform scale departure to each frame. The three sliders multiply these stored departures. They do not resample them. At full control range, displacement is at most 0.07 m on each axis, angles at most 24 degrees on each Euler component, and uniform scale factor between 0.75 and 1.25. Operations are composed as scale, rotation, then translation in each frame pose.

All 64 sites and 256 frames are allocated once. DEPTH changes visible counts, from 16 sites/64 frames to 64 sites/256 frames; it is not a memory-allocation experiment. RESET restores the three amounts to zero, preserving the selected visible layer count. Fixed grey markers stay at each indexed site. They are position markers, not printed address labels. No claim that the visitor can edit an individual cell from these three global controls: the controls vary the extent of already distinct per-frame decisions.

The edge geometry is shared in one MultiMesh. The 64 outer faces use low alpha; inner cubes are edges. No per-frame processing runs at rest. Animation interpolates control changes. This is a bounded exhibit, not a measured Quest performance benchmark.

A 3 m plinth carries the volume. Controls are at 0.96, 1.105 and 1.25 m; the depth/reset buttons sit beside them. Existing shared desktop pointer and XR grab/button mechanisms are used. A 6×6 m floor pad, 0.03 m thick, supplies a continuous walk around the display after the first physical probe found an existing floor drop. Other source grid cells were preserved.

## Attribution and shared figure

After Vera Molnár, (Des)Ordres (1974): https://dam.org/museum/artists_ui/artists/molnar-vera/des-ordres/. Our cube geometry, third dimension, stored departures and controls are an Ada Research interpretation. Do not attribute this particular algorithm or 3D object to Molnár. The earlier vera_molnar_des_ordres artifact remains intact.

The book uses native Godot captures of this same production scene. tools/probes/molnar_book_plates.gd renders selected poses in a neutral photographic stage, hiding the plinth and controls; it does not change cube geometry. The first two views show one layer at zero and combined amounts (0.7,0.7,0.6); the third shows four layers at those amounts. The composed illustration crops a small lower image margin containing an unrelated HUD. It is a book plate, not a museum screenshot. Actual museum images are provided separately.

## Evidence and limits

Review: doc/book/iterations/2026-09-23-array-molnar-volume/index.html. Runtime: report.json, source_manifest.json and molnar_volume.gd in that directory. 38 checks pass, including real pointer callbacks for all controls, repeated-setting equivalence, fixed indices, geometry bounds, and supplied walking input for the actual museum body around all sides of the plinth. This is not a continuous entrance-to-exit test, headset comfort check or learner observation.

Existing startup output includes the unrelated unrecognized UID rwex60pqapc and GridStructureComponent invalid-position warnings from gridagent. They did not fail the new study checks; they remain separate follow-ups. No live museum was restarted and no live bake/save was overwritten.
