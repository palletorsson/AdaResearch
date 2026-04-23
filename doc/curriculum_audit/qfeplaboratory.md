# QFEP Laboratory — Curriculum Audit

**Sequence ID:** `qfeplaboratory`
**Spine order:** integration layer (penultimate, before `postfoundationscrisis`)
**Maps:** 9 (Introduction, F_Term, E_Term, Lambda_Spectrum, Phi_Term, Edge_Of_Chaos, Sandbox, Synthesis, Chamber_QFEP)
**Truth:** `QFE = F − λE(S) + φΔE(S,t)`. Life exists at λ ≈ 0.3–0.5.
**Prerequisites:** primitives, randomness, wavefunctions, foundationscrisis
**Unlocks:** recursiveemergence, speculativecomputation
**Evolutions written:** 0 (8 intent.md files present, each with critical/technical angles — audit-ready)

## 1. Core Concept

The theoretical core of Ada Research made tangible. Every prior sequence was secretly teaching one term of a single formula. Primitives and transformation were building **F** (structure, order-seeking, prediction error). Randomness and noise were building **E(S)** (the entropy term, possibility space). Wavefunctions and forces were building **ΔE(S,t)** (the temporal derivative). The `qfeplaboratory` sequence is where those capacities are retrospectively unified: the learner recognizes the formula rather than learning it. The pedagogical move is to dismantle the formula into isolable terms, give each its own room, then reassemble it under full parametric control. The final twist is political: **φ > 0** (embrace becoming) is named as the queer signature, making QFEP not a physics formula but an ethics.

## 2. The Red Thread

1. **Recognition** (QFEP_Introduction)
   - The whole formula presented as 3D object with four grabbable term-spheres
   - Captures: retrospective coherence ("oh, that's what all of it was about")
   - Leaks: terms are opaque until decomposed — needs isolation

2. **F (Free Energy / Order)** (QFEP_F_Term)
   - Prediction error minimization, pattern-finding, crystallization
   - Captures: drive to compress world into model; surprise reduction
   - Leaks: the dark room problem — pure F-minimization = death; needs entropy

3. **E(S) (Entropy / Possibility)** (QFEP_E_Term)
   - Log-microstates, unconstrained configurations, pure chaos
   - Captures: freedom, openness, the -λE(S) drive opposing F
   - Leaks: pure E dissolves structure; freedom without constraint is noise

4. **λ (Coupling / Balance)** (QFEP_Lambda_Spectrum)
   - Continuous dial from 0 (crystal) through 0.4 (edge) to 1 (dissolution)
   - Captures: body-as-probe; position maps to λ; spectrum is walkable
   - Leaks: static snapshot of spectrum — says nothing about rate of change

5. **φ (Rate Sensitivity)** (QFEP_Phi_Term)
   - Temporal derivative term; resist (φ<0) vs embrace (φ>0) change
   - Captures: the political dimension — conservative vs queer disposition toward becoming
   - Leaks: φ in isolation still doesn't show where productive complexity lives

6. **Edge of Chaos** (QFEP_Edge_Of_Chaos)
   - Langton's λ ≈ 0.3–0.5, Turing morphogenesis, criticality
   - Captures: where computation/life/adaptation happen; connects back to CA and reaction-diffusion
   - Leaks: guided — learner hasn't proven mastery

7. **Full Control** (QFEP_Sandbox)
   - Both sliders unlocked, reactor and reactive_particles respond live
   - Captures: operational understanding — tuning, prediction, capacity
   - Leaks: no narrative closure; pure play

8. **Synthesis** (QFEP_Synthesis)
   - Four term-spheres return alongside queer_morphology_specimen
   - Captures: the thesis embodied — biological form at the edge, φ>0 made flesh
   - Leaks: the question of what to *build* with this lens → postfoundationscrisis

9. **Chamber** (Chamber_QFEP)
   - Catalyst chamber, creature (`qfep_calibrator`), Science Screen, return to Lab
   - Captures: mathematics becomes relationship; player-creature boundary transforms
   - Leaks: the chamber's creature is listed but not documented deeply in intent.md — thin

## 3. Map-to-Concept Mapping

| Order | Map | Concept | Anchor Artifact | Status |
|-------|-----|---------|-----------------|--------|
| 1 | QFEP_Introduction | Recognition (whole formula) | qfep_formula_3d + 3 grab_spheres | Intent ✓ |
| 2 | QFEP_F_Term | Free energy / order-seeking | crystal_cluster + snap puzzles | Intent ✓ |
| 3 | QFEP_E_Term | Entropy / possibility space | particle_chaos + random_cubes | Intent ✓ |
| 4 | QFEP_Lambda_Spectrum | Coupling (walkable spectrum) | bifurcation_walkway + 3 gradient artifacts | Intent ✓ |
| 5 | QFEP_Phi_Term | Rate sensitivity (queer term) | phi_slider + rigid/fluid/preserved/transforming | Intent ✓ |
| 6 | QFEP_Edge_Of_Chaos | Criticality (λ ≈ 0.4) | edge_core + turing_pattern + emergence_zone | Intent ✓ |
| 7 | QFEP_Sandbox | Full parameter control | qfep_reactor + reactive_particles | Intent ✓ |
| 8 | QFEP_Synthesis | Mastery + queer embodiment | queer_morphology_specimen + 4 grab_spheres | Intent ✓ |
| 9 | Chamber_QFEP | Catalyst ritual closure | becoming_catalyst + qfep_calibrator creature | Intent thin |

The flow is unusually clean. Each map isolates one slot of the formula and then recombines. This is the "completed" shape the other sequences aspire to.

## 4. Artifact Inventory

### Core QFEP controllers and displays (`commons/interfaces/qfep/`)
| Concept | Artifact | File | @identity | Status |
|---------|----------|------|-----------|--------|
| Whole formula | qfep_formula_3d | formula_display/qfep_formula_3d.gd | ✓ | ✓ central anchor |
| λ control | lambda_slider | lambda_slider.gd | ✓ | ✓ broadcasts globally |
| φ control | phi_slider | phi_slider.gd | ✓ | ✓ |
| Sandbox console | qfep_sandbox_console | qfep_sandbox_console.gd | partial | planned (registry flag `status: planned`, `include_in_map_data: false`) |
| Live reactor | qfep_reactor | qfep_reactor.gd | ✓ | ✓ |
| Edge core | edge_core | edge_core.gd | ✓ | ✓ |
| Reactive particles | reactive_particles / reactive_particle_field | reactive_particle_field.gd | — | ✓ present |
| Entropy meter | entropy_meter | entropy_meter.gd | — | ✓ present |
| Phase space | phase_cube | phase_cube.gd | — | ✓ present |
| Oscilloscope | qfep_oscilloscope | qfep_oscilloscope.gd | — | ✓ present |
| Edge detector | edge_detector | edge_detector.gd | — | ✓ present |

### Term-sphere grabbables (registered in qfep.json)
| Term | Artifact | Status |
|------|----------|--------|
| F | grab_sphere_F | ✓ registered |
| E | grab_sphere_E | ✓ registered |
| λ | grab_sphere_lambda | ✓ registered |
| φ | grab_sphere_phi | ✓ registered |

### F-side (order) artifacts
| Concept | Artifact | @identity | Status |
|---------|----------|-----------|--------|
| Pure order crystal | crystal_cluster | — | ✓ registered |
| Breathing grid | ordered_grid | ✓ | ✓ |
| Rigid form | rigid_sculpture | ✓ | ✓ |
| Preserved pattern (φ<0) | preserved_pattern | ✓ | ✓ |
| Snap assembly | snap_cube_puzzle, snap_tetra_puzzle | — | ✓ registered |

### E-side (entropy) artifacts
| Concept | Artifact | @identity | Status |
|---------|----------|-----------|--------|
| Drifting cubes | random_cubes | ✓ | ✓ |
| Particle chaos | particle_chaos | ✓ | ✓ |
| Chaos particles (high λ) | chaos_particles | ✓ | ✓ |
| Dissolving form | dissolving_form | ✓ | ✓ |

### Edge / transformation artifacts
| Concept | Artifact | @identity | Status |
|---------|----------|-----------|--------|
| Complexity (Conway GoL) | complexity_pattern | ✓ | ✓ |
| Crystal → edge → chaos gradient | crystal_formation, edge_particles, chaos_particles | partial | ✓ registered |
| Bifurcation diagram walk | bifurcation_walkway | ✓ (logistic map x_{n+1}=rx(1-x)) | ✓ |
| Turing / reaction-diffusion | turing_pattern (in qfep/), turing_pattern_generator (artifacts/) | ✓ on generator | ✓ |
| Edge of chaos unlocked | edge_of_chaos_orb, edge_of_chaos_unlocked | — | ✓ registered |
| Emergence zone | emergence_zone | — | ✓ registered |

### φ-side (becoming) artifacts
| Concept | Artifact | @identity | Status |
|---------|----------|-----------|--------|
| Becoming fluid (φ>0) | fluid_form | ✓ | ✓ |
| Wave-driven grid (φ>0) | transforming_pattern | ✓ | ✓ |
| Living specimen | queer_morphology_specimen | ✓ (soft_body stiffness(λ), damping(φ)) | ✓ the culmination |

### Supporting / ambient
| Artifact | Purpose | Status |
|----------|---------|--------|
| dark_sphere | F_Term ambient constant | ✓ |
| fuzzy_cloud | ambient | ✓ |
| AnickaYiLab, PipilottiRistWorld, earths_delight | art-world references | ✓ |
| science_desk, science_glasses | chamber instruments | ✓ |

This is by far the densest and most coherent artifact inventory of any sequence. Almost every term of the formula has at least two artifact expressions (one affirmative, one negative), and nearly every script carries a well-formed `@identity` block.

## 5. Gap Analysis

### Structural gaps (relatively few — this sequence is near complete)

- **qfep_sandbox_console is `status: planned` / `map_ready: false`.** The Sandbox map (QFEP_Sandbox) is currently anchored by `qfep_reactor` + `reactive_particles` + the two sliders rather than a unified console. The intent.md for Sandbox describes "no more guided tours" and "full parameter control," but there is no single artifact that combines λ, φ, F-meter, E-meter, and a phase readout. This is the biggest concrete build gap.
- **Chamber_QFEP intent.md is one-line thin.** Every other map has a rich four-paragraph intent with critical angle + technical angle; the chamber has five bullet lines. The `qfep_calibrator` creature is named but has no visible `@identity`, no script found in a quick scan. The final "mathematics becomes relationship" beat is asserted but not instrumented.
- **No `algorithms/qfep/` folder.** All QFEP artifacts live under `commons/interfaces/qfep/` (treating them as instruments) and `commons/artifacts/queer_morphology_specimen/`. That's a defensible choice — QFEP is a framework, not an algorithm family — but it means there is no `algorithms/qfep/` algorithm walkthrough the way there is for fractals or noise. A QFEP tutor artifact or axiom scene (beyond the existing `qfep_*_axioms.md` markdown) would help.
- **`entropy_meter` token collision (already noted in memory).** QFEP owns `entropy_meter`; `shannon_entropy_meter` was used elsewhere. Document this in the sequence README so future builders don't repeat the collision.

### @identity coverage gaps

Registered artifacts without `@identity` blocks that should have one (order of priority):
- crystal_cluster, crystal_formation, edge_particles, emergence_zone
- snap_cube_puzzle, snap_tetra_puzzle
- grab_sphere_F / _E / _lambda / _phi (the physical term-handles deserve identity blocks, since they are the narrative through-line from Intro to Synthesis)
- reactive_particle_field, edge_detector, entropy_meter, phase_cube, qfep_oscilloscope
- edge_of_chaos_orb, edge_of_chaos_unlocked
- qfep_calibrator (the chamber creature — file not located)

### Ordering issues

The current order is excellent. One minor concern:

- **Edge_Of_Chaos comes after Phi_Term but before Sandbox.** Phenomenologically this works (you need φ to understand why the edge is "alive"), but the edge is fundamentally a λ-position phenomenon. A purist ordering would be `Lambda_Spectrum → Edge_Of_Chaos → Phi_Term` (finish λ, then introduce the temporal derivative). The current order is defensible because Phi_Term lays the ethical ground (becoming > being) that makes the edge feel like more than a parameter setting. Keep current order — just document the choice.

### Missing transitions

- **Prerequisites → QFEP_Introduction.** The sequence JSON lists `primitives, randomness, wavefunctions, foundationscrisis` as prerequisites. The Intro intent.md says the formula "appeared there [Crisis_Synthesis] as culmination of the crisis." If the crisis synthesis doesn't literally hand the learner the formula, the Intro has no hook. Confirm Crisis_Synthesis ends with a formula reveal and that QFEP_Introduction opens with the same formula.
- **F_Term dark-room counterpoint.** The intent names the dark room problem as the critical beat, but the artifact list (crystal_cluster, snap puzzles) shows *only* F-minimization. There is no "dark room" artifact that demonstrates F-only failure. A simple one — a sphere that closes its eyes and stops responding — would land the lesson.
- **Synthesis → postfoundationscrisis.** Synthesis ends with queer_morphology_specimen but doesn't explicitly gesture at the next sequence. A forward-leak utility (portal, text panel, or a second specimen that refuses to resolve) would lead the learner out.

### Redundancies

- **turing_pattern vs turing_pattern_generator.** There are two Turing artifacts — one under `commons/interfaces/qfep/turing_pattern.gd` and one under `commons/artifacts/turing_pattern_generator/`. Only the generator has the rich `@identity` block. Clarify which is canonical and either consolidate or differentiate (e.g., QFEP's is the edge-of-chaos exemplar; the generator is the reaction-diffusion tutor).
- **crystal_cluster vs crystal_formation vs ordered_grid.** All three occupy the low-λ / high-order slot. Good for visual variety; ensure each intent text distinguishes them (e.g., crystal_cluster = grown, crystal_formation = static exemplar, ordered_grid = lattice).
- **preserved_pattern + rigid_sculpture** both demonstrate φ<0. Fine — one is 2D (pattern), one is 3D (sculpture) — but naming could be crisper.

## 6. Forward Leaks

Concepts this sequence raises but does not close. These are the ontological edges:

- **What do we build with QFEP?** → `postfoundationscrisis` (the next and final spine sequence). The synthesis says the formula is a lens, not an answer; postfoundations is where the lens is used to act.
- **Recursive emergence** → `recursiveemergence`. The sandbox shows parameter → behavior; recursive emergence asks what happens when the behavior modifies the parameters (autopoiesis, self-reference).
- **Speculative computation** → `speculativecomputation`. If φ>0 is the queer signature, a speculative machine is one that computes in the φ>0 regime. This sequence introduces φ but doesn't build a machine from it.
- **Criticalalgorithms / critical theory transfer.** QFE = F − λE(S) + φΔE(S,t) is explicitly named "the political term" for φ. The algorithms-as-ethics move happens here but is not fully carried out — which algorithms have what (F, λ, φ) fingerprint? That audit is the sequel.
- **Langton's λ vs QFEP's λ.** The sequence uses λ for both; a footnote or axiom file clarifying the correspondence (they are conceptually aligned but mathematically distinct: Langton's λ is an automaton-rule activation ratio) would prevent confusion.
- **Active inference / Friston.** Listed as a key reference but no artifact instruments the Markov blanket / generative model directly. This may belong in `neuroscience` (which exists) rather than here — worth checking for a cross-link.

## 7. Proposed Ordering

Current ordering is strong. Minimal proposal:

```
1. QFEP_Introduction       — recognition, whole formula, 3 grab_spheres (F, E, λ)
2. QFEP_F_Term             — order, crystallization, dark-room problem (ADD dark-room artifact)
3. QFEP_E_Term             — entropy, possibility, unconstrained particles
4. QFEP_Lambda_Spectrum    — walkable coupling, body-as-probe
5. QFEP_Phi_Term           — rate sensitivity, queer signature, 4th grab_sphere appears
6. QFEP_Edge_Of_Chaos      — criticality, Turing, Langton — the phenomenon named
7. QFEP_Sandbox            — full control, BUILD qfep_sandbox_console as unified anchor
8. QFEP_Synthesis          — all 4 term-spheres return + queer_morphology_specimen; add forward-leak to postfoundations
9. Chamber_QFEP            — catalyst ritual — DEEPEN intent.md, instrument qfep_calibrator
```

### Near-win build list (ordered by leverage)

1. **Build `qfep_sandbox_console`** — registered as planned; would unify the Sandbox map under one artifact.
2. **Flesh out `Chamber_QFEP/intent.md`** to the four-paragraph standard and locate/create `qfep_calibrator`.
3. **Add `@identity` blocks** to the grab_sphere_{F,E,λ,φ} quartet — these are the narrative through-line.
4. **Add a dark-room artifact** to QFEP_F_Term (pure F-minimization failure — a sphere that stops sensing) to land the critical beat.
5. **Write evolution files** for QFEP_Introduction, QFEP_Lambda_Spectrum, QFEP_Edge_Of_Chaos, QFEP_Synthesis (the four pedagogically pivotal maps). Current `intent.md` files are already of evolution-quality draft depth.
6. **Clarify turing_pattern canonicality** between qfep/ and artifacts/turing_pattern_generator/.
7. **Add Langton-λ vs QFEP-λ clarification** as an axiom file or intro side-panel.

## Summary

QFEP Laboratory is the **most theoretically finished sequence in Ada Research**. It is the inverse case of primitives: primitives has a clean concept flow but several missing maps; qfeplaboratory has every map present, every map with a thoughtful four-section intent, and a dense, well-identified artifact inventory. Its gaps are small and concrete: one planned console (`qfep_sandbox_console`), one thin chamber (`Chamber_QFEP`), a missing dark-room counter-artifact in F_Term, `@identity` blocks on the four grab_sphere terms, and a canonical-Turing cleanup. The sequence succeeds at its central pedagogical move — recognition rather than instruction — by isolating each term of QFE = F − λE(S) + φΔE(S,t) into its own room, then recombining under full parametric control, then closing with a queer morphology specimen that embodies the thesis biologically. The formula is not only taught here — it is **named as ethics** (φ>0 = queer signature), which is the argument that unifies the whole curriculum.
