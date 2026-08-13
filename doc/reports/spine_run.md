# The spine run — the whole curriculum through the spatial chain

Status: session evidence (Level C). Canonical parent: `doc/SPATIAL_PIPELINE.md`
Run 2026-08-13. Follows `doc/reports/museum_wizard.md` (which ran the chain on eight
artifacts) and `doc/reports/order_to_walk.md` (which measured the dealer, not the plan).

Everything before this sampled. `museum_wizard` proved the chain end to end on **8 spine
anchors into 1 museum**; `export_museum_plan --all` offered **8 artifacts into 30 museums**,
the same eight, thirty times. Both answer *does the pipeline run*. Neither answers **can
these buildings hold the book**, which is the only question the endless museum exists to
ask.

This runs all 24 chapters, with their real casts, into the building the museum itself would
deal each chapter into. New tool: `tools/spine_run.py`. Data: `ada_run/spine_run.json`,
`ada_run/spine_run_sorts.json`, `ada_run/spine_run_probe.json`.

---

## PREDICTION (written before the run)

Fixed in the scratchpad at 15:12:28, before `spine_run.py` was pointed at all 24 chapters,
and quoted here unedited:

> **Predicted share of the WHOLE SPINE's offered cast that lands INTERIOR: 33%.**
>
> offered ~1070 bodies (799 curriculum rows x ~1.34 bodies/anchor; measured 1.32 on forces
> 151->200 and 2.0 on boolean_surfaces 4->8). A museum's interior capacity for a large cast
> measured 5..25 in the 16-body corpus pass. Call it ~16 per chapter for the 20 chapters
> whose cast exceeds it, plus 4 small chapters that fit whole = 320 + 53 = ~373.
> 373/1070 = 34.9%, rounded DOWN to 33% because forces measured 12.5% and the five biggest
> chapters carry a third of the corpus.
>
> Also predicted: the single biggest reason the spine cannot be housed is CAPACITY
> (physical_overlap — the building runs out of floor), not contract mismatch.

**MEASURED: 383 interior of 1156 offered = 33.13%.**

The share was right to a third of a percentage point, and both of its inputs were wrong in
compensating directions: offered was 1156, not 1070 (+8%), and interior was 383, not 373
(+2.7%). A prediction that lands by cancellation is worth less than its digits suggest, and
the second prediction is where the real information is: **it was wrong, and backwards.**
Capacity is not the binding constraint. See §4.

---

## 1. The cast defect, fixed

`export_museum_plan.py` offered `spine_order()[:limit]` — a flat prefix of the curriculum
walk. Each artifact arrived alone, carrying no argument about why it stands where it stands.
`tools/museum_wizard.py` had already measured the alternative on one building
(`museum_wizard.md` §2.3): the prefix placed 8 (7 interior), the brief-derived cast placed
15 (13 interior).

The fix gives `export_museum_plan` the wizard's cast by **calling it**, not by copying it —
`brief_cast()` imports `museum_wizard.stage_brief`, so the rule that decides which brief
entries reach the floor (features and their typed relations yes, `dna_variant` no) has one
owner. `--limit` still works and now counts ANCHORS, which is what `museum_wizard --count`
counts, so the two tools are directly comparable. `--flat-cast` restores the old prefix,
which is how the row below was measured rather than remembered.

### Corpus-wide, all 30 museum-tagged templates, `--limit=8`

| | offered per museum | placed | interior | rejected |
|---|--:|--:|--:|--:|
| flat prefix (`--flat-cast`) | 8 | 240 | 189 | 0 |
| brief-derived cast | **16** | **450** | **344** | 30 |
| change | +8 | **+210 (+87.5%)** | **+155 (+82.0%)** | +30 |

Per building the brief cast placed 15 in **all thirty**, with exactly one rejection each
(`fractal_recursion_2`, `support_matches_contract: slot offers 'podium', artifact needs
'platform'` — the same refusal `museum_wizard.md` §5 recorded, and the first sighting of
what §4 turns out to be about). Interior varied 5..13, and `uffizi-spine-enfilade` returned
**15 placed / 13 interior**, reproducing the wizard's number exactly, which is the check
that the two tools now build the same cast.

The rejections are not a regression. The prefix cast rejected nothing because eight bodies
never filled a building; a cast that reaches a building's limits is a cast that can be
refused.

---

## 2. The spine, chapter by chapter

Each chapter goes to the building `endless_museum.gd` would deal it into: its crown from
`commons/data/museum_crowns.json` if it has one, otherwise the next template in the
`em_order` rotation, with the cursor advancing only for uncrowned chapters — the rule at
`endless_museum.gd:1052-1070`, read from the museum's own files rather than chosen here.

**Whole-run totals**

```
24 chapters · 799 curriculum rows · 799 anchors (every row has a brief)
offered  1156 cast rows over 944 unique tokens (212 repeat appearances — a
         relative can be named by anchors in more than one chapter)
placed    678
interior  383          33.13% of offered
rejected  478
exterior  295          225 outside, 70 porch
lineages  481 declared · 115 found a wall long enough
chapters fully housed: 0 of 24
```

| chapter | museum | why | rows | offered | placed | **interior** | rejected | biggest refusal |
|---|---|---|--:|--:|--:|--:|--:|---|
| primitives | sainsbury-false-perspective-enfilade | crown | 82 | 115 | 80 | **26** | 35 | support_matches_contract 21 |
| transformation | uffizi-spine-enfilade | rotation | 24 | 42 | 36 | **21** | 6 | support_matches_contract 4 |
| symmetry | grande-galerie-axial | rotation | 21 | 29 | 13 | **10** | 16 | support_matches_contract 14 |
| array_tutorial | altes-rotunda-hub | rotation | 23 | 40 | 28 | **21** | 12 | support_matches_contract 8 |
| color | castelvecchio-endstopped-enfilade | rotation | 50 | 69 | 50 | **26** | 19 | escalation 10 |
| change | grande-galerie-axial | crown | 10 | 14 | 7 | **6** | 7 | support_matches_contract 7 |
| forces | sainsbury-false-perspective-enfilade | crown | 151 | 200 | 73 | **25** | 127 | physical_overlap 60 |
| formfinding | castelvecchio-pinch-v2 | rotation | 16 | 29 | 23 | **19** | 6 | support_matches_contract 4 |
| wavefunctions | louisiana-pavilion-chain | rotation | 81 | 107 | 72 | **38** | 35 | escalation 19 |
| randomness | soane-cabinet-vista | rotation | 64 | 83 | 52 | **22** | 31 | escalation 14 |
| noise | kanazawa-room-matrix | rotation | 16 | 23 | 12 | **8** | 11 | escalation 9 |
| cellularautomata | neue-nationalgalerie-free-plan | rotation | 23 | 35 | 21 | **14** | 14 | support_matches_contract 9 |
| fractals | pompidou-plateau-libre | rotation | 45 | 65 | 30 | **22** | 35 | support_matches_contract 18 |
| lsystems | grande-galerie-axial | crown | 16 | 30 | 19 | **14** | 11 | support_matches_contract 7 |
| proceduralgeneration | dia-beacon-field | rotation | 12 | 22 | 10 | **3** | 12 | escalation 11 |
| softbodies | mezquita-hypostyle | rotation | 16 | 30 | 18 | **11** | 12 | support_matches_contract 7 |
| isosurfaces | castelvecchio-pinch-v2 | crown | 25 | 32 | 10 | **5** | 22 | escalation 21 |
| boolean_surfaces | bilbao-atrium-radial | rotation | 4 | 8 | 7 | **7** | 1 | support_matches_contract 1 |
| swarmintelligence | guggenheim-serpentine | rotation | 11 | 19 | 10 | **7** | 9 | escalation 5 |
| machinelearning | chichu-buried-cells | rotation | 19 | 25 | 9 | **2** | 16 | escalation 16 |
| graphtheory | grande-galerie-axial | crown | 14 | 18 | 7 | **2** | 11 | escalation 8 |
| foundationscrisis | grande-galerie-axial | crown | 31 | 41 | 34 | **32** | 7 | support_matches_contract 7 |
| qfeplaboratory | teshima-droplet | rotation | 31 | 51 | 36 | **24** | 15 | support_matches_contract 14 |
| postfoundationscrisis | uffizi-spine-enfilade | crown | 14 | 29 | 21 | **18** | 8 | support_matches_contract 6 |

**Refusals across the whole spine**, 478 of them:

```
support_matches_contract  205      escalation (precinct)     184
physical_overlap           67      body_inside_room           11
faces_out_of_wall           4      wall_is_available           3
circulation_on_floor        3      required_access.front       1
```

### Which chapters cannot be housed

**None of the 24 is fully housed**, so the useful question is which ones are barely housed
at all. Five chapters put less than a fifth of their cast inside a building:

| chapter | interior / offered | share |
|---|--:|--:|
| machinelearning | 2 / 25 | 8% |
| graphtheory | 2 / 18 | 11% |
| forces | 25 / 200 | 12% |
| proceduralgeneration | 3 / 22 | 14% |
| isosurfaces | 5 / 32 | 16% |

And four are housed well enough to walk today: `boolean_surfaces` 7/8 (88%),
`foundationscrisis` 32/41 (78%), `formfinding` 19/29 (66%), `postfoundationscrisis`
18/29 (62%).

Those two lists are not about chapter size. `forces` is the largest chapter and
`graphtheory` one of the smallest, and they fail together; `foundationscrisis` (31 rows) and
`formfinding` (16 rows) succeed together. §4 is what actually separates them.

### The plan the museum receives

`ada_run/em_plan.json`, written by `spine_run.py --write-plan`: **17 museums, 507
placements, 281 interior.** Not 24, and that is a finding rather than a bug:

`em_plan.json` is keyed by **building**, and the museum's own assignment gives 24 chapters
only 17 distinct buildings — `grande-galerie-axial` is crowned for four chapters and is also
where the rotation puts `symmetry`, so five chapters want one key. The exporter gives the key
to the first chapter in curriculum order and records the other seven under
`_spine_run.displaced` rather than silently overwriting. In the live corridor there is no
collision, because a building is re-entered segment after segment in time; the collision is
a property of the plan FILE, and it means **`em_plan.json` in its current schema cannot
express the whole spine.** Seven chapters — change, forces, lsystems, isosurfaces,
graphtheory, foundationscrisis, postfoundationscrisis — have a negotiated plan in
`spine_run.json` that no building can currently receive.

---

## 3. The two sort fixes, measured

Two commits landed hours before this run:

```
d1adfb394  em_sets._slot_before      rank,y,x  ->  y,rank,x   (chapter opens at the door)
38b6ca2e2  _build_segment slot sort  rank      ->  y,rank,x   (the two sorts agree)
```

and the second says in its own message: *"NOT VERIFIED: I have no controlled BEFORE number
for this configuration ... The measurement belongs with the corpus run that follows."* This
is that run.

**Method.** `git worktree add --detach` at HEAD into a throwaway directory, with the repo's
`.godot` import cache copied in so Godot reimports nothing. Three arms, patched in that
worktree only — the repository's working tree was never reverted and never edited:

| arm | `_slot_before` | `_build_segment` |
|---|---|---|
| `neither` | rank before depth (read from `git show d1adfb394^`, never retyped) | rank only |
| `fix1` | depth first | rank only |
| `both` | depth first | (y, rank, x) — HEAD |

Reverting the two hunks at HEAD rather than checking out an older commit matters: the parent
of 38b6ca2e2 is `a37b26a73`, the wall-run rewrite, which would have entered the comparison as
a confound. **Every arm, including `both`, runs in the worktree**, so the build directory is
not a second variable.

(HEAD was `38b6ca2e2` when the arms ran; a concurrent session has since committed
`a11685cad` and `39d57385d`. Checked: neither touches `endless_museum.gd`,
`commons/scenes/em/`, `template_patterns.json`, `artifact_relations.json` or
`spine_artifact_order.json`, so the arms are still a comparison against today's HEAD.)

Two measurements per arm, both from the shipped code's own stdout — nothing was instrumented:

- **placements** — `endless_museum.gd:1299` prints `placed n/budget` per segment. One
  6-segment corridor, plus one segment forced into each of ten buildings with `--em-first`.
- **walk order** — a probe (`ada_sort_probe2.gd`, in the worktree) calls the real
  `EmSets.build_set()` on the real slot arrays of all 30 museum-tagged templates, with the
  real relations db and the real spine lead order, reproducing `_deal_segment`'s loop
  (`set_budget = 1 + rel_per_lead`, spent until the segment budget runs out).

### 3.1 Walk order — the corpus number

`tau = 1 - 2 * inversions / pairs` over the cell depths in deal order, the formula
`order_to_walk.md` used, so these are directly comparable to its `+0.401`.

| arm | tau, all placements | tau, leads only | lead inversions | museums opening at the back wall | mean lead slot rank | leads on a hero cell |
|---|--:|--:|--:|--:|--:|--:|
| `neither` | **+0.0517** | **+0.0966** | 92 / 225 | **14 of 30** | 0.851 | 30 |
| `fix1` | **+0.7601** | **+1.0000** | **0 / 225** | **0 of 30** | 1.501 | 4 |
| `both` | +0.7601 | +1.0000 | 0 / 225 | 0 of 30 | 1.501 | 4 |

`fix1` and `both` are identical to the digit, which is the control working: fix 2 lives in
`endless_museum.gd` and cannot touch which cell `em_sets` chooses. The probe isolates fix 1
and says so by returning the same number twice.

**Zero inversions among all 225 lead pairs, across all 30 museums.** `walk_order_fix.md`
claimed this for 46 lead pairs in 3 templates; it holds for the corpus. And the defect
`order_to_walk.md` §4 named — *"in 10 of 26 templates the first-dealt slot is the single
deepest slot in the building"* — measures **14 of 30** on the live code path, and **0 of 30**
after.

**The cost, corpus-wide, because a fix that straightens the walk by throwing the furniture
away is not a fix:** leads standing on a rank-0 hero cell fall **30 → 4** (one per museum
becomes one in seven), and mean lead slot rank rises **0.851 → 1.501**. `walk_order_fix.md`
measured 3/3 → 1/3 and 1.02 → 1.37 on three templates and called it *"partly yes"*. Over
thirty it is worse than that: the chapter's own pieces have essentially vacated the heroes.
That is the real price of the fix, and it is larger than the sample suggested.

### 3.2 Placements — the number 38b6ca2e2 says it does not have

**Ten buildings, one segment each, forced with `--em-first`:**

| building | budget | `neither` | `fix1` | `both` | both − neither |
|---|--:|--:|--:|--:|--:|
| sainsbury-false-perspective-enfilade | 14 | 13 | 13 | **14** | +1 |
| chichu-buried-cells | 4 | 3 | 2 | **2** | **−1** |
| uffizi-spine-enfilade | 16 | 16 | 16 | **16** | 0 |
| grande-galerie-axial | 18 | 17 | 18 | **16** | **−1** |
| guggenheim-serpentine | 17 | 16 | 17 | **17** | +1 |
| kanazawa-room-matrix | 12 | 7 | 8 | **7** | 0 |
| louisiana-pavilion-chain | 14 | 11 | 12 | **13** | +2 |
| labrouste-stack-hall | 24 | 12 | 15 | **19** | **+7** |
| soane-cabinet-vista | 24 | 24 | 24 | **24** | 0 |
| castelvecchio-pinch-v2 | 9 | 6 | 6 | **6** | 0 |
| **total** | **152** | **125** | **131** | **134** | **+9 (+7.2%)** |

**Fix 2 is worth +3 placements over fix 1 alone** (131 → 134), and the pair is worth +9 over
neither. That is the missing number, and it is positive.

**The 6-segment corridor, by contrast, cannot see any of it:** 76 → 75 → 75, i.e. 12.67 →
12.5 → 12.5 per segment. This is not a contradiction; it is the explanation for why neither
commit had a controlled number. `primitives` is crowned to the Sainsbury and `use_crown`
skips the rotation cursor, so a default run is **the same building six times**
(`order_to_walk.md` §3). A defect whose size depends on slot geometry is invisible to a
corridor with one geometry in it. You have to force the buildings.

### 3.3 One claim in the commit message is false

38b6ca2e2 and `walk_order_fix.md` §3 both assert that `endless_museum.gd`'s rank-only sort
*"was the whole of Chichu's 3 → 2 placements"* and that fixing it would recover them.

**Measured: it does not.** Chichu is 3 under `neither`, 2 under `fix1`, and **2 under
`both`**. The placement fix 1 cost is still gone with fix 2 applied. The mechanism described
in the commit (a lead selected as `footprint >= 2` from a stale `free[0].rank`, then refused
by `_seal_cells` on a one-cell threshold slot) may well be real, but it is not what is
happening in Chichu, and the attribution was inferred from a single after-run rather than
measured. The real gain is elsewhere: **Labrouste, 12 → 19, +58%**, which no one predicted.

Fix 2 is also **not monotonic** — Grande Galerie goes 17 → 18 → **16**, so agreeing the two
sorts costs that building two placements. The net is clearly positive; the per-building
effect is not.

---

## 4. The single biggest reason the spine cannot be housed

**It is not capacity. 457 of the 1156 offered bodies — 39.5% — cannot stand inside any of
the thirty authored museums before a single cell of floor is consulted.**

Two causes, measured over the same cast, from the contracts `emit_dressing_room.staged_contract`
returns:

| | bodies | share of offered |
|---|--:|--:|
| `containment == "precinct"` — the body is larger than any slot can contain, so `negotiate()` routes it past the slots to open ground (`spatial_negotiation.py:645`) | **260** | 22.5% |
| `required_support` is a word no slot in the corpus can speak | **198** | 17.1% |
| both | 1 | — |
| **union — excluded before capacity** | **457** | **39.5%** |
| eligible for an interior slot at all | 685 | 59.3% |
| of those, actually placed interior | 383 | 56% of the eligible |

The support half is the sharper of the two, because it is a vocabulary gap rather than a
physical one. Slots offer exactly three supports (`spatial_floorplan.SLOT_RANKS`: `floor`,
`podium`, `high_podium`). The rule at `spatial_negotiation.py:404-412` accepts
`floor`/`""`/`any`, an exact match, `wall` on a wall slot, and lifts `pedestal`/`table`/`podium`
onto a plinth. Everything else is refused by every slot in every building:

```
platform  120     none  29     float  23     pit  10
monument    8     sunken 6     plinth  2              = 198 bodies
```

`platform` alone is 120 bodies — a tenth of the curriculum — and `plinth` (2) is a plain
synonym of `pedestal`, which IS lifted. `none` (29) is the clearest defect of the three: an
artifact that declares it needs **no** support is currently refused by every slot in the
corpus, because `"none"` is not in `("floor", "", "any")`. That is why
`support_matches_contract` is the single largest refusal reason at 205 of 478, ahead of
`escalation` at 184 (which is the precinct half — *"no exterior venue is large enough
either"*), and why `physical_overlap` — the building genuinely running out of floor — is only
**67 of 478, 14%.**

The correlation holds per chapter, which is what makes it a cause rather than a coincidence.
The five worst-housed chapters are the ones whose casts are mostly precinct or mostly
unspeakable:

| chapter | offered | precinct | bad support | interior |
|---|--:|--:|--:|--:|
| isosurfaces | 32 | **26 (81%)** | 1 | 5 |
| machinelearning | 25 | **20 (80%)** | 0 | 2 |
| proceduralgeneration | 22 | **15 (68%)** | 1 | 3 |
| graphtheory | 18 | **12 (67%)** | 2 | 2 |
| symmetry | 29 | 2 | **14 (48%)** | 10 |
| foundationscrisis | 41 | **0** | 7 | **32 (78%)** |

`foundationscrisis` is the control: zero precinct bodies, and it is the best-housed chapter
of any size in the corpus.

**So the honest headline is not "the museums are too small".** A quarter of the curriculum is
built at a scale no gallery was ever going to contain — those are landscapes, fields and
walkable systems, and `containment: precinct` is the contract correctly saying so. Another
sixth is refused over a word. Only after both of those does floor area start to bind, and
when it does it accounts for one refusal in seven.

Filed as a follow-up: the `none` / `plinth` / `platform` vocabulary gap in
`spatial_negotiation.py`, which is not this pass's file to edit. Recovering `platform` alone,
if it turns out to be a third synonym for a raised surface, is worth up to a tenth of the
curriculum for one line.

---

## 5. Captures — and a third loss nobody had counted

Four buildings from four different chapters, each booted with `--em-plan` so the museum
consumes the spine run's own arithmetic instead of dealing. One Godot at a time,
`--xr-mode off --no-window`, never `--headless`, each under `tools/godot_watchdog.py`.
Frames in `ada_run/spine_run/capture/`, PNG mtimes checked against the wall clock rather
than trusting the exit code.

Published as iteration **`20260813-153117`**, 4 images, now the top row of
`http://localhost:3003/spatial-iterations`.

| building | chapter | plan says interior | not in pool | **stamped in the room** |
|---|---|--:|--:|--:|
| sainsbury-false-perspective-enfilade | primitives | 26 | 6 | **20** |
| louisiana-pavilion-chain | wavefunctions | 38 | 3 | **21** |
| teshima-droplet | qfeplaboratory | 24 | 6 | **17** |
| grande-galerie-axial | symmetry | 10 | 3 | **7** |
| **total** | | **98** | **18** | **65** |

Read that table right to left and there is a **third** subtraction, after the two in §4:

1. **18 of 98 are `not in pool`** — the plan names a token the museum cannot build. This is
   `order_to_walk.md` §2's 43 dead artifacts arriving at the last stage, and it is the first
   time they have been counted against a plan rather than against the pool.
2. **15 more vanish silently.** Sainsbury and Grande Galerie balance exactly
   (26−6=20, 10−3=7), Teshima loses 1, and **Louisiana loses 14**: 38 interior minus 3 not in
   pool is 35 attempted, and 21 stamped. `_deal_from_plan` prints its exterior, off-tile and
   missing counts, but a row where `_stamp()` simply returns `false` is not printed at all,
   so those fourteen leave no line in the log.

So the chain's real yield on these four buildings is **65 objects in rooms from 98 planned
interior placements, from 210 offered bodies** — and only the first of those three
subtractions was previously visible anywhere.

---

## 6. What this run does not measure

- **No headset, no walk.** Every number here is about a plan and a deal. Whether a chapter
  *reads* as a chapter is a VR question.
- **`interior` is the housing test, and it is the museum's own test**, not a chosen one:
  `_deal_from_plan` (`endless_museum.gd:1387`) stamps only `venue == "interior"` rows
  because the building has no apron. A porch placement is counted and reported, and lands
  nowhere.
- **The 43 dead artifacts of `order_to_walk.md` §2 are still dead**, and this run does not
  re-check them. A plan naming a token the pool does not carry is skipped at assembly with
  `N not in pool`; the capture logs in §5 are where that number is visible.
- **One cast per chapter, one building per chapter.** No search over which museum suits which
  chapter — the assignment is the museum's own, reproduced, not optimised. A chapter that
  fails in its crowned building might be housed by another.
- **`relations=2` throughout.** The cast size is a parameter (`--relations`), and 1156 bodies
  is what 2 produces. A different value moves every number in §2.
- **The sort arms are one corridor and ten buildings** for placements, though all thirty for
  walk order. The probe does not model `_deal_segment`'s guest phase, `em_multiples`,
  `em_plinths`, or `_seal_cells` — those are the museum's, and they are what the ten forced
  building boots measure.
- **The probe's `rel_per_lead` is fixed at 2.** The live `em_budget` varies it per building,
  so the probe's absolute placement counts are not the engine's; only the *difference between
  arms* is the claim, and the input slot order is held identical across arms so that the
  comparator is the only variable.

### One measurement bug found and fixed mid-run, recorded because it was invisible

The log reader matched the museum's banner as `seg N = KEY (label) chapter=...` with
`\(([^)]*)\)`. `castelvecchio-pinch-v2` prints *"(Museo di Castelvecchio, Verona (edited
v2))"* — nested brackets — so the group stopped mid-label, the whole line failed to match,
and that building reported **`placed 0/0` in all three arms**. Zero-of-zero reads exactly
like a template with no slots, which is a plausible fact about a museum, so nothing looked
wrong. It was caught only by opening the log by hand.

The logs are the evidence, so the repair was `spine_run.py reparse` — re-read the saved arm
logs with the fixed pattern — rather than thirty more Godot boots. The corrected building
totals (125 / 131 / 134 above) differ from the run's own printed line (119 / 125 / 128) by
exactly Castelvecchio's 6.

---

## 7. On disk after this pass

Nothing is committed; everything is left for review.

```
CHANGED  tools/export_museum_plan.py   the cast fix (+ --sequence, --relations, --flat-cast)
new      tools/spine_run.py            spine | sorts | probe | reparse | capture
new      tools/probes/*.gd             the two walk-order bench scripts, behind a
                                       .gdignore so Godot never parses them as
                                       part of this project; spine_run.py plants
                                       them in the worktree it builds
new      doc/reports/spine_run.md      this file
new      ada_run/spine_run.json        the 24-chapter run
new      ada_run/spine_run_sorts.json  three arms, engine + probe 1
new      ada_run/spine_run_probe.json  three arms, probe 2 (the walk-order table)
new      ada_run/spine_run_capture.json
new      ada_run/spine_run/            arm logs, arm frames, the four published frames
CHANGED  ada_run/em_plan.json          17 museums, 507 placements, 281 interior
                                       (was 30 museums / 247 / 195 from the wizard pass;
                                        a copy of the previous version is in the scratchpad)
new      ada_encyclopedia/public/spatial-iterations/20260813-153117/ (+ index.json)
```

The measurement worktree was removed after the run. `spine_run.py sorts` rebuilds it on
demand — detached at HEAD, import cache copied, probes planted — so §3 is reproducible from
a clean checkout with one command.

Nothing in `commons/scenes/endless_museum.gd`, `commons/scenes/em/*`,
`tools/museum_wizard.py`, `tools/pipeline_images.py` or `tools/spatial_*.py` was edited. The
pre-fix comparators were read out of git with `git show`, never retyped, and both patch
sites are matched as exact text so a drift in either file fails the arm loudly instead of
silently producing a no-op "before".
