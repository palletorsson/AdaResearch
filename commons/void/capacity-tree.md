# From a point, a world

19 October 2026. Palle asked for a visual tree of capacities for understanding
and building, including prefabs created by association.

Open `http://localhost:3003/capacity-tree`. **Palle corrected the level of the
graph: nodes must be concrete artifacts, as in the original tree, not halls or
sequences.** The default now reads `capacity-artifacts.json`: 100 authored
objects/assemblies in the initial artifact view, expanded to 105 objects and
138 operation/composition/association edges after the construction-lineage
discussion, across all 25 sequences. Its wider catalogue reads current map grids and registries (1,029
entries on 19 October, including explicit Void components and a proposal).
This is a revisable authored subset, not a claim that every museum object has
a proven tutorial lineage. The unconnected field remains searchable.

The Void lab editor and trial board link to it. The sequence overview remains
at `?scope=spine`; it joins the live spine, the existing execution
plan and saved hall subjects. `commons/void/capacity-spine.json` supplies the
curated conceptual tree and proposed building associations. The detailed
opening branch remains at `?scope=foundation`, backed by
`commons/void/capacity-tree.json`. The viewer lives in the sibling encyclopedia
under `src/app/capacity-tree/`.

### Artifact graph contract

- One token, one node; its current hall placements are occurrences, not copied
  nodes. Different tokens sharing a scene are explicitly listed as file matches.
- `develop` = authored operation/learning relation; `combine` = composition or
  carry; `associate` = a creative or conceptual connection. None asserts code
  inheritance. The graph does not derive edges from co-placement.
- Actual live map cells establish placement. Registry scene paths establish
  source existence. Neither establishes interaction tests or Void readiness.
- Void beam, two-point gate and triangle brace link to their actual component
  sources; they are not claimed to be standalone registry artifacts.
- The static wedge + platform route now has an implemented Polyhedra source,
  striped blockers and reusable editor pieces. The Transformation bay remains
  proposed. The graph keeps source existence distinct from verified behaviour.
- Each object unfolds to understand / use / typed relations / source / halls.
  Selecting its branch shows returns across sequence boundaries. Whole tree,
  sequence and hall scopes, search, catalogue, photos, SVG and JSON are available.
- All 25 sequences are represented; 209 hall grids were read. Coverage and
  source assertions: sibling `scripts/check-capacity-artifacts.cjs`.
- Palle's next clarification: the graph must track the building pieces a lesson
  leaves, not just related exhibits. `construction-lineage.md` records the
  tetrahedron -> obstruction, prism -> wp, cube -> platform, assembly ->
  Transformation handoff. Selected nodes now have definition / keep / add /
  proof records. The first Polyhedra building pass adds the actual blocker,
  standard platform and wp assembly: 107 authored nodes and 141 relations.
  The moving Transformation bay remains proposed. Keep symbols as the default.

## Compact contract

Point -> line -> triangle -> closed body -> wedge + cube -> construction ->
transformation. Trace -> retained record -> Grid is a returning branch.
Association creates further uses: line -> ruler / beam / boundary; triangle ->
brace / sign; trace -> light. These are distinct relations, not code inheritance
or a claim that every prefab belongs in the tutorial.

- `learn`: an authored learning route, not a universal prerequisite.
- `associate`: a form suggests another use or meaning.
- `combine`: pieces compose or a recipe carries forward.
- Node: understand / build / gap / sources / hall / editor floor.
- `placed`: implementation placed in the Void or its separate trial; not a new
  interaction test or headset certification.
- `source`: source exists, but the proposed Void return remains unverified.
- `proposed`: the connection or reusable variant remains to be built.

The detailed branch covers Primitives to Transformation, plus returns to
repetition and surface. Shared player, streaming, light, recording and
placement capacities are shown separately there.

The global view covers all 25 current sequences, 209 halls and 126 registered
topics (19 October live sources), with 503 recorded hall prerequisites. Counts
are computed from sources, not fixed. Every hall can unfold to bring / learn /
carry, object, operation, checks, source review and saved runtime evidence.
The topic register is not an exhaustive inventory of every hall subject.
Conceptual branches, current walking order, recorded prerequisites and
proposed prefab associations remain different edge meanings.

## Arrays before Transformation?

Palle raised this as a possibility, not an instruction to reorder the spine.
Basic arrays and loops already enter in Trace and return in Grid. The complete
Arrays sequence currently depends on Trans_Pre, Trans_Rotation and Trans_Pit.
A preview swap produces six new forward links across Array,
Tutorial_Tiling_Floor, Tutorial_Tiling_Walls and Tutorial_Disco. Show those
handoffs; do not silently change or remove them. Proposed bridge: use a small
static repeated wedge/cube arrangement before Transformation, then deepen
ownership and many-object arrangement in Arrays. This remains a proposal.

## Read the gaps honestly

Five registered topics are unplaced (including intentionally deferred topics).
Twelve have placement questions, including old halls outside the current
spine and a return before its recorded introduction. Three current halls have
no saved execution-plan entry: Random_Entropies, Noise_Cellular, Noise_Box.
ISO_RhizomeBody has no tutorial file. These remain visible; none are invented
from artifact names or silently filled. Runtime evidence is carried with its
current/stale status; opening this graph runs no Godot lesson test.

The graph has pan/zoom, search, sequence/hall navigation, topic returns,
associations, order comparison, deep links and SVG/JSON export. Authored
global tree placements and all proposed associations are revisable in the
annotation JSON. Edit teaching choices through existing hall cards / plan.

## The missing join

The original `commons/scenes/mapobjects/walkableprism.tscn` is a real walkable
wp: one-metre rise, two-metre run. Polyhedra already uses it to reach a platform.
The Animated Cube tutorial's CubeBody renders faces but has no collider.
The Trans_Pre trial now uses 24 one-metre platform blocks and six original wp
ramps in a saved construction. These are the same definitions used on Cube,
arranged at a single height under the four finished pickups. Arrival through A
and departure through B give the comparison and construction a walking order.
Native checks cover both player capsules, the joins and both drops; editor
checks cover separate parts, copy/move/turn and the shared save. Evidence:
`doc/book/iterations/2026-10-19-transformation-two-shafts/`.
The animated pickup examples still do not certify a platform that carries a
player. That is the next capacity to test in Trans_Introduction.

Palle also proposed a bounded dangerous lower space for Transformation. Keep
that as an encounter design choice. Ordinary floor-drop damage and physical
headset comfort still have their own existing contracts.

## Keep it revisable

Edit labels and relations in the JSON; reload the page. Node positions describe
only the diagram. Source links and floor links are read-only navigation. The
graph does not write rooms.json, change museum code, or rewrite tutorial.md /
final.md. Save SVG exports the selected diagram view. A source file existing
does not prove the authored relationship or the runtime operation.
