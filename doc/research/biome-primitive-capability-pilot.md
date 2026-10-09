# One world, eight encounters

19 September 2026. Full-size companion prototype for a biome that begins at Point One
and accumulates capabilities through the spine towards QFEP.

Review: http://127.0.0.1:3003/biome-primitives/index.html

## What this pass changes

`commons/artifacts/biome_primitives/biome_primitives.tscn` is a 12 x 12 metre
collidable ground, at scale 1. The active museum walker supplies a position.
For XR, the camera's x/z position includes room-scale movement and is projected
onto this ground; this is not a measurement of the feet. The hall supplies the
stage. There are no tables, handles, labels, control panels or in-world controls. It is
registered as a prototype, not placed in any authored map.

This implements Palle's correction: the biome is full size and needs no
interface. The research page keeps optional controls outside the world, in a
collapsed browser sketch, and leads with actual standing-height Godot views.

The mature BiomeObject is developed separately (generation 17 at this pass's
inspection). This pass changes only the companion prototype. This is a research
branch for how capabilities accumulate, not another generation of the visual
ecology benchmark. Nothing here computes a concealed mature terrain.
Seed 7 identifies the specimen; it is not yet a terrain-generation parameter.

The HTML companion implements the same state transitions and sampling rule. It
is not a Godot web export. A shared recorded gesture is run in both models and
compared against the Godot probe's state file. Actual Godot captures lead the
review page. The optional browser sketch can export the current record as JSON.

## The eight encounters

| Hall | Operation | Observable consequence | Question left open |
|---|---|---|---|
| Point One | Change a position | Nothing records where it was | What would it take for this world to remember? |
| Lines | Retain an anchor and join it to the point | The segment stays straight while the movement can wander | What does this relation leave out? |
| Trace | Sample movement into bounded memory | The retained points and interpolating segments differ from continuous movement | Which differences fit into the time and memory budget? |
| Grid | Quantize the point's x/z coordinates | Several positions share a cell; crossing a boundary changes its address | What can an address carry, and what does it discard? |
| Triangle | Join two triangles into each of five equal faces | A face becomes almost a line when seen edge-on; a deliberately thickened panel blocks passage | Who chose that collision thickness? |
| Polyhedra | Give the same fronts 2.2 metres of depth | Equal volumes leave differently accessible corridors | Which body does an opening admit? |
| Rotation | Revisit the thin faces and turn them about fixed left edges | A forward route opens while a transverse route is interrupted | Where did the refusal move? |
| Scale | Repeat the same turn at two panel widths | The first gap admits or excludes the same collision body | How small a change turns an invitation into a refusal? |

The ground is support. It is not claimed as geometry constructed by the point.
The black mark represents a mathematical position;
it is not the museum's invisible-point artifact. No change was made to that
artifact or to final.md.

## Withdrawal is not time reversal

The point, first line anchor, clock and retained samples persist across stage
changes. Turning off trace stops recording and hides its archive. Restoring it
starts a new stroke so an unrecorded gap is not silently joined. Clearing memory
explicitly discards its samples; recording can start again immediately if the
capability remains active. Earlier discarded samples are not recoverable here.

The clock runs while recording is unavailable. Sampling defaults to 0.12 seconds,
with at most one observed position per update. A late update does not invent
missed intermediate positions. Stationary duplicates are omitted. Memory keeps
the latest 64 samples and exposes how many older samples have been removed.

The browser's prerecorded gesture is fed through fixed 0.05-second steps so it
can be compared to Godot's fixture; live hand/mouse movement uses actual update
time. The full-size ground ignores positions outside its extent; reentry starts
a new stroke instead of joining across an unseen excursion. The browser
additionally offers a 0.50-second sampling interval. Its
code fragments are teaching extracts, not complete implementations.

## Evidence and checks

- `commons/testing/probe_biome_primitives.gd`: staged capabilities, sample timing,
  long-frame behaviour, hidden archives, stroke gaps, memory limits, boundaries,
  local coordinates, active desktop and XR camera discovery, ground collision,
  standalone walker support, absence of interface and reproducible demonstration.
- `tools/test_biome_primitives_web.mjs`: shared gesture compared with the Godot
  state oracle, plus withdrawal and stroke-gap behaviour.
- `ada_run/biome_primitives/`: test logs, oracle, capture specification and eight
  overhead Godot renders. The extra image shows trace withdrawn. Seven more views
  in `inside/` use a camera at 1.65 m. The first four share the original viewpoint;
  the two form studies share a forward-looking viewpoint and a collision-checked route.
- Browser checks exercise recording, withdrawal/return, grid and keyboard input.

The native standalone walk scene is
`commons/testing/biome_primitives_walk.tscn` (F6; click to look, WASD to walk,
Escape releases the mouse). Its stage is authored in the inspector. Physical
headset walking remains unverified. The prototype is not yet installed in the actual halls or
to the mature biome's construction history. Godot's headless project startup
also reports an existing unresolved audio-bus UID and, in the restricted run,
a certificate-store warning; neither is a failure of this artifact's scripts.

## Next integration

Use the same four-part encounter record for every new capability: action,
implementation, consequence, unresolved question. Preserve a specimen identity
and the learner's interventions. At each hall introduce one actual operation,
not simply an image labelled with its name.

The next integration decision is how the learner's positions and traces become
inputs to the mature world's terrain, growth and routes. Compare a branch grown
from the learner's retained trace with one grown from a fixed prescription.
Record which differences survive. Do not silently turn every trace into a
pre-chosen ecological outcome.

At QFEP the accumulated world should support experiments with objectives and
their exclusions. That endpoint is a design intention, not implemented in this
prototype.

## Art and intervals: second full-size pass, 19 September

The source is Palle's [artist collection](https://docs.google.com/document/d/1p0hG1Og96_CwDl-OA1eZMUG0GPdLy41Am2Adstc07Qo/edit?tab=t.0),
read through Google Drive on 19 September 2026. Its opening connects visual and
spatial desire with folds, gravity, soft bodies, grids and assemblage. Its
working references include Lygia Clark, Oldenburg, Hatoum, Do Ho Suh, Saraceno,
Tara Donovan, Ian Cheng, Jacolby Satterwhite and Pussykrew. The page's proposed
experiments are our interpretation of this collection, not claims that the
artists form a linear development or share one method.

For Judd, the [Foundation's account of space](https://juddfoundation.org/donald-judd/)
supports treating the interval as part of the encounter. The installation here
is an original study, not a reconstruction of a named artwork. Five equal fronts
are retained between two stages. Each is 1.1 m wide and 1.8 m high, made from two
visible triangles. In the surface stage a 4 cm slab supplies collision. In the
solid stage depth becomes 2.2 m. The front stays at z = 0.4. The four intervals
are 0.35, 0.65, 1.25 and 1.65 m. This authored repetition foreshadows the explicit
array operation later; the visitor has not yet learned an array by seeing five objects.

The observable claim is limited and testable: the standalone 0.5 m capsule is
stopped by the 0.35 m interval; a 0.24 m capsule passes. The larger intervals and
an outer edge provide routes. The collision body is a modeling choice, not a
universal human measurement. The retained trace lets the visitor compare a
straight reference with the route the forms allowed. XR room-scale tracking
does not necessarily enforce the desktop collision restriction: test that in
the headset before making an embodied claim about the installed museum.

DNA is currently a shared authored parameter record (`pilot.json.form_dna`),
not an evolutionary algorithm. Width, height, gaps and identity are retained
when depth is withdrawn and returned. Withdrawing the surface removes its
colliders as well as its image. The seed remains specimen identity. Live
interpolation, genotype mutation, mature-biome integration and QFEP are future work.

The immediate next candidate is a hinge transformation of the same planes,
prompted by the Clark notes: expose the pivot, let a closure become an opening,
and test the changed route. Later the Calder encounter can connect mass,
lever arms and motion. The [Calder Foundation's timeline](https://calder.org/timeline/1930-1936/)
describes the move from motor-driven mobiles towards environmental response.
The project already has `commons/artifacts/calder_mobile/calder_mobile.gd`:
reuse its mass and lever calculation. Its unsolved variants draw a residual
moment as a static angle; they are not a dynamic rigid-body simulation. Building
a responsive motion model is still work to do.

Other reusable material includes `commons/biome_layers/families/README.md`
and the existing composition-family modules. They currently place a cage's
elements along spatial paths. Preserve them as research resources; do not
silently call their composition scores a complete developmental biome.

Validation: 83 Godot checks, zero failures; 2,034 browser/Godot field comparisons.
Checks include collision sweeps through each claimed route, differing capsule
sizes, identical form identity after withdrawal/return and removal of obsolete
colliders. Rendered six stages, with zero rejected parameters in seven overview
variants. Standing-height captures suppress the unrelated mushroom inventory
HUD in the isolated harness; the actual museum autoload is unchanged.

## A turn makes room: hinge pass, 19 September

The hinge candidate above is now implemented in the companion's `Trans_Rotation`
study. This revisits the five **thin faces** from the surface encounter. It does
not morph the preceding solid blocks into paper or imply that an earlier
capability has been forgotten. Width, height, front positions, specimen IDs and
the unequal intervals are retained. Each left edge becomes a vertical pivot,
visible as a dark pin. An arc on the ground shows where the outer edge travels.

The motor repeats a twenty-second schedule: rest closed for two seconds, ease
to ninety degrees over eight, rest open for two, ease closed over eight. This
is prescribed rotation; torque, wind and force-based motion remain later work.
The scene advances the motor in physics ticks (at most 0.1 seconds per step),
updates the existing AnimatableBody3D poses, and leaves the geometry allocated.
The general clock and sampling clock remain independent of the motor phase.

The bank holds when the tracked visitor is within a conservative quarter-disc
sweep with 0.4 m clearance. It resumes from its retained phase when the visitor
leaves. In the browser research controls, withdrawing the motor similarly holds
the pose; it does not exchange panels for solids. This is a convenience for
inspection, not an in-world panel. The isolated desktop walk scene now starts
in this encounter. XR room-scale collision and comfort still need headset testing.

The practical argument was tested with the actual scene's physics. At x=-4.15,
the closed face stops a 0.5 m capsule moving along z; the ninety-degree pose lets
it through. Behind the closed panels, a transverse x route is clear. Turning
them interrupts that route. An opening changes location and direction, rather
than rotation simply making everything more accessible. All five hinge points
and dimensions remain invariant. A tracked visitor test verifies the pause,
ongoing general clock and resumption; motor withdrawal preserves the pose.

Review: http://127.0.0.1:3003/biome-primitives/index.html#Trans_Rotation

`commons/testing/capture_biome_hinge.gd` renders 240 native Godot frames with a
fixed camera at 1.65 m. `tools/encode_biome_hinge.py` encodes them without visual
alteration as a 20-second, 12 fps MP4. The film uses fixed simulation steps and
an unoccupied sweep; it is not evidence of real-time headset performance. Three
native stills show 0, 45 and 90 degrees. `ada_run/biome_primitives/hinge/capture.json`
records the scene, camera and timing. The page leads with that film in the hinge
stage and keeps the external browser sketch separate.

Validation after this pass: 114 Godot checks, zero failures; 3,063 comparisons
between browser and Godot state, including eleven hinge poses. The actual halls,
book prose and mature biome remain separate from this prototype.

## The size of an invitation: scale pass, 19 September

`Trans_Scale` extends the hinged-panel study. The same five vertical pivots stay
fixed. Only local panel width changes, from 0.66 to 1.375 metres (0.6 and 1.25
times the base width). Height remains 1.8 m, thickness 0.04 m, and the grid and
standalone 0.5 m walking capsule retain their dimensions. This is a comparison
of the space offered to one body; it does not shrink the player.

The 48-second schedule makes the two operations separately observable:

- 0–20 s: narrow panels execute the existing twenty-second hinge cycle.
- 20–24 s: closed panels widen with smoothstep interpolation.
- 24–44 s: wide panels repeat exactly the same hinge cycle.
- 44–48 s: closed panels narrow, returning to the initial dimensions.

Width never changes while the panels turn. The first closed gap changes from
0.79 to 0.075 metres. Actual Godot capsule sweeps verify passage at the smaller
width and refusal at the larger one on the same line, x=-3.645. An outer route
at x=5.5 stays clear. The experiment asks how a continuous parameter change can
cross a bodily threshold. It does not establish mathematical topology change
in the geometry alone: the body's dimensions and collision rule are part of
the accessibility question.

Each existing BoxShape3D changes size along with the visible mesh. The moving
physics body's scale remains one. The ground sweep grows about the same pivot.
Visitor detection reserves the maximum possible sweep, with 0.4 m clearance;
entering it holds both width and angle before growth reaches the visitor.
Leaving resumes the retained phase. The general clock and trace keep running.
Withdrawing the study in external review controls likewise holds both operations.

The standalone walk scene now starts at this encounter. There is still no
in-world interface. Native Godot recording uses the same standing camera as the
hinge study, 576 frames at 12 fps, with the sweep unoccupied. It is rendered at
fixed simulation steps and is not a headset performance measurement. Three
stills compare narrow/closed, wide/closed and wide/open; the overview shows the
wide panels at 45 degrees. The existing capture and encoder accept `--scale`.

Review: http://127.0.0.1:3003/biome-primitives/index.html#Trans_Scale

Validation: 153 Godot checks, zero failures; 4,214 browser/Godot field comparisons,
including twelve scale poses. Tests include fixed hinges, matching rendered and
collision widths, maximum-sweep holding/resumption, withdrawal and operation
separation. Headset walking and installation in the spine remain later work.
