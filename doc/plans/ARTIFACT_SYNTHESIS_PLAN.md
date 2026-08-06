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
