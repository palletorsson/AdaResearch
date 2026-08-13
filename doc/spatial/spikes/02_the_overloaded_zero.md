# SPIKE 02 — the overloaded zero: why a tall artifact is refused a plinth it does not need

*Diagnostic only. No code changed — `spatial_negotiation.py` and
`spatial_contract.py` were both uncommitted-modified in another session's working
tree while this ran, and the support-vocabulary fix inside them is what made this
residue visible in the first place.*

## QUESTION

The plinth ruling says *"a floor slot is not a refusal; it is a taller plinth"*
and removed 315 rejections. After the support-vocabulary fix took
`support_matches_contract` from 205 refusals to 18, three of the survivors still
read `slot offers 'floor', artifact needs 'podium'` — exactly the case the ruling
was written to place. Why does the ruling not reach them?

## PROBE

- `pattern_studio_plate` — 3.02 × 2.14 × **2.24** m, wants podium
- `csg_architecture_cavity` — 5.40 × 4.40 × **2.64** m, wants podium
- `MolecularDesigner` — 3.13 × 3.68 × **2.21** m, wants podium

Controls, to check the diagnosis does not over-explain:

- `science_screen` — 2.35 m tall and also refused, but needs `wall`
- `lambda_slider` — 1.30 m, wants wall, and *does* compute a 0.50 m lift

## BASELINE

Recorded in `HANDOVER.md` §5, whole spine: offered 1156 · placed 678 · interior
383 (33.13%) · refused 478, with `support_matches_contract` the largest single
refusal reason at 205 of 478.

Re-run today against the in-flight working tree:

| | recorded | now | Δ |
|---|---|---|---|
| placed | 678 | **769** | +91 |
| interior | 383 | **429** | +46 (33.13% → 37.1%) |
| rejected | 478 | **387** | −91 |
| `support_matches_contract` | 205 | **18** | −187 (−91%) |
| chapters fully housed | 0/24 | 0/24 | — |

Top refusal is now `escalation (precinct)` 186, then `physical_overlap` 125.
**The support bottleneck named in §7.2 is spent.**

## PREDICTION, WRITTEN FIRST

1. *"Zero support refusals remain; §7.2 is stale."* — **WRONG.** 18 remain.
2. *"All three podium cases are taller than the 1.80 m crossover."* — **RIGHT.**
   2.24, 2.64, 2.21.
3. *"30–60 spine artifacts are podium-wanting and over 1.80 m."* — **62.**
   Marginally over the range.

## THE FAULT

**F1 — `lift_for` returns 0.0 for two different reasons and the caller can only
read one.**

`spatial_contract.lift_for`:

```python
want = band["target_centre"] - body_h_m * 0.5 - slot_top_m
if want < band["min_lift"]:
    return 0.0                      # already in band; a lift would overshoot
return min(want, band["max_lift"])
```

`0.0` means **"no plinth is needed here"** — the body is already tall enough that
its centre sits at or above the viewing band, so raising it would push the work
over the visitor's head.

`spatial_negotiation.py:425` then reads that same `0.0` as **"a floor slot cannot
serve this artifact"**:

```python
or (wants_lift and slot.support == "floor" and plinth_h > 0.0)
```

EXPECTED: a tall podium-wanting body stands on a floor slot with no riser.
ACTUAL: it is refused from every floor slot in every museum.
CAUSE: `plinth_h > 0.0` is being used as permission to place, when it only ever
described *how much riser to build*. Zero riser is a valid, common answer.

With `plinth_band() = {target_centre: 1.15, min_lift: 0.25, max_lift: 1.20}`,
the crossover is exact:

```
body_h > 2 × (target_centre − min_lift) = 2 × (1.15 − 0.25) = 1.80 m
```

**Any body over 1.80 m that asks to be raised is refused from floor slots
precisely because it does not need raising.** The ruling that a floor slot is a
taller plinth holds all the way up the size range and then inverts at the top.

## EVIDENCE

```
spine artifacts       799
want podium           419
...and need NO lift    62   ← latent exposure
actually refused        3   ← realised in this run
```

The gap between 62 and 3 is real and worth keeping: most of the 62 find a genuine
`podium` slot and match at line 422, so the fault only bites when floor is all
that remains. 62 is the population at risk; 3 is what it cost in this
configuration. Reporting 62 as the win would be the same overclaim the
`interior_bottleneck` report was written to correct.

Tallest exposed: `vector_fields` 3.97 m, `koch_curve_3d` 3.89, `cloth_straps`
3.80, `Hilbert3D` 3.68, `calder_mobile` 3.52.

The controls behave as they should, which is what rules out a broader diagnosis:
`lambda_slider` at 1.30 m computes its 0.50 m lift correctly, and
`science_screen` is refused on the wall path (`slot.wall_side is None`), not this
one. Both refusals are correct.

## PROPOSED FIX — not applied

Separate "no riser needed" from "cannot stand here". One clause:

```python
    # A zero lift means the body ALREADY sits in the viewing band, not that the
    # floor cannot host it. em_plinths builds a 0 m riser happily; refusing here
    # inverts the plinth ruling at exactly the tall end of the corpus.
    or (wants_lift and slot.support == "floor"
        and (plinth_h > 0.0 or contract.body_m[2] >= 2 * (band["target_centre"] - band["min_lift"])))
```

or, cleaner, have `lift_for` return `Optional[float]` — `None` for *cannot*, `0.0`
for *no riser needed* — so the overload cannot recur. That is the larger change
and it touches every caller.

**Negative test that must bite:** a 2.24 m podium-wanting body against a
floor-only floorplan. Refused today, placed after. `pattern_studio_plate` is the
ready-made case.

## WHY THIS IS THE ENDEMIC BUG AGAIN

§8: *"Two places holding one number is this codebase's endemic bug."* This is its
sibling — **one place holding two meanings**. `0.0` is simultaneously a
measurement (riser height) and a verdict (placeable), and nothing in the type says
so. The same shape as `[1,1,1]` in `capture_dressing_room.gd`, which is both "a
one-metre cube" and "I measured nothing", and as the 159 registry blocks carrying
`aabb_size: [0,0,0]` with no flag distinguishing them (§7.6).

A sentinel that means two things is a statement the system cannot evaluate from
inside itself. Assert types too — or return a type that cannot hold both.
