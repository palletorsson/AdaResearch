# The Void

## Body charge and retained hands / 20 October

The body now has one battery, starting at 100. Walking drains 0.1 charge per
metre of actual horizontal travel. Standing, turning, spawn relocation and
passive platform carriage do not intentionally consume charge. A deliberate
jump costs five points on landing; an uncushioned hard one-floor drop costs
five too. Marked pads still cushion passive drops. Skipping a floor remains fatal.
These rules supersede the earlier health and landing costs recorded below.

The first wall charger is on Point Trace (floor 04), on the existing unfinished
wall beside the drawing aisle: position `[3.65,-5.3]`, facing 90 degrees.
It connects to that floor's northeast overhead socket. The roof has no charger.
It restores eight points per second while its button is held within reach.
The exposed electrical junction on the roof discharges twenty
points, with a 1.5-second contact cooldown. Both are reusable props in the
lab editor. An empty battery uses the existing dark-red shutdown and last-floor
restart, restoring 100 charge. Existing pickups and calmed crawlers refill this
same resource through compatibility methods in `health.gd`; museum saves and
health are separate.

The starting VR body is a simple humanoid with two existing IK arms and the
original hand scenes, finger animation, grip and pointer. The sleeve cuff
follows the forearm instead of inheriting the hand's full rotation. The
growing costume and extra limbs are disabled only for the Void. The inferred
torso and legs are an initial representation, not full-body tracking or a
finished walking animation. Desktop retains its existing mouse interaction.

Native screenshots, charge rules and executable evidence:
`doc/book/iterations/2026-10-20-charge-and-care-body/index.html`.

## Triangle / original museum interactions / 19 October

Floor 5 follows Point_Triangle_Context/final.md: close three edges before
filling; carry the original Trace into an open outline; edit both scales;
collapse/restore area; shift the concave fan's first corner; share vertices
in the quad and strip; compose twelve triangular faces. Proof walls, mesh
threshold, three large braces and directional signs remain.

LiveTwin moved from world (-9.75,-30,0), inside shaft A, to (-16,-30,0) on the
west slab. Five captions follow their curator-placed objects. Other artifact,
prop and wall poses are preserved. Nine shaft rays pass clear at this storey.
The small drawing now honors SHOW / HIDE FILL through `show_local_fill`; its
two-winding mesh culls hidden faces, avoiding coplanar transparency flicker.
The existing parasol is restored as the independently editable FacingTriangle:
pink front, blue back. Correct winding/culling and unshaded painted colours
keep that orientation comparison readable in the evening light.

Original museum map, final.md and tutorial.md remain unchanged. Shared layout
and Desktop backup agree. Lab-editor models are exported from actual Godot
geometry. `python tools/test_triangle_museum_return.py` checks desktop and
synthetic XR; add `--capture` for Mobile screenshots. Editor validation:
`node tools/test_triangle_museum_return_editor.cjs`. Report and detailed limits:
`doc/book/iterations/2026-10-19-triangle-museum-return/index.html` and WORK.md.
The old 23-stop route guide and south-edge folded-strip placement are retained;
these encounter tests do not certify every route through curator placements.

## Point Trace / original museum interactions / 19 October

Floor 4 keeps the original glass wall and pens, three 10/40/80 mm beads,
same-gesture sampling monitor and replenishing ball ramp. The smaller Shadow
point and lit trace remain. Six captions now accompany the curator's moved
objects; route guidance reaches the bead row and Grid's west-rim controls.
No artifact/prop placement, source museum map, final.md or tutorial.md changed.

The imported Grid walking recorder now shares the floor-aware Lines adapter,
with `preserve_museum_style`: its one-metre quantization and unrounded ghost
remain, but it follows the real desktop/XR body on this storey and clears on
sleep. This temporary walking record is separate from released bead strokes.
Bead release sends an exact copy of world positions to session TraceData;
Grid transforms a display copy. Glass ink and ball trajectories stay local.
This archive survives floor streaming/retry, not application shutdown.

Run `python tools/test_trace_museum_return.py` for desktop and synthetic XR
assertions; add `--capture` for native Mobile screenshots. Editor copy/move/
rotate and non-destructive save validation: `node tools/test_trace_museum_return_editor.cjs`.
Report: `doc/book/iterations/2026-10-19-trace-museum-return/index.html`.
Resolved in the Triangle pass above: the imported MuseumPlinth that intersected
shaft A below Grid now stands on the west slab. This verifies that obstruction,
not every descent or landing throughout the tower.

## Point Lines / original museum interactions / 19 October

The original map and final.md remain the encounter references. Floor 3 keeps
Palle's arrangement, free joining field, gate puzzle, black measuring room,
1:10 plan, 1:1 ruler, markings, barriers, material studies and light tunnel.
Imported X/plus artifacts now use Void health. The original player_trace uses
the floor-aware adapter; one recorder draws, and streaming clears it on sleep.
This walking recorder is separate from the hand trace carried into Grid.

Six independent DepthGridHorizontal/Vertical rods restore the plane-to-depth
study beside the tunnel. They use the existing LineBody and remain individual
lab-editor parts. Movable assembly rods now use the original break/rebuild
reaction; fixed bridge/guard rods are excluded. Original imports already had
their reactive/burn settings. Source map, final and tutorial are untouched.

`python tools/test_lines_museum_return.py` exercises desktop and synthetic XR
in Godot; add `--capture` for the rendered XR pass and screenshots.
`node tools/test_lines_museum_return_editor.cjs` checks
the exported models and real editor operations without saving test copies.
The screenshot report records verification scope and current curation:
`doc/book/iterations/2026-10-19-lines-museum-return/index.html`.

## Point Coordinates / restored ball target / 19 October

The existing `museum-point_coordinates-10-6` target on floor 2 now uses its
original `arrows` encounter. Carry the same black point within 45 cm of the
red arrow: seven white rigid-body balls fall with live world X/Y/Z labels.
Staying inside does not repeat; leaving and returning releases another seven.
The coordinate frame stays fixed. All saved placements are preserved.

Only this Void instance's configuration changed. `drop_height: 3.4` keeps its
3.4–4.8 m spawn band beneath the next storey. The original artifact script,
museum map, tutorial and final text are unchanged. The target remains a movable,
copyable artifact in the lab editor, sharing the desktop/VR layout and Desktop
backup. Its editor model is a static preview; balls run in Godot.

`python tools/test_coordinate_ball_target.py --capture` checks the actual
target with desktop grip and synthetic XR, including falling/landing, live
labels, entry/re-entry and the fixed frame. Physical headset testing remains
with Palle. Screenshots and results:
`doc/book/iterations/2026-10-19-coordinate-ball-target/index.html`.

## Point Coordinates / fixed frame / 19 October

Palle confirmed that the coordinate frame stays fixed during play: only the
black point moves. The experimental amber handle, extra panel and reset button
have been removed. The original axes, projection guides and WORLD/LOCAL wall
cards remain, with the frame still placeable in the lab editor. The original
museum map and its final.md remain the reference for this encounter. The
moving-frame screenshot report is retained as a superseded experiment.

## Melencolia / carried forms / 19 October

Floor 12 closes Primitives with the original nine-piece pyramid court, winged
skull, three pickable solids, box library and running counter. The saved route
visits the court from more than one position, goes past the tableau, then
reaches the composition table and eastern return. Tested clearances take the
visitor around the table and the south pillar.

`melencolia_composition.gd` adapts the existing tetrahedron, cube and octahedron
scenes to a comparable 0.65 m envelope, deriving their convex collision from
the visible mesh transform and keeping rigid-body scale at one. Their source
geometry and scripts remain. Shelf snapping is disabled for these instances;
release freezes the placed body. Each has a shadowless light while held.
The table readout counts changed placements. RESTORE skips held bodies and
uses poses captured after editor configuration. All four editor part names
remain stable; copying the table alone safely leaves it with no linked solids.

`python tools/test_melencolia_return.py` runs native desktop/synthetic-XR
assertions. Add `--staged --capture` for actual Godot pictures; export with
`python tools/export_void_editor.py`, then run
`node tools/test_melencolia_return_editor.cjs` for production-editor checks.
Report: `doc/book/iterations/2026-10-19-melencolia-carried-forms/index.html`.
The reflection and tutorial are preserved. This encounter prepares a possible
next pass on the separate Transformation trial without changing its layout.

## Profiles into Portals / 19 October

Floor 11 now begins with a small editable `ProfileToRing` study beside the
existing ramp. It uses Profiles' actual letter I and unchanged `profile_sweep.gd`.
PATH +90 changes the circular path through 90/180/270/360 degrees; I / ROUND
changes only the section. The closed path joins the seam instead of adding caps.
The round section has 32 sides and the full path has 96 segments. RESET returns
to the open 270-degree I sweep. The section specimen, controls, readout and light
move together when this part is moved, turned or copied in the lab editor.

The original Achilles and tortoise table is now beside the southern approach;
its controls sit above the tabletop. All original artifacts and curator copies
remain. The walk still uses the original torus refinement, wedges, one-metre
cubes, F33 bridge, rideable transport platform and bounded skull/cube/ring
arrivals. Desktop and VR use the same saved layout. Tutorial and final texts
are unchanged by this spatial pass.

`python tools/test_portal_handoff.py` checks source geometry identity, watertight
meshes and topology, outward normals, accessible button areas, actual pointer
events, the approach route, the complete walk and ride, pickup/release, and
independent copies in desktop and synthetic XR. Add `--staged --capture` for
native screenshots. Export with `python tools/export_void_editor.py`, then run
`node tools/test_portal_handoff_editor.cjs`. Physical headset review remains open.
Report: `doc/book/iterations/2026-10-19-portals-carried-profile/index.html`.
Next proposed spatial pass: Melencolia, floor 12, composing with the carried forms.

## Floors as cliffs / 19 October

Palle's spatial premise: the repeated museum hall became an unfinished tower
because descending to another ledge offered a more compelling encounter. The
next landing should be visible from the edge. Crossing a floor leads to another
drop; the architecture carries part of the experience.

The shared base now adds an irregular concrete slab to each of floors 01–13.
Three convex outlines stagger left/right along the south facade, projecting
3–3.8 m beyond the original 42 × 18 m floor. This supersedes the initial
opposite-facade study: the next floor is reached on the same side. They are flush, 0.36 m thick, and
use matching polygon collision. The roof rail has a four-metre launch opening.
Shape and offsets live in `layout.json:cliff_landings`; `cliff_landings.gd`
builds the same geometry for desktop, VR and the exported lab-editor models.
These are fixed architecture, not draggable props. Authored rooms remain editable.
Trials without this optional setting keep their own base.

Concrete landings now cost five charge and retain the grounded checkpoint;
skipping a floor remains fatal. The shaft-B plank pads remain the cushioned
alternative. The shafts, Grid, existing artifacts and saved arrangements were
not moved. On Point Lines, aim inside the entry enclosure, not onto its rear wall.

`python tools/test_void_cliffs.py --capture`: 160 landing/collision checks plus
42 existing fall, death and recovery checks passed using desktop and synthetic
XR tracking. Every floor-edge descent and the first direct balcony-to-balcony
jump are exercised. Physical headset comfort and route preference still need Palle's
play test. Images: `doc/book/iterations/2026-10-19-void-cliff-landings/index.html`.

## First maps as sequence trials / 19 October

Palle's current direction is to adapt the first map of every spine sequence,
learning what capacities transfer and what needs adaptation. Open
`http://localhost:3003/void-trials`: 25 authored opening briefs follow the live
curriculum order, with original artifact inventories, tutorial/final links and
project-saved observations. See `trials/README.md` for the working agreement.
The board does not place artifacts or modify the curated tower. Source checks,
native interaction tests and physical headset observations are separate evidence.

Start with Transformation / Trans_Pre. Preserve the still collectible cube,
then cumulative translation, rotation and scale demonstrations, before a short
route to finished pickups. Record reusable capability and later-map exceptions.
Palle chose separate selectable trial floors. Transformation is now playable
via Main menu -> Void trials -> Transformation, and editable at
`/lab-editor?mode=void&trial=transformation&floor=1`. Its layout, score, previews,
browser drafts and Desktop backup are separate from the curated tower.
The latest Trans_Pre route arrives through shaft A, compares the original cube
motions, climbs a one-metre cube/wp platform, and departs through B. The 30
building pieces remain individually editable. Both shaft centres stay open;
marked corner boards cushion the two drops. See
`doc/book/iterations/2026-10-19-transformation-two-shafts/index.html`.
See `doc/book/iterations/2026-10-19-void-separate-trials/index.html` for evidence
and the outstanding headset review / existing menu shutdown issue.
Run `python tools/void_sequence_trials.py --check` for the source inventory and
`node tools/test_void_trial_store.cjs` for review persistence/conflict checks.

## Mechanical crawler and sight / 19 October

The existing Cube-floor crawler now has an original industrial head (pale
armour, optical slit, respirator and moving grippers). Its Void-specific gait
keeps eight mechanical legs in separate radial sectors. Planted feet are
constrained during turns and reset after relocation; the original museum
octapod scene is unchanged. The lab-editor model is exported from this creature.

Shared desktop/XR rules: a bite still costs 20 health with a three-second
cooldown. Each bite adds 0.42 sight impairment, capped at 1, and starts a fresh
ten-second linear recovery from the current impairment. Another bite during
recovery increases the impairment. Any actual positive healing clears sight;
reset clears it too. A normal ten-point floor landing does not trigger blur.
Death retains the existing grunt, dark-red fade and checkpoint restart. The
catalyst still calms the crawler; nearby healing remains 10 health every two
seconds. There is no camera shake, camera takeover or head attachment.

`health.gd` owns both health and sight state. `sight_effect.gd` binds the active
camera. `sight_blur.gd` performs two raster passes per eye, after transparency,
using the native colour format; Mobile cannot use storage-image colour buffers.
The effect is disabled at zero impairment. Compatibility desktop uses a final
CanvasLayer pass; headset blur requires Mobile or Forward+. Physical headset
comfort/performance has not been verified by the automated checks.

Run `python tools/test_void_crawler_sight.py` for timing, healing, death,
geometry clearance through 720 movement/turn samples, and real crawler attacks
with both desktop and synthetic XRTools players. Add `--staged --capture
--renderer=mobile` (or `forward_plus` / desktop `gl_compatibility`) for real
screenshots and pixel checks: blur strengthens and healing restores the original
image. Existing spider, tower, fall and landing probes remain regressions.
Report: `doc/book/iterations/2026-10-19-crawler-sight/index.html`.

## One game, desktop and VR / 19 October

Persistent requirement from Palle: **desktop and VR are the same game**. Keep
layout, artifacts, progression, health, enemies and checkpoints shared. Input
adapters translate gestures; they must not create shortcuts or alternate rules.

Both modes use `rooms.json`, the original artifacts and `first_catalyst_ability.gd`.
`player_rules.gd` owns speed, jump, acceleration, drag and pointer reach. The VR
player remains the rig shared with `base.tscn`. The desktop hand extends the
existing museum mouse pointer and uses XRTools' actual pick-up/let-go lifecycle;
pickup lights, coordinate feedback and triggers therefore receive the same events.

Desktop: WASD to move, mouse to look, Space to jump, right click to pick up/release,
wheel to adjust carry distance, left click to use/drag. Hold C to bring empty
virtual hands together, then left click to send the earned catalyst. Unlock,
formation delay, cooldown and projectile rules are shared with VR. C alone does
not shoot. R retries the checkpoint; T returns to the roof; M opens the menu.
Escape releases the cursor; click the view to return to mouse look.

Run `python tools/test_void_shared_play.py` for native input/physics checks in
both modes, actual switch and point interactions, spider behaviour, fall damage,
safe landings and rig regressions. Mouse-input tests use the window backend
because headless Godot cannot capture the mouse. XR tests use synthetic trackers;
they do not establish physical headset comfort or test every museum artifact.
Results: `doc/book/iterations/2026-10-19-void-shared-play/`.

## Autosave, group placement and live rulers / 19 October

The web lab editor autosaves after one second to the same `rooms.json` that
desktop and VR read when The Void starts. Restart play to apply changes; this
does not rebuild floors under a player. A previous-version backup remains in
`ada_run/void-editor-backups`, and the latest file is mirrored to Desktop / Ada
Void / rooms.json. Saves are serialized with revision conflict protection. Failed
saves remain visibly unsaved, with a browser draft available for download.

Placement heuristics now return warnings to the editor. Previously two rooftop
warnings blocked saving unrelated Lines edits. Schema errors, missing resources,
duplicate IDs and invalid part names still block saving. The strict CLI validator
retains its spatial checks. Review warning locations in the actual game.

Ctrl/Cmd-click (or Shift-click) selects multiple objects in the list or viewport.
Drag, arrow keys and inspector coordinates move them together; selecting a parent
and its child does not move the child twice. Undo/Redo and Copy/Paste preserve the
group. R rotates each selected root around its own origin.

`lines_survey.gd` retains the existing pickable endpoints and segment calculation.
They now move freely in XYZ. `survey_ruler.gd` carries bounded, live graduations
along the actual segment: table 1:10, large ruler 1:1. There is no large static
board. Released points remain local to their editable assembly. Zero-length and
vertical segments are supported. `survey_blueprint.gd` draws the structural
outline, shafts, columns, balcony, saved partitions and entrance enclosure at 1:10.
It is an architectural drawing, not an inventory of every loose artifact or prop.

Run `node tools/test_void_editor_autosave.cjs` and `python tools/test_void_survey.py`,
then `python tools/export_void_editor.py` to update the web geometry. Report and
native captures: `doc/book/iterations/2026-10-19-live-rulers-and-editor/`. The native
test verified all 48 saved floor-03 part overrides, real XRTools pickup/release,
3D distances, scale ratios and bounded graduation geometry. Physical headset
testing remains separate. User placements were preserved through this change.

## Readable signs and construction fence / 19 October

The four pink direction signs use unshaded, nonreflective ink on their round
black fields. Their physical TURN buttons and direction states are unchanged.
The Lines entrance points start 0.60 m apart, slightly toward the landing.
Retry restores that spacing and keeps an already solved gate open. The enclosure
uses matte white walls. Its door reuses `fence_segment.gd` through `entry_fence.gd`:
a tubular frame, thin diamond wires in one MultiMesh, and an attached DANGER /
DO NOT ENTER / AUTHORIZED PERSONNEL ONLY plate. The door and its collider rise
together through the original puzzle mechanism.

Run `python tools/test_void_signs_fence.py`, then `python tools/export_void_editor.py`
to refresh the real editor models. Captures and native test results are in
`doc/book/iterations/2026-10-19-signs-and-fence/`. Saved room placements are unchanged.

## Triangle light, rooftop title and Point One / 19 October

Triangle's original handles now activate `triangle_edge_light.gd`: luminous
edges plus at most two shadowless lights per artifact. The skin reads the real
snap lines, drawn faces, shared diagonal, folded strip and held table pieces.
Release lets the light expire after two seconds. Geometry, puzzle state and
stored drawings remain owned by the original artifacts. Triangle work lamps
use energy 1.2. Each editable part owns its lighting, including independent copies.

Point Zero keeps its live frame counter, enlarged to 3.5x, beside the independent
`void_roof_letters` artifact: 9.6 m wide extruded ADA RESEARCH lettering.
Point One removes the three small study plinths; the glossy future sphere keeps
its base. Four small downward lamps terminate the pink rods. The reusable
`point_light_switch` prop uses the original museum hand/pointer button to switch
these lamps, without changing the sun. Its state survives floor streaming.

All placements live in `rooms.json`. Roof letters, counter, switch, triangle
parts and construction props remain movable/copyable in the lab editor. Save,
then restart The Void to load the arrangement. Source museum defaults and book
texts are unchanged.

Validation: `python tools/test_void_triangle_light.py`, then
`python tools/export_void_editor.py`, then
`node tools/test_void_triangle_light_editor.cjs`. Native tests cover actual
XRTools with simulated controllers, switch pointer events, geometry tracking,
streaming and independent copies. Mobile captures compare real light on/off.
See `doc/book/iterations/2026-10-19-triangles-roof-and-points/index.html`.
Headset frame time has not been measured.

## Visual quality / 19 October

The playable scene now sets its own rendering profile through `render_quality.gd`.
Balanced uses 4x MSAA; Performance uses 2x. FXAA and TAA are disabled to retain
fine text and moving geometry. Mobile/Forward+ use debanding for the sky and fog;
Compatibility skips it. The viewport allows 8x anisotropic filtering, with local
copies of eligible textured structural/prop materials. Artifact materials, live
screen textures and intentional nearest filtering are left alone. These changes
do not add lights, postprocessing blur or supersampling.

Select **Visual Quality** on `commons/void/void.tscn` in Godot, or launch with
`-- --void-quality=performance` for the lighter option. Viewport settings restore
when leaving the tower. Re-enter/restart the game to pick up this code change.
The web editor retains its own renderer; layouts and exported model geometry
are unchanged.

Run `python tools/test_void_visual_quality.py` and again with `--compatibility`
and `--forward-plus` (one renderer at a time). All 22 checks pass in each renderer.
The report is `doc/book/iterations/2026-10-19-void-visual-quality/index.html`.
Controlled screenshots compare AA/debanding off against Balanced: older capture
tools already forced 4x MSAA, so this is not a claim that every earlier view lacked
anti-aliasing. Headset frame time still needs measurement on the target device.

## Point Trace becomes light / 19 October

The three existing drawing beads and the small black drawing point on floor 04
now carry `trace_light.gd`. It reads the original recorded positions and displays
them as 24 mm luminous tubes in one MultiMesh per drawing. At most two short-range,
shadowless lights sit along each trace, with fixed total energy. Release keeps the
mesh and illumination; clearing a live bead removes both. Separate black-point
strokes stay separate. Recording, quantization and the TraceData-to-Grid handoff
are unchanged. The Grid and all authored placements remain untouched.

Both Trace work lights use energy 1.2. Existing drawing parts and editor copies
own their light components; the floor residency system sleeps/restores them.
Run `python tools/test_void_trace_light.py`, `python tools/export_void_editor.py`
and `node tools/test_void_trace_light_editor.cjs`. Native tests include real
XRTools with synthetic controllers, desktop movement, Grid reuse and matched
Mobile light-on/off captures. Report:
`doc/book/iterations/2026-10-19-trace-becomes-light/index.html`.

## Point Lines opens and carries light / 19 October

Floor 03 now starts in an open-top enclosure on the south landing. The original
two-endpoint line (`lines_entry_gate.gd`, derived from `line_black_box.gd`) opens
a steel grid door after a held endpoint approaches the other within 0.24 m for
0.25 s. The gate stays open through retry and floor streaming. The checkpoint
spawn follows the editable entrance assembly, including direct floor starts.

`lines_survey.gd` reuses that same segment and XRTools endpoints for a 1:10
structural floor-plan table and a separate 1:1 five-metre ruler. Their constraints
are local to each assembly. Seven existing lengths hang on the collection wall.
The original pink `Hand_light` illuminates a new roofed passage while held;
other movable line bodies also illuminate their surroundings on pickup.
`line_touch_light.gd` is a Void-only attachment; source museum skins are unchanged.
Floor 03 work lights use energy 1.2, as on Coordinates. Existing bridge rails
were returned to the shaft crossing to clear the new entrance route.

Move/copy `MeasurementRoom`, `FloorPlanTable`, `FullSizeRuler`, `LightTunnel`,
individual line bodies and `CollectionHangers` in the lab editor. JSON remains
the shared source for VR. Original book texts and source map remain unchanged.

Run `python tools/test_void_lines_light.py`, then `python tools/export_void_editor.py`
and `node tools/test_void_lines_editor.cjs`. Native checks use synthetic XR
controllers, not a physical headset. Report:
`doc/book/iterations/2026-10-19-lines-that-open-and-light/index.html`.

## Point Coordinates carries light / 19 October

On floor 02, the existing held black point now has `carried_point_light.gd`:
one warm, shadowless OmniLight with a 3.8 m range, visible only between the
pickable's pickup and drop signals. It is attached to the real point, so grip,
editor placement, streaming ownership and coordinate readouts retain the same
object. A local glossy black material override remains non-emissive on pickup.
The Coordinates work-light profile is 1.2 instead of the catalog's 7.5; copied
work lights on this floor inherit the same profile. Other halls are unchanged.

Run `python tools/test_void_point_light.py` for actual XRTools controller tests
and Mobile screenshots, including matched light-on/off renders at two positions.
Report: `doc/book/iterations/2026-10-19-point-carries-light/index.html`.
Physical headset frame time and comfort are not inferred from these checks.

## Evening lighting study / 19 October

The shared atmosphere now defaults to evening: low pink sun, plum/violet sky,
cool ambient fill and darker depth fog. `atmosphere.gd` retains `lighting_mode`
0 (daylight) and 1 (evening), with `set_lighting_mode()` for a live comparison.
The twelve-minute cycle, 1 Hz updates, incremental 128px sky reflections and
six-metre clear fog distance remain. No volumetric fog or post-process is added.

The Void catalog gives the reusable work-light prefab energy 7.5 and range 10 m;
the prefab's original defaults remain for other scenes. Six extra stands serve
the rooftop counter, future sphere, Lines measurement, Trace release, Triangle
proof and Polyhedra boundary areas. The Trace drawing lamp turns 180 degrees.
All use the same editable prop records; artifact and route records are unchanged.
Preview and sleeping floors hide their Light3D nodes; live floors restore their
authored light visibility, including after return.

Run `python tools/test_void_evening.py` for Mobile captures, actual work-light
contribution and synthetic XR binding. `tools/test_void_fog.py --renderer=mobile`
with a new `--out` folder verifies the real autoloads respect evening lighting.
Report: `doc/book/iterations/2026-10-19-void-evening/index.html`.
Restart The Void to see the lighting change. The web editor remains a geometry
preview; headset comfort and frame time still need a physical play-through.

Nine structural levels: the rooftop and four existing lesson floors, followed by
four empty floors for the depth study. The authored descent currently ends at
Point Trace; floors 05â€“08 have no safe route built yet. Launch the project (F5),
then choose **The Void** in the main menu. This uses the normal XR staging path.
For desktop-only iteration, open `void.tscn` and run the scene (F6).

## Nearby floors

The playable scene enables `stream_floors` by default. `floor_stream.gd` shows
at most nine structural levels: four above, the current level, and four below.
Slabs retain their simple collision even outside this window. Columns, risers,
signs and ceiling services have per-storey visibility.

Only the current floor runs its complete artifact collection. The next floor
is prepared one assembly per frame; scene resources load sequentially on a worker
before main-thread construction. Preview visibility uses each authored part's
world bounds against the two shaft openings, with a 1.5 m margin. Moving or
copying a part in the lab editor changes this selection automatically.
The preview freezes bodies, disables scripts, sound, particles and screen updates,
and keeps collision only on its visible supports. Hidden parts leave physics.
Entering the floor restores its normal behaviour before landing. A fast descent
or checkpoint jump completes unfinished loading synchronously to keep supports safe.

Previously visited floors sleep in RAM. This keeps the actual objects, saved
traces, ink and altered catalyst cells intact. Holding an object keeps its owning
floor live; a released object carried away from that floor also stays live while
within eight metres of the player. This can temporarily increase the live content
count. Re-entering a sleeping floor wakes the same instances.

Playable depth fog runs from 6 to 30 metres with full density at its far end,
using the existing slowly shifting pink/violet sky. It uses standard fog on the
Mobile path; no volumetric pass. The architectural viewer retains its full view.

The Environment is marked `scene_owned_atmosphere`. `NatureRenderer` respects
this for fog and ambient lighting: its deferred boot previously found the Void's
WorldEnvironment and reduced fog density from 1.0 to 0.01 at vegetation density
1.0 (or disabled it at density 0). The isolated streaming test missed this
autoload interference. `python tools/test_void_fog.py --capture` now checks the
full project's startup and real player camera. Repeat with `--renderer=mobile`
and a separate `--out` folder for the Mobile path. Restart play after this fix;
the existing Environment instance must be recreated. Before/after evidence:
`doc/book/iterations/2026-10-18-void-fog-runtime/index.html`.

This bounds visible structure and ordinary active content, not total memory:
visited instances and shared resources remain cached. Large factories can still
produce a construction spike; background I/O does not split their `_ready()`.
Quest frame time and comfort require headset testing.

Run `python tools/test_void_stream.py --capture` for native streaming assertions
and Mobile screenshots. Add `--out=doc/book/iterations/2026-10-18-void-nine-levels`
to use the nine-level report folder. Report: `doc/book/iterations/2026-10-18-void-nine-levels/index.html`.
From Point Trace (floor 04), look up and down shaft A to see four floors each
way. To start there for a desktop inspection, pass `-- --void-start-floor=4`.
The earlier Mobile captures showed fog but did not include the nature autoload;
the full-runtime test above now verifies that fog stays active. Transparent
shaft sheets remain unimplemented. If a headset needs that fallback, use two-sided, non-colliding shaft
planes at offsets 2â€“4, smoothly increasing alpha with camera height; never cover
the next landing. That fallback is a proposal, not enabled geometry.

## Controls

### Stick comparison room

F5 â†’ **Movement test** beside The Void. `motion_room.tscn` inherits the actual
`game.gd` player builder, with the existing coordinate point and black line room
on one flat floor. It has no tower streaming. Same hands, pickups, head-relative
left-stick walking/strafe, right-stick forward/backward and 30Â° snap turn.
Right B resets; left Y compares the tower
with telemetry; left X returns to the menu. Desktop R/T/M are the equivalents.

The optional `motion_meter.gd` records raw/adjusted input for both sticks, per-tick
input ranges, walking stalls, speed, frame p95/max and physics/headset rates.
It also observes existing slide collisions: bounded collider paths, normals,
visibility, layers and body position. The readout names recent non-floor hits
and marks hidden nodes. It does not alter movement or run extra collision queries.
Bounded summaries save on exit to `user://void-motion-room.json` or
`user://void-motion-tower.json`. Normal tower play has no meter unless launched
from this room or with `--void-motion-test`. No global calibration is changed.

Both sticks use XRToolsUserSettings: per-axis deadzone/remap and optional
per-controller rest-offset correction. The inspected PC settings file has
X=0.20/Y=0.10; the HUD shows live values, which can differ after visiting a base
scene. Snap turn reads right X separately with a 0.25 threshold and still turns
30Â° once per deflection. PlayerBody applies a 0.1 m/s control threshold,
traction=30 acceleration and drag=5 braking (unless a surface overrides them).
The old base.tscn VelocityDeadzone (0.15 m/s) and JoystickDeadzoneFix (fallback
X=0.30/Y=0.50; optional calibration) are not mounted in the Void. Their global
settings can nevertheless survive a previous scene until the app restarts.
No filter, sensitivity or calibration values were changed by restoring right Y.

`python tools/test_void_motion.py --capture` passes 108 assertions across 29
movement trials in the actual project, with native Mobile rendering and
synthetic XR trackers. Both sticks move forward/back at 60/90 Hz; tests also
cover left strafe, turning while walking, release, combined-input speed cap,
pickup/carry/drop, reset and one jump per held press. The process exits cleanly
with no engine or script errors. Automated samples go to the
report folder, not over a player's headset record. It does not establish actual
controller quality or headset frame delivery.

`python tools/test_void_collisions.py` uses the actual staging scene, then the
room, tower and menu return. 25 functional checks / eight walking trials passed;
no persistent menu obstruction, duplicate capsule or hand-mushroom collider.
A temporary hidden wall verifies the contact readout's positive detection.
The entire process is currently a FAILED check because of staging cleanup:
44 null-material messages, 61 retained resources, Windows exit 0xC0000005.
`--menu-baseline` reproduces the same failure without loading the Void or meter.
The separate rendered 108-check motion suite passes cleanly. Do not describe the
staging process as a clean pass or assume it establishes physical headset comfort.

Report: `doc/book/iterations/2026-10-18-void-movement-room/index.html`.

### City, ambience and feedback

`soundscape.gd` reads `audio/manifest.json`. Wind, two distant city sources and
sparse bird calls and rare distant sirens use VoidAmbience. Wind is 10 dB and
city 12 dB quieter than the first sound pass. Birds wait 50â€“110 s; sirens wait
120â€“240 s, including arrival. Calls do not overlap; sirens stay at distant city
positions below the tower and fade gently. Rendered songs use VoidMusic and register
with the existing SoundBank; the default playlist is empty. Put MP3s under
`audio/music/` and add their resource paths to the playlist. VoidEffects carries
positional grab, release, click, activation and rejection/damage cues. The three
bus levels are independent; no runtime synthesis or external generation service
is required. Initial sounds are original provisional offline synthesis.

Bindings observe existing signals, including newly supplied ramp balls. They
ignore sleeping/preview sources, rate-limit slider/contact repeats, cap object
voices at eight, and cull beyond 24 m. Static displays do not produce invented
interaction events. Set `void_sound_enabled=false` metadata before binding for
an object that already has sufficient feedback; for a new signal-less operation
use `game.soundscape.play_cue(kind, world_position)` after it succeeds.
The city silhouette uses one MultiMesh with 72 bodies and no collisions.

Sound-making handoff: `audio/CLAUDE_SOUND_BRIEF.md`. Test:
`python tools/test_void_audio.py --capture`. The test uses actual project
autoloads and an audio dummy driver, plus real XRTools with synthetic tracking;
headset listening remains essential. Report and listening sketch:
`doc/book/iterations/2026-10-18-void-city-sound/index.html`.

### Input

| Action | VR | Desktop |
| --- | --- | --- |
| Move | Either stick forward/back; left stick sideways | WASD / arrows |
| Look / turn | Head + right stick sideways (30Â° snap) | Mouse |
| Jump | Right A, once per press | Space |
| Carry the black point | Hold either grip; release to leave it | View only |
| Use held object | That hand's trigger | â€” |
| Catalyst / aim at dark floor panels | Empty hands together, then either trigger (earned ability) | C (camera aim, inspection shortcut) |
| Retry saved floor | Right B | R |
| Restart on roof | Left Y | T |
| Main menu | Left X | M |
| Release mouse | â€” | Escape; click to capture again |

The VR appearance reuses the animated hands, wrist-following IK arms and
PlayerCustomization/wardrobe from `commons/scenes/base.tscn`. The wardrobe
reads the existing progression and outfit preference. `avatar.gd` mounts these
on the Void's controllers; there is still one collision body and four movement
providers. Grips animate and hold; the trigger animates and uses the held tool.

The shared first catalyst requires empty hands within 24 cm for 0.15 seconds;
after forming it tolerates separation up to 32 cm. Either trigger fires in that
controller's direction. Moving apart cancels it. Its existing unlock is respected.
The old unconditional left-trigger shot and right-trigger jump are removed.
Recovery clears the formed catalyst and suspends it until the checkpoint is ready.
To test the VR ability, launch through the normal project/staging with its
CatalystCapabilityManager; the isolated desktop scene keeps C for inspection.

`python tools/test_void_avatar.py --capture` exercises actual hands, pickup,
jump and the shared ability using synthetic controllers and captures Mobile
renders. It does not measure headset comfort or grant live progression.

Land safely on a main floor or its marked balcony to save it (0.18 seconds
grounded). Passing a floor's height does not save it. A hard one-floor landing
costs five charge; it is survivable if enough charge remains. The allowance is
measured from the last support surface, so the upward arc of a jump does not
count against it. Going beyond one storey (6 m plus 0.35 m collision tolerance),
an excessive impact above 13 m/s, or falling outside the building causes death.
Deliberate jumps cost five charge on contact; passive drops onto marked timber
pads remain cushioned.

Damage plays a short synthesized grunt. Death fades to opaque dark red over
0.3 seconds, relocates to the checkpoint at 0.65 seconds, then clears the fade
between 0.85 and 1.2 seconds. Movement and grabbing are disabled during recovery.
Charge returns to 100 and falling velocity is cleared. Checkpoints last for this visit;
returning to the menu and entering again begins on the roof.

Both shafts are open through all three slabs, with no intermediate platforms.
The early route uses one balcony on each lower floor: Floor 01 projects south,
Floor 02 north. Walk through the rooftop rail opening, jump onto the pink pad
below, cross Point One and pass through its north doorway to the next pink lip.
Each balcony is 6 Ã— 2.4 m and flush with its floor. Only a top contact on its
marked cushion absorbs a normal six-metre jump (up to 13 m/s). A larger impact
still kills; a normal one-floor impact on concrete now costs health instead.
Floors 04 and 05 use the staggered shaft timber described below.

Run `python tools/test_void_fall.py --capture` for real desktop/XRTools falls,
health costs, skipped floors, checkpoint recovery and Mobile death-fade captures.
Grunt source: `commons/void/audio/grunt.wav`; regenerate only this sound with
`python tools/build_void_audio.py --grunt-only`.

The frame is now 42 Ã— 18 m: six metres added on each side, leaving an 8.5 m bay
beyond each shaft for later exhibits. Twelve columns support the widened frame.
The four current artifact stations and catalyst area remain in the central hall.
Point Lines on Floor 03 now supplies a fixed timber crossing and movable line
specimens. Player-built load-bearing structures remain a direction for later work;
the old fixed ledge study remains an alternative layout mode, not a building tool.

## Sources

- `layout.json`, `architecture.gd`: shared permanent frame, slabs, shafts,
  services and cushioned balconies. Roof rails have colliders; service pipes
  and braces remain visual details.
- `void.tscn`, `game.gd`: playable XRToolsSceneBase, scene-local checkpoints,
  death and recovery; no changes to museum progress/saves.
- `jump.gd`: edge-triggered jump provider. Uses the real XRTools body, direct
  movement and snap-turn providers. Catalyst fire and direct grip pickup are available. Flight and desktop pickup
  have not been added to this prototype's rig.
- `walker.gd`: desktop companion controller.
- `layout_viewer.tscn`: original architectural viewer, without game rules.

VR comes through the project's existing XR setup. Standalone Quest testing
requires exporting/installing the current project; no APK is built by the test.

## Verification

`python tools/test_void_game.py --package --capture --menu`

Real Godot 4.6 / Jolt collisions; synthetic XR trackers feed the real XRTools
body and controller providers. Traverses all three balcony jumps continuously, checks
both expanded wings, rail collision, ordinary fatal impacts, excessive pad
impacts, checkpoint recovery, tracking preservation and input.
The package test runs a Windows PCK with the Android preset's exclusions, from
an empty runtime directory. It is not an Android/headset performance test.

Menu integration runs the actual menu callback through a staging fixture,
plus initialization in the full project. The package also checks the typed
XRToolsSceneBase assignment required by the real staging loader. The menu's
existing null-material cleanup messages reproduce in a menu-only baseline;
they are recorded separately in the report rather than hidden.

Latest route report: `doc/book/iterations/2026-10-18-void-point-lines/index.html`.
Physical headset comfort/reach and Quest performance still need playtesting.

## Above the clouds

The playable scene and architectural viewer both use `atmosphere.gd` and
`cloud_sky.gdshader`: a blue/lilac sky, peach horizon, warm low sun and a pale
cloud sea beneath the tower. The cloud sea is a distant sky background, not
a landing surface. A single generated noise texture supplies the clouds;
there is no animated volumetric simulation or per-frame texture generation.

Depth fog begins 6 metres from the camera and increases towards 60 metres,
so nearby landing targets and checkpoint floors remain clear. The same standard fog
and sky run on Forward+ and Mobile. Both render paths have native desktop
captures; that verifies rendering, not Quest frame rate or headset comfort.
The active desktop or XR camera explicitly uses this environment so a
staging environment cannot take precedence over the scene's fog settings.

Reload The Void from the game menu, or F6 `commons/void/void.tscn`, to see it.
Before/after views: `doc/book/iterations/2026-10-18-void-sky/index.html`.
Optional Mobile render check: add `--mobile-capture` to the game test command.

## Point One on Floor 01

`rooms.json` places the existing `point_absent`, `point_visible`, `point_solid`
and `point_pedestal` scenes on Floor 01 (-6 m). They connect to SW, NW, NE and
SE respectively; their positions can differ from these fixed supply sockets.
The first three studies have matching off-white podiums; the final 1.3 m
black sphere keeps its original glossy material and larger pedestal.

The visible and solid scenes receive `config: {"study_plinth": true}` via
the existing placement configuration hook. This adds supports without
changing either sphere's collision condition. The shared artifact defaults
remain unchanged, so the original museum corridor still has unsupported
visible/solid points. The first podium remains empty. The source
`Point_One/map_data.json` is not modified.

The north wall carries the museum title and Point One label. Both shaft
approaches and the existing catalyst patch remain accessible. These are
fixed studies, not grabbable spheres; the held-point encounter remains a
separate artifact.

Report: `doc/book/iterations/2026-10-18-void-point-one/index.html`.

## Point Zero and the floor editor

The rooftop now carries Point Zero's existing running frame-counter scene,
the existing `you_are_here` floor marker, and the Origin scene at world zero.
Its wire cage rises above the roof rather than being buried inside the slab.
The tower's two shafts provide the descent; the old museum arrival shaft is
not instantiated around them. The original Point_Zero map remains unchanged.

Open **http://localhost:3003/editor/void**. There is a link in `/editor` and
a **The Void / floor editor** button in Godot's MapToolEditor inspector.
The encyclopedia dev server must be running. Save, then re-enter The Void
to read the new arrangement; a running headset does not hot-reload this file.

- `layout.json` remains the fixed structural frame: levels, columns, slabs,
  shafts and descent geometry.
- `rooms.json` is the compact content layer, one record per floor: map link,
  title, optional walls, construction scenery, station connections, artifact
  positions/settings and impact cells.
- `rooms.schema.json` describes that layer. `tools/validate_void_rooms.py`
  is used by both the editor API and CLI. It checks structure and known map /
  artifact IDs, prevents double-booked stations, and protects checkpoints,
  balcony approaches, shafts, columns and minimum artifact access footprints.
  Walls and scenery can use the wider floor within these constraints.
- `catalog.json` names four floor stations: NW, NE, SW, SE. Each placement
  has a facing of 0, 90, 180 or 270 degrees. 0 faces +Z; 90 faces +X.
  Artifacts retain scale, height and their existing `apply_grid_config` settings.
  Search the editor palette to use the project's registry beyond the initial
  counter/marker selection. Large artifacts still need a spatial fit check;
  the editor does not infer a reliable footprint for every registry scene.
- A visible steel channel and pink cable connect every station to the
  vertical electrical riser. Elevated artifacts receive a cable and support.
  This is common supply infrastructure; electricity and power failure are
  not simulated yet. World zero is a fixed reference, not a fifth station.
- Only authored catalyst panels respond to the existing projectile dispatch.
  A hit raises one panel in 0.3 m steps, then returns it to its initial height.
  Mesh and collider agree. The permanent slab remains beneath it. Ordinary
  contact and elapsed time do not change it. Changes persist across death
  during this visit and reset when the scene is reloaded.

The web API preserves the full floor record, validates before writing,
rejects stale revisions and keeps timestamped backups in
`ada_run/void-editor-backups`. It does not modify the museum map files.

Checks: `python tools/test_void_editor.py` (server on port 3003),
`python tools/test_void_game.py --package --capture`,
`python tools/test_void_layout.py`.
Report: `doc/book/iterations/2026-10-18-void-point-zero-editor/index.html`.

Next decisions: the actual power on/off contract; artifact footprint and
controller reach; which artifact state survives death. Preserve the marked
balcony route, open shafts and safe floor checkpoints as these are developed.

## Point One / a concentrated court

Floor 01 now has a compact comparison row: absent (-3,2.5), visible (0,2.5),
solid (3,2.5). The glossy future sphere is beyond it at (0,-4.3). These are
floor-local X/Z positions; the floor remains at Y=-6. The four original
supply sockets stay fixed, with cable leads to the relocated artifacts.
Their original scene logic, plinths and collision differences are preserved.

One standard 40 ft shipping container screens the east side: 12.192 m long,
2.438 m wide, 2.591 m high. Two large packing crates frame the entrance. West and north
walls meet the existing pillars. The north door has a 2.5 m lintel base; its
opening leads to the second balcony. The west checkpoint still has access.
This is construction-site scenery around the lesson, not additional tutorials.

### Edit the same floor in the encyclopedia

Open `/editor/void`, select Floor 01:

- Select an artifact, then **Move artifact on plan**, or edit Artifact X/Z.
  `position` is optional; without it the artifact sits at its supply socket.
- **Place scenery** chooses a container or crate, then places it on a half-metre
  grid. Select a piece to move, rotate, recolour or remove it. Crates can also
  be scaled; the container retains its standard external size. Exact
  coordinates can also be typed, independent of the placement grid.
- **Draw wall** creates a horizontal/vertical segment. Base height 0 starts on
  the floor; a raised base makes a lintel. Wall height is measured from its base.
- **Save to Godot**, then reload The Void. The same `rooms.json` drives both views.
  A running game does not hot-reload or receive a remote edit on Quest.

The schema adds optional `props`, artifact `position` and wall `base` fields,
so earlier floor records continue to load. `catalog.json` supplies the scenery
sizes and defaults to both the editor and runtime. `set_dressing.gd` makes
matching static collision shapes; corrugations use MultiMesh instances.
Scenery does not consume the four artifact slots or react to catalyst hits.

Validation checks structural bounds, rotated scenery footprints, shafts,
columns, checkpoint and balcony approaches, catalyst panels and minimum artifact
access footprints. Walls can connect into columns. Headers above 2.3 m can
span walkways. Registry mesh sizes are not inferred: the minimum artifact
access check does not prove every imported artwork fits, nor can these local
checks guarantee every edited route remains connected. Playtest a new layout.

The frame remains `layout.json`; authored floors remain `rooms.json`. The
web editor is the content editor for the tower, not another copy of the level.
Original museum map files and the tower's death/checkpoint rules are unchanged.

Evidence: `doc/book/iterations/2026-10-18-void-real-container/index.html`.

Container dimensions: https://www.marguisa.com/en/solutions/container-service/
(length/width/height; the catalog stores width/height/length for Godot X/Y/Z).
The editor shows dimensions and the schema requires unit scale for containers.


## Point Coordinates / Floor 02

The second descent reaches the existing `point_held` on its own plinth, the
`CoordinateSystem3M` frame and two `coordinate_readout` scenes. A dedicated
`void_coordinates` channel keeps WORLD and LOCAL tied to this frame. The point
retains the original `point_one_main` identity and XRTools pickable behavior.
Either hand can grip it; release leaves it where it was placed. Retry/death
returns it to the plinth so a point released over a shaft remains recoverable.

The L-shaped basin is one metre deep, cut out of the actual slab and closed by
walkable glass at floor level. Its footprint follows the pink X and black -Z
arms. The frame's display scale is 1.35 here (4.59 m shafts), fitting its upper
arrow and label below the next slab. It keeps the museum's opaque pink, grey
and black palette. WORLD includes the tower floor elevation; LOCAL uses the
frame's position, orientation and scale. The player's point is not confined
to the ends of the drawn axes.

`rooms.json` contains the basin rectangles and all four placements. The editor
shows the basin footprint and preserves it on save. The schema and shared
validator protect shafts, columns, approaches and catalyst cells; solid walls
and scenery cannot fill the basin. Basin geometry is currently edited in JSON;
the visual editor displays it but does not yet provide drawing handles.

A catalog scene may opt into `configure_before_ready` to receive its existing
configuration before construction. Coordinate tools use this to avoid creating
a temporary duplicate point. `wall_mounted` allows a readout to overlap a wall's
plan footprint while still checking its access against other objects.

Report and captures: `doc/book/iterations/2026-10-18-void-coordinates/index.html`.
Verification includes real XRTools grip/release and retry with synthetic inputs,
WORLD/LOCAL values, walkable glass, recessed bottom, continuous descent, and
container mesh bounds as well as collider dimensions. Forward+ and Mobile
captures are desktop renders; physical headset testing is still required.

## Point Lines / Floor 03

A third alternating balcony descent reaches Y=-18 m. Coordinates now has a
clear central opening in its south wall. Its two wall readouts move outward
so the departure to this balcony remains clear.

Four assemblies reuse existing artifacts, with one supply connection per area:

1. West wing: twelve connecting points, the black measurement room and an
   unarmed surveying laser.
2. Central slab: two blue painted wooden police barricades, WALK THIS LINE, a red shaft warning,
   parallel survey lines, a floor trace and FOLLOW THIS LINE climbing a white
   crate before continuing without collision over the shaft.
3. East wing: the original pickable line skins, +/X studies, parallel and
   upright lines, seven increasing planks, a workbench, fixed timber crossing
   and crossed edge guard. Fixed construction cannot be grabbed. Loose
   specimens retain the gallery's frozen-on-release behavior.
4. Near the arrival: the existing X and + passage artifacts. Their optional
   health-provider reference connects them to the tower's local health.
   Other museum instances retain their original health-provider fallback.

X subtracts 14 every 0.6 seconds while occupied. + restores 28, caps at 100,
and returns after five seconds. The pair has a bypass. Health depletion and
fatal falls use the same last-safe-floor checkpoint. Recovery restores health,
resets the line specimens and measurement room, and clears the floor trace.
It also retrieves lost pairing points; their existing connections are retained.

The editor displays four work areas and a crossing footprint that follows the
assembly's position, facing and scale. Internal arrangements live in
`lines_area.gd`; these are grouped assemblies, not individually draggable props
in the current editor. Changed placements need another traversal check, since
minimum artifact bounds cannot validate all internal geometry.

The original `commons/maps/Point_Lines/final.md` is preserved. `final.void.md`
keeps its reflective passages and updates the choreography for this floor.
The tutorial and main museum map are unchanged. The four-area report shows
native eye-height Forward+ photographs, with a Mobile-render comparison.

Run `python tools/test_void_game.py --reuse --package --capture --mobile-capture
--out=doc/book/iterations/2026-10-18-void-point-lines` on one line.
The isolated package excludes external menu/museum exit destinations; full
project menu integration is covered separately by `--menu`. The desktop
controller can walk and jump; direct hand pickup is tested through the real
XRTools providers with synthetic input. Physical Quest playtesting remains.

## Grid within Point Trace / Floor 04

Grid stays entirely on Trace, by explicit placement decision. `trace_area.gd`
adds `GridReplay` to the recording assembly. `grid_area.gd` places the existing
`grid_lines.tscn` lattice in shaft A at (-10,-25,0), one metre below Trace, with
its original readout on the east rim at (-6.9,-22.8,1.8). The lattice is not a
walkable surface. Shaft B retains Trace's existing timber descent.

Released drawings enter the existing TraceData archive. Grid displays a copy
and its grid-aligned version, preserving the source record. Grid shares
Trace's floor-streaming lifetime. The lab editor exposes GridReplay as a
movable, rotatable and copyable part; user placements are stored in rooms.json.
No separate Grid floor is assigned yet.

Verify with `python tools/test_void_grid.py --capture`; export the editor
preview with `python tools/export_void_editor.py`. Report and native images:
`doc/book/iterations/2026-10-18-void-grid-shaft/index.html`.

## Triangle / Floor 05

`Point_Triangle_Context` now follows Trace, with Grid still on floor 04.
`triangle_area.gd` mounts four assemblies of existing scenes: the three-edge
closure and construction plate; the drawing tool, live twin and reveal monitor;
the four-edge puzzle, editable quad, folded strip and pink triangle; and the
twelve-piece assembly table. The Void table starts with a partial fan, two
raised faces and loose pieces, as if someone has left a composition in progress.
All twelve remain independently pickable; the original museum table keeps its
row layout. A single unfinished backdrop focuses the arrival.
The floor's individual parts are exported to the shared lab editor. The folded
strip uses a 1.75 geometry scale here: seven metres long, with broader faces.
Its handles and replay panel retain their normal physical size.

Shaft B has two staggered timber landings, at Y=-27 and Y=-30. The first retains
the Trace checkpoint; the second saves Triangle. Existing shaft A Grid is not
a landing. Earlier floor arrangements are preserved.

The drawing area waits until its floor first becomes live before importing the
latest TraceData record. This matters because it can preload while the player
is still drawing upstairs. The original drawing tool reduces and flattens a
copy to at most six corners; the raw trace is retained. An absent trace gets
the existing three-corner reference. Later visits and retry preserve edits.

Run `python tools/test_void_triangle.py --capture` for native interaction,
lineage and descent assertions, then `python tools/export_void_editor.py` to
refresh the real editor models. The quad's optional narration managers are now
looked up at runtime so its scene also loads in isolated previews. Its geometry
and interaction are unchanged. The original map, final.md and tutorial.md remain.

Report: `doc/book/iterations/2026-10-18-void-triangle/index.html`.
Editor: `http://localhost:3003/lab-editor?mode=void&floor=5`.
The checks use real Godot code and synthetic XR controllers, not a physical
headset. A saved editor rearrangement still needs a traversal check in VR.

### Construction triangles and proof walls

Three full-height bolted chevron bays stand in succession along the east side,
inside the column faces (`construction_triangle_brace`).

The former floor-proof placement now contains `pythagoras_cubicle`: a 7 × 7 m
open-front room whose three walls are paired proofs. Each wall is 7 m wide and
3.9 m high, with two 3.5 m square diagrams. Leg ratios are 3:4, 2:5 and 1:6.
Display numbers are diagram units. All panels use the original `pythagoras_floor`
geometry in `diagram_only` mode; its standalone floor version is still available.
The front and top are open, and the controls remain outside the entrance.
SWAP animates the same 24 triangle objects; RESET restores the six diagrams.
The stable editor part key is `PythagorasFloor`.

Four round pink signs stand together at the back of the west wing. Each has a
metal post, weighted base and TURN button. The editor parts are `PinkTriangle`
(up), `PinkTriangleDown`, `PinkTriangleLeft` and `PinkTriangleRight`. They are
separately movable and copyable; copies own independent direction state.
The original square pink-triangle scene retains its default appearance.

The carried drawing, live twin, three steel bays, folded strip and assembly
remain. Earlier floors, original map and book texts remain unchanged.

Run `python tools/test_void_pythagoras.py --capture` for native area and geometry,
interaction, wall collision/open entrance, editor copy, carried Trace and route
checks, then `python tools/export_void_editor.py` for real editor models.
Report: `doc/book/iterations/2026-10-18-void-pythagoras/index.html`.

### Mesh reveal zone

Floor 05 reuses `wireframe_threshold` beside the folded strip in the west wing.
Enter its 1.7 m diameter ring to see the actual rendered triangle edges; leave
to restore surfaces. The lab-editor part is `MeshRevealZone`, including its
floor instruction and occupancy volume. It can be moved or copied. It changes
the viewport while occupied; it does not change meshes, collisions or materials.

Run `python tools/test_void_mesh_zone.py --capture` for physical entry/exit with
the desktop and synthetic XR bodies, overlap/copy/removal restoration and actual
Mobile rendering. Report: `doc/book/iterations/2026-10-18-void-mesh-zone/index.html`.

## Polyhedra / Floor 06

`Primitives_Polythedra` follows Triangle through two timber landings in shaft B
at Y=-33 and -36. The intermediate landing keeps Triangle's checkpoint; the
lower landing saves Polyhedra. Floor 07 now continues into Cube.

Four adapters reuse the original scenes: vertex alignment and a corner
tetrahedron; open/closed bodies, boundary plate, editable pyramid and unfolding
monitor; a bank of standing prisms; and the wedge platform, six-piece column and
mouse model. The raised platform uses the artifact's existing standalone ramps.
The original rock enclosure and diamond basin remain in the museum hall.
The original map, interaction implementations and book texts are unchanged.

The arrangements expose individual parts to the lab editor, including the
plinths and timber descent. Two work lights, a tarp scaffold, a stud wall and
two corner partitions remain separately editable. Move the whole support work
area to carry the platform, column and maze together. `rooms.json` has a
31-point route; its overlay is planar, while the native movement probe follows
the platform at its actual 0.9 m elevation. Completed alignment bodies and
edits persist on return; retry recovers escaped pickable pieces.

Run `python tools/test_void_polyhedra.py --capture` for descent, traversal,
original interactions, retry and synthetic XR assertions. Then run
`python tools/export_void_editor.py` and
`node tools/test_void_site_editor.cjs --polyhedra` for model and placement checks.
Tests never save their trial copies into the shared layout.

Report: `doc/book/iterations/2026-10-19-void-polyhedra/index.html`.
Editor: `http://localhost:3003/lab-editor?mode=void&floor=6`.

## Complete Primitives route / Floors 07–13

The tower now contains fourteen occupied floors, following the fifteen-map
Primitives spine with Grid still on the Trace floor. Floors 00–06 retain their
saved arrangements. The remaining order is Cube, Primitives/Ignorance, Godot
Primitives, Columns, Profiles, Portals and Melencolia.

`primitive_hall.gd` is a placement adapter for the existing museum scenes and
mesh factories. Each named direct child is an editable part in the lab editor;
the seven `primitive_*.tscn` scenes are registered in `catalog.json`. Their
placements, prefabs and walking routes live in the same `rooms.json` used by
desktop and VR. The first arrangement includes work lights, selected tarp
scaffolds and two timber landings per floor in shaft B. Streaming and checkpoint
selection use the expanded fourteen-level frame. Restart The Void after saving.

The paired cube, folding net and 24-box library introduce Cube. The five original
solids, sphere atlas, smoothness budget and resolution catalyst occupy Primitives.
Eight original mesh resources and Seven Words Choir occupy Godot Primitives.
Columns retains all 25 recipes, with its five controlled columns at 4.67 m and
varied heights multiplied by 0.85. Profiles retains all six original sweep meshes
and their collisions at 0.64 exhibition scale. Portals uses seven original rings
at 0.58 scale and the manual Zeno study. Melencolia reuses the existing engraving
scene and returns to pickable solids and the box library for composition.

The original map files, tutorial.md and final.md texts are unchanged. These
floor arrangements are a first spatial pass for playtesting, not evidence of
student learning or headset comfort. Native tests use the actual Godot player
body for collision, walking and descent; editor tests use temporary in-memory
layouts and never save trial copies into the shared arrangement.

Validation: `python tools/test_void_primitives.py --capture` (165 native checks),
then `python tools/export_void_editor.py`, then
`node tools/test_void_primitives_editor.cjs` (15 model, copy and placement checks).
The headless native run is faster if screenshots are not required.

Report: `doc/book/iterations/2026-10-19-void-primitives-complete/index.html`.
Editor: `http://localhost:3003/lab-editor?mode=void&floor=7`.

### Scientific and strange / Cube encounter

Design rule: meet a thing, change one relation, notice a consequence, test it
again, carry that capacity onward. Exactness comes from declared conditions and
repeatable operations. Strangeness comes from discovering a consequence inside
an apparently familiar object.

The Cube adapter adds `cube_edge_study.gd` to the existing paired-cube scene.
TRY 25 cm restores both position lists, permits the single pink handle, then
moves corner 6 by +0.25 in local z. The original artifact mirrors the handle
and rebuilds both surfaces using its unchanged face lists. The added instrument
measures each shared triangle edge's midpoint z. At this controlled setting the
midpoints share local x=0, y=0; their z values are 0.500 and 0.625 metres.
During free editing, the readout explicitly stops implying a common x/y sample.
RESTORE and REPLAY keep their original distinct meanings. A held handle blocks
the preset, so it cannot reset the object while the player is carrying it.

The instrument moves with the `PairedCubeDiagonals` editor part. The museum
source scene and the tutorial/reflection texts are unchanged. This first
prototype applies the rule to Cube; it does not claim the other encounters
have already been redesigned.

Run `python tools/test_void_cube_edge.py --capture` for independent rendered-mesh
intersection, repetition, restoration, synthetic XR grip/release and editor
transform checks. Then export editor geometry using `tools/export_void_editor.py`.
Report and compact encounter card:
`doc/book/iterations/2026-10-19-cube-same-points-different-surface/`.


### Prefab library / 2026-10-19

The lab editor opens a **Prefab props** tab with 16 picture cards, search and
category filters. Choose a prop, then click the floor; Escape cancels. **On
this floor** returns to the placed-object list and cancels pending placement.
Pictures and GLBs are exported from the same Godot scenes used by desktop/VR.
The existing blue wooden barricade, warning tape, steel crowd barrier, traffic
cone and workbench are now available as independent placements. The blue
barricades in Point Lines and the reusable palette read **DO NOT CROSS**.
Existing floor placements were preserved.

Native probe: `tools/probes/void_prop_library_probe.gd` against the staged Void
project: 13 geometry, rotated-collision and legend assertions passed. All 16
models/thumbnails are served; all five new prop kinds passed the editor's save
validator using an in-memory draft. Whole-web TypeScript checking has unrelated
existing failures; none were reported in the modified lab-editor files.


### Introduction / carried crossing, 2026-10-19

The separate Transformation trial now continues from Pre (floor 1) through B
to Introduction (floor 2). The same wp and unit cubes form two banks beside A;
the shared ferry carries four cubes between them. An A landing reaches the
catch floor below. R / B or death returns to the current encounter.

Thirty parts remain editable at
`/lab-editor?mode=void&trial=transformation&floor=2`, including a fixed route
anchor for the moving platform. Native copy/rotation tests use an actual
editor-generated record. No tutorial/final text or curated tower layout changed.

95 desktop/synthetic-XR assertions, 48 native-render assertions, nine editor
checks and the 112-check Pre regression passed. Headset review remains pending.
See `doc/book/iterations/2026-10-19-introduction-carried-crossing/index.html`
for screenshots, commands and remaining test limitations.

Update: Introduction's crossing now occupies a raised lethal pit in the central
bay. Seven editable unfinished partitions make arrival -> ramp -> ferry -> far
bank -> descent the walkable route. The shafts retain open interiors. 41 artifact
parts plus seven wall objects; 121 desktop/synthetic-XR assertions and eleven
editor checks pass. Latest native images and limitations:
`doc/book/iterations/2026-10-19-introduction-hazard-pit/index.html`.

### Void voxel construction / Translation, 2026-10-20

Open `/voxel-editor?mode=void&trial=transformation&floor=3` to paint cubes,
quarter-metre slabs and the original two-metre wp wedges, or place suspended
moving platforms. Base height selects the painting layer; platforms use deck
height. Select a platform to edit its local travel vector, speed and pause.

Both editors use the existing revision-checked layout save API and Desktop
backup. The optional `construction` array in each floor is loaded by
`construction_grid.gd`: sparse static cells become MultiMesh batches with
collision, and carriers remain individual moving bodies. Reopen the trial
after saving to load changes in desktop or VR.

Translation's former single crossing assembly is now four cubes, four wedges,
two raised slabs and a carrier, individually editable in either editor.
78 native desktop/synthetic-XR assertions and nine editor/API checks pass;
physical headset review remains pending. Screenshots, browser checks and usage:
`doc/book/iterations/2026-10-20-void-voxel-editor/index.html`.

Translation now trials a steel mezzanine: two 6 × 3 m banks at 3 m height,
reached by the original Cube/wp ramps and joined by the suspended carrier.
The voxel palette includes `truss`, `deck` and `support`. Their dimensions and
brace geometry come from `steel_modules.json`, shared with the browser.
Each steel kind uses a single native MultiMesh batch; collision follows the
individual bars and tiles. “Match 3 m mezzanine” sets deck/truss base heights.
78 desktop/synthetic-XR and eight editor/API checks pass. Screenshots and
editing instructions: `doc/book/iterations/2026-10-20-translation-steel-mezzanine/index.html`.
