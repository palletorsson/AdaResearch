# Super Drag Looking Glass

Placed at cell **(30,35), facing 180 degrees**, in `Pattern_Foundry`, at the dressing end of the connected catwalk annex. Next and Previous immediately dress the actual player. Walk Dress returns to the earned garment. The selected look persists in `user://super_drag_outfit.cfg`; progression and trophies are independent.

Four authored silhouettes use the dream material libraries: Latex Cathedral, Chrome Orchid, Holographic Fan, Pearl Rococo. These are procedural costumes on the existing inferred torso. The sleeves follow hand positions; their shape is an approximation, not full-body tracking or simulated cloth. Chrome uses the dream shader's procedural reflected environment.

The mirror renders the live World3D through a reflected, off-axis camera into a bounded SubViewport. Its near plane is the mirror surface. Render layer 20 holds panes and is excluded from reflection cameras to prevent recursion; layer 19 holds the dressed head and is excluded only from the wearer's camera while dressed. Frame lights are real local lights. The mirror stops updating outside its front-side activation distance.

XR currently uses one head-centred image, shared by both eyes. Per-eye stereo reflection and headset frame-time/comfort validation remain future work. A shader surface does not substitute for that check.

Sources: [Godot Camera3D projection](https://docs.godotengine.org/en/4.6/classes/class_camera3d.html), [SubViewport](https://docs.godotengine.org/en/4.6/classes/class_subviewport.html).

Validation: run `commons/testing/probe_super_drag.gd` with Godot 4.6, `--xr-mode off`; add `-- --shots` with an actual renderer for the four captures. The isolated wearer uses a progression stub and a separate probe appearance path. It checks wardrobe controls, costume/trophy preservation, hand following, view masks, off-axis mirror corners, rotated mirrors and persistence. Results: `ada_run/probe_super_drag.json`.

Verified 9 September 2026: 46 isolated checks and 27 museum checks passed. All four looks were rendered with Compatibility/OpenGL and inspected; the final museum capture shows the full player costume on the level aisle. `commons/testing/probe_super_drag_museum.gd` verifies the real registry/loader, local player association, camera activation and floor height. Captures live in `ada_run/super_drag_shots/`. No headset or per-eye stereo validation is claimed. Existing unrelated warnings remain for the audio-bus UID and Tutorial_Disco's ragged map rows.
