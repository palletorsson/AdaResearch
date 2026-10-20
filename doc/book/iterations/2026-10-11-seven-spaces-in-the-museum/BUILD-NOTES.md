# Seven spaces in the Endless Museum

Installed in `NonEuclidean_Spaces`, alongside its existing artifacts. The narrow pink-topped doorway at hall-local `(13,1,7)` opens into seven full-size chambers. Open `museum.tscn` here and run the current scene to start in the actual museum hall. The launcher writes its own `user://` settings and does not change the saved museum route.

Take the black point from its small podium. This carries the existing `noneuclid-lineage/point_body.gd` unchanged, with the same instance carried between chambers. Its byte-identical copy lives in this artifact because `doc/` is excluded from exported game builds; the probe verifies the match. Desktop uses the museum's right-click pickup/drop and left-click held action; XR uses the existing pickup function and held-object action. Controls also sit on the left-hand console. Drop the point to press a button on desktop. **Next**, **Previous**, **Museum** and **Recall point** remain available. Next in the seventh chamber returns to the first.

| Chamber | What the visitor does | What is actually computed |
| --- | --- | --- |
| 1. A room that will not fit | Looks through and walks across a narrow door into a 14 m wide gallery, carrying the point; walks back through the same door. | Native Godot 4.6 stencil aperture, rigid positional transfer, swept head crossing and aperture bounds. These are connected Euclidean rooms, not curvature. |
| 2. The corridor returns your point | Carries the point across either blue end line without turning; counts returns. | Periodic flat corridor. Translation preserves the held point's head-relative position. Local curvature is zero. This version wraps at the line; it does not render recursive corridor views. |
| 3. Its arrow does not return | Moves the held point sideways, or advances one arc at a time. | A tangent transported along three short great-circle arcs of a spherical octant. The position returns; the arrow changes by 90 degrees. The large sphere is a surface model in an ordinary room. |
| 4. The edge you cannot reach | Moves the held point sideways/up to move a corner; switches disk and Klein displays. | Exact hyperboloid geodesics and tangent angles. Equal intrinsic steps compress in the display. Coincident/collinear corners refuse a triangle reading. The floor disk is a model, not a walkable hyperbolic floor. |
| 5. Hyperbolic galleries | Holds the point away from the chest and presses the trigger, or uses step controls. | An immersive finite H² × R architecture view. Horizontal motion applies Lorentz boosts; vertical motion changes ordinary product height. This is not a regular {4,5} tessellation. |
| 6. The room curves upwards too | Uses the same point to navigate sideways, forwards and vertically through the surrounding view. | An immersive finite H³ view. Lorentz boosts work in all three directions; the Klein projection follows the observer and eye position. |
| 7. Aim straight. Watch the path. | Moves the point sideways to aim, presses its trigger to launch, and tries another direction. | H² geodesic motion and metric-distance hit tests. A tracer represents the shot; the held point remains the aiming object. Hit-test substeps prevent jumping over the target. |

The point is a controller for the enlarged geometric representations. Those visible corner markers, arrows and shots are not additional independently carried student objects. The ordinary support decks remain under the visitor in the two immersive chambers. Jolt does not solve hyperbolic collisions here; the surrounding architecture is rendered by the metric shader. Virtual travel is bounded to five accumulated curvature radii in this finite exhibit, with Reset to restart. The player can still move physically around the deck.

The shader uses `INV_VIEW_MATRIX` plus `EYE_OFFSET` to obtain the rendered eye and restores the eye offset before Godot's multiview projection. See the [Godot 4.6 shader documentation](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html) and the [Mobile renderer source](https://github.com/godotengine/godot/blob/4.6/servers/rendering/renderer_rd/shaders/forward_mobile/scene_forward_mobile.glsl). Native desktop rendering is tested; physical headset comfort, stereo acceptance and Quest performance still require an actual device run.

The doorway preview contains visual copies with a stencil test, never duplicate colliders or a duplicate live PointBody. Opaque foreground objects prevent the mask from being written; the remote receivers ignore the local wall's depth behind the aperture. The preview is unlit and nonrecursive. The room itself has ordinary lighting and physical floors. Rooms are children of the artifact, outside the main hall's footprint, and unload with it.

## Verification

Run from the repository root:

```powershell
python -X utf8 tools/run_encounter_probe.py NonEuclidean_Spaces --sequence foundationscrisis --render --no-bridges --output-tag seven-spaces --probe tools/probes/noneuclidean_wing.gd
python -X utf8 tools/run_encounter_probe.py NonEuclidean_Spaces --sequence foundationscrisis --render --rendering-method mobile --no-bridges --output-tag seven-spaces-mobile --probe tools/probes/noneuclidean_wing.gd
python -X utf8 tools/publish_noneuclidean_wing.py
```

The probe loads the actual map and registry, sweeps the museum's walker through the entrance, checks supported arrival and an unobstructed walk past the console, exercises native pickable signals, checks point identity and relative offsets, tests metric invariants, and captures all seven spaces. It samples actual stencil pixels with the writer on/off and with an opaque foreground object. It must reach its last assertion; an aborted test cannot pass.

This is author validation of installed encounters. It is not a fresh ghost-student reconstruction of an expanded tutorial. The existing frozen plane/sphere tutorial and its earlier receipts remain unchanged. Expand that tutorial after this built spatial passage has been reviewed.
