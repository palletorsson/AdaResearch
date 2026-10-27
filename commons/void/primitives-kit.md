# Primitives: the kit we carry

The tutorial leaves named game pieces with a source scene, dimensions, an insertion
anchor and a behaviour. `primitive-prefabs.json` holds these definitions;
`capacity-artifacts.json` holds their teaching introductions and typed relations.
The Three.js tree reads both. A geometric association is not code inheritance or
an automatic unlock. The original chapter texts have not been rewritten.

| Entry | Reusable output | Return / association |
| --- | --- | --- |
| Point Lines | Timber planks: 1, 2, 4 m × 60 mm × 250 mm | Barrier, carried stick, ruler, striking tool; crossed lines become the existing health pickup and danger X |
| Point Trace | Black carried sphere, 280 mm diameter, 0.3 kg; measured trace stays with the ramp | The body and its recorded path are separate pieces |
| Triangle | Timber sheets: 1 × 1, 2 × 1, 2 × 2 m; 45 mm thick | Flat deck, tilted surface, upright infill; existing stud, mesh and concrete wall families are associations |
| Polyhedra | Tetrahedron (4 vertices), square pyramid (5), triangular-prism wedge (6), pentagonal bipyramid (7) | An orange/ivory square pyramid borrows the warning role of a traffic cone; the seven-vertex solid is an optional comparison |
| Cube | Existing one-metre block and cube/wedge construction; Matter AND is now also on main floor 7 | Observe all four physical cases to earn the AND assembly; eight vertices belong to a cube here |
| Later Primitives | Existing Platonic/sphere studies, columns, profile vessels and rolling letter tyre, torus/bridge studies | More ways to refine, repeat, sweep and arrange the known kit; keep their own source behaviours |
| Melencolia | The built construction court | A usable place composed from prior pieces, supporting the original saved solids and image study |

Vertex count does not determine a unique polyhedron. The seven-vertex example is
five corners around a waist and two tips, with ten triangular faces. A hexagonal
pyramid is another seven-vertex example. A smooth cone is a different construction;
the five-vertex traffic marker remains a square pyramid.

The recurring **white surface-test shower** stays separate from the carried Trace
ball. Its factory defaults to 200 mm spheres; encounters may configure the radius
(the Matter Gate uses 280 mm). It releases equal balls from above, with no launch
impulse. It belongs to the walkable surface rather than to the loose-prop palette.

The plus, X, police barrier, ruler and hammer keep their existing source scripts.
Their taxonomy entries do not re-certify health, damage or striking behaviour.
They already exist as map artifacts and can be copied as those artifacts; they
have not been replaced with static decorative props. A mesh fence is not a solid
quad, and every existing wall does not need a separate compulsory tutorial stop.

## What Melencolia builds

The former single court slab is now 25 original one-metre concrete blocks,
25 one-metre timber sheets and a fitted border made from the 1 and 4 metre planks.
The two original wedges still provide access. `CourtDeck` retains its original
root and saved-placement meaning. Its main walking surface stays at one metre
(plus 3 mm of finish); the border reaches 1.03 m. The original nine solids and the
user's image-study orientation remain separate saved records.

The timber has metre-based grain UVs, small light-catching chamfers and flush sheet
fixings. Collision retains the nominal boxes. The fixed court skins are grouped
into at most eight GPU instance groups, retaining the individual source bodies/colliders.
Single kit members remain independent editor objects. Warm work lights belong to
the court assembly.

The larger composition goal is a construction atelier: approach, raised court,
workbench, framed view, a ball test and legible boundaries/consequences. The built
court is the first concrete assembly. This does not claim that every proposed
Dürer/Duchamp study or future combination has been ported. Melencolia should make
the small vocabulary productive, rather than introduce a shelf of unrelated props.

## First earned recipe: Matter AND

Main Cube floor 7 adds `matter-and` in the central bay, retaining every existing
saved object and part pose. Its controls are at local (0,0,2), leaving the previous
cube/wedge walkway intact. The separate `matter_gates` trial remains a practice
space and cannot award main-tower inventory progress.

`primitive-prefabs.json` now also defines the recipe's placement source, objective
and required observations: 00→0, 01→0, 10→0, 11→1. The source encounter emits
completion only when its actual observed trajectories match all four cases.
RESET restocks the ball and inputs while retaining the observation table.

The main game writes earned objectives to `user://void-prefab-inventory.json`,
separate from weapon holsters, museum scores and room arrangements. Repeated
completion is idempotent; restarting the lesson does not remove the reward.
I on desktop or left stick click in XR opens a pointer-operated inventory. A
placement requires an unoccupied slab bay within the frame and outside the shafts.
In-game copies last for the session; permanent compositions use the lab editor.

The web tree and Player inventory tab read the same catalogue and the local
desktop game's save. They show locked recipes without granting them. An earned
placement is an ordinary source-backed `copies` record with all named parts;
it uses the existing room autosave and shared desktop/VR layout. The six new fixed
deck-support cubes also remain individual editable parts, bringing the assembly
to 22 parts. They meet the plank undersides without filling either AND gap. This first pass
does not synchronize player progress between desktop and Quest. The editor's
authoring library remains separate from the player's earned inventory.

Evidence: `ada_run/matter-cube-inventory/`. Native tests use isolated test saves;
the visitor's actual inventory remains theirs to earn. Physical headset testing
is not implied by the synthetic XR checks.

## Verification and editing

Ten new standalone palette prefabs use their actual scenes in the native
`set_dressing` loader. Their placement schema is registered. New named sheets and
solids in Triangle/Polyhedra, the Line hand plank, the Trace ramp and the Melencolia
court have fresh editor exports. Existing arrangement records are not rewritten.
All exported meshes come from those running scenes, including the pyramid's band.

Evidence: `ada_run/primitives-kit/`. Native geometry, collider, source reuse and
palette-loader checks pass; editor checks parse real GLBs and validate independent
copy/move/turn drafts. The saved rooms stay byte-identical. Captures use the real
slab/column builder in a bounded frame; the saved Melencolia court is loaded with
the game's own placement loader, at the same floor-local poses. These checks are
not a full-tower playthrough or a physical-headset review.

The whole web project still has unrelated TypeScript errors; the changed capacity
tree modules have no reported diagnostics in that run. No claim of a globally
clean web build is made.
