# Transformation machines � decisions and strategies

2026-10-22. Design interview with Palle. No new mechanism build is authorised
until we agree on the intention and chosen strategy.

## Settled

- Work on one artifact at a time, beginning with the crank and piston.
- Ask questions before implementing another version.
- Keep a short record of decisions, possible strategies and unresolved questions.
- Remove the four machine placements from main Translation floor15.
- Retain their source scenes, shared catalogue definitions, relationships and
  native model snapshots as sketches.
- Preserve the existing Translation crossing, all348 construction cells and all
  other floors. Chapter texts remain unchanged.

## Current artifact: crank, metal connecting rod, wooden piston

Palle's starting intention: explore how rotation produces translation, with a
physical purpose, and how animation becomes logic through an observable result.
The previous assembly is a sketch to question, not an accepted design.

## Round 1 � waiting for Palle

1. Should the first purpose be pushing a loose wooden cube through real contact?
   Recommendation: yes; establish the rotation / straight movement / contact
   relationship, then decide what the cube reaching its destination enables.
2. Should the player's own hand supply the initial rotation?
   Recommendation: yes; begin with manual turning so speed, direction and effort
   remain connected to the resulting piston movement.

## Candidate strategies � provisional, none selected

- Push a cube: expose contact, load and friction.
- Move a plank into a bridge: make the stroke change the player's route.
- Open or close an aperture: make the stroke control what can pass.

Purpose, scale, reach, load, failure, controls and placement remain unresolved.
Which questions come next depends on the round1 answers. The previous motor,
ball delivery and removable pin are not commitments for the next design.

## 2026-10-23 — staging method before further building

Palle described an artifact box model: occupied content, interaction padding,
walk-around border, and deliberately bounded outer margin, with extra clearance
in the facing direction. See [the staging discussion](artifact-space-box-model.md).
This is a general method to discuss and test per artifact. The crank purpose and
manual-drive questions above remain unanswered; no new machine build is agreed.

## 2026-10-23 — rotating input and visible motion converters

Palle proposes a common circular input with different converters: a piston moving
a cube vertically, two wheels connected by a belt, and a rotating disk carrying
successively sized cubes behind a narrow viewing opening. The last proposal is
physical animation: fixed objects are revealed in succession rather than one
object changing its dimensions. These are candidates, not approved builds.

- Exact sine candidate: a rotating pin runs in a horizontal slot on a vertically
  guided yoke. Its vertical position is the pin's circular projection. Constant
  angular speed is needed for a sine over time. An ordinary finite-rod slider
  crank produces a different displacement curve; keep that distinction visible.
- Rotation candidate: exposed pulleys and a belt, with wheel sizes showing the
  speed relationship. Choose kinematic or force-driven implementation explicitly;
  do not present independently animated parts as a working physical connection.
- Apparent scale candidate: Palle's sized-cube disk with an openable housing.
  Begin slowly or step through positions. A narrow viewing window alone does not
  guarantee smooth animation; exposure timing/shutter needs investigation.
- Other candidates: cam and follower (profile determines rise, dwell and fall),
  rack and pinion (rotation becomes straight travel), paired circular projections
  (horizontal and vertical motion), and a moving light casting a changing shadow
  of a fixed object (projected size rather than actual scale).

Next decision: should the first artifact expose the circular pin and a single
vertically moving cube, driven by hand, before adding a load or another converter?
Recommendation: yes. Purpose, manual drive and final placement remain provisional.

References for the design discussion:
- Purdue's Scotch yoke demonstration:
  https://www-veritas.physics.purdue.edu/demos/display_page.php?item=1S-30
- Harvard's historical zoetrope (interrupted views of sequential images):
  https://chsi.emuseum.com/objects/3306/zoetrope

No new machine geometry or floor placements were made for this discussion.

## Agreed first build — hand wheel and sine yoke

Palle approved a hand-turned wheel and a vertically moving cube, with pin and slot
exposed, editable in the lab editor. This chooses the circular projection study
before adding a load or another converter. The earlier four Translation sketches
remain unplaced. The new `sine_yoke` is an ideal kinematic constraint, with no
independent oscillator or force-based solver claim. The shared catalogue supplies
the two editable groups, Support and Mechanism, to the editor and workbench.

## Scale zoetrope clarification

Palle clarified that the proposed "scale rotate room" is the earlier zoetrope:
a disk moves inside a cube-shaped enclosure, with viewing slits only on its
centre-facing side. Working interpretation: that wall faces the centre of the
skyscraper floor; the enclosure stays fixed while the disk turns. Cubes of
successive fixed sizes travel on the disk. They do not individually change size.

Design proposal, not built: grow/shrink sequence, eye-level viewing openings and
an openable service panel to expose the separate cubes. A stationary opening may
read as objects passing rather than one object growing. Investigate synchronized
brief exposure with a rotating shutter behind the openings; do not claim a
smooth illusion from an untested slit alone. Proposed first drive is a hand
crank, allowing slow inspection and stopping at each frame. Drive and exposure
mechanism still need agreement before building.

Primary precedent: MoMA's Pixar exhibition describes a rotating sculpture
zoetrope using strobe light for interrupted viewing:
https://www.moma.org/calendar/exhibitions/91

## Approved prototype — hand-driven scale zoetrope

Palle approved the hand-cranked first version. `scale_zoetrope` is installed on
main floor59 alongside the existing sine yoke and block-supported studies. The
enclosure stays fixed, with one viewing opening toward the floor centre. Twelve
timber cubes retain their individual sizes on the rotating disk. A black inner
drum hides opposite frames; radial dividers hide adjacent ones. The hand wheel
also drives an opaque sector shutter at an ideal12:1 ratio. This is a kinematic
model, with no claim that the transmission solves forces or belt contact.

The right-hand service panel opens with a pointer press on its brass latch.
Opening it exposes the actual disk and separate frames. The fixed transmission
is routed below the deck or outside the cubes' swept volume. The original22
artifacts,27 existing box/wedge modules, floor dimensions and shafts are retained.

Twenty native checks cover production desktop pointer motion, supplied-pose
XRTools grip, stop/reverse, unchanged cube sizes, actual shutter geometry,
service-panel visibility, negative-floor moved/rotated assemblies and capsule
circulation. Rendered identification views isolate the small, middle and large
frames; the between-frame shutter view blocks them. These establish geometry
and controls, not a physical-headset or smooth-animation perceptual judgment.
Slow turning is deliberately inspectable. Review the reading and hand comfort
with Palle before extending it or adding a motor.

The shell, coupled disk/crank and service panel share the main prefab catalogue
and have separate real geometry previews and saved part poses in the lab editor.
Evidence: `ada_run/scale-zoetrope/checks.json`. Review:
`doc/book/iterations/2026-10-23-scale-zoetrope/index.html`.

## Automatic drive and display sampling — approved extension

Palle requested automatic movement when the wheel is not being turned by hand,
an open-view test without the blind, and speed controls to explore the relation
between motion and FPS. The disk now runs at60RPM by default, yields while a
desktop pointer or XR grip owns the wheel, and resumes after a0.65s release delay.
RUN can also pause it. The physical shutter starts off and can be toggled on.

A fourth editable group, PlaybackControls, is mounted above the crank. Existing
physical faders set RPM and a local sample clock: display frames,6,12,24,30,60,90
or120Hz. This changes only the artifact's updates, never the whole game or XR
headset frame rate. MATCH advances one cube per sample:60RPM at12Hz,120RPM at24Hz.
Display matching uses measured average FPS at the moment of pressing, allowing
real frame-timing changes to show as drift. REVERSE changes direction. The display
separates RPM, cube passages per second, actual FPS and cube advances per sample.

The open-view native render check measures twelve distinct fixed-size objects
at the same horizontal image position. Their measured widths vary rather than
one mesh being scaled. Motor speed is independent of the render cadence in
measured30FPS and60FPS runs. Source cubes, enclosure, service panel and all
existing floor placements remain intact. Physical-headset comfort and subjective
animation smoothness still require play review. Evidence and screenshots are in
`ada_run/scale-zoetrope-playback/`.
