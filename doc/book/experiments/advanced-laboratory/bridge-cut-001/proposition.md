# One line, solely responsible

**Proposed — nothing has run under this record; the artifact stands in the hall as an uncommitted working-tree placement of 2026-10-13.**

This companion binds two passages of the Advanced Laboratory hall to the [bridge_cut](../../../../../commons/artifacts/bridge_cut/bridge_cut.gd) artifact, following the form of [the seed-bench pilot](../../random-definition/seed-bench-001/proposition.md) and [the book architecture](../../../RECURSIVE_ARCHITECTURE.md). The pilot has since executed; this record has not. No observation, run or claim of behaviour appears below — every expected value is a prediction. Exact source versions are bound in [the record](./experiment.json).

The [tutorial](../../../../../commons/maps/AdvancedLaboratory_Lab_Equipment_Simulation/tutorial.md) (passage `advanced-laboratory.reroute-cycle.v1`, currently dirty in the working tree) says: “Reroute the second endpoint of edge 5 from hand to head: the hand is isolated and the rest contains a cycle. Move the other endpoint from elbow to that hand: every joint reconnects.” It initiates the question whether a learner can predict, before releasing a rerouted endpoint, which of the body's twelve connections are solely responsible for it staying one piece — and reconstruct by removal, rather than by looking, how one changed relation moves an edge into or out of that responsible set.

The [final](../../../../../commons/maps/AdvancedLaboratory_Lab_Equipment_Simulation/final.md) (passage `advanced-laboratory.connected-part.v1`, committed) says: “The hand waits outside that circuit, with no line reaching it. It has not disappeared from the room. It has disappeared from the body's connected part.” It initiates the question whether a visitor can tell which single line carries a part's belonging to the body before that line is removed — or whether a circuit makes every line on it dispensable, so that belonging is only learnable by cutting and seeing.

Neither hall text mentions the artifact; both predate it. The placement is a fact about the working tree: `bridge_cut:0:0.95` stands in this hall's dirty map_data.json, beside an untracked artifact folder and registry file. Either text could initiate alone; this record binds both.

Our proposition is conditional: **If the one elected edge of the artifact's eight-node tree is removed — the single change cut "none" → "bridge" at closure "open" — does a part's belonging become legible as the responsibility of one line, and does the returned loop demote exactly the lines it passes through?** The mappings below are operational readings of that question, not its definitive literary meaning.

## Competing interpretations

| Interpretation | Operational mapping | Assumptions | Exclusions |
| --- | --- | --- | --- |
| `bridge-cut.interp.tree-cut` (tutorial + final) | Read the hall body (13 joints, 12 connections, one component — a tree) through graph="tree". The passage's isolation event is the single change cut "none" → "bridge" at closure "open": `_find_special` elects the first edge whose removal raises the component count, and the outcome is read from `component_count()` (prediction 1 → 2) and `has_bridge()` (prediction true). The exiled small piece stands for the hand outside the connected part. | Tree-ness is the operative property: edges = nodes - 1 makes every edge a bridge, so the 8-node, 7-edge tree fairly reduces the 13-joint, 12-edge body. `component_count()` operationalizes “the body's connected part”. Which bridge is elected does not matter; first-found (edge [0,1]) is acceptable. | The reroute itself (remove AND re-attach in one release) is not modeled; cut only removes. No cycle appears, so the loop half of both passages is excluded. Node identities (hand, head, elbow) and all geometry are excluded; only connectivity is read. |
| `bridge-cut.interp.returned-loop` (final) | Operationalize “that circuit” via the closure export: compare "open" against "returned" at graph="tree", cut="none", reading `_bridge_edge`/`_chord_edge` through `has_bridge()` and the cut="chord" pathway. The appended edge [4,7] (crown to crown, around the trunk) creates the circuit; edges on it stop being bridges, while the trunk edge [0,1] remains one — the circuit protects the belonging of some parts and not others. | Adding the return edge is a fair stand-in, for bridge-status purposes, for the hall's reroute to the head that closes a loop. Bridge-status is the operative sense of a line “reaching” a part. | closure only ever adds an edge; nothing is exiled, so the passage's exile half is not modeled here. The demotion is read through probe methods, not through what a visitor can see. graph="theta" (born bridgeless) is outside both passages. |
| `bridge-cut.interp.chord-control` (tutorial) | Operationalize the tutorial's learning element “Prediction before editing” as a discrimination task with the built-in negative control: at graph="barbell", closure="open", compare cut="bridge" against cut="chord" — same gesture, two edges that look equally important — and read `component_count()` (prediction 2 vs 1). The written prediction of which edge is solely responsible, made before the cut, is the measured object. | The bridge and a chord are visually on a par in the barbell rendering, so prediction cannot be read off the picture. A failed prediction is an informative outcome, not a failed lesson. | The barbell is not a body; nothing maps to joints, the hand or edge 5. The final's loop and exile are untouched; closure is held at "open". The verdict plate (STILL CONNECTED / BROKEN) is readout only, not the measured change. |

## Bounded comparison

**Baseline:** BridgeCut with graph="tree", cut="none", closure="open", show_readout=true, and all other exports at code defaults (span=0.34, node_radius=0.022, edge_radius=0.006, default colors), set via `apply_grid_config` keys "graph", "cut", "closure".

**Single change:** cut "none" → "bridge" — the one edge `_find_special` elects (`_bridge_edge`) is removed; everything else untouched.

**Held fixed:** graph="tree" (the 8-node, 7-edge `_pos`/`_edges` literals in `_shape()`); closure="open" (no [4,7] return edge); show_readout=true; span=0.34; node_radius=0.022; edge_radius=0.006; whole_color, part_a_color, part_b_color and cut_color at code defaults; the other six tree edges (only `_removed` differs); and the readout channel — `component_count()` and `has_bridge()` read in both conditions.

## Invented arithmetic fixture

This is an invented calculation, hand-done from the `_shape()` literals and declared consts of bridge_cut.gd (`GRAPHS`, `CUTS`, `CLOSURES`, the tree's 8 `_pos` entries, `_edges = [[0,1],[1,2],[1,3],[2,4],[2,5],[3,6],[3,7]]`, the returned edge [4,7], span 0.34). It reuses no number from the registry description, any measured block or any past probe or capture; nothing has run under this record's identity, so every value is a labelled prediction, not output.

The arithmetic: 8 nodes, 7 edges, connected with edges = nodes - 1 (7 = 8 - 1), hence acyclic — one component, every edge a bridge. `_find_special` scans i = 0..6; removing i=0 ([0,1]) strands node 0 (components 1 → 2), so `_bridge_edge` = 0; no removal keeps the count at base, so `_chord_edge` = -1. The single change sets `_removed = [0]`; union-find over the remaining six edges chains nodes 1..7 into one set and leaves {0}: 2 components, sizes 1 and 7. closure="returned" appends [4,7]: 8 edges on 8 nodes, cycle rank 8 - 8 + 1 = 1; the cycle is 4-2-1-3-7-4, so removing any of its five edges leaves 1 component (first at i=1, so `_chord_edge` = 1), while [0,1], [2,5] and [3,6] lie off it, so `has_bridge()` stays true.

Predicted, not observed: baseline `component_count()` == 1 and `has_bridge()` == true with `_bridge_edge` == 0; baseline `_chord_edge` == -1, so a request for cut="chord" removes nothing and `_verdict()` returns "NO CHORD TO CUT\nevery edge is a bridge\nstill 1 piece"; after the single change, `component_count()` == 2 with piece sizes 1 ({node 0}) and 7 ({nodes 1..7}); at closure="returned" with cut="none", still 1 component, cycle rank 1, `_chord_edge` == 1 (edge [1,2]), `has_bridge()` still true.

## What could change the work

- The uncommitted placement changes: bridge_cut leaves this hall's map_data.json, or the untracked artifact folder and registry file never land in a commit — the record's premise that the artifact stands in this hall fails.
- tutorial.md is dirty in the working tree; if its pending edits are reverted or rewritten so the bound excerpt stops being a verbatim contiguous byte substring, the tutorial passage binding must be re-selected and re-versioned.
- A probe contradicts the hand arithmetic (e.g. `component_count()` != 2 at graph="tree", cut="bridge", closure="open", or `_chord_edge` != -1 at closure="open") — then the code reading in this record, not the artifact, is in question, and the fixture must be redone before any interpretation is trusted.
- An encounter shows the plate text (STILL CONNECTED / BROKEN / NO BRIDGE TO CUT), not the removal-and-recolour, carries the meaning for visitors — then `component_count()` as the operationalization of “the body's connected part” needs revision toward the verdict vocabulary.
- The tree-for-body reading proves too loose: the hall's reroute concerns a named connection (edge 5, the left forearm) while `_find_special` always elects the first bridge (edge [0,1]); if that mismatch matters in the encounter, the mapping needs a bespoke graph value or a different operational route.

## Planned cycle — future work, none performed

1. Capture the baseline on the real node with configuration receipts, and keep the written prediction beside it.
2. Apply the single change through `apply_grid_config` alone; no other export touched.
3. Compare `component_count()`, `has_bridge()`, the verdict string and a capture against the fixture's predictions; record agreement, disagreement or failure as different findings.
4. Keep an independent copy of configurations and readbacks under this record's identity.
5. Replay from the kept record and compare within the declared build.
6. Have a reader independently reconstruct the comparison from the two hall texts and the artifact code; record assistance.
7. Review tutorial and final separately — revise, retain with reasons, or hold an open question — then select, defer or stop a next experiment from what was observed.

## What remains open

Execution (no probe or scene has run under this record); observation (the [log](observations.md) is empty); the tutorial review and the final review (both [pending](revision.md)); the human encounter in the hall; and independent reconstruction. The [text simulation](text-simulation.md) is the hypothetical trace, nothing more.
