# Cellular Automata — Curriculum Audit

**Sequence ID:** `cellularautomata`
**Spine layer:** emergence (E(S) — entropy phase)
**Maps:** 9 (CA_Introduction, CA_ElementaryRules, CA_GameOfLife, CA_BeyondBinary, CA_ExpandingSpace, CA_SoftRules, CA_AgentsCircuits, CA_EdgeOfChaos, Chamber_CA)
**Prerequisites:** primitives, randomness
**Unlocks:** swarmintelligence, proceduralgeneration
**Truth:** "Local rules, global patterns. Each cell knows only its neighbors, yet worlds emerge. Rule 110 is Turing complete — simple rules can compute anything."
**Formula:** `cell(t+1) = rule(cell(t), neighbors(t))`

## 1. Core Concept

Cellular automata are laboratories for emergence. A cell knows nothing but its immediate neighbors; the rule is the same everywhere; time is discrete; updates are synchronous. From that minimal grammar — cells, states, neighborhoods, a shared transition function — entire universes crystallize: Persian-rug symmetries, gliders, oscillators, disease fronts, digital circuits, chaos. The sequence teaches that complexity is not proportional to rule complexity. Rule 110, a 1D two-state nearest-neighbor rule, is Turing complete. The E(S) phase thesis lives here: entropy is not disorder but the medium in which computation occurs, and structure emerges at the edge of chaos. Simplicity is not a limitation; under the right local dynamics, simplicity is sufficient.

## 2. The Red Thread

1. **Substrate** (CA_Introduction)
   - A grid of cells, each in a state, each reading a neighborhood. Same rule everywhere, synchronous time.
   - Captures: discreteness, locality, simultaneity, the Persian-rug demonstration that symmetric local rules preserve global symmetry.
   - Leaks: why this rule, not another; how to read the rule table; the actual per-step update mechanic.

2. **Life Cycle / 2D Rule** (CA_GameOfLife)
   - Conway's B3/S23 as a canonical 2D CA — birth, survival, death as vocabulary for state transitions.
   - Captures: sensitivity to initial conditions, still lifes, oscillators, named dynamical regimes (avalanche, percolation, dendrite, disease, ecosystem, crack).
   - Leaks: gliders and glider guns (moving structures, unbounded growth) aren't directly anchored; no artifact proves Life's computational universality.

3. **1D Classification** (CA_ElementaryRules)
   - Wolfram's elementary CA: 1D, 2 states, radius 1, 256 total rules. Rule 30 = chaos, Rule 110 = Turing complete.
   - Captures: the rule-number-as-binary-lookup-table concept, Wolfram Classes I–IV, the central result of the whole sequence (Rule 110 is universal).
   - Leaks: the 256-rule landscape as a navigable survey; the precise mechanism by which Rule 110 simulates computation.

4. **Generalization: Totalistic & Non-Square** (CA_BeyondBinary)
   - Count neighbors instead of distinguishing them; tile in hexagons instead of squares; allow more states.
   - Captures: rule-table compression, tessellation-independence of CA behavior, embodied VR CA encounter.
   - Leaks: the totalistic-vs-general rule-table contrast is conceptual, not visualized.

5. **Generalization: Extended Neighborhoods / 3D** (CA_ExpandingSpace)
   - Radius becomes a variable; neighborhoods reach farther; 3D growth becomes possible.
   - Captures: "horizon" of locality, branching 3D growth, interference between overlapping influence zones, structural decay.
   - Leaks: a single artifact that sweeps radius (1→2→3…) live and shows the transition from granular to smooth.

6. **Stochasticity** (CA_SoftRules)
   - Rules that fire probabilistically; deterministic CA under external bias (gravity).
   - Captures: robustness vs fragility of patterns, link to statistical mechanics and lattice-gas fluid models.
   - Leaks: a deterministic/stochastic side-by-side comparator; the continuous-state CA (true "soft rules") is not visualized.

7. **Edge of Chaos / Classification** (CA_EdgeOfChaos)
   - The sequence's organizing principle named: Class IV lives between order (I, II) and randomness (III); Langton's lambda quantifies the transition.
   - Captures: why Rule 110 computes and Rule 30 doesn't, criticality, the entropy-phase thesis.
   - Leaks: a lambda slider that sweeps through all four classes live; no explicit link to neural criticality or phase transitions in other sequences.

8. **Computation / Authorship** (CA_AgentsCircuits)
   - Wireworld as proof-by-construction that CA compute; the rule explorer hands authorship to the learner.
   - Captures: CA-as-computer (AND/OR/NOT gates conceptually possible), active authorship after seven maps of passive observation, 1D-to-3D arc summarized by stacked spacetime volume.
   - Leaks: a Wireworld circuit library with working logic gates and a clock; a visible adder; the bridge to actual programs.

9. **Synthesis / Chamber** (Chamber_CA)
   - Catalyst chamber: two cellular automata interact across the player-creature boundary.
   - Captures: rule systems meeting, narrative closure, QFEP connection, handoff back to Lab.
   - Leaks: transitions to swarmintelligence and proceduralgeneration — the intent is only one paragraph long.

## 3. Map-to-Concept Mapping

| Order (json) | Map | Concept | Anchor Artifact | Status |
|---|---|---|---|---|
| 1 | CA_Introduction | Substrate — grid, cells, neighborhoods | persian_rug, line_network_ca | Intent written; needs evolution |
| 2 | CA_ElementaryRules | 1D classification / Rule 30 / Rule 110 | structure_growth | Intent written; needs evolution |
| 3 | CA_GameOfLife | 2D life-cycle rule, B3/S23 | ca_bridge, ca_columns, mirrored_cellular_automata | Intent written; needs evolution |
| 4 | CA_BeyondBinary | Totalistic, hexagonal, multi-state | hexagon_ca_vr, ca_growth_network, game_of_life_petri, mold_network | Intent written; needs evolution |
| 5 | CA_ExpandingSpace | Extended neighborhood / 3D | cellular_automata_3d_tree, crossway_ca, decaying_bridge, ca_chair_test | Intent written; needs evolution |
| 6 | CA_SoftRules | Stochastic CA, noise, bias | rule_30_110_gravity, ca_sphere | Intent written; needs evolution |
| 7 | CA_AgentsCircuits | Wireworld, authorship, 3D-stacked | ca_rule_explorer, CellularAutomata3DStacked, sierpinski_pyramid | Intent written; needs evolution |
| 8 | CA_EdgeOfChaos | Wolfram classes, criticality | ca_screen, self_organization_ca, disease_spread_ca, volumetric_fog_ca | Intent written; needs evolution |
| 9 | Chamber_CA | Synthesis, catalyst | lifeform_walker, Science Screen | Thin intent; needs evolution |

**Ordering concern (significant):** The json lists CA_ElementaryRules (1D) after CA_Introduction and before CA_GameOfLife (2D). But CA_Introduction's anchor artifacts are **2D** (Persian rug, line network), CA_GameOfLife is also 2D, and CA_ElementaryRules is 1D. The intent files for both GameOfLife and ElementaryRules claim different map numbers (GameOfLife says "Second map"; ElementaryRules says "Third map") — and ElementaryRules claims it "drops from 2D to 1D" after CA_GameOfLife. The intent narrative describes order **1 → 3 → 2 → 4…** (substrate → Life → elementary → beyond), which is clearer pedagogically but contradicts the json ordering. This needs a decision.

## 4. Artifact Inventory

Registered in `commons/artifacts/registry/cellular_automata.json` (primary) and `commons_artifacts.json`, `substrate_vectors.json`, `procgen_extra.json`.

| Concept | Artifact | Script path | Status |
|---|---|---|---|
| Substrate / symmetry | persian_rug | algorithms/cellularautomata/persian_rug/persian_rug.gd | Present |
| Substrate / neighbor graph | line_network_ca | algorithms/cellularautomata/ (tscn only, registry ok) | Scene/tscn — verify implementation |
| 1D CA showcase | structure_growth | registry ok, no .gd matching name | Scene-only — verify |
| 1D CA / Rules 30 & 110 | Rule30110 | algorithms/cellularautomata/rule_30_110/Rule30110.gd | Present (referenced by rule_30_110_gravity.tscn) |
| 2D Life — bridge | ca_bridge | algorithms/cellularautomata/ca_bridge/ca_bridge.gd | Present |
| 2D Life — columns | ca_columns | algorithms/cellularautomata/ca_columns/ca_columns.gd | Present |
| 2D Life — mirrored | mirrored_cellular_automata | algorithms/proceduralgeneration/growth_systems/mirroredcellularautomata/mirrored_cellular_automata.gd | Present (cross-sequence location) |
| Hexagonal / VR Life | hexagon_ca_vr | registry ok; tscn exported, no .gd by that name | Scene-only — verify |
| Growth dynamics | ca_growth_network | algorithms/cellularautomata/ca_growth_network/ca_growth_network.gd | Present |
| Petri-dish Life | game_of_life_petri | commons_artifacts registry; scene exported | Scene-only — verify |
| Slime-mold dynamics | mold_network | registry ok; scene exported | Scene-only — verify |
| 3D tree growth | cellular_automata_3d_tree | algorithms/cellularautomata/cellular_automata_3d_tree/CellularAutomata3DTree.gd | Present (CamelCase) |
| Crossway | crossway_ca | algorithms/cellularautomata/crossway_ca/CrosswayCA.gd | Present (CamelCase) |
| Decay | decaying_bridge | algorithms/cellularautomata/living_architecture/decaying_bridge.gd | Present |
| 3D chair test | ca_chair_test | registry ok (in CAchairtests folder) | Verify — folder exists |
| Stochastic Rule 30/110 + gravity | rule_30_110_gravity | algorithms/cellularautomata/rule_30_110/rule_30_110_gravity.tscn | Scene variant on Rule30110 |
| CA on sphere | ca_sphere | algorithms/cellularautomata/CA_sphere/CA_sphere.gd | Present |
| Interactive rule sandbox | ca_rule_explorer | commons_artifacts registry; scene exported | Scene-only — verify |
| 1D stacked into 3D volume | CellularAutomata3DStacked | algorithms/cellularautomata/cellular_automata_3d_stacked/CellularAutomata3DStacked.gd | Present |
| Sierpinski via Rule 90 | sierpinski_pyramid | algorithms/cellularautomata/sierpinski_pyramid/SierpinskiPyramid.gd | Present |
| Classification screen | ca_screen | algorithms/cellularautomata/ca_screen/ca_screen.tscn | Scene-only |
| Self-organization | self_organization_ca | algorithms/cellularautomata/ca_showcase/self_organization_ca.gd | Present |
| Disease spread | disease_spread_ca | algorithms/cellularautomata/ca_showcase/disease_spread_ca.gd | Present |
| Volumetric fog CA | volumetric_fog_ca | algorithms/cellularautomata/volumetric_fog/volumetric_fog_ca.gd | Present |
| Lattice gas (orphan) | — | algorithms/cellularautomata/lattice_gas_automata/ | Folder exists, not placed in any CA map |
| noc_ch07 (orphan) | — | algorithms/cellularautomata/noc_ch07/ | Folder exists, not placed |

## 5. Gap Analysis

### Pedagogical (the intents name these themselves)

- **Single-step rule visualizer** (CA_Introduction gap) — no artifact shows the actual per-cell read-neighbors-apply-rule-write-state mechanic in slow motion. Without this, the whole sequence rests on hand-waving. **Highest priority.**
- **Glider / glider gun** (CA_GameOfLife gap) — the canonical moving structures that make Life's universality legible; absent.
- **256-rule wall** (CA_ElementaryRules gap) — a visual landscape of all elementary rules so Rules 30 and 110 are located within a space, not shown in isolation.
- **Totalistic rule-table visualizer** (CA_BeyondBinary gap) — the compression from general to totalistic is claimed but not shown.
- **Radius slider** (CA_ExpandingSpace gap) — same rule at r=1,2,3,… would make "horizon" tangible.
- **Deterministic-vs-stochastic comparator** (CA_SoftRules gap) — identical initial conditions, side-by-side.
- **Lambda slider** (CA_EdgeOfChaos gap) — sweep Langton's λ through Class I→II→IV→III live.
- **Wireworld circuit library** (CA_AgentsCircuits gap) — working AND/OR/NOT + a clock + an adder to close the "CA compute" argument.

### Ordering / Narrative

- **1D vs 2D ordering conflict** — json order is Intro(2D) → ElementaryRules(1D) → GameOfLife(2D) → BeyondBinary. Intent narratives describe Intro → GameOfLife → ElementaryRules → BeyondBinary. Pedagogically stronger to do Life (the famous example) before the 1D classification, then generalize. See §7.
- **Chamber_CA intent is one paragraph.** It names "rule systems meeting" but doesn't specify which two automata, what the catalyst does, or how the chamber resolves the sequence. Thin compared to the other eight intents.

### Registry / Code Integrity

- **Cross-sequence artifact: mirrored_cellular_automata** lives under `algorithms/proceduralgeneration/`, not `algorithms/cellularautomata/`. Fine if intentional (it is also a procgen artifact), but worth flagging.
- **Scene-only artifacts** (line_network_ca, structure_growth, hexagon_ca_vr, game_of_life_petri, mold_network, ca_chair_test, ca_screen, ca_rule_explorer) — these are registered and scenes exist in `.godot/exported/` but do not have a same-name .gd script in the expected folder. Either they use differently-named scripts (CamelCase, class-name files) or they are tscn-only compositions. Needs a pass to confirm each one actually runs.
- **Orphan code**: `algorithms/cellularautomata/lattice_gas_automata/` and `algorithms/cellularautomata/noc_ch07/` exist but no map places them. Either wire into CA_SoftRules (lattice gas) and CA_EdgeOfChaos (noc_ch07) or archive.

### Missing Transitions

- No bridge from **randomness → CA**: the prerequisite is named in the json but no map/artifact references Rule 30 as a PRNG to make the back-link visible.
- No bridge from **CA → fractals**: Rule 90 generates the Sierpinski triangle; sierpinski_pyramid is here but CA_EdgeOfChaos / CA_AgentsCircuits don't narratively link forward. Fractals sequence should feel like a continuation.
- No bridge from **CA → swarmintelligence / proceduralgeneration** in Chamber_CA.

## 6. Forward Leaks

Concepts this sequence raises but cannot hold:

- **Computation itself** → turingmachines / computation sequence (Rule 110 is universal is stated, not demonstrated as a computation).
- **Self-similarity / Rule 90 → Sierpinski** → fractals sequence.
- **Collective behavior from local rules** → swarmintelligence (the unlock).
- **Growing worlds with local rules** → proceduralgeneration (the unlock).
- **Reaction-diffusion / continuous CA** → proceduralgeneration / waves (Gray-Scott, Turing patterns).
- **Phase transitions / criticality** → statistical mechanics or a dedicated phase-transitions sequence; touched in CA_EdgeOfChaos but not formalized.
- **Neural criticality / brains at the edge of chaos** → neuroscience sequence.
- **Embodied CA / agent-based models** → swarmintelligence, NoC ch06–07; the orphan noc_ch07 folder already gestures this direction.
- **Asynchronous / continuous-time CA** → not addressed; all CA here are synchronous discrete-time.

## 7. Proposed Ordering

The intent-narrative ordering is stronger than the json ordering. Recommend:

```
1. CA_Introduction     — substrate: cells, neighbors, a rule, symmetry preservation
2. CA_GameOfLife       — 2D life-cycle rule, named phenomena, still lifes/oscillators
3. CA_ElementaryRules  — drop to 1D, systematize, Rule 30 / Rule 110 / Wolfram classes
4. CA_BeyondBinary     — totalistic, hexagonal, multi-state (generalize cell/topology)
5. CA_ExpandingSpace   — extended neighborhoods, 3D growth (generalize reach)
6. CA_SoftRules        — stochastic rules and external bias (add noise)
7. CA_EdgeOfChaos      — classify: why Class IV matters, Langton's λ
8. CA_AgentsCircuits   — Wireworld + rule explorer: CA compute, learner authors
9. Chamber_CA          — synthesis, catalyst, handoff to swarm/procgen
```

This reads as **substrate → canonical example → systematize → generalize (two axes) → perturb → theorize → compute → synthesize**. The current json swaps steps 2 and 3, which the intent files themselves don't follow. Either update the json to match the intents, or rewrite the two intents to match the json.

Swap 7 and 8 is also defensible (author first, then classify), but the current intent for CA_AgentsCircuits treats it as the final synthesis before the chamber — so classification before authorship keeps that framing intact.

## Summary

Cellular Automata is a **structurally complete** sequence: 9 maps, all with map_data.json, intent.md, blurb.md, and technical.md (Chamber_CA lacks technical.md and has a minimal intent). Registry coverage is broad. The red thread is articulable and the intents are of high quality — the nine intent.md files genuinely form a curriculum.

Three concrete issues block it from being release-ready:

1. **Json map order contradicts the intent narrative** (1D vs 2D placement). Pick one and reconcile.
2. **Eight specific artifact gaps** named by the intents themselves — single-step visualizer, glider, 256-rule wall, totalistic table, radius slider, stochastic comparator, λ slider, Wireworld library. Build these and the sequence becomes self-teaching.
3. **Chamber_CA is thin.** The last map needs a real evolution — specify the two CA that meet, what the catalyst does, how swarm/procgen get seeded.

The sequence is in strong mid-shape: red thread clear, artifacts mostly present, classification map (CA_EdgeOfChaos) does serious conceptual work. Compared to primitives, this sequence has more artifacts per map but fewer evolutions written — no map-level evolution docs yet (primitives has three).
