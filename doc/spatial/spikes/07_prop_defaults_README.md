# SPIKE 07 — could the modular system hold prop defaults along its walls?

*Palle's question, 2026-08-13. Two agents, split so they could disagree with each
other as well as with me: 07a asked where the single owner should be, 07b asked
what would read it and what it costs. Both contradicted the brief. Neither edited
a repo file.*

- [07a — what the walls say](07a_what_the_walls_say.md)
- [07b — what would consume them](07b_what_would_consume_them.md)

---

## The answer, in one line

**Yes — and the duplication the question was worried about has already shipped.**

`em_props.gd:115-132` is eighteen constants, each annotated with the file it was
hand-copied from:

```gdscript
const VESTIBULE_H := 4        # endless_museum.gd VESTIBULE_H
const WALL_H := 3.0           # endless_museum.gd wall boxes: y 1.5, size 3.0
const CORNICE_BOTTOM := 2.72  # em_detail.gd — nothing may be hung above this
const SKIRT_H := 0.13         # em_detail.gd — nothing hangs below this
```

One of those copies is `VESTIBULE_H` — the same constant whose two holders
produced the 4 m displacement fixed hours earlier the same day
([spike 03](03_where_the_fifteen_go.md)). The endemic bug is not a risk this
design would introduce. It is the current state, and this design is the occasion
to fix it.

So the question changes from *can the system hold prop defaults* to **which file
owns those numbers.**

## What is actually there

**Five wall-height vocabularies, and the shipping museum reads none of them.**
`commons/scenes/em/` imports neither `tools/wall_bands.py` nor the JSONs it
reads. `em_detail.gd:213` hangs everything on a lone `HANG_Y := 1.58`.

`museum_prop_placement_rules.json` reaches no GDScript at all, and contradicts
the code where the two are comparable — `fire_extinguisher` by **1.10 m** and by
mounting kind, and `exit_sign` declared at **3.15 m on a wall `em_detail.gd:137`
builds 3.0 m tall.** The declaration places a sign above the wall it hangs on.

`wall_bands.check()` cannot see any of it: it validates against
`museum_module_kit.json`, which has no height key and **is not in HEAD**, so
`CERTIFIED_WALL_M = 4.0` is the only path that ever runs.

## What it would cost — much less than §6 implies

The kit's `prop_zones` are **four coordinate dicts weighing zero draw nodes**,
and they share no object with the 19 props `em_props` stamps. A prop-default
scheme therefore **does not inherit the kit's weight**, which was the standing
objection. All a declaration does is replace `em_props`' `run[0]/run[-1]` guess
with the author's answer.

The real failure is the opposite of overload: `em_props.gd:465` does
`cap = mini(cap, artworks)`, truncating **42 requested zones to 16 stamped** per
segment, silently.

Cost measured rather than assumed: the 16 props already stamped are **277 draw
nodes against that segment's 202 wall boxes** — service furniture already
outweighs the wall it hangs on, and is 76% of the corpus's wall geometry. Nobody
had counted it.

## Corrections to the handover, and to me

| claim | status |
|---|---|
| `props_per_10m` "never supplied by anything" (§8) | **WRONG.** `em_budget.gd:450` emits it, `em_props.gd:449` consumes it, `em_budget.gd:299` calls it "a key em_props has always read". §8 quotes a past-tense *before*-state as present tense. The orchestrator repeated it twice. |
| the kit is 11.7× heavier (§6) | **mixed denominators.** 11.69 is per metre of dressed run; the museum's 1.0 is per wall *cell*. On one denominator the true factor is **8.68×**. |
| mean unbroken run 2.7 m (§5) | **2.41 m pooled.** 2.7 is a mean of 30 per-building means, quoted beside three pooled figures. |
| "all 30 museums can host a 4 m panel" (§5) | holds — **by one museum and one metre.** |
| 182 templates / 30 museums; 5071 m / 2104 walls; 91.4% bare; 59% at 1 m; 55.1% in ≥4 m runs | all reproduce exactly |

Two live consequences found on the way. At the supplied value of 2 props/room the
quota table gives the single statutory slot to the exit sign and **deletes the
fire extinguisher and the E-stop from every building**. And the white-cube prop
numbers were never measured in the engine: `em_white_cube_measure.py` models a
bypass the GDScript does not have (59 props claimed against 50 derived).

## The binding constraint is addressing, not length

A tile has seven closed cell codes and no suffix grammar, so **a wall is a
derived thing with no nameable position**. That, not the 59%-of-walls-are-1 m
figure, is what a scheme has to solve.

Hence 07a's proposal: a declaration stores only a **(prop token, band name)**
pair, and face, rotation, standoff and horizontal position are *derived* from the
segment-local tile cell. One pair, one owner, nothing mirrored — which is the
only shape that does not reproduce the fault this spike found already shipped.

## Negative test

Retune `exit_sign.preferred_center_v_m` and assert the sign moves. **It must fail
today at exactly 0.00 m of movement** — the signature of an unwired declaration.

## Both agents caught themselves

07a recorded as F0 that it had claimed all targets HEAD-clean after checking six
of the thirteen files it went on to cite. 07b found the `props_per_10m` supplier
that falsified its own brief. Neither correction was requested.

## Untracked evidence — the one thing to fix first

`museum_module_kit.json`, `em_module_measure.py`, `em_white_cube_measure.py` and
`museum_prop_placement_rules.json` are **untracked and not gitignored — simply
never added**, while `museum_modularity.md` and `ceiling_convergence.md`, which
cite them, are committed. A clean clone has the rulings and none of the evidence,
and HANDOVER §5's wall numbers are not reproducible from it.

This is the failure `549f83e23` recorded against itself — *"zero of six
dependencies were in the repo"* — still live, in different files.
