# Four faces / an enclosure

The next monitor follows Triangle with the existing grabbable tetrahedron in **Primitives_Polythedra**. It reveals four stored positions, six edges and four faces, then unfolds rigid copies of the faces into a net and folds them back into an enclosure. The camera films real geometry in a private Godot world.

## What is read, what is illustrated

`commons/primitives/tetrahedron/grab_tetrahedron.gd` supplies `_tetrahedron_geometry()` and its actual `MeshInstance3D` arrays. The snapshot checks agreement between the source position/face lists and the rendered vertices. It preserves face order and source normals, including their inward orientation. Materials, numbered corners, framing and pacing belong to the monitor's illustration.

The source generator constructs four faces directly. Folding is a display operation, not a claim about the algorithm's execution or physical material. Face 3 stays fixed; each other face turns about its shared edge with that face. A hinge rotation moves its free corner into the base plane, on the opposite side from the base's third corner. All triangle edge lengths remain constant. At zero unfolding the transform is exactly identity.

The repeated 0 labels mark copies of one source vertex. They meet at the apex on closing. The display makes no changes to the original body, mesh, collider or generator.

## Relation to the existing room

The existing `polyhedra_boundary_plate` remains in place. It compares the **open trihedron's** three rendered faces with its closed collision hull. The new monitor examines the **tetrahedron's** four rendered faces and their connections. These are different artifacts; removing a face from the regular tetrahedron would not reproduce the wedge-shaped trihedron already in the room.

The monitor is registered as `polyhedra_reveal_monitor` and added at map cell **(1,2)** with rotation 90°, its own stand, and offset **(1.5,0,0.5)**. It is brought forward and along from the wall to clear the existing pink corner. The initial placement hid a control and was rejected. The final placement is checked from inside the museum for screen and button visibility.

Only this hall's active and shipped plan rows were refreshed. The original map and rows are backed up beside this file. No source artifact logic, manuscript, tutorial or storyboard was edited.

## Verification and reuse

- `tools/probes/polyhedra_reveal_record.gd`: 48 checks against the real tetrahedron scene. Exact mesh copies, indices, preserved normals, source immutability, stable snapshots, nonuniform root transform, rigid edge lengths, fixed hinges, flat net and closed identity. Maximum numerical deviations were below 0.00000036 m.
- `tools/probes/polyhedra_reveal_monitor.gd`: gaze, pause, controls, rendered net coplanarity, rendered edge lengths, exact closure, source preservation and actual museum placement. `report.json` contains the final results.
- `tools/run_polyhedra_reveal_monitor.py`: private museum capture with redirected runtime output, protected-source hash checks and script-error detection.
- The review film and stills are rendered Godot geometry. `museum.png` and `museum-feed.png` show the real hall's monitor. No generated image is used as evidence.
- The shared gaze system is reused: looking at the physical screen starts the film; looking away pauses it; manual pause remains in force. This is head/camera direction, not hardware eye tracking.
- Physical headset readability, reach and performance remain to be checked. Existing unrelated museum warnings are left outside this change.

Run `res://commons/artifacts/concept_monitor/polyhedra_reveal_preview.tscn` for the native preview. Its source is a frozen preview copy of the actual tetrahedron scene. In the museum, the monitor reads the existing body automatically.
