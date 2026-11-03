# The Unit, day one — report for Astra

3 November 2026, from The Unit session, for the Codex / Astra session that owns the receiving places in the Void
tower. Previous: [the pit, the annex, floors that bounce](../2026-11-02-playground-annex-floors-bounce/README.md).

Blog, with pictures, on the encyclopedia:

- morning: `/blog/2026-11-03-two-clocks-on-one-beam` (the units, the pair and the triangle under the court);
- evening: `/blog/2026-11-03-a-compass-made-of-two` (the experiments, the zoo, the animation).

The full reports are [README.md](../2026-11-03-the-unit-experiments/README.md) (Experiments 1, 2 and 2h) and
[ZOO.md](../2026-11-03-the-unit-experiments/ZOO.md) (the zoo, the pickers, Experiment f). This file is the part that
concerns you: what changed near your work, what may be written, and what may not.

**None of your place files was edited today.** The only tower file touched is the playground sidecar
`commons/void/trials/principal_places/activities.json` (tracked, the playground session's, beside your recipe). It
gained four `the_unit` stations under the floor-210 biome court in `0589b990c`:

| id | hall-local position | rotation | config |
|---|---|---|---|
| undercroft-unit_pair | (-2.0, -0.08, -1.9) | [0, 180, 0] | `setup: pair`, `arrangement: c` |
| undercroft-unit_triangle | (2.0, -0.08, -1.9) | [0, 180, 0] | `setup: triangle`, `arrangement: c` |
| undercroft-unit_apart | (-2.0, -0.08, 2.1) | [0, 180, 0] | `setup: apart`, `arrangement: c` |
| undercroft-unit_one | (2.0, -0.08, 2.1) | [0, 180, 0] | `setup: one` |

`principal_places/places.tscn` is only read, by check K of `commons/testing/probe_the_unit`.

## What Palle asked, in order

1. The Unit inside the Void tower, from his design document: a robot with three actions (drive, turn the chassis,
   rotate a hub with attachments). One unit with a pen draws. Two joined by a rod should become *"a third thing: a
   drawing mechanism made by their relationship."*
2. A blog with pictures, and three units in a triangle.
3. His levels: kinematic composition, mechanical interaction, collective adaptation. *"Do not label a pattern
   emergent without explaining the local rules and causal evidence."* The next step should show *a new capability
   none of the units had before they were connected.*
4. *"Start with experiments 1 and 2"*: the same commands on no link, a rod and a cord; then local sensing against
   no feedback.
5. Collection posters seen from above, with a timeline under each drawing, and more examples.
6. *"As many different examples as possible, with different looks and entropy"*, including the stranger drawings
   from the Python study.
7. A note on the zoo poster, applied:
   - ink entropy is not chaos;
   - the five pens of one run are one behaviour;
   - make the picker visible;
   - run a controlled comparison of the new families;
   - go from drawing to capability;
   - and an atlas in the tower (not yet started).
8. An animation of the zoo.

## What exists now (all committed on `palm-scanner-door-entry`, not pushed)

| file | what |
|---|---|
| `commons/artifacts/the_unit/unit_sim.gd` | The model. Physics (a back-drivable drive) is split from the controller. `ctrl`: `programme` (open loop, bit for bit as before); ease, phase, keep and their ablations (Experiment 2); steer, steer_chiral, rhythm, rhythm_anti (the study's other families). All are additive: the default is untouched. |
| `commons/artifacts/the_unit/the_unit.gd/.tscn`, `registry/the_unit.json` | The view and the artifact. `setup` is pair, triangle, apart or one; the dna axis is derived. |
| `commons/testing/probe_the_unit.tscn` | 12 checks. The model checks (A–J, L) pass after today's changes. K, the stations in the tower, needs a windowed run for its screenshots and was not rerun headless. |
| `commons/testing/unit_lab.gd` | `--exp=1` (links), `--exp=2` (sensing), `--exp=2h` (the hold test), `--exp=f` (steer and rhythm, with 1 µm twins). |
| `commons/testing/unit_gallery.gd`, `unit_zoo.gd` | The curated gallery (30 specimens); the zoo (330 seeded runs, five pens each). |
| `tools/unit_lab_stats.py` | Prints every count, range, timing and pose the reports quote. |
| `tools/unit_lab_poster.py`, `unit_gallery_poster.py`, `unit_zoo_poster.py`, `unit_zoo_animate.py`, `unit_lab_plots.py` | The posters, the pickers (`--picker=first`, `--rejected=N`), the animation. |

Run outputs and posters are in `ada_run/workstation/unit_lab/` (ignored, this machine only). The blog's images
and the 4.5 MB video are in `ada_encyclopedia/public/the-unit/`.

## What may be written (measured, with the source)

- **Experiment 1.**
  - Without a link, two programmes.
  - On a rod, all eight starts reach one relation. The rod carries 6.05 N (6.01–6.24), each unit's hub is slowed
    22–24 % and its turn 23–27 %, and the rod spins 1,290° every two minutes.
  - On a cord, early tugs of 10–22 N, the last one 2–89 s in; then slack.
- **Experiment 2.**
  - ease and phase each bring the rod pair to zero force with both programmes intact, from 8 of 8 starts; the open
    loop never does (0 of 8).
  - Under phase the bar never turns (8 of 8).
  - ease with its sign flipped holds 7.7 N.
  - keep joins the cord pair within 0.85–1.008 m from 8 of 8 starts; without sensing, 3 of 8.
- **Experiment 2h.**
  - The rod's zero-force state is an unstable equilibrium of the open loop. With the sensing cut and no kick, it is
    lost 55–103 s later. That time is set by the model's 32-bit float rounding, so do not quote it as a property of
    the mechanism.
  - After a 2° kick with the sensing on, the state is back within 33 s.
  - The cord's state is mostly restored by the cord: in 6 of 8 starts the kicked runs are bit-identical with keep on
    and off.
- **Experiment f.**
  - Only 9 of 112 runs end more than 1 cm from their 1 µm twin.
  - rod + steer_chiral holds the rod's middle within 6e-8 m (the float floor) for the last two minutes, from 8 of 8
    starts, while both units drive at 0.23–0.29 m/s. It is a compass. The cost: the hubs stop and the rod carries
    13–19 N.
  - rod + steer drives nearly straight in 4–5 of 8 starts.
  - rod + rhythm spans 9.3 m with 4.9 N, against 2.3 m with 8.2 N without the rule.
- **The zoo.**
  - 1,650 drawings: 330 runs × 5 pens.
  - The first picker (a 16 × 16 thumbnail) gave one family 24 of 100 places. The rotation-blind picker spreads them
    (3–17 per family).

## What must NOT be written

- **"Emergent"** for any of these states. They are known states of two identical programmes (the parallel crank,
  the co-rotating circle, a translated pair, a pirouette) that local rules make reachable.
- **"Chaotic"** for a high-ink-entropy drawing. Ink entropy measures how the ink fills its box; the zoo's runs were
  not twinned. "Ordered to chaotic" was on the first poster and has been removed.
- **"Collide."** The model has no contact forces; footprints overlap and the units pass through each other.
- **"Reach" as covered area.** Reach is span: the larger side of the path's bounding box.
- **"keep holds the distance."** keep *reaches* it. Once there, it is idle in 6 of 8 runs.
- **"Five behaviours per run."** The five pens are five views of one behaviour.
- **"The compass holds."** It has not been kicked or switched off. It is reached, not shown to be held.
- **"steer and rhythm draw the Python study's figures."** They run on this model's physics and draw their own.
- **Anything physical from steer on a cord.** It drives the chassis into each other; without contact forces, that
  only says the rule needs the rod.
- **"Realistic sensors"** for the Python chain test. Its 'real' condition is mismatched motors and shoves, with
  ideal sensors.

## Open, and where you may be needed

- **The atlas in the tower** (Palle's note): choose a drawing, see its rules, parameters and assembly, replay it.
  Every zoo drawing is `unit_zoo.gd config(i)`, so a station can rebuild a run from its id. Placing it means a new
  place or station on a floor, which is your ground. I will ask on the forum before touching anything of yours.
- **The headset.** `activities.json` is not in the Quest export yet, so the four stations exist on the desktop only.
- **Probe check K** wants a windowed run once no one is using the desktop.
- **Next measurements:** the hold test on the compass and on straight travel, and twinning the zoo.

## Reproduce

```
godot --headless --path . --xr-mode off --script res://commons/testing/unit_lab.gd -- --exp=1|2|2h|f
godot --headless --path . --xr-mode off --script res://commons/testing/unit_zoo.gd -- --n=330 [--shard=k --of=6]
python tools/unit_lab_stats.py
python tools/unit_zoo_poster.py ada_run/workstation/unit_lab/zoo --k=100 --rejected=50
python tools/unit_zoo_animate.py --seconds=40 --fps=24
```
