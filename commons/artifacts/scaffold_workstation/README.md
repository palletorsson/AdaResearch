# The evolving scaffold workstation

The hand model is the construction record. The glass-bay copy is generated from
that same record, with the same connections. No second arrangement is authored.

## Random walk on the workbench

Glass workstations with rods now have a front RANDOM WALK strip. **ADD WALK**
generates 24 planar steps at the shown seed and merges their legal points and
one-metre rods into the current model. **NEXT SEED** selects the next seed;
press ADD WALK to apply it. **LOAD KEPT** imports the exact retained step from
the standalone constructive-walk bench's KEEP slot, on this device.

The whole addition is one ordinary UNDO edit. Repeated members are reused;
an incompatible overlap refuses the whole addition and preserves existing work.
Generated members remain hand-editable and use the shared blueprint save path.
**BUILD MODEL** copies those same records into the glass room, at the corrected
quarter scale. Put on the visor to enter; TAKE OFF VR GLASSES returns normally.
Generation is refused while visiting or holding a piece. The glass copy changes
only on BUILD, just like hand construction.

The mode button switches **2D / FLAT** to **3D / RAMPS**. In 3D mode, ADD WALK
grows a branching network using the same points, short rods, triangular surface
halves and wedge ramps. It needs a Polyhedra or later glass workstation with
surfaces and wedges enabled. The seeded walker starts at a ground-level corner;
its first connection is a ramp. Over 24 steps it can extend a level path, climb,
descend, reconnect to a landing, or retrace an existing connection. There is no
authored spiral. Growth is favoured over revisiting while legal space remains.
Branches and loops emerge from the retained connections; backtracking removes
nothing. Different seeds choose different routes and histories.

The domain remains a bounded 3×3 field of 2m landing tiles, up to 4m high.
Each ramp rises 1m over a 2m run, between level landings. Occupied tiles and
overhead floors exclude growth that would leave less than a 2.2m clearance envelope.
These are deliberate spatial constraints, not an unrestricted six-axis walk.

Every reached landing has a framed surface and support posts; wedges rest on
their own framed surfaces and retain physical gravity. The construction fits
the existing workshop domain. The glass room keeps its quarter-scale visitor
and fixed entrance. Existing UNDO and hand editing apply to the generated parts.
Use an empty model for the first 3D trial, or UNDO the preceding 2D addition;
overlapping incompatible structures are refused atomically. LOAD KEPT currently
imports the original 2D bench format and selects flat mode. The shared blueprint
does save the generated 3D construction; a separate 3D event-history save slot
and removal-over-time are not implemented yet.

Branching generation is covered by `tests/test_branching_walk.gd`; the native
scale probe walks every generated connection in both directions. See
[branching-walk evidence](../../../doc/book/iterations/2026-10-30-branching-walk/README.md)
for seed comparisons, the overhead-clearance correction and headset trial limits.

## 30 October: tool arc and scale visit

The shared semicircle holds point, 1m rod, 2m rod, triangle, quad, wedge and pyramid
in fixed positions above the model. Only the parts introduced by that floor can
be picked up. Later sockets remain empty. The solids now sit on this arc too,
inside the editable Model group, rather than on a separate side shelf.

The hand model remains at its existing size and keeps the canonical playground's
part proportions. Following the user's further scale correction, the glass
construction and visitor both use 0.25 of ordinary playground scale. A 20cm
hand rod becomes 50cm, a 10cm short rod becomes 25cm, and the hand wedge's 10cm
rise becomes 25cm. The glass copy is 2.5 times the hand model. Rod thickness,
joint size, surfaces and the test ball shrink by the same factor. From inside,
their dimensions relative to the visitor match the ordinary playground. This
replaces the previous model_scale = 0.4 / visitor_scale = 0.25 mismatch, which
made the construction feel 1.6 times too large. The six-metre shaft and
6.6m enclosure remain unchanged. The floor grid covers the full 6.4m clear span,
with 25cm cells and a fixed, marked START near the front, facing into the model.
BUILD reserves the arrival pad; entry checks it again for loose obstructions.
Saved graph records and canonical 1m/2m part sizes are unchanged.

BUILD first. The glass enclosure stays closed; entry is through the visor. Grip the visor on the small front-right side table and hold it near your eyes for 0.3 seconds.
Picking it up alone does not enter. Entry always uses the marked START pad. Desktop: right-click to grab, left-click while
holding. TAKE OFF VR GLASSES returns to the saved position and size; Escape is a
desktop fallback. Leaving the chamber also returns. Checkpoints, charge drain
and floor streaming pause during a visit. Rebuilding beneath the visitor is refused.

This is one reversible visit into the actual built copy, not another progression
system. A bench inside could introduce a second 1:4 relation (1:16 relative to the
tower). That recursive version is a proposal, not installed behavior: it needs a
stack of return positions and a bounded depth, and must decide whether an inner
edit can rebuild the structure supporting the editor. The current build rejects
nested scale ownership rather than losing the return route.

The sections below describe the canonical full-size part grammar. The display
edition applies its scale to that grammar without changing saved records.


## One work unit across six encounters

| Floor | Stock introduced | Valid attachment |
| --- | --- | --- |
| 1 / Point One | Six-port point | One cardinal neighbour of an existing point |
| 3 / Point Lines | One- and two-metre rods | Two points one or two metres apart |
| 5 / Triangle | Right triangular panel | Half of a square closed by four rods |
| 6 / Polyhedra | Wedge and pyramid shelf | Completed solids placed on the metre grid, with quarter-turn orientation |
| 7 / Animated Cube | Full square quad | One empty square closed by four rods |
| 20 / Transformation playground | Glass test bay and falling ball | Build, test support, revise the carried construction |

The hand model is 1:10. Its 10 cm and 20 cm rods become one- and two-metre rods.
The scaffold world still uses a 1 m grid: a rod spans two cells.
`model.gd` owns HAND_STEP = 0.2 m and WORLD_STEP = 2 m.
Module addresses are multiples of 0.5 (one physical metre). The same graph drives poses, meshes and colliders; rigid bodies retain unit scale. Two complementary
right triangles fill one square, on any of the three coordinate planes. The
diagonal is fixed for this first experiment. Animated Cube adds a full quad: the
same 1 × 1 or 2 × 2 m face takes one placement instead of two. Two short rods can complete a side of the larger frame. It cannot overlap a half
already occupying that frame. All three coordinate planes work. These panels are distinct from the
equilateral faces used by the retained TriangleTable folded-edge experiment.

Take the floating stock above the front of the grid. Bring it near a lit location; a bright preview
appears. Release to attach and return the tool to its tray. Desktop and XR use the
existing pickable's pickup/drop events. The current prototype auto-aligns stock
to the nearest legal position; arbitrary placement and free folding are separate
experiments. UNDO reverses the latest model step. An earlier edition cannot undo a
later surface it does not display.

The first Quest playtest reported a low table and difficulty reaching or starting
construction. The revised worktop is 1.10 m high (previously 0.85 m), with the model
60 cm nearer the player. The grid and sockets now move together as Model. Stock is
raised above the grid, the panel faces the player, and BUILD/UNDO are nearer the
centre. A low, inclined information card at the front-left edge replaces the
central board so the full-size result stays visible. Twelve translucent targets across six directions show
the first connections before pickup. A held rod or panel explains its missing
prerequisites; snap capture is 12 cm, without changing the metre-grid connection rules.

BUILD creates the full-size copy in the marked bay. Editing the model does not
remove the surface under someone walking on the previous copy. Rebuilding refuses
overlapping colliders or a player occupying the bay. Finished parts have physical
collision. Points, rods and faces are fixed construction; the new wedge and
pyramid are loose rigid bodies. This is not a structural-strength simulation.

## First completed solids and entry

Polyhedra introduces the first two assembled prefabs: a wedge (a slope) and a
square-base pyramid (a cap or stopper). The wedge measures **1.6 m clear width ×
1 m rise × 2 m run**; the pyramid has a **2 × 2 m base and 1 m height**.
Their small shelf pieces are exactly one tenth of those dimensions and use the same
holographic material as the hand model. The solids share the tool arc and belong to the Model group in the lab editor.

The construction grid specifies contact heights: a deck at one metre has its top
at one metre. Panel thickness extends below that plane. Covered joints have flush
upper caps and horizontal rails sit beneath the surface. Wedge clearance accounts
for the joints, and its high end docks against the rail's outer face. No rod is
shortened. The chamber no longer raises the entire graph according to joint
radius; negative authored levels shift the datum by whole metres. Stored
construction records remain unchanged. `test_building_shop.py fit` measures the
settled wedge-to-deck join, the pyramid base and tip, both triangle and quad contact
planes, and a capsule walking up the ramp without jumping.

Grip a shelf piece, bring it onto the miniature grid, turn it in your hand and
release at the preview. Desktop uses the existing Q/E and R/F rotations. The
miniature snaps its base to the half-module lattice and its orientation to quarter
turns. Two prefab envelopes may touch but cannot overlap. It can be moved, removed
in the basket and restored with UNDO like every other member. These two tools
remain available in Animated Cube and Transformation. Triangle keeps their saved
records but neither displays nor removes them.

A successful BUILD retracts the front glass wall into its sill in 1.4 seconds.
Walk around either side of the table to enter. A failed build leaves it closed;
an occupied bay still refuses rebuilding. The wall stays above its floor while
retracting, so it does not enter the storey below.

The full-size wedge and pyramid use their actual convex shapes, gravity and the
existing desktop/XR pickable. Release within 16 cm of a horizontal metre-grid
address and within 18 degrees of a quarter-turn orientation for a gentle snap.
Height is left to gravity; a release into another collider is never snapped.
Fixed scaffolding remains fixed. Moving a large solid is physical experimentation:
it does not rewrite the small design. BUILD or a newly loaded floor restores the
saved miniature arrangement, then gravity acts again.

The floor 6 station stands over the east shaft. The existing museum artifacts and
west-shaft wedge structure remain. One boundary work light moves clear of the bay.

## Carrying work forward

`user://void_scaffold_work.json` writes version 2 records with an explicit 2 m coordinate unit; it also reads version 1 integer records without changing their size. The current
blueprint broadcasts to other loaded editions and reloads after restarting. JSON
numbers are normalized before validating the connection sequence. Invalid saved
records are rejected atomically. Earlier editions display their introduced stock;
the whole record remains available at the later edition.

The full-size copy currently belongs to the loaded floor instance. After a floor
streams out or a game restarts, press BUILD again to regenerate the saved design.
The first workspace is bounded to seven nodes per axis (-1 through 2 in half steps): at most a
6 m span. This is a small construction trial, not the whole tower editor.

## Curation and reuse

Support, Model, Controls and Output are independently editable groups in the lab
editor. Output can be moved away from the bench to serve an actual passage. Keep
its 6.6 m plan bay clear. An isolated copied group is a visual/editor component;
it cannot produce invisible construction without Model, Controls and Output.

All six installed editions use `workstation.gd` and `model.gd`; scenes only select the
available vocabulary. Existing museum artifacts and folded assembly stay in place.
The primitive prefab catalogue exposes the editions for reuse.

`python tools/test_building_shop.py solids` checks shelf pickup through desktop
and synthetic XR tracking/grip, save compatibility, stock availability, basket and
UNDO, falling and settling, convex slope collision, gate entry, occupied-bay
protection and positive/negative snap cases. `unified` checks the six installed
stations against their actual tower colliders. These are native automated checks,
not a claim of a human headset playtest or of installation on Quest.

## Verification

Run `python tools/test_scaffold_workstation.py` through the shared native slot.
It uses real tower floors, the production desktop adapter, synthetic controller
tracking and grip inputs through Void's actual proximity pickup, a hand collider
touching BUILD, a moving CharacterBody on the result, save/restore and invalid joins.
The tracker test assembles a square from an empty model, without calling pick_up
directly or teleporting the held parts. First-person captures and sightline checks
cover stock blocking the initial targets and the board hiding the full-size result.
Run `node tools/check_scaffold_workstation_editor.cjs` after the native model export
to check editor geometry and validate moved/copied groups without saving drafts.
Native captures use fixed inspection lighting. The measured standing reach fixture
is a regression check, not a claim of physical comfort. Palle subsequently
confirmed that the corrected workstation works well as a prototype in the headset.

## Earlier experiment: a square becomes a crossing

This section records the predecessor to the glass shop. The crossing scene is
retained as a reusable prefab; the current floor-20 station and current test
commands are described under "Six-metre shafts and the glass shop" below.

After the reach revision, Palle reported that the workstation works well as a
prototype in the headset. The next experiment is on floor 20, `Trans_Playground`.
Its north-side scaffold landing carries the same bench and shared save. Two deck
tiles in the connector are separated by a receiving gap. A completed
two-metre square supplies a two-metre-wide crossing between the retained decks.
The deck ends leave clearance for the larger point fittings at each end.
The receiver is offset from the fixed circuits and its supporting rails leave the vertical fittings clear. A
read-only snapshot of Palle's Quest construction (28 records: 11 added points,
13 rods and four panels) was fitted without dropping its wall or extra frame.

`crossing.gd` extends the existing workstation. BUILD requires a full quad or both
triangular halves of a horizontal square. The nearest completed square to the original point
is selected; its integer position is subtracted from the output poses. This is
translation of the entire graph, preserving the saved connections and the
two-metre module. A square built on the lower model layer can fit too.
The receiver does not contain an invisible collision platform. Editing keeps the
previous crossing; an incomplete, obstructed or occupied rebuild is refused.
Large designs that collide with the surrounding scaffold must be revised or the
Output receiver curated to a larger clear space. BUILD never discards extra parts.

Support, Model, Controls and Output remain editable in the lab editor. The landing
and circuit members remain individual scaffold recipe parts.
Both moving circuits and the downward TC remain in place. This first connection
installs a static deck; adding motion or repetition to the learner's construction
is a subsequent experiment.

`python tools/test_scaffold_crossing.py` checks the actual floor, the falling case,
shared save/load, the retained grip interaction and tabletop sightline, and walking
over the built copy with the desktop player and native XRTools body at 72/90 Hz.
`node tools/check_scaffold_crossing_editor.cjs` checks native editor models and
move/rotate/copy through the layout validator. These are automated checks; the new
floor-20 crossing has not yet been physically playtested in a headset.

## Material vocabulary arrives with the sequence

The built copy shares `construction_materials.gd` with the scaffold world; the
hand model uses a neutral translucent override. Before Colour, full-size joints are dark steel, sockets are grey collars,
rods are neutral rails and the two halves have the same neutral surface. A fine
seam identifies the diagonal without a pink/yellow code. Snap previews use white
light and READY text. Interface controls and the existing hand bracelet retain
their own feedback; they are not coloured construction parts.

The receiving map resolves the existing monochrome/colour phase. A player-operated
palette is a later Colour encounter, not a new menu or progression save added here.
Saved version 1 integer records remain readable; version 2 adds half-module addresses for the separate one-metre stock. WORLD_STEP remains the two-metre physical module. A maximum-height
four-node construction can exceed a standard floor's clearance; the overlap check
still refuses it. The floor-20 trial has additional headroom.

The native grip test also renders base.tscn's actual right hand. Captures
08–11 show stock acquisition, a rod preview, a panel preview and hand contact on
BUILD. These are supplied tracker/grip inputs, not a recording of human play.

## The playground uses the workshop's parts

`geometry.gd` supplies the same meshes, materials and collision shapes to the hand
model, its built copy and the native playground renderer. The renderer uses the
world unit of 2 m. Points, rods, triangular halves and full quads form every member
of the two circuits and their connector. Tower floors and pillars remain architecture.

`tools/build_authorized_scaffold.py` compiles small legal workshop assemblies into
`motion.json`, `revolving.json` and `connection.json`. Each records its original
point/rod/face graph and the encounter that introduces every part. `contract.gd`
rejects unknown sources, resized members and faces without a closed frame before
an opted-in recipe runs. Existing recipes without this contract are unaffected.

The upper deck is two rods high: 4 m between its lower and upper joints. Lift
plates start outside the return walkway, keeping the rising player's head clear.
Translation, pivot rotation and parented folding act on rigid assemblies. Extension
now slides another fixed square into reach; it does not stretch a rod and is not
a demonstration of scale. The downward lift uses the same framed quad and waits
for its passenger on the lower floor. Exposed electrical ground only resets a
player in contact with it, not one supported by a low workshop plate above it.

Run `tools/test_building_shop.py tower`, `tools/test_authorized_riders.py` and
`tools/check_scaffold_connection.py` for the contract, native floor routes and
desktop/XR movement. These checks use production physics and synthetic input;
they do not establish physical headset comfort or Quest frame rate.


Individual playground members can also be copied in the lab editor. The shared
layout schema accepts their hyphenated member names. Native `only_parts` handling
keeps a copy static and removes the source course's other bodies, labels and
electrical field. `tools/test_workshop_part_copy.py` checks that isolation,
physical collision, saved pose and editor preview for all three recipes.

## Six-metre shafts and the glass shop

Both main-tower shafts now have 6 × 6 m structural openings. Trial layouts keep
their separate specifications. Floor 20 places a 6.6 m glass case over shaft A,
with its base flush with the floor. The bench now stands at floor level in front
of the case, connected by a short white counter and low service links. A taped
boundary surrounds both, leaving a 1.4 m entrance. The electrical-ground mesh
and contact rules use the actual editable Support footprint as a safe area.
The case and bench are apparatus, not unlocked kit parts. The surrounding
playground still consists entirely of authorized parts. Its south-centre upper
deck remains, but its supports no longer cross the bench; the superseded shop
landing is removed. The northern turn is offset 0.8 m outward to clear the case.

The table is a white tubular counter; its stock and hand model have slight neutral
transparency. There is no stock rail or upright across the hand space. Recessed
task lights, a low information card and rectangular push caps retain the
existing interaction signals, hand areas, sound and haptics. The large platform
has matching metre lines. The full-size output retains solid materials and collision. Both
rod lengths share the same grid. A 2 m side may use one long rod or two short rods;
occupied segments cannot overlap. Halves and quads adapt only to a complete 1 m
or 2 m square, not to arbitrary rectangles.

`display.gd` translates the unchanged construction into the case. It never scales
it to fit. The usable width/depth is 6.4 m; a construction too tall for the falling
ball is refused. BUILD preserves the old output on failure. DROP TEST creates a
real rigid ball. Resting on the built structure succeeds; touching the glass base
fails. This tests collision and support, not bending, structural stress or gravity
acting on the rigidly fixed construction.

The previous crossing scene remains in the reusable prefab library, with its own
native preview. It is no longer the primary station on floor 20.

Current checks: `tools/test_building_shop.py rules`, `tools/test_building_shop.py tower`,
`tools/test_scaffold_workstation.py`, `tools/check_building_shop_editor.cjs`.
After a structural change, `tools/export_void_structures.py` refreshes all floor
frames without loading every exhibit. Export the affected artifacts separately
with `tools/export_void_floors.py`. The earlier raised station was installed on
Quest on 2026-10-29; its receipts remain historical evidence in
`ada_run/building-shop/quest-apk/`. The later re-install preserved the current
13-record save (`ada_run/quest-upload-2026-10-29-playground-factory/`).
The grounded working-area revision requires a new APK before headset testing;
native render and synthetic input checks do not establish physical comfort.
Select The Void → Transformation → floor 20 for the current desktop station.


## One apparatus across the installed stages

Points (floor 1), Lines (3), Triangle (5), Animated Cube (7) and Transformation
(20) now instantiate `display.gd`. Their tier selects stock, not a different
interface. BUILD / DROP TEST / UNDO occupy identical positions. Five stock
addresses remain fixed as the vocabulary expands; reserved positions are inert.
The hand model remains near the visitor with no stock rail across the hands.

The chamber has the same 6.6m square footprint. Early floors use 5.4m height to
clear their 5.64m ceiling; Transformation's double-height bay uses 6.6m. These
are apparatus dimensions, not a scale change to the construction. Oversized
builds are refused without shrinking or deleting their saved graph. The earlier
carried-crossing prefab remains available separately.

The visual intention is precise, ambiguous cognitive work: familiar addresses,
a low dark instrument card, restrained light at the glass edges and a machine
ready for another revision. This is a design interpretation, not a new narrative
progression, quota, or reward system. The test is observation of fixed colliders
and a falling ball, not a structural engineering simulation.

Validate installed editions with `tools/test_building_shop.py unified`; it
checks authored placements, stock gating, stable tool/control positions, ceiling
clearance, standing support and real ball outcomes. The hand-input regression
still uses `tools/test_scaffold_workstation.py`. Native checks are not physical
headset acceptance. Re-export native editor models for floors 1,3,5,7,20 after
changing these scenes.

### Table-integrated miniature and controls

The miniature and stock keep their established positions. The 1.10m-high worktop
now extends to z=1.02m, supporting every corner of the miniature pad instead of
leaving its near edge overhanging. BUILD, DROP TEST and UNDO share a right-hand
faceplate tilted 12 degrees towards the visitor. Button caps, hand areas and
press travel follow that plate; labels lie on its surface. The low information
panel has a closed housing down to the tabletop, and stock captions are printed
on the work surface. The grid between these two consoles remains unobstructed.
Support, Model, Controls and Output remain the same editable groups.

### Move and discard miniature members

Placed points, rods and faces use the existing desktop/VR pickup bodies. Grip a
placed member and release at a legal socket to move it; release elsewhere to
return it. The implicit origin stays fixed. Release a member over the small
REMOVE basket at the front left to delete it. Merely holding it over the basket
does nothing, and returning a stock tool never consumes its supply.

Edits are atomic: the remaining graph must still be reconstructible from the
origin. A rod carrying a face, or a point required by another member, returns
with an explanation; remove its dependent faces/rods first. Nothing cascades
silently. UNDO restores the last move, removal or placement at this station
(up to 32 edits in the current session). The shared version-two blueprint format
is unchanged. The built full-size copy remains until BUILD is pressed.

Only one miniature member can be held at a time. Incoming shared revisions wait
for release, and body replacement is deferred until pickup callbacks finish.
The basket follows the editable Controls group. Validate with
`tools/test_building_shop.py edit` and the existing construction regression.
