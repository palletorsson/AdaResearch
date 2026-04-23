# Graph Theory — Curriculum Audit

**Sequence ID:** `graphtheory`
**Spine order:** 19 (final spine sequence)
**QFEP phase:** Integration
**Maps:** 8
**Evolutions written:** 0
**Truth:** *"Everything is a graph if you squint hard enough."*

## 1. Core Concept

Graph theory is the mathematics of pure relation. A graph is two sets: vertices (identity — the things that exist) and edges (relation — how they connect). Everything else in the sequence is a consequence: layout is a way to *see* the relations, pathfinding is a way to *use* them, connectivity asks which relations hold globally, spanning trees ask which are essential, flow asks how much they can carry, and matching asks how they pair. The sequence's deeper claim is ontological: any system with discrete parts and discrete relations is a graph, and graph theory gives you the language to reason about it. This is the integration sequence — relation as the primitive, structure as what emerges from relation, and algorithms as the operations that extract meaning from structure.

## 2. The Red Thread

1. **Foundations — what IS a graph** (GT_Foundations)
   - Vertices + edges; Euler's parity theorem; the Königsberg impossibility
   - Captures: definition, degree, Eulerian walks, the birth of the field
   - Leaks: embeddings, visualization, why some layouts reveal structure and others hide it

2. **Layout — making structure visible** (GT_Layout)
   - Force-directed equilibrium: springs pull connected nodes, repulsion pushes all pairs apart
   - Captures: physics as a way of seeing; relation as force
   - Leaks: the path between nodes, not just their arrangement

3. **Pathfinding — navigating relation** (GT_Pathfinding)
   - A* search, heuristics, the tradeoff between optimal and greedy
   - Captures: what can be reached, at what cost, along which edges
   - Leaks: global structure — a path is local; what is the shape of *all* reachability?

4. **Network Analysis — centrality and flow** (GT_Network_Analysis)
   - Hub/cluster/periphery tiers; centrality as importance; pulsing edges as live flow
   - Captures: nodes are not equal — some carry more structure than others
   - Leaks: mutual reachability, which components are truly closed under relation

5. **Connectivity — strongly connected components** (GT_Connectivity)
   - Tarjan (single-pass DFS, low-link), Kosaraju (transpose + two-pass DFS), topological sort
   - Captures: equivalence classes of mutual reachability; partial order across SCCs
   - Leaks: among the edges that hold connectivity together, which are essential?

6. **Spanning Trees — the lightest skeleton** (GT_Spanning_Trees)
   - Kruskal / Prim MST; the minimum edge set that still spans all vertices
   - Captures: essentialism — what is the cheapest structure that still holds everything?
   - Leaks: capacity, throughput, what flows through the skeleton

7. **Flow — capacity and cuts** (GT_Flow)
   - Push-relabel max flow; min-cut duality; bottlenecks
   - Captures: edges aren't just present/absent — they have capacity; the graph throttles
   - Leaks: when you can't flow through the whole graph, who pairs with whom locally?

8. **Matching — optimal pairing** (GT_Matching)
   - Edmonds' blossom algorithm; maximum matching; symmetry of pairs
   - Captures: pairing as the finest relation — one-to-one, mutual, exclusive
   - Leaks: hypergraphs (edges with more than two endpoints), continuous relations, topology

## 3. Map-to-Concept Mapping

| Order | Map | Concept | Anchor Artifacts | Status |
|-------|-----|---------|------------------|--------|
| 1 | GT_Foundations | Definition of a graph | graphspace, KonigsbergBridge | Built, needs evolution |
| 2 | GT_Layout | Structure through physics | force_directed_layout | Built, needs evolution |
| 3 | GT_Pathfinding | Search and traversal | pathfinding3d | Built, needs evolution |
| 4 | GT_Network_Analysis | Centrality and live flow | networkflow3d, network_analysis, rhizomatic_structure | Built, needs evolution |
| 5 | GT_Connectivity | Strongly connected components | tarjan_algorithm, kosaraju_algorithm | Built, needs evolution (topological_sort declared but not placed) |
| 6 | GT_Spanning_Trees | Minimum spanning tree | mst_visualization | Built, needs evolution |
| 7 | GT_Flow | Max-flow / min-cut | push_relabel_algorithm | Built, needs evolution (karger_algorithm declared but not placed) |
| 8 | GT_Matching | Maximum matching | edmonds_algorithm | Built, needs evolution |

The spatial metaphors are strong throughout — Königsberg islands with bridges, asymmetric force-directed rooms, a literal maze for pathfinding, a hub-and-spoke for centrality, three rooms as SCCs, scattered platforms for MST, a narrowing funnel for flow, a mirrored room for matching. Each map embodies the algorithm in its architecture. This is the sequence's structural strength.

## 4. Artifact Inventory

| Concept | Artifact | File | Status |
|---------|----------|------|--------|
| Graph definition | graphspace | algorithms/graphtheory/graphspace/graphspace.gd | Force-directed rooms walked as a graph |
| Königsberg | KonigsbergBridge | algorithms/graphtheory/graphspace/konigsbergBridge.gd | 4 nodes / 7 edges Euler demo |
| Graph (3D variant) | graphspace3d | algorithms/graphtheory/graphspace3d/graphspace3d.gd | Not placed in any map |
| Force-directed (2D) | force_directed_layout | algorithms/graphtheory/force_directed_layout/ForceDirectedLayout.gd | Hooke + repulsion |
| Force-directed (3D) | forcedirected3d | algorithms/graphtheory/forcedirected3d/forcedirected3d.gd | Not placed (3D variant) |
| Pathfinding | pathfinding3d | algorithms/graphtheory/pathfinding3d/pathfinding3d.gd | A* on voxel grid |
| Pathfinding (legacy) | pathfinding | algorithms/graphtheory/pathfinding/pathfinding_visualization.gd | Not placed |
| Network flow (3D) | networkflow3d | algorithms/graphtheory/networkflow3d/networkflow3d.gd | Edmonds-Karp with particles |
| Network flow (legacy) | networkflow | algorithms/graphtheory/networkflow/network_flow_visualization.gd | Not placed |
| Network analysis | network_analysis | algorithms/graphtheory/network_analysis/NetworkAnalysis.gd | Centrality tiers, pulsing edges |
| Rhizomatic structure | rhizomatic_structure | registered in alternative_geometries.json (not in graphtheory/) | Placed but lives in another algorithm folder |
| SCC (Tarjan) | tarjan_algorithm | algorithms/graphtheory/tarjan_algorithm/tarjan_algorithm.gd | Single-pass DFS, low-link |
| SCC (Kosaraju) | kosaraju_algorithm | algorithms/graphtheory/kosaraju_algorithm/kosaraju_algorithm.gd | Transpose, two-pass |
| Topological sort | topological_sort | algorithms/graphtheory/topological_sort/topological_sort.gd | Built, NOT placed in GT_Connectivity |
| MST | mst_visualization | algorithms/graphtheory/minimumspanningtree/mst_visualization.gd | Kruskal or Prim |
| Max flow (push-relabel) | push_relabel_algorithm | algorithms/graphtheory/push_relabel/push_relabel.gd | Preflow-push |
| Min-cut (Karger) | karger_algorithm | algorithms/graphtheory/karger_algorithm/karger_algorithm.gd | Built, NOT placed in GT_Flow |
| Matching | edmonds_algorithm | algorithms/graphtheory/edmonds_algorithm/edmonds_algorithm.gd | Greedy matching (not true blossoms) |

Identity blocks are present and well-formed on every artifact file inspected (all 15 .gd files have essence / desire / critical_parameter / triggers / emerges / needs fields).

## 5. Gap Analysis

### Artifacts built but not placed
- **topological_sort** — declared in merge_plan for GT_Connectivity but not in the interactables grid. This is a natural companion to Tarjan and Kosaraju; placing it completes the connectivity triad.
- **karger_algorithm** — declared in merge_plan for GT_Flow but not placed. Karger gives min-cut from a randomized angle; pairs naturally with push-relabel (deterministic max-flow) to show the duality.
- **graphspace3d**, **forcedirected3d** — 3D variants exist but GT_Foundations and GT_Layout use the 2D versions. Could add as "richer" anchors for VR, or dedicate a separate map.
- **pathfinding** (legacy 2D), **networkflow** (legacy 2D) — appear superseded by 3D versions; candidates for cleanup or repurposing as compact intro artifacts.

### Artifact weaknesses
- **edmonds_algorithm** — its identity admits *greedy* maximum matching, not Edmonds' blossom algorithm. The map title is "Optimal Pairing via Blossoms" but the artifact doesn't do blossom contraction. Either rename ("Greedy Matching") or upgrade the algorithm to actual blossoms.
- **rhizomatic_structure** — placed in GT_Network_Analysis but lives in `alternative_geometries` registry, not `graphtheory`. Either move the registry entry, duplicate into graphtheory, or justify the cross-sequence placement (the rhizome is a Deleuze/Guattari figure — probably deliberate, but should be documented).

### Missing concepts (no map, no artifact)
- **Graph coloring** — classic graph theory (four-color theorem, chromatic number). Absent from the sequence.
- **Planarity / embeddings** — Kuratowski / Wagner. The Königsberg problem raises this implicitly but nothing follows it up.
- **Degree distribution / random graphs** — Erdős–Rényi, scale-free networks, small-world. Critical for the QFEP "E-term lives in randomness" framing but not represented.
- **Bipartite matching / stable marriage** — Edmonds generalizes bipartite matching; the bipartite case is simpler and more intuitive but absent.
- **Traveling salesman / Hamiltonian paths** — a natural counterpart to Eulerian paths (visit every edge vs visit every vertex) and absent.
- **Spectral graph theory** — Laplacians, eigenvalues, community detection. Network_analysis touches community membranes visually but no artifact does the math.
- **Chamber_Graphtheory** — there is no synthesis/catalyst chamber map. Every other spine sequence ends with one; graphtheory returns straight to the post-graphtheory Lab. Given this is the final spine sequence, a chamber is doubly important — it should be the QFEP-integration terminus.

### Ordering issues
The current order (Foundations → Layout → Pathfinding → Network Analysis → Connectivity → Spanning Trees → Flow → Matching) is mostly correct but has a subtle bug: **Network Analysis is placed before Connectivity**, which means "centrality and flow" is introduced before the reader knows what "strongly connected" means. Centrality only makes sense on a connected (or component-decomposed) graph. Swapping those two gives a cleaner build: Definition → Layout → Pathfinding → Connectivity → Network Analysis → Spanning Trees → Flow → Matching.

Additionally, **Flow and Spanning Trees are close siblings** (both ask "what edges matter?" — one by weight-minimum, the other by capacity-maximum), so keeping them adjacent is correct. Matching as the finale is correct — it is the finest grain of relation.

### Transition breaks
- Pathfinding → Network Analysis (or Connectivity): no bridge explaining why we shift from "find a path" to "analyze structure." A bridge text: *"A path is a local question. Now we ask global ones."*
- Connectivity → Spanning Trees: no bridge from "which vertices reach which" to "which edges are essential." Spanning trees are what's left when you throw away redundant edges.
- Flow → Matching: the jump from "how much can pass through?" to "who pairs with whom?" is not obvious. Matching is flow on a bipartite graph with unit capacities — that identity should be told.

## 6. Forward Leaks

This is the **final spine sequence** (order 19). It does not leak forward into another spine sequence — it leaks into branches and into the Lab integration:

- **Hypergraphs, simplicial complexes** → topologicalstructures / computationalgeometry branches
- **Random graphs, percolation** → randomness branch (E-term of QFEP lives here)
- **Continuous relation, manifolds** → foundationscrisis branch
- **Dynamical graphs (nodes/edges changing over time)** → wavefunctions, forces, neuralnetworks branches
- **Semantic edges (what a relation *means*)** → queer-theory / QFEP framing; the Lab's catalyst system
- **Graphs as games** → machinelearning, decision trees
- **Embodied graphs** → the map grid itself — every map in Ada Research is a graph (rooms = nodes, doors/teleporters = edges). The graphtheory sequence is self-referentially the key to the whole project's navigation.

Because this is the integration terminus, the "leaks" are really **back-references** — every earlier sequence can now be re-read as a graph problem. Transformation is a graph of linear maps. Wavefunctions are graphs of phase relations. Forces are graphs of interactions. A chamber here should make that legible.

## 7. Proposed Ordering

```
1. GT_Foundations       — definition, Königsberg, Euler
2. GT_Layout            — structure through physics (force-directed)
3. GT_Pathfinding       — traversal, A*, heuristics
4. GT_Connectivity      — SCCs, topological sort  [moved earlier]
5. GT_Network_Analysis  — centrality, community, live flow  [moved later]
6. GT_Spanning_Trees    — essential edges by weight
7. GT_Flow              — capacity, max-flow, min-cut (+ Karger)
8. GT_Matching          — pairing, Edmonds / blossoms
9. Chamber_Graphtheory* — QFEP integration terminus (MAP MISSING)
```

### Minimum viable fixes (in priority order)

1. **Swap GT_Network_Analysis and GT_Connectivity.** Structure must precede analysis.
2. **Place topological_sort in GT_Connectivity.** It's registered in merge_plan already; the grid just needs a cell.
3. **Place karger_algorithm in GT_Flow.** Same deal — declared, unplaced. Completes the max-flow / min-cut duality.
4. **Rename GT_Matching title OR upgrade edmonds_algorithm.** "Via Blossoms" is currently aspirational — the artifact is greedy matching.
5. **Build Chamber_Graphtheory.** The spine's final room. Integrates catalyst with graph-as-everything: every prior sequence reappears as a graph on the walls.
6. **Write transition bridges** between maps 3→4, 4→5, and 7→8 — the three thread breaks above.

### Long-term additions

- A **graph coloring** map (chromatic number, four-color). Natural fit after Matching.
- A **random graphs** map. Bridges to the randomness branch and grounds the QFEP E-term.
- A **bipartite matching** map. Gentler onramp to Edmonds.
- Consolidate or retire the legacy 2D pathfinding/networkflow artifacts.

## Summary

The graphtheory sequence has a strong structural backbone — every map's architecture embodies its algorithm, every artifact has a proper @identity block, and the eight maps cover the canonical graph theory curriculum from Königsberg to Edmonds. The sequence is **built** in the pipeline sense: all maps have data, all anchor artifacts exist. What it lacks is **integration polish**: two artifacts are orphaned (topological_sort, karger_algorithm), one is misnamed (edmonds_algorithm is greedy, not blossoms), the order misplaces Network Analysis before Connectivity, and — most significantly for the final spine sequence — there is no Chamber_Graphtheory to close the QFEP arc. Zero evolutions have been written; this entire sequence sits at Stage 2 (Documentation) of the completion pipeline despite being at Stage 4 (Maps) structurally. Given its position as the integration terminus of the whole spine, completing this sequence is the last mile of the Ada curriculum.
