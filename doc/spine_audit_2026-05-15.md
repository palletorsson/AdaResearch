# Spine audit — actionable punch list

_Generated 2026-05-15 from `tools/spine_coherence.py` + `tools/spine_gaps.py` after applying the three fixes (calibration, infrastructure exclusion, two-axis classification). See `/timeline` for live state._

> **REVISED 2026-05-15 (later that day)**: a tool bug in `load_sequence_text` was returning empty stubs from `sequence_index.json` instead of the populated entry from each sequence's own JSON. After fix (`spine_gaps.py` now picks the richest match across all sequence files), the BUILT count doubled from 2 → 4. The "P0 Rewrite description" band emptied out. The sections below are kept for archive; the current live state at `/timeline` and `/spine-audit` reflects the corrected picture.
>
> **Sequences that flipped after the bug fix:**
> - `transformation`: was OK (false), now **BUILT** (58 claims, 55% covered)
> - `wavefunctions`: was OK (false), now **BUILT** (78 claims, 56% covered)
> - `softbodies`: was OK (false), now **GAP** — real build gap (58 claims, 31% covered)
> - `swarmintelligence`: was LOW_CLAIMS (false), now **GAP** — real build gap (63 claims, 29% covered)
>
> The first attempt to *close one audit loop* (by picking softbodies and rewriting its description) instead exposed the auditor's own bug. The audit auditing itself caught the issue; the fix is committed; the picture is more honest. See `/blog/2026-05-15-closing-one-loop`.

The diagnostics distinguish **four distinct kinds of fix**. Each item below has a class tag so you can pick by what you're in the mood for.

Class tags:
- **[DESC]** — rewrite a sequence's `description` field (cheap; unlocks better measurement)
- **[BUILD]** — author missing artifacts to cover claimed concepts
- **[FRAGMENT]** — investigate a fragmented sequence; consider splitting or curating
- **[INFRA]** — handle infrastructure / scaffolding artifacts polluting sequences
- **[EMPTY]** — fill an empty phase or sequence

---

## Priority 0 — DESCRIPTIONS (cheapest wins, unblocks everything else)

These sequences have many artifacts but their `description` field in `commons/maps/sequences/<name>.json` is too thin for the metric to evaluate them. Rewriting the description with richer language costs minutes and immediately surfaces real coverage gaps that are currently hidden.

| sequence | artifacts | keywords claimed | class |
|---|---|---|---|
| `wavefunctions` | 91 | **3** | OK (false signal) |
| `transformation` | 29 | **6** | OK (false signal) |
| `softbodies` | 18 | **2** | OK (false signal) |
| `swarmintelligence` | 11 | **4** | LOW_CLAIMS |

**Template to use**: copy the structure of `forces.json` or `qfeplaboratory.json` (both BUILT). They have rich `description`, `truth`, `qfep_connection`, and `learning_objectives` fields.

For each:
- [ ] `wavefunctions/sequence.description` — write 3-5 sentences describing what wave & oscillation behaviour the player walks through; list 6-10 specific concepts (interference, phase, amplitude, standing wave, resonance, mode shape, dispersion, wave packet, group velocity)
- [ ] `transformation/sequence.description` — name the geometric transformations exercised (translation, rotation, scale, shear, reflection, projection, basis change)
- [ ] `softbodies/sequence.description` — name the materials & forces (spring lattice, finite element, Verlet integration, mass-spring constraints, cloth, jelly, plastic deformation)
- [ ] `swarmintelligence/sequence.description` — name the algorithms (boid flocking, particle swarm, ant colony, stigmergy, emergent leader, pheromone fields)

Acceptance: re-run `python tools/spine_gaps.py`. Each should now have claim_richness ≥ 20.

---

## Priority 1 — BUILD (real curriculum gaps)

These have rich descriptions but the artifacts don't deliver what the curriculum claims. The metric is honest here: the gap is real.

- [ ] **`boolean_surfaces`** [BUILD] — 5 artifacts, 34 claims, **21% covered**. Most claimed-but-uncovered: `addition`, `architectural`, `assembly`, `calculus`. Either add ~15 artifacts (one per uncovered concept) or trim the description.
- [ ] **`proceduralgeneration`** [BUILD] — 13 artifacts, 61 claims, **25% covered**. Most-claimed-uncovered: `against`, `algorithms`, `balances`, `boundary`. Description is rich; many algorithms named but only some implemented.
- [ ] **`primitives`** [BUILD] — 70 artifacts, 47 claims, **30% covered**. Counter-intuitive: largest sequence has lowest coverage. The text claims `atomic`, `atoms`, `axioms` — abstract concepts that aren't surfaced in artifact descriptions even though artifacts may embody them. Probably better-fixed by enriching artifact descriptions than by adding artifacts.
- [ ] **`array_tutorial`** [BUILD] — 52 artifacts, 39 claims, **33% covered**. Uncovered: `access`, `address`, `arithmetic`, `before`. Some are likely metaphorical (access patterns of memory) — needs review whether they're absent or implicit.

---

## Priority 2 — FRAGMENTED sequences (low calibrated coherence)

Below ~10σ calibrated coherence means *barely tighter than chance*. Possible causes: the sequence is genuinely heterogeneous (a synthesis sequence), or its artifacts don't fit together (curation problem).

- [ ] **`change`** [FRAGMENT] — only **+8σ** calibrated coherence. Outlier artifacts: `riemann_pump`, `ftc_bridge`, `particle_flow_swarm`. Investigate: is `change` actually one sequence or three? Could split into `flow_and_pumps`, `integrals_and_bridges`, `motion`.
- [ ] **`swarmintelligence`** [FRAGMENT] — **+7σ**, weakest of all. Outliers: `self_organizing`, `fitness_landscape`. Combined with the [DESC] todo above — once description is fleshed out, re-evaluate.
- [ ] **`postfoundationscrisis`** [FRAGMENT] — **+9σ**. Outliers: `MolecularDesigner`, `bias_from_inside`, `bias_visualizer`. Possibly a deliberate sieve point — the crisis phase IS heterogeneous by design.
- [ ] **`foundationscrisis`** [FRAGMENT] — **+7σ**. Outliers: `parallel_lines`, `riemann_sphere`, `magritte_pipe`. Same caveat: synthesis-of-refusal pattern may legitimately scatter.

---

## Priority 3 — INFRASTRUCTURE cleanup

15 artifacts appear across ≥5 sequences (scaffolding). They dilute every sequence's coherence and aren't topic-specific.

Detected names: `dark_sphere`, `science_screen`, `catalyst_target`, `configurable_portal`, `library_rack`, `health_display`, `spawn_point`, `teleporter`, `catalyst_foe`, `catalyst_vent`, `wedge_skill_pickup`, `configurable_doorway`, `catalyst_sustain_demo`.

- [ ] [INFRA] Decide: do we want a `scaffolding` meta-sequence that owns these, or are they invisible-by-design and we just tag them as `category: "infrastructure"` in the registry?
- [ ] [INFRA] `array_tutorial` has 6 infrastructure artifacts (12% scaffolding) — the heaviest. Could pull them out into shared utility set.
- [ ] [INFRA] Update `tools/spine_coherence.py` `SCAFFOLDING_NAMES` set if more infrastructure is added later, or replace with a registry-flag check.

---

## Priority 4 — EMPTY phase

The `relation` phase (added during the 2026-05-13 sieve work) has **0 spine sequences** and only **18 artifacts** in branches. It's a placeholder waiting to be populated.

- [ ] [EMPTY] Either define a spine sequence for `relation`, or fold its 18 artifacts into adjacent phases and remove the phase from the spine. The current empty phase is a visible gap in the curriculum's argument.

---

## Priority 5 — MODELS (use these as templates)

Two sequences scored BUILT. Their text is rich AND well-covered by artifacts. Use them as exemplars when rewriting Priority 0 sequence descriptions.

- `forces` — 65 artifacts, 104 keywords claimed, **60% covered**
- `qfeplaboratory` — 29 artifacts, 53 keywords claimed, **60% covered**

Open `commons/maps/sequences/forces.json` and `qfeplaboratory.json` to see the shape of well-written `description` + `learning_objectives` + `truth` blocks.

---

## How to track progress

After working any item:

```
python tools/spine_coherence.py     # recompute calibrated σ per sequence
python tools/spine_gaps.py          # recompute classification
```

Then in `/timeline`: click "re-run diagnostics" → diagnostic row updates. Watch for:
- The number of GAP sequences decrease
- LOW_CLAIMS sequences flip to GAP or BUILT (which is *progress* — they're now evaluable)
- Calibrated coherence rise for FRAGMENTED sequences once outliers move

The signal is iterative. Each fix surfaces what wasn't measurable before.

## What we are NOT doing yet

These would be future tools, not part of this audit:

- **Concept embeddings** — would catch semantic gaps the keyword overlap can't see
- **External canon comparison** — would surface what the curriculum *should* cover by reference to e.g. a maths textbook table of contents
- **Per-artifact text enrichment** — many artifacts have skeletal `description` fields. The metric depends on artifact text quality too.

For now, the four-class system + calibrated coherence is enough signal to start working. Iterate from here.

---

_Source data: `doc/placement_research/spine_coherence.json`, `doc/placement_research/spine_gaps.json`. Re-run anytime; this file is a snapshot._
