# Learning produces the next building material

## Primitives Ignorance comparison path, 19 October 2026

Floor 8: ordinary sphere → three matched surface/edge pairs in the central bay
→ Budget of Smoothness beside the pairs → twelve-sphere atlas in the west wing.
Five exact pickable solids remain north. All original imported IDs and variants
remain. Six equal supports put the comparison centres at 1.35 m; their geometry,
material and size match within each pair. Only overlay visibility differs.
Moved loose artifacts out of the atlas footprint. A walking test passed an old
counter placement whose controls were visually hidden by another display; native
screenshots caught this. The counter is now adjacent to the pairs with a clear
front approach. Check visibility as well as walkability.

72 native desktop/synthetic-XR checks; editor verification and native screenshots:
`doc/book/iterations/2026-10-19-ignorance-comparison-path/index.html`.
All parts remain editable. Other floors and chapter texts are preserved.

## Melencolia restoration, 19 October 2026

Preserve object + configuration + relation + support + approach. Inventory alone
loses the encounter. The old Melencolia grid already held the four blue corner
pyramids, pink central spire, ochre cross and figure:skull setting. Void had
scattered the nine solids and omitted the skull configuration. Floor 13 now
groups the original instances on a 5 x 5 m, one-metre-high court, reached by
two original wp ramps. The tableau uses an enlarged carved skull with feathered
wings; this is Ada's substitution, not Dürer's original figure. User's 90-degree
tableau orientation and other floors are preserved. Everything remains editable.

62 native desktop/synthetic-XR checks and 7 editor checks passed. Native images,
source comparison and proposals for floors 8–13:
`doc/book/iterations/2026-10-19-primitives-restored-relations/index.html`.
The other late floors were assessed, not rearranged. Next useful curation:
Primitives_Ignorance surface/edge comparisons; then test one full-size profile
opening. The existing final.md already describes the court and is preserved.
Its small-skull and raised-connection spatial cues need an edition-specific
update before claiming text/world synchronization. No physical headset test.

Palle, 19 October 2026: keep the graph's symbols. Reconstruct CGI and Godot
knowledge inside a real project. Each selected lesson should leave a named
object or operation that can help construct later levels. The level itself
becomes evidence of accumulated capacity. The old grid made this relation
concrete; recover it without returning the whole tower to a uniform grid.

## Portals sky walk, 19 October

Palle chose Portals floor 12 for the first rideable version. Walk up wp ramps,
through twenty increasingly resolved and larger torus rings across the tower,
then eleven metres beyond its eastern edge. The old Primitives_Portals long
walk is the spatial reference. F33_Bridge supplies the actual br bridge cells;
it did not contain a moving platform. The existing tc transport cube supplies
passenger carry, dressed with four one-metre cubes and a matching collider.

The one-metre-high, two-metre-wide route crosses shaft A on static bridge
cells and shaft B on a 2 x 2 m deck shuttling three metres. It returns by itself.
The whole span, moving route anchor, ramps, docks, bridge strips, ring study
and sky lookout are available for lab-editor placement/copy. A moved or turned
ferry rebinds its travel to its saved anchor. Desktop and XR use the same layout.
The compact Portals passage is replaced only in the authored floor-12 instance;
its remaining original artifacts survive. Achilles is aligned with the user's
moved LimitTable. Other floors and the separate Transformation trial are retained.

The boundary permits the authored exterior walk only above actual support.
Falling beside it still kills and respawns at Portals. Native tests exercise
walking the entire span, boarding, both carry directions, detachment, outside
jumping, death/respawn, reverse refinement and rotated copies. Synthetic XR
is not physical headset testing. Evidence and screenshots:
`doc/book/iterations/2026-10-19-portals-sky-walk/`.

## First implementation: Polyhedra, 19 October

Built gradually in Primitives, following Palle's next instruction:

- AlignTetrahedron and AlignWedge now expose fixed corners and edges, a visible
  target ring, a release cue and the purpose of the completed grabbable solid.
- Completed solids and the three large blockers share diagonal construction
  paint. Tetrahedron and square-based pyramid have matched convex collision.
- The wedge blocker wraps the original wp scene, including its collider, at
  floor-local origin. It rises one metre over two metres; its width is one metre.
- Polyhedra's support assembly uses a 5 x 6 m shaft-cover deck at +1 m and
  nine original wp ramps. It retains the editor placement over shaft A;
  the mouse model has been removed. Ramp joins follow the resized edges.
- Tetrahedron, pyramid, wp and a one-metre platform block are reusable editor
  palette props. Existing per-part editing can copy the larger assembly.

This is the first static construction, not the complete paintable grid layer
or a moving Transformation assembly. The latter remain the next steps below.
Evidence: `doc/book/iterations/2026-10-19-polyhedra-building-pieces/`.

## Cube handoff, 19 October

Palle's correction: reusable cubes enter on Cube, not Polyhedra. Polyhedra
keeps the six-vertex wp construction; its 5 x 6 m cover is floor architecture,
not the first building-cube artifact. Existing tetrahedron/pyramid encounters
and the user's placements are retained.

Cube now combines 30 exact one-metre blocks with six original wp ramps. The
first rise reaches +1 m; the second reaches +2 m. The route is three metres
wide. Visible joints make the unit blocks legible. All 36 members have stable
names and editable poses; the complete route is also a palette prefab.

`cube_walkway.json` remains Cube's construction recipe. The shared factory now
accepts a recipe path: Trans_Pre uses `trials/transformation/pickup_walkway.json`
to arrange the same block and wp definitions as a single-height pickup path.
Local editor overrides remain local to their instance; they do not silently
rewrite either recipe or the other floor. Moving construction and hazards in
Transformation remain future work. No tutorial or final text was rewritten.

Evidence: `doc/book/iterations/2026-10-19-cube-carried-structure/`.
Verified: 300 checks in Cube and 300 in the Transformation trial (desktop and
synthetic XR), 72 shaft-cover physics checks, 19 original Cube checks, and eight
editor export/copy/move checks. Both Desktop mirrors match the saved layouts.
Palle explicitly confirmed removing the individual cube prop from Polyhedra;
that removal preserved all other live edits. Physical headset testing is pending.

## The first construction chain

Triangle -> tetrahedron -> obstruction.
Triangle profile -> triangular prism -> wp slope.
Connected faces -> cube -> platform.
Slope + platform + beam -> saved walking structure.
The same structure + a movement controller -> Transformation.

This is not a vertex-count ladder. A tetrahedron has four shared vertices and
four triangular faces. The existing wp is a six-vertex triangular prism: two
triangular ends, three quadrilateral sides. Adding a fifth point to a tetrahedron
does not automatically produce it. Connectivity and arrangement must change.
The cube has eight shared corners and six quadrilateral sides. Triangulation
for rendering is a separate representation of those sides.

## Current source versus intended carry

- `primitive_encounters/geometry.gd` already constructs tetrahedron and wedge
  recipes, outward-facing surfaces and matching convex collision.
- `align_solid.gd` already lets the player complete a tetrahedron or wedge;
  completion creates a grabbable physical solid. These are actual source
  behaviours, not a new play test performed for this note.
- `corner_tetrahedron.gd` already uses a tetrahedron as a static corner blocker.
  The new freestanding striped blocker reuses the completed tetrahedron's
  recipe at a declared scale. Its association is a concrete barrier; no real-world
  defensive performance is claimed or simulated.
- Original `walkableprism.tscn` is the wp: one-metre rise, two-metre run,
  one-metre width, visible mesh and collider. Preserve this geometry.
- The cube-net exhibit makes a closed cube; the tutorial's CubeBody renderer
  exposes the face list. The Trans_Pre BoxBody branch deliberately swaps to a
  BoxMesh and adds no supporting collider. Therefore the tutorial currently
  carries the idea of a cube more strongly than a reusable walking cube.
- Trans_Pre now replaces its 0.6 m timber deck with 24 one-metre blocks and
  six original wp ramps. The same construction definitions support the four
  original finished pickups. The comparison objects and their configuration
  remain intact. Arrival through A and departure through B frame this route.

## What an object carries

### Recover the wp + structure 2 construction

Palle's clarification, 19 October: the older grid already builds the walk-up
platform from `wp` and structure `2`. Carry this rule into the Void. A new
generic cube prefab is not a prerequisite for recovering that capacity.

Source inspection: `GridStructureComponent` treats a number as a stack count.
With one-metre cells and no gutter, `1` has its top at grid Y = 0.5; `2` at
Y = 1.5. The difference is one metre. `GridUtilitiesComponent` seats wp with
an additional half-metre offset because its scene origin is at mid-height.
The Void's slab top is floor-local Y = 0. An adapter must account for this
origin difference; copying raw world positions will not preserve the join.

Proposed optional construction layer within the shared Void floor record:

- Keep the slab, pillars and shafts as the permanent tower frame.
- A one-metre construction grid has its own floor-local origin and rotation.
- Legacy `1` corresponds to the existing slab surface; add no duplicate slab.
- Legacy `2` adds a one-metre-high block above the slab. Adjacent blocks form
  the walkable platform. Preserve the connection to the cube lesson.
- Reuse the original wp scene and matching collider, with base at Y = 0 and
  high edge at Y = 1. Test each rotated join, including horizontal offsets.
- Empty construction cells mean no added block. They do not cut the slab.
  An imported legacy `0` over a pit must therefore remain an explicit design
  decision: a bounded hazard on the slab or a separately supported floor hole.
- Save cells, ramps, placement and named assembly membership in the same layout
  used by the lab editor and native play. Allow painting blocks, placing and
  quarter-turning ramps, and copying a named construction. Keep existing free
  artifact placement alongside this optional grid.

The Polyhedra grid currently has a 16 x 3 m platform and ten wp units; Melencolia
also uses `2` with wp. Recompose those arrangements to fit the tower bays while
keeping their unit dimensions. Do not silently resize the ramp to make it fit.
Before this pass the Void support exhibit used the standalone wedge_palace
variant: a 0.9 m platform with different ramps. Polyhedra now uses the original
wp and a one-metre deck. The separate Transformation trial now carries the
same wp and platform-block definitions in a new static arrangement.

The static wp-to-`2` handoff is built in the separate Transformation trial,
preserving Trans_Pre's pickup demonstrations. Introduction now reuses the same
pieces for two banks around a raised lethal pit in the central bay. The original `tc` controller, through the
Void ferry/rider adapter, carries a four-cube deck between them. A fixed editor
anchor owns the moving child. Copy/move/turn that anchor preserves a working
route. Desktop and synthetic tracked XR tests cover boarding, body and eye
motion, leaving/jumping, return, fatal fall/retry and streaming. Translation
can develop this operation; `rc` and `sc` remain sources for later rotation
and scaling under a passenger, still requiring their own tests.

Evidence: `doc/book/iterations/2026-10-19-introduction-hazard-pit/` (current);
`2026-10-19-introduction-carried-crossing/` records the earlier shaft version.
The gap is a five-by-three-metre opening in a one-metre-high block construction.
The glowing bottom kills on contact. Both shafts stay free for descent. Pre and the curated tower are preserved. Real headset
comfort/performance remain to be observed; chapter texts are unchanged.

The optional grid schema is a design proposal. The first static wp/platform
assembly is implemented and tested as recorded at the top of this document.

Keep a stable recipe/definition identity, source lesson and source file. Name
what is retained and the new capability added. For a building piece also record
metre dimensions, a consistent placement origin, collision and join locations.
For example, wp has low and high connections; the cube has a base and a top one
metre apart. A material variant may give concrete, steel or timber its Void
appearance while preserving geometry, collision and joins.

Copies use the same definition with separate instance IDs and transforms.
An assembly retains its member IDs and local transforms. Its controller acts
on that assembly rather than replacing it with a visually similar exhibit.
Records such as the student's trace additionally carry saved data. Reusing a
definition is not the same as transferring a running physics instance.

Suggested saved record, **design proposal, not an existing JSON schema**:
`piece id / definition / source lesson / pose / material variant / joins`.
An assembly adds `members / local poses / controller / parameters`.
The editor and Godot should read the same placement record. Map files should
reference these definitions instead of duplicating their mesh-building code.

## Transformation within the fixed tower

Start in the existing separate selectable Transformation trial. Preserve the
curated tower. The floor is 42 x 18 m with six-metre storeys. Both shafts,
pillars, overhead services, spawn and descent route remain its permanent frame.

Use a bounded construction bay on the slab, between the pillars in a side wing.
An initial bay around 6 x 10 m is a layout candidate, not a surveyed final fit.
Build a route above a marked hazard bed using one-metre cubes, the original wp
ramps and beams. A first platform is one metre up; later parts can rise farther
within the storey. Falling off the route can enter a local hazard volume even
though the tower's real slab still lies beneath it. Do not place the hazard in
the arrival area or shared descent route.

Begin with the complete static route. Then change one relation at a time:
translation closes a gap, rotation aligns a bridge, scale changes a reach or
opening. Keep recognizable piece and assembly identities. Hold a clear view of
the destination and provide a local checkpoint before entering the bay.

This needs no new floor holes for its first test. If later encounters genuinely
need a larger drop or height, add a per-floor structural exception with matching
editor/runtime support. First test the raised route; do not widen or remove the
whole tower frame on the assumption that every later hall requires it.

## Acceptance for the next implementation

1. Complete the tetrahedron; its four faces enclose the intended volume. Its
   collider matches that volume. A proposed static blocker obstructs the route.
2. Walk up the original wp onto the platform supplied by the `2` construction
   rule, one metre above the Void slab, with a supporting collider.
   Both edges and the join work for the desktop and tracked player bodies.
3. Save, copy, rotate and reload that assembly in the lab editor. Dimensions,
   placement and identity agree with native play.
4. Put that saved assembly in the Transformation trial. Start with no motion.
5. Add translation first. The passenger moves with its supporting platform,
   resets correctly, and cannot bypass the intended gap through a stale collider.
6. Add the bounded hazard and checkpoint; test arrival, fall, respawn and exit.
   Real headset observation remains separate from synthetic XR tests.

The physical book shows the new operation. Online full files preserve each
complete runnable state. tutorial.md explains construction and the carry;
final.md can reflect on obstruction, permission and support. Neither text
should claim a physical capacity before its implementation and checks exist.

Introduction route constraint: seven editable partitions now interrupt the
side/rim bypasses. The player approaches, waits, rides, disembarks, then reaches
A's marked descent. Future growing and rotating crossings should follow as
ordered thresholds, as in the original museum. The current trial implements
only the travelling crossing. Walls, hazard and contact remain explicit saved
objects; moving them changes the route and requires another traversal check.
