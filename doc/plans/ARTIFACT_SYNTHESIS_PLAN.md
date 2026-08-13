# Synthesis pass — one more artifact out of each expansion

> 2026-08-06. After twenty promotion batches: 665 artifacts carry a genome, 407
> axis words, and the words that recur are families that learned to say the same
> thing. This pass reads each expanded artifact and asks what ONE MORE artifact
> the expansion earned — a synthesis. Some stand alone as heroes; some only make
> sense as a series.

## The sieve, held first

- **Thicken?** A synthesis gives a family its cross-member argument as a thing
  you can stand in front of — the tick ladders' different lengths, the four
  ballistic machines' one parabola. Those claims currently live only in registry
  notes.
- **Foreclosed?** The risk is flattening members into "examples of a concept."
  Rule: a synthesis NEVER replaces its sources and must keep each member's own
  argument legible inside it. The originals stay placed.
- **Dark spot?** A synthesis hides the walk-scale encounter with one artifact
  alone. That encounter is the curriculum's spine; syntheses are additions for
  rooms that want the comparison, not upgrades.

## Rules for a synthesis artifact

1. Born promoted: it declares `dna.axes` from day one, and where it reuses a
   family word it reuses the VALUE LIST exactly (or documents the refusal — see
   doc/DNA_PROMOTION_BRIEF.md, which is binding here too).
2. Three files: `<token>.gd`, `<token>.tscn` (root carries the script), and a
   per-token registry file `commons/artifacts/registry/<token>.json` with the
   `{"artifacts": {...}}` shape — per-token so parallel builders never touch one
   file.
3. Sources credited in `relationships` with `[[token]]` links; the synthesis
   must SAY what its sources learned (the finding is part of the exhibit).
4. Still-visible, seeded, budgeted: it is built for the same capture bench as
   everything else. No unseeded randf, no time-domain-only argument, element
   budget under ~3200, `layers = 0` extent anchor when MultiMesh carries the
   body.
5. New artifact = no shipped placements, so the default is a free design choice:
   make it the strongest single reading, not the emptiest.

## Wave 1 — building now

| synthesis | kind | sources | the argument |
|---|---|---|---|
| `pedagogical_sketchbook` | hero | klee_walking_point (walk_style, line) | Klee's opening taxonomy as one triptych: the same walk as active line, medial figure, passive plane. The project's founding image, made literal. |
| `recursion_observatory` | hero | cantor_set, koch_curve_3d, sierpinski_pyramid, menger_sponge (tick) | Four canonical fractals at matched rungs. The ladders have different lengths because the branching factor differs (2/4/5/20) — the shortness IS the argument, D = log N / log s etched per plinth. |
| `evidence_ladder` | hero | the 44-artifact `evidence` word | One phenomenon told four ways side by side — result, trace, longhand, axiom. The corpus's most-shared vocabulary as a single object. |
| `foresight_range` | series | catapult, force_pad, human_catapult, mortar_vector_siege (foresight, vectors) | One firing range, four machines, one parabola family. foresight applied range-wide: how much future each machine admits. |
| `lambda_promenade` | series | preserved_pattern, rigid_sculpture, edge_core, transforming_pattern, fluid_form, random_cubes, particle_chaos, qfep_reactor | The λ spectrum as a walk: the QFEP positions in λ order on one line, each member keeping its own axis. |
| `herbarium_cabinet` | series | botanical_flower (species ×10), exhibit_furniture (house) | Ten species as a collection. `house` reused: how a collection presents — white_cube, wunderkammer, depot, forensic. |

## Backlog — the rest of the census, grouped

- **disclosure cabinet** (12 members: slot_machine, coin_toss, monte_carlo…):
  one RNG at five disclosures. The rank ladder is already shared by preload.
- **the subtraction suite** (strike/breach: fontana_puncture,
  csg_difference_demo, csg_compose_workbench, sphere_splitting_showcase,
  destructibles_test_scene): what a cut is — art, operator, catalogue.
- **field room** (law/field/coding, 6 members): six field artifacts, one space.
- **operations gallery** (workings, 26 members; the slate+brass housing family):
  the embodied vectors-forces arc as one bench row — partially exists in maps.
- **retention corridor** (retention, 11): what a trace keeps, from draw_dot to
  mystic_writing_pad.
- **assay wing** (assay, 18 benches), **admission rack** (GlassRack 14),
  **pipe slack yard** (BigPipe 11), **initial_order sorting hall** (bar_array
  10), **tuning room** (metallophone/harmonic_distance/vowel boards),
  **noise quarry** (generator/readout families), **warning yard** (10 hazards).
- **Reachability bench** (spring_demo cap, bounce_well clamp, cantor floor,
  control_pendulum units): instruments showing the case their own controls
  could not reach. Thesis-adjacent; needs a ruling on whether apparatus
  belongs on exhibit.

Status: wave 1 in build. Verification: compile gate, declaration gate, fixed-
camera sweep per token, then commit. Placement into maps is a separate ruling.

---

## Wave 8 — target picked by census, 2026-08-13

Picked by census rather than from the backlog above, per the handover's rule. Of every
axis word in the corpus, **7 families have 5+ members and no synthesis drawing on them.**
Ranked by vocabulary count, because a word declared with one value list is a word the
family agrees about:

| word | members | vocabularies | distinct scenes |
|---|---:|---:|---:|
| `selection` | 6 | 2 | **4** |
| `subdivision` | 5 | 2 | **1** |
| `course` | 5 | 2 | 5 |
| `resolution` | 5 | 3 | 5 |
| `mode` | 6 | 4 | 6 |
| `depth` | 6 | 5 | 6 |
| `support` | 10 | 8 | 10 |

**Two of the top three collapse, and the census as published would not have caught it.**
Member count counts registry TOKENS, and CLAUDE.md's most common hidden family is one
scene wearing several names:

- **`subdivision` is not a family.** All five tokens — `icosahedron_base`,
  `subdivision_demo`, `strut_inventory`, `dome_builder`, `geodesic_dome` — resolve to the
  single scene `dome_kit.tscn`. A synthesis there would be five photographs of one object
  varied by a token meta. Its values `v1|v2|v3|v4` are a bare ordinal besides, which makes
  no claim there is anything to be dishonest about.
- **`course` is real but split at the wrong seam.** Five scenes, but four declare
  `lift|lateral|depth` while `translation_cube_demo` declares
  `lift_lateral|lateral_lift|lift_depth|lateral|free` — a different question wearing the
  same word. That is the VOCABULARY_SPLIT "genuinely different" case, not a family.

**So the census needs a third column — distinct scenes, not token count — before anything
is picked from it.** Added here rather than to the tool, because the tool's own output is
what misled it.

### `selection` — 6 tokens, 4 scenes, one honest vocabulary

| token | values | scene |
|---|---|---|
| `evolved_creatures` | drift·uniform·culled·runaway·split | `evolvedcreatures.tscn` |
| `evolving_flowers` / `evolvingflowers` | same five | `evolvingflowers.tscn` |
| `non_teleological_evolution` | same five | `non_teleological_evolution.tscn` |
| `evolutionary_algorithms` / `particle_randomness_evolutionary` | drift·uniform·culled·split | `evolutionary_algorithms.tscn` |

The subset is real and derived, not a defect: `EvolutionaryAlgorithmsDemo.gd` extends
`extrem_randomness.gd`, whose `const SELECTIONS` is four words wide (line 86) and whose
`_apply_selection` (line 634) rejects anything outside it. `runaway` is absent because the
parent never had it.

**What the word means, read from all four scenes rather than from the registry.** Each
value is a PAST-TENSE claim about what a pressure did to a population, and `drift` is the
shipped default and live artifact in every one of them:

- `drift` — the unselected gen-0 spread; the artifact as it ships, byte for byte
- `uniform` — one converged genome copied N times; nothing left to tell apart
- `culled` — a few survivors of that converged form, the rest of the plots bare
- `runaway` — the population pinned at the genome's own clamp ceilings
- `split` — two ranks with a corridor between them; disruptive selection

### The synthesis, and LAW 2 answered from the code

The four substrates are **parallel**: four scenes, four `match selection:` blocks with
mutually exclusive branches, no shared state, and nothing about a flower contains a biped.
So the simultaneity is the object — all four stand at once — and `selection` is the axis.
Same shape as `tier_terrarium`'s parallel case.

**The argument no single member can make:** a selection regime is a claim about a
population's SPREAD, and each substrate renders that same claim in a different currency —
limb length, petal count, radius and hue, position in a fitness landscape. Standing them
together asks whether the word survives the change of currency.

**And that is a falsifiable prediction, not a theme.** If the vocabulary is honest the four
bays must measure ALIKE at each value — the shared-vocabulary check the corpus keeps
rediscovering, and the one kind of claim that cannot be right by luck. `tier_terrarium`
found the opposite (a factor of 4.49 across one word, and one bay running backwards), so
the interesting outcome is available in both directions.

Open before building: the second axis. `tier_terrarium` used `channel` — which of the
word's readings to draw. Candidate here is how the population is drawn (bodies against a
spread gauge), which must be pinned so it cannot borrow the first axis's signal. **Do not
reuse `regime`** — VOCABULARY_SPLIT records it as the worst word in the corpus, 15 members
across 13 vocabularies.
