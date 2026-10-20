# The objects are the nodes

Palle's correction: the knowledge graph should unfold at the level of artifacts,
as the original point-to-construction tree did. Sequence and hall summaries are
useful navigation, but do not replace the objects and their possible uses.

Open http://localhost:3003/capacity-tree. The default is now the artifact view.
The previous sequence overview remains at `?scope=spine`; the original opening
diagram remains at `?scope=foundation`.

## What is represented

100 authored artifacts or proposed assemblies, 133 explicitly labelled
relationships, all 25 sequences. The surrounding catalogue contains 1,026
entries, drawn from the live 209 hall grids plus the explicit Void components
and proposed assembly. An unconnected catalogue object is marked as having no
authored lineage yet. This is not a complete pedagogical judgement of all
museum artifacts.

Operation, combination/carry and association remain separate meanings. A
repeated token has one identity and multiple current hall occurrences. Tokens
using the same scene file are listed separately as file matches. Neither a
shared scene nor co-placement automatically creates a teaching edge.

Selecting Drawn trace reveals Held point, Frame counter, Walking trace, Grid,
Drawn face, Painted flow field, Random-walk terrarium and Physarum trails. These
returns cross sequence boundaries. The held point is not lost in a list of
abstract subjects.

The source audit replaced stale Forces and Swarm examples with the current
point-addition rig, spring-linked points, orbiting points, momentum cradle,
neighbour lens, Physarum trace gallery and ant trail table. Cube uses the
folding net actually placed in Point_Animatedcube.

The beam, two-point gate and construction brace link to their existing Void
component sources, without claiming standalone registry placement. Wedge + cube
route remains explicitly proposed: common dimensions, collision, joins and a
saved recipe are still an implementation question.

## Verification

- Focused TypeScript compilation: zero diagnostics.
- `scripts/check-capacity-artifacts.cjs` in the encyclopedia: passed. Checks
  every reported occurrence against current map cells, edge endpoints, stable
  identity, source existence, sequence coverage and key carry/association edges.
- Browser: all 100 nodes in the whole graph; selected trace branch; current
  Swarm sequence; wider catalogue; old Point_Trace hall link; SVG download.
- Exported SVG parses and contains all 100 artifact node groups.
- Browser reported no warnings or errors during these checks.
- No Godot runtime or lesson reconstruction test was run: this change is a
  read-only knowledge view. Source presence and placement do not certify play.
- rooms.json and curriculum_spine.json hashes match their pre-task values.

## Files and editing

`commons/void/capacity-artifacts.json` is the editable source for object
explanations and authored edges. Diagram positions are derived from those
relationships; no room positions are written. The encyclopedia reads live
registries and maps on page load through `src/lib/capacity-artifacts.ts`.

`trace-branch.png` and `whole-tree.png` are actual browser captures.
`whole-tree.svg` is a portable vector export. `verification.json` records the
source-level assertions. Existing artifact images are labelled as stored
captures, not new Void screenshots.

Arrays before Transformation remains a separate order proposal. The graph
does not reorder the spine, alter game logic, or rewrite tutorial/final text.
