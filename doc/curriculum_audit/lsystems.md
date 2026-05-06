# L-Systems — Curriculum Audit

**Sequence ID:** `lsystems`
**Spine order:** between fractals/randomness → proceduralgeneration
**Maps:** 7 active (+ 11 deferred)
**Evolutions written:** 0 (0/7)
**QFEP term:** Lambda_Edge — the iteration parameter that pushes rules toward emergent complexity

## 1. Core Concept

**Grammar is generative. A sentence can become a forest.** L-systems teach a single radical idea: a finite set of string-rewriting rules applied to an axiom, then interpreted as turtle-graphics movements, produces unbounded structural complexity. The sequence walks the pipeline axiom → production rules → iterated string → turtle interpretation, then widens the claim in three directions: the same engine builds plants, buildings, and space-filling paths; the same engine, run by multiple agents, produces ecology; the same engine, made continuous and evolvable, produces life. By the last map, the rules that drew a tree are drawing the world itself. The sequence sits at Lambda_Edge — deterministic F-descriptions generate exponential E(S) unfolding, and each iteration (λ) pushes further toward emergence.

## 2. The Red Thread

1. **Axiom & Rewriting** (LSystems_Grammar_Lab — `fractal_lsystem_string`)
   - The string before the geometry. F → F[+F]F[-F]F exploded letter by letter, generation by generation
   - Captures: exponential expansion, F as minimal description, one-rule → many-symbols
   - Leaks: the string is invisible until interpreted — where does meaning come from?

2. **Turtle Interpretation** (LSystems_Grammar_Lab — `lsystem_editor`, `lsystem_tree`)
   - `+ - [ ]` as turtle commands turn symbols into lines. The editor shows 7 presets (Koch, Sierpinski, Dragon, Plant, Bush, Fern, Binary Tree)
   - Captures: geometry as a reading of grammar, interpretation as design choice
   - Leaks: turtle is one interpretation — why should +/- mean rotation at all?

3. **Generation & Animation** (LSystems_Growth — `AnimatedTree`)
   - Growth made temporal. Each generation visible, wind sways the result
   - Captures: time-as-iteration, growth animation, recursion depth as biological age
   - Leaks: real growth responds to conditions; a deterministic sequence doesn't

4. **Context Sensitivity** (LSystems_Growth — `ContextSensitiveTree`)
   - if ray_cast(tip, obstacle) → prune else grow. Rules consult the environment
   - Captures: responsive morphology, environment-encoded shape
   - Leaks: still local rules; global selection (fitness) unaddressed here

5. **Parametric Continuity** (LSystems_Growth — `parametric_lsystem`)
   - angle(depth) = base_angle · 0.95^depth + random(±var). Continuous angle/length decay
   - Captures: organic softness, parameters as gradient
   - Leaks: stochasticity not formalized yet; where does noise enter grammar?

6. **Formal Grammars** (LSystems_Grammars_And_Curves — implicit)
   - Production rules as CFG-like objects, derivations as computation
   - Captures: grammar-as-language, computational semantics
   - Leaks: **no dedicated CFG artifact in this sequence** — `ContextFreeGrammars.gd` exists in `algorithms/lsystems/context_free_grammars/` but isn't surfaced. Gap.

7. **Space-Filling** (LSystems_Grammars_And_Curves — `Hilbert3D`, `space_filling_curve_gallery`)
   - A → -BF+AFA+FB- produces a 1D path that visits every point in 2D/3D space
   - Captures: dimension transcendence, locality preservation, F-compression of total coverage
   - Leaks: space-filling curves are fractals — this leaks into the `fractals` sequence

8. **Reinterpretation / Architecture** (LSystems_Architecture — `CityGenerator`, `lsystem_dungeon`)
   - Same string, turtle re-bound to 90° orthogonal moves. Branch → corridor, leaf → room
   - Captures: interpretation as design choice, grammar is medium-agnostic
   - Leaks: dungeons want constraints (connectivity, keys) L-systems alone can't supply — forward leak to procedural generation / graph grammars

9. **Competition & Ecology** (LSystems_Competition — `ForestCompetition`, `branching_coral`)
   - Multiple grammars, shared soil. Nutrients diffuse, crown overlap degrades health
   - Captures: multi-agent emergence, niches from spatial constraints, terrestrial vs marine (same engine, different kingdom)
   - Leaks: competition introduces selection — the door to genetics/evolution opens but isn't walked through until next map

10. **Evolution / Life** (LSystems_Living — `genetic_tree_sculptor`)
    - 8 DNA sliders → CritterDNA → tree morphology. Grammar parameters become a genome; Plant arms the catalyst
    - Captures: grammar + selection = evolution, player-as-breeder, bridge into ecology subsystem
    - Leaks: full evolution/genetics lives in `biological_growth` / `morphogenesis` / Pokemon Studio

11. **Chamber / Synthesis** (Chamber_LSystems)
    - Branching catalyst active; miura creature approaches. Two grammars coexisting
    - Captures: narrative closure, catalyst bracelet mode unlocked
    - Leaks: transitions to proceduralgeneration — grammars beyond plants

## 3. Map-to-Concept Mapping

| Order | Map | Concept | Anchor Artifact | Status |
|-------|-----|---------|-----------------|--------|
| 1 | LSystems_Grammar_Lab | Axiom → Rule → String → Turtle (the whole pipeline) | lsystem_editor + fractal_lsystem_string | Needs evolution |
| 2 | LSystems_Growth | Generation, context-sensitivity, parametric decay | AnimatedTree + ContextSensitiveTree + parametric_lsystem | Needs evolution |
| 3 | LSystems_Grammars_And_Curves | Formal grammar, space-filling | Hilbert3D + space_filling_curve_gallery | Needs evolution |
| 4 | LSystems_Architecture | Reinterpretation beyond biology | CityGenerator + lsystem_dungeon | Needs evolution |
| 5 | LSystems_Competition | Multi-agent ecology, catalyst intro | ForestCompetition + branching_coral | Needs evolution |
| 6 | LSystems_Living | Grammar as world, DNA sculpting | genetic_tree_sculptor + lsystem_tree | Needs evolution |
| 7 | Chamber_LSystems | Synthesis, catalyst, miura | (branching catalyst tool) | Needs evolution |

Flow is coherent: the pipeline unpacks in map 1, deepens (time, context, continuity) in map 2, formalizes in map 3, widens in map 4, socializes in map 5, biologizes in map 6, resolves in 7. Each map earns its place.

## 4. Artifact Inventory

| Concept | Artifact | File | Status |
|---------|----------|------|--------|
| Axiom pipeline | lsystem_editor | commons/artifacts/lsystem_editor/lsystem_editor.gd | ✓ @identity written, 7 presets |
| String expansion | fractal_lsystem_string | commons/artifacts/fractal_lsystem_string/fractal_lsystem_string.gd | ✓ @identity |
| Canonical tree | lsystem_tree | commons/artifacts/lsystem_tree/lsystem_tree.gd | ✓ @identity (F→F[+F]F[-F]F at 25.7°) |
| Animated growth | AnimatedTree | algorithms/lsystems/Growth/AnimatedTree.gd | ✓ @identity, wind sway |
| Context sensitivity | ContextSensitiveTree | algorithms/lsystems/ContextSensitive/ContextSensitiveTree.gd | ✓ @identity, ray-cast pruning |
| Parametric decay | parametric_lsystem | commons/artifacts/parametric_lsystem/parametric_lsystem.gd | ✓ @identity |
| Space-filling 3D | Hilbert3D | algorithms/lsystems/Hilbert3D.gd | ✓ @identity |
| Space-filling gallery | space_filling_curve_gallery | commons/artifacts/space_filling_curve_gallery/space_filling_curve_gallery.gd | ✓ @identity (Hilbert/Peano/Moore) |
| Architectural reinterp | CityGenerator | algorithms/lsystems/Architecture/CityGenerator.gd | ✓ @identity, orthogonal rules |
| Dungeon reinterp | lsystem_dungeon | commons/artifacts/lsystem_dungeon/lsystem_dungeon.gd | ✓ @identity (also in fractals seq) |
| Ecology | ForestCompetition | algorithms/lsystems/Ecosystem/ForestCompetition.gd | ✓ @identity, seasons+nutrients |
| Marine branching | branching_coral | commons/artifacts/branching_coral/branching_coral.gd | ✓ @identity |
| DNA sculptor | genetic_tree_sculptor | commons/artifacts/genetic_tree_sculptor/genetic_tree_sculptor.gd | ✓ @identity |
| Cultural grammars | grammar_provenance | commons/artifacts/grammar_provenance/grammar_provenance.gd | ✓ @identity — **not placed on any active map** |
| Formal CFG demo | ContextFreeGrammars | algorithms/lsystems/context_free_grammars/ContextFreeGrammars.gd | ✓ exists, **no registry entry, not on any map** |
| Tree generation UI | TreeGeneration + TreeUI | algorithms/lsystems/tree_generation/ | ✓ exists, **unused by sequence** |

**Coverage score:** 13 placed + 2 orphaned = 15 L-system artifacts. Every concept in the red thread has at least one anchor. No concept is naked.

## 5. Gap Analysis

### Orphaned Artifacts (Content Without Placement)
- **`grammar_provenance`** is authored (@identity + registry + QFEP connection) and explicitly critical-theory-coded, but isn't placed on any of the 7 active maps. Its home is almost certainly **LSystems_Grammar_Lab** (alongside `lsystem_editor`) where "whose grammar?" would frame the whole sequence, or **LSystems_Architecture** where Lindenmayer-vs-Islamic-vs-Kinship would hit hardest. Right now it's a strong artifact with no audience.
- **`ContextFreeGrammars.gd`** exists in `algorithms/lsystems/context_free_grammars/` with a UI script, but has no entry in `commons/artifacts/registry/lsystems.json` and no map placement. This is the missing **formal grammar** artifact — the one that would make concept-atom #6 (Formal Grammars) legible. LSystems_Grammars_And_Curves is the right host.
- **`TreeGeneration`** also lives unused in `algorithms/lsystems/tree_generation/`. Possibly redundant with `lsystem_tree` — candidate for retirement or consolidation.

### Deferred Maps (Not In Active Flow)
The sequence file lists 11 deferred maps — all have `map_data.json` files but aren't in `maps: []`:
`LSystems_Tree_L_Systems`, `LSystems_AnimatedTree`, `LSystems_ContextSensitiveTree`, `LSystems_ForestCompetition`, `LSystems_Context_Free_Grammars_CFG`, `LSystems_CityGenerator`, `LSystems_Hilbert3D`, `LSystems_Different_Grammar_Types`, `LSystems_Shape_Grammars`, `LSystems_Stochastic_L_Systems`, `LSystems_Backus_Naur_Form_BNF`.
Most are single-artifact spotlight maps (AnimatedTree, Hilbert3D, etc.) that have been **correctly absorbed** into the 6-map flow — keep deferred.
**Exceptions worth reconsidering:**
- `LSystems_Stochastic_L_Systems` — stochastic rewriting is a distinct concept not taught elsewhere. Currently the sequence has context-sensitive and parametric but no explicitly probabilistic grammars. Consider folding a stochastic artifact into LSystems_Growth.
- `LSystems_Shape_Grammars` — shape grammars (Stiny/Gips 1972) generalize L-systems to 2D/3D shapes, not strings. Could be the natural bridge into LSystems_Architecture.
- `LSystems_Backus_Naur_Form_BNF` — formal grammar notation. Would anchor concept-atom #6 cleanly, but `ContextFreeGrammars` probably suffices.

### Missing Transitions
- **Between map 3 (Curves) and map 4 (Architecture):** the leap from "formal grammar fills space" to "grammar builds dungeons" is fast. A single sentence on the floor — "replace the meaning of F" — would suffice; doesn't need a new map.
- **Between map 5 (Competition) and map 6 (Living):** the catalyst bracelet is introduced in map 5 but only armed in map 6. Make sure Chamber_LSystems explicitly resolves this arc.

### Redundancies
- `lsystem_tree` appears in Grammar_Lab, Competition (as reference), and Living — consistent with its canonical-example status. Not a redundancy, a motif.
- `dark_sphere` appears on 4 of 7 maps as anchor. Consistent use.
- `branching_coral` in both Competition and Living works (integration → synthesis callback).

### Documentation Gaps
- **0 evolutions written.** Primitives has 3/13; lsystems has 0/7. This is the main content debt.
- Maps have strong `documentation` blocks in `map_data.json` (summary/objective/key_elements) but no `blurb.md`/`intent.md` pairs confirmed. Need to verify with Pipeline Scorer.

## 6. Forward Leaks

What lsystems raises but cannot hold:

- **Stochastic grammars / noise** → `randomness` (already a prerequisite — but probabilistic rewriting specifically is under-served both here and there)
- **Self-similarity as pure geometric recursion** → `fractals` (Koch curve is an L-system; sequence treats it as a preset but fractals sequence owns the dimension/self-similarity framing)
- **Graph grammars, shape grammars, wave function collapse, constraint-based generation** → `proceduralgeneration` (lsystems is the *first* member of the procgen family; procgen picks up what L-systems can't express: global constraints, solver-driven generation)
- **Full genetics, mutation, fitness landscapes, speciation** → `biological_growth` / `morphogenesis` / `pokemonstudio` (genetic_tree_sculptor is a bridge, not a destination)
- **Ecology depth — trophic levels, symbiosis, decomposition** → `flowers` / `pokemonstudio` ecology rules
- **Formal language theory — Chomsky hierarchy, parsing, computability** → `grammar_systems` sequence (sibling), `foundationscrisis` (halting/undecidability)
- **Architectural programs — Koolhaas-style diagrams, topology-driven plans** → `facades`, `bricolage`, city-specific work
- **Why this grammar and not another** → partially addressed by `grammar_provenance` but only if placed. Deep form is a critical-theory question that leaks back into `criticalalgorithms`.

## 7. Proposed Ordering

The current order is **correct**. Keep as-is:

```
1. LSystems_Grammar_Lab           — pipeline revealed (string + editor + tree)
2. LSystems_Growth                — time, context, continuity
3. LSystems_Grammars_And_Curves   — formal grammar, space-filling
4. LSystems_Architecture          — reinterpretation beyond biology
5. LSystems_Competition           — multi-agent ecology + catalyst intro
6. LSystems_Living                — DNA + world-as-grammar
7. Chamber_LSystems               — catalyst, miura, synthesis
```

### Recommended Actions (in priority order)

1. **Place `grammar_provenance`** on LSystems_Grammar_Lab or LSystems_Architecture. The artifact is built and waiting. A single cell-position change in map_data.json surfaces a critical-theory layer the sequence is currently missing.
2. **Surface `ContextFreeGrammars`**: add a registry entry in `lsystems.json`, verify scene, place on LSystems_Grammars_And_Curves. This closes the "Formal Grammars" concept-atom which is currently implicit.
3. **Write evolutions** (blurb + intent + technical) for at least the first 3 maps. Template available from primitives.
4. **Audit for stochasticity**: either add a stochastic rule toggle to `lsystem_editor` (cheap) or surface a dedicated stochastic artifact on LSystems_Growth.
5. **Verify Chamber_LSystems catalyst wiring**: the branching stone mode must be armed here. Check against `commons/hazards/becoming_catalyst/`.

## Summary

L-systems is a **mid-strength sequence**: the artifact layer is rich (13 placed, all with @identity), the red thread is coherent, the map-to-concept mapping is clean, and the forward leaks are well-targeted at procgen, fractals, and morphogenesis. The gaps are in three places:
1. **Two authored-but-unplaced artifacts** (`grammar_provenance`, `ContextFreeGrammars`) — cheap wins, high payoff
2. **Zero written evolutions** — the 7 maps lack blurb/intent documentation at the level primitives has
3. **One conceptual thinness**: stochastic grammars are under-represented relative to context-sensitive and parametric variants

The sequence successfully earns its QFEP positioning at Lambda_Edge. Each iteration genuinely pushes toward emergence — by map 6 the player is literally sculpting a tree's DNA and unlocking world-growth flags. The architecture-as-grammar pivot in map 4 and the ecology pivot in map 5 are the strongest structural beats. With grammar_provenance placed, the sequence would also earn critical-theory weight that currently only lives in @identity comments.
