# Prefab workbench: Primitives and Transformation

Open `/prefab-workbench`. Ten map tabs show Lines (3), Trace (4), Triangle (5),
Polyhedra (6), Cube + AND (7), Solids and spheres (8), Columns (9), Profiles (10),
Portals (11), and Melencolia (12). The library groups variants by family. Concepts
and proposals are optional; selecting a piece shows its immediate parents and
descendants rather than drawing the entire spine at once.

## Shared definitions

`primitive-prefabs.json` defines source scene, dimensions, anchor, behaviour and
recipe metadata. It now includes the existing building cube, walkable wedge and
tetrahedron marker in addition to the previously defined kit. This does not create
new geometry or award player progress. `capacity-artifacts.json` remains the main
authored relationship graph, also read by the existing tree.

There are now 148 placeable source examples across Primitives and Transformation. Geometry
comes from the existing native GLB exports, never schematic replacement meshes.
Standalone previews remove palette-placement offsets so the coloured origin axes
mark the actual prefab insertion point. AND composes its 22 named source parts;
labels without geometry remain listed. Select a part or separate the preview to
inspect it. Separation changes the preview only.

## Editing relationships

Choose a connection in the graph or list. Edit its source, target, relationship
type and explanation. Add/update/remove modifies a browser draft. Undo and Discard
restore earlier/saved relations. Save relationships writes the shared graph;
changed built-from links also update the matching catalogue recipe metadata.
These are descriptive relationships, not a generator that rebuilds source scenes.
Geometry and functional assembly changes use the live editor or the source scene.

Developed-from expresses a learning development; built-from is an ingredient to
assembly dependency; associated-with records another use or interpretation. The
store rejects duplicate links, unknown endpoints, self-links and new circular
built-from recipes. Save uses a revision covering both catalogue and graph. A
conflict retains the visitor's browser draft instead of overwriting another edit.
Previous graph and catalogue versions are kept in
`ada_run/prefab-workbench/history/`.

## Placing instances

Choose any main-tower destination floor and Stage in live editor. This opens the
normal shared Void editor with a named placement tool. Click the floor to add a
normal prop or source-backed assembly copy; Escape cancels before any room edit.
The existing room save/undo and desktop/VR layout are used. AND's 22 parts remain
editable through its main-floor preview source. Workbench placement is an authoring
operation. It does not bypass or grant the separate AND player inventory reward.

Source/preview bounds remain uncurated; the editor's existing placement warnings
still apply. No existing floor arrangement was moved to build this workbench.

## Verification

`tools/test_prefab_workbench.cjs` exercises save/reload/backups, stale revision and
origin checks, invalid/circular link rejection, catalogue recipe updates, parsed
real GLBs for all 148 placeable examples, and editor placement/move/rotation/schema
validation/JSON save parity. Graph mutation tests use isolated fixture copies;
live-room tests are validation-only. Evidence and browser screenshots live in
`ada_run/prefab-workbench/`. No native physics or headset claims are made for this
web authoring change; the existing source encounters retain their native tests.

## Melencolia and remaining Primitives examples

The shared catalogue includes the five Platonic studies, sphere atlas and edge
comparisons, 25 column comparisons, 13 letter/profile examples including the rolling
tyre, the portal sweep and pink rings, and the Melencolia compositions. The Line
associations now resolve their existing native models too. These are static Three.js
views of actual exported geometry; the game retains each source behaviour.

Melencolia's deck has a 58-member teaching assembly: 25 cubes, 25 one-metre timber
sheets and eight rim planks. Court + access adds the two existing wedges. Foundation,
Deck, Rim and Access reveal the construction cumulatively. Separate parts lifts the
layers apart for inspection. Clicking a named member links to its shared ingredient.
The poses mirror `melencolia_platform.gd`; no floor or source geometry was changed.
A deck places as the existing court prop; Court + access places the three named
source parts together, with a movable group anchor and independently editable pieces.
Each ingredient can also be placed separately. The teaching preview does not claim
that editing relationship metadata regenerates a game assembly.

Single-part examples retain only their named source part and align its visible base
to the insertion plane. Multi-part examples preserve their internal poses. The room
schema accepts up to 64 unique retained part names, matching the native factory's
existing filtering contract. Original standalone height/scale are retained when
placing the existing Line tools. Tests validate every placeable example through the
real save validator in bounded draft groups, without saving to the user's rooms.

The concrete-wall association resolves to the existing concrete_barrier source,
matching its description and palette model; it previously pointed to the separate
plastic A-frame barrier scene. The surface-ball diagnostic remains an emitter
attached to a surface rather than a freestanding authoring object.

## Transformation and first curation pass

The sequence switch keeps the seven Transformation floors (13–19) in a compact
row. Its examples use the original scenes and configurations, plus existing steel
modules and the curated Translation construction preset. The same catalogue feeds
the tree, workbench and live-editor palette. Construction presets place as ordinary
independent `construction` cells; all newly inserted cells are selected together.
Moving or turning them uses the existing editor tools and the same desktop/VR save.
No player unlock is granted by authoring placement.

The Three.js study can translate, rotate, scale or combine transforms on any chosen
Transformation example. Quick choices reuse the canonical construction cube, wedge
and two-metre plank; no duplicate prefab definitions are made. Axes stay fixed.
The progress slider and playback apply preview math only, with scale, then rotation,
then translation for the combined case. Placing uses the original definition;
edit its actual world pose in the live editor. These previews do not claim to run
native input or physics. Map context is retained in the shareable URL.

Only floors 15, 16, 18 and 19 were curated. Translation retains every original one
of its 146 cells and adds a reflected counterpart plus a two-metre connecting deck.
The subsequent walkability correction replaces Rotation's display row with four
parallel bodily trials. The cubes retain their original 2.04 m edge and 2 m pitch:
one strip per X, Y, Z and composed orientation, each sampling six angles. A common
three-metre start bank and finish bank have joined two-metre wedge approaches.
The source's actual 0.44 m and 1.20 m body comparison is restored. Other museum
placements retain their original array mode. Both shaft descents remain.

Body now frames three encounters across the floor: a 12 m slat wall, a 35×7×13
body-height carving lattice and fifteen proximity-scaling blocks. All three keep
unit placement scale, so visitor sensing uses the original body dimensions.
Pit stages translation beside shaft A, two turning walls inside a cube-built
crossing lane, three growing blocks narrowing the east-bank route, and the final
combined-operation door. Ball launchers rest in the cube side walls. Waiting bays
and an observation route give room to read the clocks. All original artifact occurrences remain.
Chapters and final.md are unchanged.

Evidence is in `ada_run/transformation-workbench/`: revisioned layout save and
before-layout, 72 actual native geometry/collision/motion-placement checks, a fresh
incremental export for floors 13–19 plus seven native construction previews,
workbench/editor checks and browser screenshots. These are targeted placement
checks, not a complete playthrough or physical-headset acceptance. Other floors
and their source artifacts were preserved. Large previously imported source works
outside these four floors remain subject to later curation.

The corrected encounters have separate evidence in
`ada_run/transformation-walkability/`: actual two-width collision results,
natural visitor-triggered wall/carve/scale passage tests, a targeted ramp-access
follow-up, fresh editor exports and screenshots. The two tested widths cross Y;
other orientations block or shed the same bodies. This is a result under the
recorded body, gravity, speed and no-jump conditions, not a universal walkability
ranking. Native inspection captures use neutral lighting; editor models remain
static snapshots of the original running sources.

The catalogue retains four physical machine sketches: wood crank / metal rod /
piston, working lever, suspended cube and size-gravity sorter. Their floor15
placements were removed at Palle's request on 2026-10-22. Their definitions
are shared by the tree, workbench and editor, bringing this slice to 152 placeable
examples. They reuse the timber finish, familiar bodies and the existing
force-study constrained grips. The native mechanisms run actual joint/contact
physics; the Three.js previews remain static mathematical/geometry studies.
The current floor15 crossing and all 348 construction cells are preserved.
See `commons/artifacts/transformation_machines/README.md` and
`ada_run/transformation-machines/` for mechanism and integration evidence.
