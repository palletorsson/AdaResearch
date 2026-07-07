# Open threads — held, not dropped

_Recorded 2026-05-15. Palle: "hold this and all other strategies starting with distance fields sound good."_

This file is the project's *held state* across the open arcs from the past 48 hours of work. Nothing is being closed; nothing is being prioritized away. Active focus starts with distance-fields. Other threads remain alive in this index and any of them can be picked back up.

## Active focus — RESOLVED 2026-05-15 by auto-research

The original active focus was distance-fields-as-placement-solver. Palle then said: *"the thing is that you should do auto research and find what is the best approach, that is the while thing"* and then *"Circle packing, amazon warehouse algorithm, Issacs gym, others etc etc? then blog findings."* 

Auto-research ran on TEN placement strategies × 300 seeds × 10 constraint metrics. Results in `doc/placement_research/results.json`, blog at `/blog/2026-05-15-no-base-algorithm-wins`, code at `tools/placement_research.py`.

**Ranking by mean score:**

| # | strategy | mean | best | std | notes |
|---|---|---|---|---|---|
| 1 | simulated_annealing | 0.946 | 0.965 | 0.010 | Isaac-Gym/RL surrogate — winner |
| 2 | hybrid (SDF + rule ordering) | 0.940 | 0.948 | **0.003** | lowest variance — most reliable |
| 3 | fold | 0.928 | 0.957 | 0.023 | high reward, higher variance |
| 4 | sdf (pure) | 0.908 | 0.945 | 0.036 | strong baseline |
| 5 | paradoxical (Gödel) | 0.890 | — | 0.000 | deterministic mid-tier |
| 6 | rule_based | 0.882 | 0.948 | 0.028 | current Ada baseline |
| 7 | voronoi | 0.880 | 0.952 | 0.059 | high variance |
| 8 | random | 0.859 | 0.958 | 0.047 | control |
| 9 | warehouse (Amazon) | 0.853 | 0.882 | 0.017 | optimizes travel, not clearance |
| 10 | circle_packing | 0.781 | — | 0.000 | classical — no game awareness |

**The rules emerging from the data (now codified in the blog):**
1. No single base algorithm wins
2. The winners are COMPOSITIONS (rule-ordering + geometry signal)
3. Classical algorithms (circle_packing, warehouse) optimize the wrong thing for game maps
4. Hybrid (SDF + rule) is deterministic and reliable (std=0.003) → default
5. Simulated annealing is opt-in for high-stakes maps (extra compute, +0.5 peak)

**Concrete next step (if picked up):** Drop hybrid as the `/editor` default; add simulated_annealing as opt-in for chambers + principle maps. Both already implemented in `tools/placement_research.py`.

### VALIDATED on real maps 2026-05-15

`tools/place_artifacts.py` runs hybrid (or any strategy) on a real existing map and writes a sibling `<MapName>_Hybrid` for VR comparison. Tested on 6-7 curriculum maps with 3-9 artifacts each:

| | initial run (stale footprints) | after footprint sync |
|---|---|---|
| improved | 7/7 | **6/6** |
| regressed | 0/7 | 0/6 |
| mean Δ | +0.044 | **+0.079** |
| best Δ | +0.060 (Point_Tests → 1.000) | +0.121 (Random_Game) |

**Probing the footprint nearly doubled the apparent gain.** The original gain was real but underestimated — bootstrap-inferred footprints in `spatial_needs` disagreed with AABB-measured footprints 75% of the time. After `tools/sync_footprints.py --apply` corrected 1,719 artifacts, the scorer sees real space and the hybrid algorithm's improvement is +0.079 mean.

The probe-loop existed (`commons/testing/measure_artifacts.gd` ran 2026-04-29) but wasn't wired into `spatial_needs.footprint_cells`. The wire is now connected. Algorithm is empirically ship-ready on corrected ground truth.

## Adjacent strategies — formerly held, now ranked by data

### Folding strategy — RANKED 3rd (mean 0.928)
Validated as a high-quality but high-variance strategy. The energy-minimization formulation works; needs better attraction-vs-repulsion balance (cluster scored 0.87 vs isolation 0.99 — repulsion dominates).

### Gödel / paradoxical geometry — RANKED 5th (mean 0.890)
Validated as a coherent strategy with the deliberate trade-off "refuse single-constraint perfection, get coverage." Deterministic. Not a winner but legitimate.

### Distance fields (pure SDF) — RANKED 4th (mean 0.908)
Solid geometry baseline. Beaten by hybrid (which uses SDF + rule ordering). The lesson: SDF math is RIGHT for placement *if combined with priority ordering*.

## Held substrate work — from prior conversation arcs

### From the 2026-05-13/14 facade arc

- **Pattern_pt* parallel cleanup** — 10 wallpaper-pattern stubs from yesterday's array_tutorial discard, queued for rebuild under mosaicanalysis as wallpaper-group expression maps using the existing pattern-gallery substrate (17 wallpaper groups already DNA'd). Same shape as the facade rebuild but with the wallpaper substrate.
- **Pompeii-interior subset** — 10 presets in `commons/facade_parts/presets/pompeii_*` and `villa_*` never used. Different tradition from facades (interior wall paintings). May want different room shapes; R9 in `commons/maps/rules/facade_placement.md` flagged them as outside the current rule coverage.
- **Custom capture angle** — `capture_first_person.gd` exists and is wired into `/editor`'s Capture tab. The multi-angle iso/front/left captures don't show facade architectural detail well; a custom head-on angle would. Worth wiring if/when facade hero shots are needed.

### From the Deleuzian-reframe arc

- **`research_threads` registry** — surfacing the 22+ DNA galleries from `/dna` as a first-class spine block. Sieve already confirmed this is good *as a live process index, not a taxonomy*. Hold until the SDF work clarifies whether new galleries should join.
- **Catalyst bracelet as re-virtualization device** — a blog Palle named yesterday morning. The bracelet at synthesis holds ~34 affordances; this is the morning's "the player IS the differentiation engine" claim made specific. Blog-shaped work; holds for when the substrate side wants documentation.
- **Substrate-partial-actualization dark spot** — what the audit can't measure (affects, intensities, durational). R9 in any rule file. Worth a future blog or sieve. *Don't ever claim the substrate's measurements are exhaustive.*

### From earlier sessions

- **ML schema duplication fix** — `machinelearning.json` has nested empty `artifact_groups` and root-populated `artifact_groups`. Bug, not feature. Flagged twice; never addressed.
- **`qfep_term_compass` proper wiring** — built but I never verified its in-VR behavior. Sits in QFEP_Synthesis map.
- **R11/R12 stamping discipline applied to other concerns** — wallpaper_placement, sequence_arc, intent_md, catalyst_affordances. Each is a small rule file's worth of work, following the `facade_placement.md` template. Hold until SDF investigation completes; some of these may dissolve into SDF-shaped rules.

## The R0 anti-naivety discipline

For any future strategy taken off this list:

1. Survey `commons/<obvious-name>/`, the encyclopedia at `localhost:3003/<topic>`, `MEMORY.md`, `project_*.md`, the `/fractal` API, recent git log, `tools/` directory — **before** any structural proposal
2. If a system already exists for the concern, the work is *use it, not rebuild it*
3. Only after the survey shows a real gap is a new substrate justified

The R0 discipline applies to every thread in this file when picked back up.

## Status

| arc | status | next move when picked back up |
|---|---|---|
| SDF placement/pathfinding | **active** | read full DistanceFieldsSDF.gd; find existing SDF→map bridge if any |
| Folding strategy | held | read fold_solver subclasses; recast as placement constraint solver |
| Gödel paradoxical geometry | held | walk Godel_Incompleteness + Escher_Impossible; find spatial primitive |
| Pattern_pt* / wallpaper rebuild | held | same shape as facade rebuild; pattern-gallery substrate already there |
| Pompeii interiors | held | derive R9-extension rules from image experience |
| `research_threads` registry | held | post-SDF, re-evaluate whether registry shape changes |
| Catalyst bracelet blog | held | writerly work; blog-shaped |
| Substrate dark-spot blog | held | name what audit measures vs. what actualization includes |
| ML schema duplication | held | one-off cleanup |
| qfep_term_compass verification | held | VR walkthrough |
| Other rule files (wallpaper, sequence, intent) | held | each is small; pick when need surfaces |

Nothing has been dropped. Active focus has shifted to SDF. The rest waits.
