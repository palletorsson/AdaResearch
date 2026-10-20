# Seven spaces in the Endless Museum

Installed in `NonEuclidean_Spaces`, alongside its existing artifacts. The narrow pink-topped doorway at hall-local `(13,1,7)` opens into seven full-size chambers. Open `museum.tscn` here and run the current scene to start in the actual museum hall. The launcher writes its own `user://` settings and does not change the saved museum route.

Take the black point from its small podium. This carries the existing `noneuclid-lineage/point_body.gd` unchanged, with the same instance carried between chambers. Its byte-identical copy lives in this artifact because `doc/` is excluded from exported game builds; the probe verifies the match. Desktop uses the museum's right-click pickup/drop and left-click held action; XR uses the existing pickup function and held-object action. Controls also sit on the left-hand console. Drop the point to press a button on desktop. **Next**, **Previous**, **Museum** and **Recall point** remain available. Next in the seventh chamber returns to the first.

| Chamber | What the visitor does | What is actually computed |
| --- | --- | --- |
| 1. A room that will not fit | Enters a gallery containing a small pavilion. Its rose and blue doors open into separate 14 x 12 m interiors whose apparent footprints overlap. Carries the same point in, leaves it, returns and retrieves it. | Bidirectional Godot 4.6 stencil views, sector/aperture culling, rigid positional transfer, swept head crossing and split held-point visuals. Connected Euclidean rooms; no claim of intrinsic curvature. |
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

### Around the corner (11 October extension)

In the first chamber, follow the gold floor line along the pavilion's right side to **AROUND THE CORNER**. Walk into Room 0001. The solid inner block hides its next doorway until you round the corner. Continue through the coloured door into Room 0002, turn right again, and continue. Four right turns restore your heading but take you into another numbered room. Walk backwards through the same doors to return to the museum.

`corner_rooms.gd` extends the existing portal graph. Each ordinary 12 x 12 metre room turns the route right. Consecutive rooms rotate their layout by 90 degrees, while each paired doorway preserves the visitor's world orientation and hand offset. One room ahead is prepared on entry, out of sight behind the solid corner. The route has no authored last room. This changes spatial connections; it does not simulate intrinsic hyperbolic curvature.

At most five corner rooms are resident: the first, current, previous, next, and any room holding the dropped point. Distant empty rooms are freed and deterministically rebuilt when revisited, using bounded physical slots. Room numbers, colours and landmarks are reproducible. The one live PointBody is never rebuilt or cloned. This is session continuity, not a new disk-save system; arbitrary additional editable objects are not part of this cache's persistence contract.

The existing stencil views, aperture culling and split point apply to these doors as well. There is no travel button, camera rotation, or forced fade. Preview lighting remains simplified and views are one level deep. Physical headset/stereo/Quest checks remain open.

```powershell
python -X utf8 tools/run_encounter_probe.py NonEuclidean_Spaces --sequence foundationscrisis --render --rendering-method mobile --no-bridges --output-tag corner-rooms-mobile --probe tools/probes/corner_rooms.gd
python -X utf8 tools/run_encounter_probe.py NonEuclidean_Spaces --sequence foundationscrisis --render --no-bridges --output-tag corner-rooms-gl --probe tools/probes/corner_rooms.gd
python -X utf8 tools/run_encounter_probe.py NonEuclidean_Spaces --sequence foundationscrisis --render --rendering-method mobile --no-bridges --output-tag overlap-corners-regression --probe tools/probes/overlapping_rooms.gd
python -X utf8 tools/run_encounter_probe.py NonEuclidean_Spaces --sequence foundationscrisis --render --rendering-method mobile --no-bridges --output-tag wing-corners-regression --probe tools/probes/noneuclidean_wing.gd
python -X utf8 tools/publish_corner_rooms.py
```

The corner probe sweeps the actual museum collision body around twelve successive corners, checks backward traversal and regeneration, retains a dropped point while reaching Room 0019, and checks the five-room limit. Its pictures come from the real renderer. The two earlier overlapping rooms and seven-chamber wing are tested separately for regressions.

### Overlapping rooms (11 October extension)

The first chamber now contains a 6 x 3 metre pavilion. Walk around its solid exterior, then enter either coloured door. Rose has round columns and gold rings; Blue has square columns and cyan frames. Both interiors have ordinary physical floors and walls. The same live `PointBody` passes between them; a point left in one stays there until collected or explicitly recalled. The wing's original Next/Previous controls remain at the left wall.

`overlapping_rooms.gd` owns four directed portal links. It renders only the occupied sector plus one level of previews through visible connecting apertures. CPU sector, front-face, camera-frustum and eye/aperture-pyramid tests reject disconnected or invisible preview geometry. GPU stencil masks restrict the remaining pixels, including foreground occlusion. Remapped portal depths let remote objects correctly obscure remote floors. This is portal visibility culling, not recursive portal rendering or a GPU timing benchmark. Hidden sectors keep their physical state.

The visual proxy for the held point is clipped at the doorway when the hand reaches through before the head. There is still one live pickable. Releasing it beyond the aperture transfers that instance into the destination. The proxy geometry has no physics bodies or copied behaviour scripts. Portal previews use a simplified directional finish; room lighting and wall labels are rendered normally after entering. Other portals seen through a portal are not recursively rendered.

```powershell
python -X utf8 tools/run_encounter_probe.py NonEuclidean_Spaces --sequence foundationscrisis --render --no-bridges --output-tag overlapping-rooms --probe tools/probes/overlapping_rooms.gd
python -X utf8 tools/run_encounter_probe.py NonEuclidean_Spaces --sequence foundationscrisis --render --rendering-method mobile --no-bridges --output-tag overlapping-rooms-mobile --probe tools/probes/overlapping_rooms.gd
python -X utf8 tools/run_encounter_probe.py NonEuclidean_Spaces --sequence foundationscrisis --render --rendering-method mobile --no-bridges --output-tag seven-spaces-overlap-regression --probe tools/probes/noneuclidean_wing.gd
python -X utf8 tools/publish_overlapping_rooms.py
```

The focused test uses the actual museum walker and desktop hand pickup/drop methods, verifies release/retrieval and hand-before-head behaviour, checks floors and approaches, tests the culling decisions, and samples real portal/depth/foreground pixels. Physical XR headset acceptance remains open; Mobile here means the native desktop Mobile renderer.

### Original seven-chamber regression

Run from the repository root:

```powershell
python -X utf8 tools/run_encounter_probe.py NonEuclidean_Spaces --sequence foundationscrisis --render --no-bridges --output-tag seven-spaces --probe tools/probes/noneuclidean_wing.gd
python -X utf8 tools/run_encounter_probe.py NonEuclidean_Spaces --sequence foundationscrisis --render --rendering-method mobile --no-bridges --output-tag seven-spaces-mobile --probe tools/probes/noneuclidean_wing.gd
python -X utf8 tools/publish_noneuclidean_wing.py
```

The probe loads the actual map and registry, sweeps the museum's walker through the entrance, checks supported arrival and an unobstructed walk past the console, exercises native pickable signals, checks point identity and relative offsets, tests metric invariants, and captures all seven spaces. It samples actual stencil pixels with the writer on/off and with an opaque foreground object. It must reach its last assertion; an aborted test cannot pass.

This is author validation of installed encounters. It is not a fresh ghost-student reconstruction of an expanded tutorial. The existing frozen plane/sphere tutorial and its earlier receipts remain unchanged. Expand that tutorial after this built spatial passage has been reviewed.
