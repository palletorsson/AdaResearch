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

### Labyrinth loop (12 October extension)

Enter Blue; its rear-right gold doorway says **LABYRINTH / LEAVE A MARK**. Four ordinary rooms form A–B–C–D–A. Leave the original point in A and return to it after a full circuit. Bring the held point within 0.35 metres of A's west gold seal to open the A–C shortcut. Both collision barriers release; the connection stays open for the running session. Return to Blue via A's south door.

`labyrinth.gd` provides static sectors -5 to -8; paired frames preserve world heading and hand offset. This is a finite connectivity encounter. It differs from the endlessly generated corner chain and periodic gallery. Probe `tools/probes/labyrinth.gd` uses native hand placement and actual collision sweeps, with tags `labyrinth-mobile` and `labyrinth-gl`; forest regression uses tag `forest-labyrinth-regression`. Publisher `tools/publish_labyrinth.py`; report `doc/book/iterations/2026-10-12-labyrinth-the-point-remembers/index.html`. Physical headset acceptance remains open.

### Column forest (12 October extension)

Enter Blue; the rear-left gold doorway says **COLUMN FOREST / GAUDI**. Eight polygonal twisting shafts branch into a sampled vaulted lattice. The nave stays clear. Carry the same point sideways to adjust the small front study's branch angle (18–55 degrees). Desktop uses the ordinary held point and view turning. Its trigger shows/hides cyan geometric guides. Return to Blue through the same door.

`column_forest.gd` is a Gaudí-inspired geometric interpretation, not a surveyed basilica, reconstruction of double-twist columns, or structural load simulation. Dynamic branch transforms/guide visibility also update their doorway proxies. Native probe `tools/probes/column_forest.gd` uses tags `forest-mobile` and `forest-gl`; regression tags `wing-forest-regression` (`noneuclidean_wing.gd`) and `repeating-forest-regression` (`repeating_gallery.gd`). Publish with `tools/publish_column_forest.py`. Review: `doc/book/iterations/2026-10-12-column-forest-a-profile-branches/index.html`. Headset acceptance remains open.

### Repeating gallery (12 October extension)

Enter Rose from the first chamber's pavilion. The rear-left cyan door says **REPEATING GALLERY / MANIFOLD**. A 7.68-metre physical tile has four supported wrap thresholds and eight batched visual neighbours. Cross a gold edge and keep walking; the same held point and your heading translate by one period. Leave the point and walk a lap to find the same instance. The smaller off-axis doorway returns to Rose.

`repeating_gallery.gd` owns the flat X/Z wrapping and fixed 3 × 3 visible patch. Visual neighbours have no physics or scripts; point echoes share its mesh and finish without cloning the live PointBody. Gravity stays upright. This is a Manifold Garden-inspired repetition study, not its gravity-changing mechanic or an intrinsically curved space. Stereo/headset acceptance remains open.

Probe: `tools/probes/repeating_gallery.gd`, native renderer tags `repeating-mobile` and `repeating-gl`. Regression probes: `overlapping_rooms.gd` with tag `overlap-repeating-regression`, `perspective_corridor.gd` with tag `perspective-repeating-regression`. Publish using `tools/publish_repeating_gallery.py`. Review: `doc/book/iterations/2026-10-12-repeating-gallery-the-same-point/index.html`.

### Perspective corridor (12 October extension)

The gold doorway to the left of the first chamber's Rose/Blue pavilion says **PERSPECTIVE / BORROMINI**. Enter with the same point. Stand on the gold viewpoint disk, then walk along the level marked path outside the colonnade. Both converging sides have full-height walls to sustain the axial depth illusion. The outside path reveals the tapered enclosure; the overhead survey shows its construction.

This Borromini-inspired study has an eight-metre passage, a floor rising 0.6 metres, an interior width tapering 3 → 0.84 metres, and a clear height tapering 3.4 → 1.3 metres. The sphere's radius stays 0.085 metres. It is a geometric proposal, not a surveyed reconstruction of Palazzo Spada. The gallery and its physical measurements remain Euclidean. A new static sector (-2) uses the same portal/hand transport as the existing spaces and returns to the lobby.

Probe `tools/probes/perspective_corridor.gd` checks native museum entry, the side walk, floor support, column dimensions, unchanged sphere size and identity, and return. Run with `tools/run_encounter_probe.py` using tags `perspective-mobile` and `perspective-gl`, and run `tools/probes/corner_rooms.gd` with tag `corner-perspective-regression`. Publish with `tools/publish_perspective_corridor.py`. Review: `doc/book/iterations/2026-10-12-perspective-the-sphere-keeps-its-size/index.html`.

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
