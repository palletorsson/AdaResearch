# Post-Foundations Crisis — Curriculum Audit

**Sequence ID:** `postfoundationscrisis`
**Spine order:** 18 (between qfeplaboratory and graphtheory)
**Maps:** 3
**Evolutions written:** 0
**QFEP term:** Edge
**Phase:** synthesis / integration
**Tagline:** *"Knowing the limits of formalization, what do we build?"*

## 1. Core Concept

After the foundations crisis (Gödel, Russell, halting, incompleteness), the question shifts from *what can we prove?* to *what do we build knowing proof is impossible?* This sequence collects three orphan maps from deferred sequences (Critical Algorithms, Speculative Computation, Advanced Laboratory) and treats them as a short post-crisis triptych. Incompleteness becomes a **design material**, not a defeat: algorithmic bias is lived incompleteness in classification systems; rhizomatic networks are non-hierarchical alternatives to tree-structured formalization; molecular design is post-reductionist construction that emerges from catalog-plus-constraint rather than deduction from axioms. The sequence is the **ethical/speculative turn** of the curriculum — the pivot from "we hit a wall" to "we now know how to build after the wall."

## 2. The Red Thread

1. **Structural Incompleteness as Injustice** (CriticalAlgorithms_Algorithmic_Bias_Visualization)
   - Embedding spaces encode power; the gaps in classification fall on real bodies
   - Captures: bias as geometry (word proximity to gendered anchors), spatial inequality made architectural
   - Leaks: how to **repair** biased systems (remediation, fairness math) — not yet here

2. **Non-Hierarchical Topology** (SpeculativeComputation_Rhizome_Network)
   - Deleuze/Guattari rhizome as the anti-tree; any point connects to any other; no root, no trunk
   - Captures: multiplicity, connection, asignifying rupture, spatial embodiment of φ > 0
   - Leaks: formal graph theory (becomes the next sequence), swarm/decentralized compute

3. **Post-Reductionist Construction** (AdvancedLaboratory_Lab_Equipment_Simulation)
   - Molecular design as catalog + bonds + constraint → morphology; form emerges from conversation, not imposition
   - Captures: assembly as speculative practice, JSON hot-reload as live formal experimentation
   - Leaks: real chemistry, real biology, the move into the QFEP laboratory proper

## 3. Map-to-Concept Mapping

| Order | Map | Concept | Anchor Artifact | Status |
|-------|-----|---------|-----------------|--------|
| 1 | CriticalAlgorithms_Algorithmic_Bias_Visualization | Bias as Structural Incompleteness | bias_visualizer (+ bias_from_inside) | Artifact ✓, evolution missing |
| 2 | SpeculativeComputation_Rhizome_Network | Networks Without Hierarchy | rhizome_cave_demo | Artifact ✓, no @identity, evolution missing |
| 3 | AdvancedLaboratory_Lab_Equipment_Simulation | Molecular Design After Crisis | MolecularDesigner | Artifact ✓, evolution missing |

Map-level notes:
- **Bias Vis** uses architecture as pedagogy: 5-wide spacious half vs 2-wide cramped half, divided by a hard wall (h=5). Spatial inequality enacts the point. Two artifacts in one map (bias_visualizer + bias_from_inside) — the only map in the sequence with a sibling pair.
- **Rhizome** is a 10×10 cave with four chambers joined by narrow passages and a central void — the grid literally refuses a single privileged path. Single artifact (rhizome_cave_demo) matches the "compact_only" budget and the whole-map-is-the-lesson design.
- **Lab Equipment** (9×8) uses raised benches (h=2) with a void pit disrupting the orderly plan — "clean but with one surprise." Single MolecularDesigner anchor.

## 4. Artifact Inventory

| Concept | Artifact | File | Status |
|---------|----------|------|--------|
| Bias (outside view) | bias_visualizer | `commons/artifacts/bias_visualizer/bias_visualizer.gd` | ✓ @identity present; VR push-buttons cycle analogy modes |
| Bias (inside view) | bias_from_inside | `commons/artifacts/bias_from_inside/bias_from_inside.gd` | ✓ @identity present; MultiMesh + perspective lerp |
| Rhizome | rhizome_cave_demo | `algorithms/spacetopology/marchingcubes/scenes/rhizome_cave_demo.tscn` (controller: `RhizomeCaveDemoController.gd`, generator: `rhizome/RhizomeCaveGenerator.gd`) | ✓ exists; **NO @identity block** on controller or generator |
| Molecular Design | MolecularDesigner | `algorithms/computationalbiology/molecular_framework/MolecularDesigner.gd` | ✓ @identity present; needs VR grab (currently keyboard-only) |
| Remediation / fairness | — | — | **Missing** (see gap) |
| Rhizome→Graph bridge | — | — | **Missing** (see gap) |

Support artifact present in the bias map: `science_screen:180:1.5#mode:scatter` — the data-viz companion.

## 5. Gap Analysis

### Is this a real sequence or a stub?
**Both.** The spine note admits it: *"Collects real maps from deferred sequences — each a standalone exploration."* The three maps were salvaged from `criticalalgorithms`, `speculativecomputation`, and `advancedlaboratory` — three sequences that were deferred but whose best single map each lives on here. Structurally this is a **curated triptych**, not a full arc. But as a triptych it is surprisingly coherent: critique → alternative → construction maps onto *diagnose → reframe → rebuild*, which is exactly the post-crisis shape the sequence title promises.

### Missing Artifacts
- **Remediation / fairness algorithm** — bias is shown but not repaired. A "debiasing" or fairness-metric artifact would complete the critique→practice loop. (Medium priority.)
- **Rhizome-to-graph formalization bridge** — right now rhizome_cave_demo is a spatial generator; a companion artifact that maps the cave's chambers/passages to an actual graph (nodes + edges, adjacency matrix) would seed graph theory (next sequence) and give the concept a formal anchor. (Medium priority.)
- **Assembly feedback loop** — MolecularDesigner is one-way (catalog → form). A variant that lets constraints push back (design from target morphology) would complete the "conversation" framing its @identity claims. (Low priority.)

### Missing @identity
- `RhizomeCaveDemoController.gd` and `RhizomeCaveGenerator.gd` have no `@identity` block. Given this is the conceptual centerpiece map (Deleuze/Guattari), this is the most important gap to close before any evolution gets written.

### Missing Maps
- **No entry/frame map.** The sequence drops the player straight into a bias visualization without a threshold that names "the crisis is behind us, now what?" A small entry map (even a single text-panel room) would make the post-crisis framing legible.
- **No chamber/catalyst map.** Every other spine sequence ends with a Chamber_* integration map. This one teleports back to the Lab cold. The `return_to: "lab"` is functional but narratively thin.

### Ordering
Current order (bias → rhizome → molecular) is correct and matches the red thread: critique first, alternative topology second, constructive practice third. No reorder needed.

### Evolutions
Zero evolution documents exist for any of the three maps. Given the theoretical density (Deleuze/Guattari, word embeddings ethics, post-reductionist chemistry), these maps especially need evolution narratives — the concepts are advanced and the spatial metaphors are doing heavy lifting.

## 6. Forward Leaks

Concepts this sequence raises but cannot hold:
- **Formal graph structures** → graphtheory (next sequence — the rhizome becomes nodes+edges)
- **Decentralized coordination** → swarmintelligence / neural networks
- **Fairness math / remediation** → no sequence currently holds this (open territory)
- **Real chemistry / simulation fidelity** → not in the curriculum (intentionally; the molecular designer is speculative)
- **The full QFEP synthesis** → already behind us in qfeplaboratory (order 17); this sequence is *applied* QFEP, not theoretical
- **Deleuze/Guattari beyond rhizome** (body without organs, becoming-animal, smooth/striated space) → QFEP laboratory holds some; others unmapped

## 7. Proposed Ordering — or Merge/Expand/Remove

### Recommendation: **Keep, expand slightly, formalize the bridge to graphtheory.**

The sequence is thin (3 maps) but deliberately so — it is a triptych, not an arc. Removing it would leave three orphan maps from deferred sequences with no home. Merging it into `foundationscrisis` would muddy the crisis→response distinction. The right move is to accept it as the curriculum's **short ethical interlude** between the QFEP lab and graph theory, and to shore up what is there.

#### Proposed ordering (no changes to the three maps themselves):
```
1. (optional new) Post_Crisis_Threshold  — entry frame: "the formalists hit a wall; now what?"
2. CriticalAlgorithms_Algorithmic_Bias_Visualization  — critique: incompleteness as injustice
3. SpeculativeComputation_Rhizome_Network            — reframe: non-hierarchical topology
4. AdvancedLaboratory_Lab_Equipment_Simulation       — rebuild: post-reductionist practice
5. (optional new) Chamber_PostCrisis                 — catalyst chamber, bridges to graphtheory
```

#### Minimum viable improvements (ranked):
1. **Add `@identity` to the rhizome artifacts** (RhizomeCaveDemoController, RhizomeCaveGenerator). Concept-central; currently invisible to the garden listener and evolution tooling.
2. **Write evolutions for all three maps.** The theoretical load per map here is higher than in most sequences; spatial metaphors alone cannot carry it in VR.
3. **Add a rhizome→graph formal-bridge artifact** in the Rhizome map, or place one as the first artifact in the graphtheory sequence. This is the most important conceptual seam in the back half of the curriculum.
4. **(Optional) Threshold + chamber maps** to bring the sequence to 5 maps and match the structural pattern of every other spine sequence.

### Why not merge with foundationscrisis?
Foundations crisis is about *hitting the wall* (Gödel, Russell, Turing). Post-crisis is about *working after the wall*. Collapsing them would erase the turn that gives the whole back half of the curriculum its ethical voice. The sequence earns its keep by being exactly the pivot point — critique (bias), alternative topology (rhizome), speculative construction (molecular) — that opens the space for graph theory, swarm intelligence, and the sequences that follow.

## Summary

Three maps, three artifacts-of-note (four counting bias_from_inside), zero evolutions, one missing @identity. The sequence is a curated triptych rather than a full arc, but its red thread — *critique → reframe → rebuild* — is genuinely coherent and earns its position between qfeplaboratory and graphtheory. Priority work is not new maps but (1) @identity on rhizome, (2) evolutions for all three maps, and (3) a formal rhizome-to-graph bridge artifact to hand off cleanly to the next sequence.
