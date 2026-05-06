# Swarm Intelligence — Curriculum Audit

**Sequence ID:** `swarmintelligence`
**Spine name:** Swarm Intelligence: No Leader, Yet Coordinated
**Maps:** 8 (7 content + 1 chamber)
**Evolutions written:** 0
**QFEP term:** λ — edge-of-chaos modulation between order and entropy
**Formula:** `Agent_i = Σ local_rules(neighbors_i)`

## 1. Core Concept

Swarm intelligence is the discovery that coordination does not require a coordinator. Many agents running the same simple local rules, reading each other or reading the environment, produce global behavior that looks intelligent without anyone intending it. The sequence argues — through boids, ants, slime molds, and particle swarms — that intelligence is a property of *media and relations*, not of individuals. The politically loaded claim sitting underneath is queer: non-hierarchical, decentralized, robust to the loss of any single agent. The ontological move is to stop looking for the leader.

## 2. The Red Thread

1. **Single Agent Following a Field** (FlowFields)
   - An agent that just reads an external vector and obeys
   - Captures: steering as lookup, purpose outside the agent, topology-drives-behavior
   - Leaks: who wrote the field? who benefits? where does shared structure come from if not imposed?

2. **Stigmergy / Environmental Memory** (stigmergy_grid, as atom)
   - Agents modifying a substrate that other agents read
   - Captures: indirect communication, medium-as-message, no direct signaling
   - Leaks: what happens when the substrate has politics of its own (later: networks, infrastructure)

3. **Social Rules on Neighbors** (Boids)
   - Three local vector rules — separation, alignment, cohesion — over a perception radius
   - Captures: flocking, lane formation, split/rejoin, emergent geometry
   - Leaks: rule weights are chosen; what is "alignment" when agents differ in kind?

4. **Agent-Based Modeling** (ABM)
   - Generalized framework: N agents + rules + environment = society-in-a-box
   - Captures: the methodology itself — emergence as experimental medium
   - Leaks: ABMs can simulate injustice as easily as equilibrium — the model hides its assumptions

5. **Stigmergic Optimization** (Ant Colony)
   - Pheromone trails + evaporation + positive feedback → shortest-path discovery
   - Captures: collective memory as decaying chemical field; τ_ij reinforcement
   - Leaks: the shortest path is amplified, not chosen; what gets forgotten as evaporation prunes?

6. **Collective-Memory Optimization** (Particle Swarm)
   - Each particle tracks personal best + global best; velocity is nostalgia + social pressure
   - Captures: explore/exploit tradeoff, hyperparameter meaning, hill-climbing without gradient
   - Leaks: "fitness landscape" is always authored — fitness_landscape_politics makes this explicit

7. **Brainless Network Computation** (Physarum)
   - No agents-as-individuals: one substrate growing toward attractors, pruning weak paths
   - Captures: Steiner trees, load-balanced vasculature, network formation without a designer
   - Leaks: if this is intelligence, what isn't? where is the boundary of cognition?

8. **Ecosystem Synthesis** (Ecosystem Simulation)
   - Predator-prey + genetic memory + selection pressure as unifying frame
   - Captures: multi-species swarms, evolution without goals, ecology as the parent of all swarms
   - Leaks: evolution previews machinelearning; ecology previews criticalalgorithms (who survives?)

9. **Chamber** (Chamber_Swarm)
   - Your eight catalyst-boids meet a native flock; becoming_catalyst in swarm mode
   - Captures: the player-as-agent becomes an agent-among-agents
   - Leaks: forward to machinelearning (neural swarms) and recursiveemergence (emergence of emergence)

## 3. Map-to-Concept Mapping

| Order | Map | Concept | Anchor Artifact | Status |
|-------|-----|---------|-----------------|--------|
| 1 | SwarmIntelligence_PhysarumColony | Brainless network | PhysarumColony | Needs evolution |
| 2 | SwarmIntelligence_FlowFields | Field-follower | FlowFieldMain | Needs evolution |
| 3 | SwarmIntelligence_Boids_Algorithm | Social rules | boid_manager + 3 variants | Needs evolution |
| 4 | SwarmIntelligence_Agent_Based_Modeling_ABM | ABM framework | ant_colony_optimization (compact) | Weak — stigmergy_grid missing from map |
| 5 | SwarmIntelligence_Ant_Colony_Optimization | Stigmergic optimization | AntColonyV2 | Needs evolution |
| 6 | SwarmIntelligence_Particle_Swarm_Optimization | Collective memory | fitness_landscape_politics + self_organizing_patterns (missing) | self_organizing_patterns has no scene |
| 7 | SwarmIntelligence_Swarm_Intelligence_Algorithms | Synthesis / ecosystem | ecosystem_simulation | Needs evolution |
| 8 | Chamber_Swarm | Catalyst chamber | becoming_catalyst (swarm mode) | Needs evolution |

**Ordering issue:** Physarum is first in the spine but conceptually it is the most radical claim (cognition-without-agents). Putting it first is a rhetorical opening — but the learner has no vocabulary yet to register what is strange about it. It likely belongs near the end as a boundary case.

## 4. Artifact Inventory

| Concept | Artifact | File | Status |
|---------|----------|------|--------|
| Field-follower | FlowFieldMain | algorithms/pathfinding/flow_field/FlowFieldMain.gd | ✓ works; needs VR target/wall placement |
| Stigmergy (atom) | stigmergy_grid | commons/artifacts/stigmergy_grid/stigmergy_grid.gd | ✓ works; sliders not wired |
| Boids (world-scale) | boid_manager | algorithms/emergentsystems/boidflocking/boid_manager.gd | ✓ works; attract/repel via trigger |
| Boids (with docs) | boid_flocking | same dir, scene file | ✓ |
| Boids (2D in 3D) | boids_2d_in_3d | same dir, scene file | ✓ |
| Boids (compact) | boids_aquarium | commons/artifacts/boids_aquarium/ | ✓ VR sliders present |
| Boids (UI) | boids_documentation_ui | same dir | ✓ but 2D canvas, not VR |
| ACO (heatmap) | ant_colony_optimization | algorithms/swarmintelligence/ant_colony_optimization/ | ✓ has evap + ant_count slider + mode cycle |
| ACO (world) | AntColonyV2 | algorithms/swarmintelligence/ants_v2/ | ✓ but no VR controls |
| PSO (core) | particle_swarm_optimization | algorithms/swarmintelligence/particle_swarm_optimization/ | ✓ but no sliders wired |
| PSO (politics) | fitness_landscape_politics | commons/artifacts/fitness_landscape_politics/ | ✓ 3 landscape modes + inertia slider |
| PSO (patterns) | self_organizing_patterns | — | **MISSING scene** — only a plan .md in doc/plans |
| Physarum | PhysarumColony | algorithms/swarmintelligence/physarum/ | ✓ but no VR controls |
| Ecosystem | ecosystem_simulation | algorithms/emergentsystems/ecosystemsimulation/ecosystem.gd | ✓ but no VR controls; hardcoded init |
| Chamber catalyst | becoming_catalyst (swarm mode) | commons/hazards/becoming_catalyst/ | ✓ wired into map |

## 5. Gap Analysis

### Missing Artifacts (High Priority)
- **self_organizing_patterns** — referenced in SwarmIntelligence_Particle_Swarm_Optimization but only exists as a plan document. Scene + script missing. Either build it or drop the reference.
- **stigmergy_grid placement** — the stigmergy atom *artifact* exists, but it is not placed in any swarm map. The ABM map currently uses ant_colony_optimization as its only artifact, which duplicates the ACO map. ABM should host stigmergy_grid (the substrate atom) before ACO demonstrates stigmergic optimization.

### VR Interaction Gaps (Medium Priority)
Every core swarm artifact ships without VR sliders except boids_aquarium, ant_colony_optimization, and fitness_landscape_politics. @identity blocks flag this consistently:
- PhysarumColony: no sliders, no grabbable attractors
- FlowFieldMain: desktop-only mouse/right-click, no VR raycast
- boid_manager: attract/repel yes, but no weight sliders
- AntColonyV2: no controls at all
- particle_swarm_optimization: inertia display only, not interactive
- ecosystem_simulation: hardcoded init, no mutation_rate slider

The learner mostly *observes* swarms. For the sequence's claim — "you are an agent among agents" — to land, they need to *poke* them.

### Ordering Issues
- Physarum first is narratively striking but pedagogically backwards. Suggested: FlowFields → Boids → ABM(stigmergy_grid) → ACO → PSO → Physarum → Ecosystem → Chamber.
- ABM currently hosts ACO's core artifact, making ABM feel like a duplicate of the ACO map. ABM needs a distinct anchor: stigmergy_grid plus perhaps a Schelling segregation or flocking-variant demo to make "ABM as methodology" legible.

### Missing Transitions
- Boids → ABM: no explicit "boids was also an ABM" bridge. The ABM map should narratively recognize that the learner has already done ABM, and now meets the formal frame.
- PSO → Physarum: no bridge. One is discrete agents with memory; the other is a substrate with no agents. That ontological jump needs a beat.
- Ecosystem → Chamber: needs the "all-swarms-are-ecosystems" synthesis line before the catalyst chamber.

### Redundancies
- Four boid variants in one map is rich but risks cognitive overload. Consider: boid_manager (world) + boids_aquarium (compact) only; move 2d_in_3d and documentation_ui into a separate side map or as optional observables.
- ant_colony_optimization and AntColonyV2 both exist; the @identity notes explain the split (compact heatmap vs. world-scale terrain). Keep both, but make the division legible: place ACOv1 in ABM (as compact stigmergy demo) and AntColonyV2 in the ACO map (as the full experience).

## 6. Forward Leaks

Concepts this sequence raises but cannot resolve:
- **Learning weights, not designing them** → `machinelearning` (backprop, evolutionary algorithms)
- **Neural swarms / distributed representation** → `machinelearning` + `recursiveemergence`
- **Who wrote the fitness function?** → `criticalalgorithms` (fitness_landscape_politics is the leak-probe)
- **Stigmergy at infrastructure scale** → `networks`, `cyberphysical` (cities as stigmergic media)
- **Agent-based modeling of human systems** → `criticalalgorithms` (Schelling, bias simulations)
- **Emergence of emergence** → `recursiveemergence`
- **When is the swarm a subject?** → `consciousness`, QFEP chamber (λ at the edge)
- **Ecology, kinship across species** → `nature_system` sequences
- **Evolution as optimization without a designer** → `machinelearning`, `recursiveemergence`

## 7. Proposed Ordering

Current spine order:
```
1. PhysarumColony → 2. FlowFields → 3. Boids → 4. ABM
5. AntColony → 6. PSO → 7. SwarmAlgorithms → 8. Chamber
```

Proposed order (concept flow, simple → radical):
```
1. FlowFields         — single agent, external field (purpose outside)
2. Boids              — social rules, neighbor-reading (purpose from kin)
3. ABM                — methodology made explicit; anchor = stigmergy_grid
4. AntColony          — stigmergy becomes optimization
5. PSO                — memory becomes optimization; fitness_politics exposes authoring
6. Physarum           — the radical case: intelligence without agents
7. SwarmAlgorithms    — ecosystem synthesis across all species
8. Chamber_Swarm      — catalyst integration; learner as agent-among-agents
```

Rationale: The current ordering opens with the most philosophically advanced claim (Physarum: cognition-as-medium) before the learner has the swarm vocabulary to register its strangeness. Moving Physarum to position 6 lets the learner meet field-follower → social-rules → stigmergy → optimization first, then hit Physarum as the boundary case that refuses to separate agent from environment. Ecosystem then synthesizes. Chamber closes.

## Summary

Swarm Intelligence is one of the stronger sequences conceptually — the red thread from local rules to collective intelligence is clean, and the @identity blocks across its artifacts are unusually coherent (each one names its critical parameter, relationships, and missing VR affordances). Three concrete blockers: (1) `self_organizing_patterns` is referenced in a map but not built; (2) the ABM map duplicates ACO's anchor and should host `stigmergy_grid` instead; (3) most artifacts lack VR sliders, so the sequence reads as a nature documentary more than a lab. The proposed reordering (open with FlowFields, save Physarum for late) would match concept flow more than current spine order. All 8 maps still need evolutions written.
