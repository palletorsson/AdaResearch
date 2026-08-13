# Walk order — the chapter's first piece was standing at the far wall

Status: session evidence (Level C). Canonical parent: `doc/SPATIAL_PIPELINE.md`
Fixed 2026-08-13. Two keys swapped in `commons/scenes/em/em_sets.gd::_slot_before`.
Follows `doc/reports/order_to_walk.md`, which named the defect and was write-restricted
from touching it.

```
-	if ar != br: return ar < br      # rank
-	if ay != by: return ay < by      # depth
+	if ay != by: return ay < by      # depth
+	if ar != br: return ar < br      # rank, now the tiebreak it was documented to be
```

---

## PREDICTION (written before the fix, after the baseline run)

**Predicted after-tau for `chichu-buried-cells`: +1.000.**

The arithmetic. Chichu declares five slots. In segment coordinates (`z = tile row +
VESTIBULE_H`, `VESTIBULE_H = 2`) they stand at

```
z=10 x=3  rank 2        z=10 x=11 rank 2
z=16 x=3  rank 1        z=16 x=11 rank 2
z=24 x=7  rank 0        <-- the single hero plinth, the DEEPEST cell in the building
```

Its budget licences three leads and dealt no relatives, so three cells are filled. Ordered
depth-first the three leads must take z = 10, 10, 16: three pairs, zero inversions, one tie
(the two cells at z=10 are met simultaneously). `tau = 1 - 2*0/3 = +1.000`.

**MEASURED: +1.000. Right number, wrong arithmetic** — which is the more useful outcome.
Chichu did not deal three leads front-to-back. It dealt **two**, at z=10 and z=24, and lost
a placement: `placed 3/4` before, `placed 2/4` after. The reason is the co-cause below, and
I would not have found it if the prediction had only been checked at the top line.

**Second prediction, on the hero cost: the plinth stays occupied in Sainsbury and Uffizi
(both fill nearly every slot) and goes empty in Chichu (it only ever fills 3 of 5).**
**MEASURED: wrong on two of three, and backwards.** Chichu is the building that KEPT a lead
on its hero; Uffizi is the one whose hero got nothing from the curriculum.

---

## 1. Before and after, measured

Method: the real scene, one segment per run, `--em-order=spine` (default), pool from
position 0 so all three runs deal the same chapter (`primitives`) from the same cursor.
Each template forced to the front with `--em-first=<key>`; `--em-shot` is what makes
`--em-segments` real. Cells were read out of `em_sets.summary()` — instrumented for the
measurement and removed again; the post-removal run reproduces the instrumented deal
placement for placement.

`tau` is the audit's formula, `1 - 2 * inversions / pairs` over the dealt sequence's cell
depths, so these numbers are directly comparable to `order_to_walk.md`. Ties (two cells at
one depth, met simultaneously) are not inversions. `tau_a` in brackets treats ties as
neither.

| template | tau, all curriculum placements | tau, leads only |
|---|---|---|
| `sainsbury-false-perspective-enfilade` | **-0.111 → +0.891** (-0.178 → +0.818) | -0.200 → **+1.000** |
| `chichu-buried-cells` | **-0.333 → +1.000** (-0.667 → +1.000) | -0.333 → **+1.000** |
| `uffizi-spine-enfilade` | **+0.308 → +0.872** (+0.256 → +0.846) | +0.429 → **+1.000** |

The deal-order depth sequences, which is where those come from:

```
sainsbury  before  32 32 13 14 32 26  7 18 24 25
           after    7  7 12 19 14 18 24 32 26 32 32
chichu     before  24 16 16
           after   10 24
uffizi     before  31 28  6  8  8  8 12 21 14 14 19 26 23
           after    6 14  6  8  8 12 15 17 21 22 25 28 26
```

In all three baselines the **first artifact dealt stood at the deepest cell the segment ever
reached** — z=32 of 32, z=24 of 24, z=31 of 31. That is the audit's "10 of 26 templates put
the first-dealt artifact in the single deepest slot", reproduced on the live code path
rather than from the template file. After the change the leads are in strict walk order in
all three: **zero inversions among leads, 46 lead pairs.**

The residual inversions after the fix are all relatives, and they are the set dealer working
as designed: an `axis_kin` is placed adjacent to its lead and a `named` is placed in the
lead's sightline, both of which can sit a few cells behind a later lead. Sainsbury's 3 and
Uffizi's 5 remaining inversions are entirely of that kind.

## 2. Did the heroes get scrambled? Measured, and partly yes

A fix that straightens the walk by throwing the best furniture away is not a fix, so:

| | before | after |
|---|---|---|
| leads standing on a rank-0 hero cell | 3 of 3 templates | **1 of 3** |
| mean slot rank of a lead (0 hero, 1 podium, 2 floor) | 1.20 / 1.00 / 0.86 | **1.83 / 1.00 / 1.29** |
| hero cell holding a *curriculum* artifact | 3 of 3 | **2 of 3** |
| curriculum objects placed across the three | 32 | **31** |
| guests placed | 2 | 1 |

So the leads do sit on humbler furniture — mean rank 1.02 → 1.37 across the three. What the
mean hides is what the heroes now hold:

- **Sainsbury**: the hero at z=32 holds `provability_sorter`, the far end of the `reach`
  axis comparison whose near end is `perspective_lines` at z=24. The terminal plinth of a
  false-perspective enfilade now closes an argument instead of opening one. That is not a
  demotion; it is the plinth doing the job an enfilade's end wall does.
- **Chichu**: the hero at z=24 still holds a lead (`line_builder_3d`). The prediction that
  this was the building that would lose its hero was simply wrong.
- **Uffizi**: the hero at z=31 receives nothing from `em_sets` — the deal reaches z=28. It
  is not left bare: `_free_slots` is still rank-ordered, so the guest phase is offered the
  hero first and `combine_capsule` takes it. *(Derived, not printed: the hero was free at
  guest time, `free_g[0]` is the lowest-rank free cell, and one guest stamped.)* A stranger
  from the corpus on the vista's terminal accent is a real regression, and it is the same
  co-cause as the placement loss below.

**The one real loss is Chichu, 3 curriculum objects to 2**, and it is not caused by the
ordering. See §3.

## 3. What `endless_museum.gd:1029` needs

> Replace `slots.sort_custom(func(a,b): return int(a["rank"]) < int(b["rank"]))` with the
> same key `em_sets._slot_before` now uses — `(y, then rank, then x)` — so that
> `_free_slots()[0]` is the cell the lead will actually stand on.

Why, with the number. `_pick_pool(int(free[0].get("rank", 2)))` chooses the artifact from
the rank of `free[0]`: rank 0 asks for footprint >= 2, rank 1 for <= 1, rank 2 for <= 2.
With `slots` rank-sorted, `free[0]` is the hero plinth — and under depth-first placement the
hero is the *last* cell taken, so `free[0].rank` stays 0 for most of the segment. Every lead
in Chichu, and four of six in Sainsbury, were therefore selected as large-footprint pieces
and then placed on one-cell floor slots at the threshold, where `_seal_cells` refuses them
because sealing that cell would cut the corridor — a silent drop, no print, the cell spent
anyway. That is the whole of Chichu's 3 → 2. The same stale ordering hands the guest phase
the room's best furniture, which is how Uffizi's hero ended up with a stranger.

The rank hint is not wrong in principle; it is reading the wrong cell.

## 4. Verification

- Compile: `godot --headless --path . --xr-mode off --script res://commons/testing/check_compile.gd -- --files=res://commons/scenes/em/em_sets.gd`
  → `ok`, `1 checked, 0 failed`. Run twice: with the instrumentation and after removing it.
- Six full scene runs plus a re-run of the shipped file, all through
  `tools/godot_watchdog.py`, all exit 0, serialized one at a time.
- The header promise at `em_sets.gd:74` said *"the lead always takes the best slot in the
  room (lowest rank)"*. It was accurate, and it was the bug written down as a feature; it
  now says what the code does.

## 5. Captures

Same museum (`sainsbury-false-perspective-enfilade`), same order source, same segment, same
pool cursor, in `%APPDATA%/Godot/app_userdata/Ada Research Zero One/`:

| pair | before | after |
|---|---|---|
| composed standpoint (`--em-shot` only) | `wo_before_sainsbury.png` @ 6.5,24.5 — 4 of 13 dealt in view | `wo_after_sainsbury.png` @ 6.5,21.5 — **5** of 13 in view |
| threshold hint (`--em-shot-at=6`) | `wo_pair_before.png` @ 9.5,8.5 — 3 of 13 in view | `wo_pair_after.png` @ 7.5,10.5 — **4** of 13 in view |

**Caveat, stated because it limits the pair:** `--em-shot-at` is a *hint* into a
content-dependent search (`_compose_auto_shot`, band 7 m), not a standpoint, so the two
frames are shot 2.0 m apart rather than from an identical camera. The pair is a like-for-like
view, not a pixel diff. Chichu and Uffizi pairs exist under the same names.

What the composed pair shows: before, the end of the enfilade is `you_are_here` — a wayfinding
sign and the chapter's third artifact — over the dark box of `origin` on the hero plinth.
After, the same end wall is `provability_sorter`, lit, captioned, and standing as the far term
of a two-object comparison. The near field, in both, is what the walker meets first: before it
was the *sixth* thing dealt, after it is the *first*.

## 6. What this does not measure

- Three templates, not 26. The corpus mean of +0.401 in `order_to_walk.md` was reconstructed
  from `template_patterns.json`; these three are live runs and disagree with the
  reconstruction in detail (its Sainsbury figure was +0.143 against a measured -0.111), so
  the corpus mean should be re-measured the same way before it is quoted again.
- Repeats (`em_multiples`) and guests are excluded from the tau figures. Repeats carry the
  lead's own token and so carry no curriculum position; guests are not curriculum.
- One segment per run. Nothing here tests the ordering *between* buildings, which is
  `_deal_segment`'s chapter guard and a different defect.
- No VR walk. The claim is about the order of cells along +z, which is a fact about the
  segment; whether the room now *reads* as a chapter is a headset question.
