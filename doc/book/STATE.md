# STATE — the book's re-entry point

> Read this first, then the newest rulings in [RULINGS.md](RULINGS.md), then the current
> voice-bar chapter. Ten minutes and both of us are back in the loop — after weeks away,
> after a model upgrade, after context loss. Updated every session that touches the book.
> To FOLLOW the process as a feed: [LOG.md](LOG.md) (append-only, every tool writes to it
> via `tools/book_log.py`) — web face at **localhost:3003/book-log** (filterable timeline
> + the rulings panel).

**Last updated:** 2026-07-04 — R-009 applied: fractals walk hand-cut (+mandelbrot_dive,
+box_counting_dimension; −fractal_scene, −recursive_tree_2 [ghost's cuts, pending friction]);
Hilbert blank declared (renders in chapter + as EMPTY PLINTH in the staging brief); field
journal carries its first real entries. R-010: blanks have a lifecycle (declared → candidates
→ filled | commissioned) — DEMONSTRATED: box_counting_dimension captured in Godot (shows
**D = 1.555** measured — undershooting the ideal 1.585, the debt photographed), copied to the
archive, chapter now 11/11 illustrated, journal recorded "capture appeared". The loop turns.

## Where we are

- **The book:** `ada_encyclopedia/public/manuscript.md` (+ `.json`), built by
  `tools/build_manuscript.py` from `doc/manuscript_frame.json` (six-part arc, 6 motifs,
  excavation note) + `ada_encyclopedia/public/tutorial/<seq>.json` chapters.
- **Coverage:** 21/22 chapters built (`boolean_surfaces` has no three-orders pearls — stratum
  unopened). Writing passes: **4/22** (primitives, randomness, noise, fractals).
- **Reader artifact:** https://claude.ai/code/artifact/0a58e039-f4df-4214-8a3a-8548559e76d5
- **Map artifact:** https://claude.ai/code/artifact/5050b8c6-3c07-4c7d-beb3-75e23d397fde
  (also `public/manuscript-map.html`, rebuild: `tools/build_manuscript_map.py`)

## Provenance of passes (honesty table)

| Chapter | Overlay | Provenance | Status |
|---|---|---|---|
| fractals | `tutorial_authored/fractals.json` | pre-protocol, **current voice-bar** | standing |
| randomness | `tutorial_authored/randomness.json` | ghost-only, zero rulings (see R-005) | **needs friction pass** |
| primitives | `tutorial_authored/primitives.json` | drafted from R-001 | needs friction pass |

## Open queue

0. **R-008 the deep dig** — `tools/dig_report.py` built; pilot reports in
   `doc/book/dig_reports/`. KEY FINDS: fractals' canon is at depth (mandelbrot_dive LB 6,
   box_counting_dimension LB 6 + uncaptured, Hilbert/space-filling = uncovered concept —
   "to the hilbert curve" literally missing); randomness: entropy_axiom LB 6 uncaptured,
   trng_vs_prng correctly buried (tension already staged), Gaussian family uncaptured.
   AWAITING RULINGS on promotions/burials. Tool refinements queued: filter counter-pairs
   to LB/promoted members, read authored-overlay prose (mislabels prose-rich walked
   artifacts "ornament?"), pull truth from tutorial JSON. Next: role overlays + builders
   consume roles.
1. **noise RULED (R-011: P1a/P2c/P4a/P5c) and drafted** — overlay in, chapter built.
   PENDING: Palle's friction pass + his wording for the two ghost-proposed truth-sentences
   (NoiseColors3D, MeltingBerniniScene) before inscription into the .gd @identity.
   Still open: randomness staging forks (env_one room-shell vs hand-cut; rhythm: bench
   market / dice_rain_room from depth) + randomness dig (entropy_axiom?) → R-012.
2. R-003 landing: queerness definition into front matter + trace-motif sharpening (approved
   in principle, not applied).
3. Friction passes on randomness + primitives (Palle reads in the artifact, marks what isn't his).
4. `boolean_surfaces` three-orders pearls; captures for machinelearning + graphtheory
   (both walk 11 with 0 illustrated — the visibility apparatus hasn't reached them).
5. Next cold pass (voice-bar) due around chapter 4–5 of the protocol — Palle picks the sequence.
6. Later: `/manuscript` reader page in the encyclopedia; auto-indesign PDF
   (`/api/import-spine` → `/api/synthesize`) once enough passes exist.

## The pipeline (one chapter)

```
trench report (chat) → rulings → doc/tutorial_authored/<seq>.json
python tools/build_critical_tutorial.py <seq>
python tools/book_drift.py          # field journal — what the site changed under us
python tools/build_manuscript.py
python tools/build_manuscript_map.py
→ republish reader artifact → friction pass → update RULINGS.md + this file
```

## Spine-graph integration (tested 2026-07-03)

- **Book lens (read):** `tools/build_spine_graph_book.py` → `public/spine-graph-book.json`;
  the **Book** toggle on `/spine-graph` rings walked artifacts violet (title = chapter),
  dims the rest to depth, and prints "N of M excavated" under concept hubs. Rebuild the
  dataset after tutorial rebuilds. Verified: 194 lit / 578 dimmed / 772 total.
- **Walk curation (write):** arrange a sequence's ring on `/spine-graph` → Export →
  `python tools/import_walk_from_graph.py <export.json> --seq=<seq> --apply` → writes the
  `walk` override into the authored overlay; the tutorial builder honors the author's cut
  over the `[:11]` formula, marks `dig.curated`, and the manuscript's field note appends
  "The cut was made by hand." The field journal records the recut (`walked +x; −y`).
  Ring membership: artifact nodes with the sequence's seq or parented to its hub;
  order = reading order (row, then col). Tested end-to-end on noise and reverted.

## Staging briefs (the final game — chapter → hangar map)

`tools/chapter_stage.py <seq>` → `doc/book/staging_briefs/<seq>.md` — the bridge from a
finished chapter to its final map: roster w/ ladder tier + measured scale + staging-DNA
type + prose flag, rhythm score (scale melody, clashes/flats), alignment (no prose, no
plinth), grid from Σ footprints, floor plan from the 8-page grammar. First run 2026-07-03:
**fractals 70% contrast, melody holds, stage-ready; randomness 30% contrast, flat small
tail, and env_one (60 m base, 3,660 cells) blows the grid to 86×129 — fork: stage it AS
the room (terrain type = the map's shell) or hand-cut it from the walk.** fractal_scene +
cube_staircase unmeasured (run tools/measure_artifact_aabbs.py).

## The fold ladder (R-011 pending confirmation — dimensional unfolding)

Plan/elevation/itinerary as conjugate projections; the room is where they agree.
Fold 0 thread (walk, gaze_ride reads back) · Fold 1 plan (footprints) · Fold 2 elevation
(hangar walls) · **Fold 3 extrusion — `tools/wall_extrude.py` (built, piloted)** · Fold 4
3D grid (place.py) · Fold 5 fold-back (ride log → book). Pilot: **`Hangar_Fractals`**
(28×40, pathfinder 1120/1120 OK, captured) — 3 curated bays S→N in walk order
(fractal_recursion, proto_fractal_recursion, nk_fractals_mandelbrotset), hero
inverted_tree_cloud north zone, box_counting_dimension + cantor on the east lane,
**one empty plinth = the Hilbert blank, physically in the room**. Cluster sources:
`commons/data/curated_walls/clusters/`. Rebuild: `python tools/wall_extrude.py
--seq=<s> --write` → compact → pathfinder.

## Fold 5 — the ride log (built, folded back 2026-07-04)

`tools/fold_ride.py <Map> --seq=<s>` → runs gaze_ride, distills machine observations →
`doc/book/ride_logs/<seq>.json` (+ raw log `.log.md`) → tutorial world page `ride` field →
manuscript prints "The machine walked <Map> and filed this ride log" as the SECOND machine
register. First fold-back (Hangar_Fractals) generated the room's own revision list:
**the hero (inverted_tree_cloud) is neither visited nor seen** (ride path never reaches it);
8 of 11 exhibits visible only on arrival (blind bays — no long sightlines);
box_counting_dimension (11 m measured base!) holds 14 of 25 stations at up to 96° — one voice
too loud; 3 exhibit overlaps (box∩cantor on the lane; two inside the proto bay).
**v2 APPLIED (ruled):** root cause was a gaze_ride bug — spawn code "s" vs the documented
"sp" (fixed, accepts both) — plus the teleporter moved onto the hero's axis (wall_extrude
now voids the t cell itself). Result: hero seen at 32°/25.6 m mid-ride, then station 24 =
HUGE 66° CENTER 11.3 m before exit; ghost line gone from the ride log. Machine's honest
correction: from the south door the ENTRY hero by angular height is fibonacci_pagoda, not
the tree-cloud. Still queued (v3): blind bays (8/11 arrival-only — angle the bays or open
sightlines), tame/crown the 11 m box_counting, respace lane + proto bay interior overlaps.

## Standing constitution

- Rulings are the source; prose is compiled output. Unruled calls in drafts get marked, not hidden.
- Divergence is surfaced, never auto-collapsed. Disagreements logged both ways.
- The ledger is a voice, not a schema. The dig line is machine-only — never hand-written.
- VR walking is Palle's trench; text is the ghost's. A chapter needs both before it's done.
