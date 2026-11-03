# The Unit — a zoo of possible drawings, and what the picker decides

3 November 2026, after Experiments 1 and 2 (README.md beside this file). Palle: *"there were other strange examples
I liked … we want as many different examples as possible, with different looks and entropy"*; then a note on the
first zoo poster asking for three corrections (below) and three next experiments: a controlled comparison of the new
rule families, from drawing to capability, and an atlas inside the Void tower.

## The zoo

`commons/testing/unit_zoo.gd`: 330 runs of 600 s, 30 for each of 11 rule families. The families are:

- the compliant open loop (`compliance`);
- Experiment 2's ease, phase, ease_flip and keep;
- a cord and a free pair, both running the bare programme;
- the Python study's other two families, now ported as controllers in `unit_sim.gd`: `steer` / `steer_chiral`
  (turn by the rod's bearing, pace by its pull, the hub yields to its torque) and `rhythm` / `rhythm_anti` (the hub
  rate yields to, or resists, the low-passed rod torque).

They run on this model's compliant drive, not on the study's physics, so they draw their own figures, not copies of
the study's. Each config is drawn from a generator seeded with its index. It varies the rod length (0.6–1.5 m), the
hub offset, the pin radius, the turn and hub rates (some reversed or stopped), seven named starts or a random one,
and sometimes a 40° kick.

Every run records five pens: unit 1's hub rim, and points 0.25, 0.5, 0.75 and 1.4 of the way from one pin to the
other. **The five drawings of one run are five views of ONE behaviour, not five behaviours.** The poster marks each
panel with its run id and picks at most two views of a run.

## What the picker decides

`tools/unit_zoo_poster.py` measures each of the 1650 drawings, then picks 100 by farthest-point sampling: each pick
is the drawing least like every drawing already picked. The measures:

- **ink entropy:** how evenly the ink fills its own square box;
- **direction entropy:** how evenly the pen's directions of travel spread;
- **coverage** and **retrace;**
- **a "look"** that the comparison runs on.

**Ink entropy is not dynamical chaos.** A dense, perfectly periodic spirograph scores high. The poster therefore runs
from *low to high ink entropy*, not from "ordered to chaotic". A high score is not a better drawing; some of the
sparse open ones are the most compelling.

The instrument that looks for variety decides which varieties are seen. The first picker's look was a 16 × 16
thumbnail. It counts the same open drift at two angles as two different drawings, so steer_chiral's near-straight
wanderings took 24 of the 100 places, and 24 picks sat below ink entropy 0.6. The second picker is rotation-blind:
it looks at how the ink spreads out from its centre and how sharply it turns, and every family gets between 2 places
and twice its share. With it, steer_chiral takes 17, the open loop goes from 3 to 9 and steer from 7 to 13, and 17
picks sit below 0.6.

Both choices can be reproduced, and so can the drawings the picker left out:

```
python tools/unit_zoo_poster.py ada_run/workstation/unit_lab/zoo --k=100 --rejected=50          # the picks + 50 left out
python tools/unit_zoo_poster.py ada_run/workstation/unit_lab/zoo --k=100 --picker=first --out=ada_run/workstation/unit_lab/zoo/poster_zoo_first_picker.png
```

On the left-out sheet, each drawing names the pick it sits closest to: what the picker counted as already seen.

## Experiment f — the steer and rhythm rules: constrained, or responding?

`unit_lab.gd --exp=f`: Experiment 1's eight starts, 720 s, the settled window the last 120 s. Each family runs on
its own programme (steer's v 0.25, turn 0.2, hub 1.6; rhythm's v 0.10, turn 0.09, hub 1.2). There are seven arms per
family: no link; and on a rod and on a cord, the bare programme against the family's two rules. The bare programme
on the same link is the control. It is *constrained* by the link; the rule *responds* to it.

Every run has a **twin** with unit 2 moved 1 µm. How far apart the two tool points end tells whether the drawing
depends on its start that finely, which is what "chaotic" would mean. Figures are medians of 8 runs, ranges in
brackets, from `python tools/unit_lab_stats.py`. "Span" is the larger side of the bounding box of the middle's path,
over the last two minutes.

| arm | settled force | span, last two minutes | twin apart > 1 cm at the end |
|---|---|---|---|
| no link (steer's programme) | — | 2.31 m (1.11–2.72) | 0 of 8 |
| rod, steer's programme | 11.8 N | 11.0 m (9.4–11.2), circling | 0 |
| rod + steer | 10.9 N (0.8–18.6) | 18.9 m (0.0–27.1): 5 travel nearly straight, 2 pirouette | 0 |
| rod + steer, chiral | 13.3 N (13.3–18.6) | **0.00 m in all 8** | 0 |
| cord, steer's programme | 0 N | 2.72 m | 0 |
| cord + steer / chiral | mostly 0 N | — (6 of 8 overlap for the whole window) | 1 / 0 |
| no link (rhythm's programme) | — | 2.09 m (0.99–2.50) | 0 |
| rod, rhythm's programme | 8.2 N (1.1–8.3) | 2.32 m (2.17–4.90) | **3** |
| rod + rhythm | 4.9 N (4.8–5.0) | **9.31 m (7.99–9.67)** | 1 |
| rod + rhythm, anti | 11.9 N (11.9–13.3) | 1.23 m (1.07–1.26) | 1 |
| cord, rhythm's programme / + rhythm | 0 N | 2.5 m | 0 / 0 |
| cord + rhythm, anti | 0 N | 2.24 m | **3** |

**Sensitivity.** Only 9 of the 112 runs end more than 1 cm from their twin. Most of the dense, high-entropy drawings
of this model are therefore not chaotic in this sense: they repeat. The sensitive arms are rhythm's bare programme on
a rod (3 of 8, parting 466–589 s in) and rhythm_anti on a cord (3 of 8). The zoo's runs were not twinned, so its
poster cannot say which of its drawings are chaotic.

**The cord is not the rod for these rules.** Steer and steer_chiral on a cord drive the two chassis into each other:
6 of 8 overlap for the whole window. The model has no contact forces, so those runs say only that the rule needs the
rod's push, not what a real pair would do.

## From drawing to capability

Three candidates, each measured against the same units' bare programme on the same link:

1. **A still point** (rod + steer_chiral, 8 of 8 starts). In the last two minutes the rod's middle moves less than
   6e-8 m, which is the model's 32-bit float floor. Meanwhile both units drive at 0.23–0.29 m/s and turn at
   0.37–0.66 rad/s, and both hubs have stopped. The pair pirouettes about its own middle, in one of two modes: 5
   starts at 13.3 N, 3 at 18.6 N. A pen anywhere else on the rod draws an exact circle, so the pair is a compass.
   One unit cannot do this, because every point of it moves; the bare programme on the same rod carries its middle
   over 11 m. The cost is the programme: the turn rate rises 85–228 % and the hub gives up its rotation, with 13–19 N
   in the rod. It is a new mode, not an unloaded one.
2. **Straight travel** (rod + steer, 5 of 8 starts). In 4 starts the pair turns at 0.011–0.014 rad/s against a
   programmed 0.2 and covers 22–27 m in the last two minutes; in a fifth it turns at 0.032 and covers 15.7 m. Each unit alone circles within 2.3 m, and the bare programme on the
   rod circles over 11 m. In 2 of the other starts the pair pirouettes, and in 1 it drifts.
3. **More reach for less force** (rod + rhythm, 8 of 8). The middle's path spans 9.3 m in the last two minutes, with
   4.9 N in the rod. The bare programme on the same rod spans 2.3 m with 8.2 N; free units span 2.1 m. rhythm_anti
   does the opposite: 1.2 m with 11.9 N.

What is not shown yet:

- whether these states are HELD (the kick and switch-off test of Experiment 2h, not run on them);
- whether they survive unequal motors, noise, or contact;
- whether a stopped hub is acceptable in a physical unit.

## Next

- **The hold test on the still point and on straight travel:** a kick, and a switch-off at 480 s, as in 2h.
- **Twin the zoo,** so its poster can mark which drawings are sensitive to their start.
- **An atlas inside the Void tower:** select a drawing and see its rules, parameters, assembly and recorded movement,
  then replay it. Every drawing is a seeded config (`unit_zoo.gd config(i)`), so the tower can rebuild any run from
  its id rather than store it.

## Reproduce

```
godot --headless --path . --xr-mode off --script res://commons/testing/unit_zoo.gd -- --n=330 [--shard=k --of=6]
python tools/unit_zoo_poster.py ada_run/workstation/unit_lab/zoo --k=100 --rejected=50
godot --headless --path . --xr-mode off --script res://commons/testing/unit_lab.gd -- --exp=f
python tools/unit_lab_stats.py
python tools/unit_lab_poster.py ada_run/workstation/unit_lab/expf --out=ada_run/workstation/unit_lab/expf/poster_expf.png --half=6
```
