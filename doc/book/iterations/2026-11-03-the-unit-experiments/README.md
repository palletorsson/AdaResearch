# The Unit — Experiments 1 and 2

3 November 2026. Palle asked: *"yes start with experiments 1 and 2"*, from his own brief for the next prototype:

- **Experiment 1, same controllers, different topology.** Identical control signals and initial conditions with
  two independent units, two units joined by a rigid rod, and two joined by a flexible tendon. Compare drawing
  trajectories, reachable workspace, forces and stability.
- **Experiment 2, local sensing and adaptation.** Each unit measures its own hub angle, movement and the force or
  displacement at its attachment. Simple decentralised rules reduce excessive tension, keep a preferred distance
  or adjust relative phase, compared with controllers that use no sensor feedback.

His standard for both: keep apart (1) kinematic composition, (2) mechanical interaction and (3) collective
adaptation; *"Do not label a pattern emergent without explaining the local rules and causal evidence"*; and the
experiment should demonstrate *a new capability that none of the units had before they were connected* (from his
Swedish, our translation), not merely a more complex pattern.

## The model, split into physics and controller

`commons/artifacts/the_unit/unit_sim.gd`. Read as physics, the force-yield the pair ran on so far is a compliant,
back-drivable DRIVE: its mobility (g_v, g_w, g_h) is passive, and (v0, w0, h0) is the drive's COMMAND. Each unit
now has a controller, `ctrl`:

- `programme` (default): the constant command, nothing sensed. This is the open-loop baseline, and it is bit for
  bit the model as it was (the port check against the Python study is unchanged).
- A sensing controller computes the command once per tick from the unit's OWN sensors: its hub angle, its own
  heading change over the tick (odometry), the force at its own pin in its own frame, and for each link its tension
  and where the partner's pin lies relative to its own — the link's bearing at its pin and its straight-line length
  (`link_sense`). The partner's command, heading and hub are not read, but its pin position, which depends on all
  three, is. A rigid rod carries that to the pin (a swivel encoder). A cord carries it only while taut; for the
  tendon we assume a weightless take-up reel that keeps the cord straight at zero tension, so a unit reads its
  partner's pin exactly even when the cord is slack. That is where keep's push half acts (below), so in hardware it
  would be a range-and-bearing sensor on the partner, carried by the cord.

The passive mobility stays on in every arm, so switching sensing on and off is the ablation.

## Experiment 1 — the same commands, three links

`commons/testing/unit_lab.gd --exp=1`: eight starts (the hand-set `c`, `parallel`, `crossed` and five seeded random
ones), 720 s each, settled window the last 120 s. Every unit runs the same programme (v 0.15 m/s, turn 0.25 rad/s,
hub 1.0 rad/s). Reach is the SPAN of the path of the link's middle — the larger side of its bounding box — over the whole
run and over the settled window. (Covered area is not a measure of reach: a path that never re-crosses itself covers more cells
however small it stays.) Medians of eight, ranges in brackets.

| link | span of the middle's path: whole run / settled | settled force | rates in the window | what happens |
|---|---|---|---|---|
| none | 1.20 m (0.50–1.50) / the same | — | the programme | two programmes; the middle point traces a closed figure |
| rigid rod | 4.17 m (3.59–4.43) / 1.77 m (1.70–1.78) | 6.05 N (6.01–6.24); settled peaks 13.1–13.7 N; in six starts an opening peak of 15.2–23.5 N within 15 s (in `c` and random 5 the force stays under 13 N early) | hub −22 to −24 %, turn −23 to −27 %; one unit 14–15 % faster, the other 15–17 % slower | one shared relation; the rod spins 1290° (1257–1330°) in two minutes |
| tendon | 1.47 m (1.24–1.87) / 1.46 m (1.24–1.52) | 0 N: slack all window in 8 of 8 | the programme | early tugs (peaks 10.6–21.8 N), the last 2–89 s after the start (median 21 s); then nothing pulls |

Levels: none is level 1. The rod is level 2 throughout: the coupling acts through the passive drive, and it bends
every rate of both programmes. The tendon is level 2 while it still tugs and level 1 after: two independent
programmes the cord no longer touches. (Tension is read from samples every 0.5 s; two starts' cords also graze
taut for an instant later, `crossed` at 77.5 s and `c` at 595.5 s.)

**Footprint overlap.** The model has no contact forces, so when two footprints overlap the chassis pass through
each other, and any motion after the first overlap is not physical. Without a link, two starts (`c` and random 5)
overlap from 2.5 and 3.5 s to the end, 18 % and 38 % of the window, because the two programmed figures cross.
The unsensed tendon pairs overlap in the same two starts (37 % and 30 % of the window) and two more briefly
(random 2 at 5.5–10 s, random 4 at 16.5–19 s). The rod pairs never overlap.

## Experiment 2 — the same physics, sensing on and off

Three controller families were designed and tested first in a Python twin of the model by three Claude agents (each
on 11 starts plus held-out seeds, with its own ablations: a survey of designs, not a controlled comparison between
them), then ported into `unit_sim.gd` `_command`. `unit_lab.gd --exp=2` runs them on the same eight starts.

**The controllers** (each unit, identical numbers):

- **ease** (rigid rod). The radial pull on its own pin, `f_rad = f_par·cos(ph) + f_lat·sin(ph)`, is the pull along
  its own hub arm. It does no work on the hub, so a passive hub cannot feel it. The hub leaks toward easing it:
  `d_h += DT·(−0.2·sign(h0)·f_rad − 1.0·d_h)`, clamped ±1; command `(v0, w0, h0 + d_h)`. Memory: `d_h`.
- **phase** (rigid rod). The same radial pull as a memoryless hub reflex, `ch = h0 − 0.05·f_rad`, plus a bearing
  hold on the chassis: the rod's spin in the world (the change of its bearing at the pin plus the unit's own heading
  change over the tick) is pushed against along the rod's normal (`du = clamp(L·0.1·spin, ±0.1)`,
  `v = v0 − sin(b)·du`, `w = w0 + cos(b)·du/v0`). Memory: the last bearing and heading.
- **keep** (tendon). Its own cord length, filtered over 3 s. When the filtered length is shorter than 0.95 m, it
  steers and paces away from where the partner's pin is seen. The cord, when taut, does the pulling; the hub is
  never touched. Memory: the filter.

**The ablations**: `ease_flip` (ease with the opposite sign); `phase_hub` (phase's hub reflex without the bearing
hold); `keep_pull` (keep's other half only — move TOWARD the partner when the filtered cord is longer than 0.95 m,
the half a cord already does); and `keep` with no link, a sanity check (with no cord it has no sensor, so the run is
Experiment 1's unlinked pair bit for bit). Removing the cord removes both its pull and keep's only sensor, so no arm
here separates the two: a pair with a range-and-bearing sensor and no cord was not run, and whether keep's result
needs the cord's pull or only the reel's reading is untested.

**The tests** (the designers' operational tests, last 120 s of 720 s):

- *unloaded carry* (rod only): mean force < 0.5 N and peak < 2 N, while every unit's realised speed, turn and hub
  rate, averaged over the window, are within 2 % of its programme (so it is not eased by giving up).
- *a bar that never turns*: the link's orientation within 2° peak to peak, its middle travelling ≥ 10 m over a
  span ≥ 0.5 m, window-mean rates within 10 %, length within 5 mm of the rod's.
- *joined at a distance*: the link within 0.85–1.008 m ≥ 95 % of the window, force ≤ 25 N, no footprint overlap,
  each unit's mean speed at least half its programme's.

| arm (8 starts) | unloaded carry | bar never turns | joined at a distance | settled force | the link's turning in the window |
|---|---|---|---|---|---|
| rod, no sensing | 0 | 0 | 8 | 6.05 N (6.01–6.24) | 1290° (1257–1330) |
| rod + ease | **8** | 7 | 8 | 0.000 N | 0° in 7; 1719° from `crossed` |
| rod + ease, sign flipped | 0 | 0 | 8 | 7.70 N (7.57–7.74) | 596° (587–604) |
| rod + phase | **8** | **8** | 8 | 0.000 N | 0° in 8 |
| rod + hub reflex alone | 8 | 7 | 8 | 0.000 N | 0° in 7; 1719° from `crossed` |
| tendon, no sensing | n/a | 1 | 3 | 0 N | 0.2–23° in 5; 1723–1751° in 3 |
| tendon + keep | n/a | 0 | **8** | 0 N in 6; in 2 (random 1, 3) a tug-and-push cycle, mean 0.28–0.33 N, tugs to 8.7–11.9 N | 0.7–2.4° in 6; 116–120° in 2 |
| tendon + pull half only | n/a | 0 | 3 | 0 N | 3.7–55° in 7; 1732° in 1 |
| no link + keep (sanity check) | n/a | n/a | n/a | — | — |

(A rigid rod passes *joined* by itself: it holds the distance mechanically, with 6 N in it. *Joined* is the cord's
test. The tendon cannot pass the bar test while its length swings: in the window keep's cord swings between its full
length and 1–14 cm short of it, and the test allows 5 mm.)

**What the ablations say.**

- *Sensing off against on* is the whole difference in every pair of rows: same physics, same starts.
- *The sign matters.* ease with the opposite sign holds 7.7 N and settles into a slow ring 3.5 m across, its turn
  cut by two thirds and its hub by two fifths.
- *The rule is not a schedule* (Python twin): ease's recorded command schedule, replayed without the sensor,
  reproduces 0 N on the exact start but settles at 4.6–6.1 N (11 of 11) when unit 2 starts 1 mm away.
- *The hub reflex alone* also unloads the rod, but from `crossed` it — and ease — end in the other zero-force
  state, co-rotating on one circle, where the bar keeps turning. The bearing hold avoided that on the one start here
  where the others fell into it (and on the two of eleven in Python).
- *The pull half of keep* passes 3 of 8, as no sensing does, though not the same three; it ends two lasting
  overlaps (`c`, random 5) and starts another (random 4, from 3.5 s to the end). In the Python twin it passed 3 of 11 against open
  loop's 1 and keep's 11. What keep adds is the push half, the one a cord cannot supply.

**How fast, and how violently.** Before the state is reached the force peaks above anything the open loop
produces: up to 27.6 N, above the wheels' 25 N grip in 13 of 24 sensing rod runs (ease 2, phase 5, hub reflex
alone 6; the open loop never exceeds 23.5 N). The force is last above 0.5 N at 13–35 s (phase), 22–60 s (hub reflex
alone) and 44–95 s (ease); ease's command keeps moving by more than 0.001 until 60–196 s. keep's cord, too, tugs harder than the open loop's in
three starts (22.5–26.0 N against at most 21.8 N), past the grip once (random 4, 3 mm of skid). keep's chassis overlap
early in three starts (2.5–7 s), at the same instants as without sensing; keep ends each overlap within two
seconds and it never recurs, while without sensing two of those pairs overlap to the end.

### Reached, or held? (Experiment 2h)

The window above starts long after the controllers settle: in it every rod-sensing unit runs within 3e-5 of its
programme, and keep's command equals the programme exactly in six of eight runs, its cord last taut at 25–79 s
(random 4 grazes once more at 314.5 s). Two identical programmes repeat the same relative motion on their own (a
fixed relative pose only as translates or on one shared circle), so a quiet window cannot tell *held by feedback*
from *left there and undisturbed*. `unit_lab.gd --exp=2h` asks directly. At 480 s, in the same runs, unit 1 is
turned 2° about its own pin (so the link's length does not jump, but the two units' relative pose changes), with the
sensing left on, switched off at the same moment, or switched off with no kick. Scored on
the same last 120 s.

| arm (8 starts) | sensing on, kicked | sensing cut, kicked | sensing cut, no kick |
|---|---|---|---|
| rod + ease: unloaded carry | **8**; under 0.5 N again 2.5–33 s after the kick | 0; 6.6–7.9 N | 0; the force passes 0.5 N 55–86 s after the cut, 7.6–12.7 N in the window |
| rod + phase: unloaded carry / bar | **8 / 8**; under 0.5 N again 2.5–12 s after | 0 / 0; 6.7–7.7 N | 0 / 0; passes 0.5 N 70–103 s after the cut, 7.1–8.2 N |
| tendon + keep: joined | 8 | 7 | 6 |

- **The rod's zero-force state is held by the feedback.** It is an unstable equilibrium of the open loop: with the
  sensing switched off and nothing else changed, rounding error alone carries every pair out of it within one to two
  minutes. (The model keeps pin positions and rates in 32-bit floats, a force noise of about 2e-4 to 7e-4 N; the
  escape time is set by that floor. A double-precision model would take longer, and real sensor and motor noise far
  less.) With the sensing on, the same state returns within 33 s of the kick. At the end of the run the cut pairs
  are still on their way: their force (6.6–12.7 N) and their link's turning (390–990°) are not yet the open loop's
  settled relation, which takes six to eight minutes to form from a start.
- **After this kick, the cord's state is held by the cord.** In six of eight starts the kicked runs are bit-for-bit
  the same with keep on and off, so keep never acts. The 2° turn lets the cord go taut; its tugs (above 0.5 N for
  1.5–29 s after the kick; in random 2 ever lighter tugs every 12.5 s go on until 710 s) settle the pair into a
  nearby slack pose (headings within 1.1°, hubs within 2.6°), and the cord never leaves the band. In these six the
  kick never brings the cord below keep's 0.95 m trigger, so it tests only what a cord can answer; a shove that
  SHORTENS the cord, the case only keep's push half can answer, was not run here. keep holds the state in the two
  starts where it was still acting before the kick (random 1 and random 3): with the sensing cut and no kick, both
  drift out of the band (71 % and 53 % of the window in it). Kicked and cut, random 3 drifts out, and random 1 stays
  in only by chance: its cord never pulls again after the kick, and the pose the kick left it in dips to 0.862 m,
  1.2 cm inside the band's edge. In the Python twin's 'real' condition (each unit's motors mismatched, speed and hub
  ±5 %, turn ±0.02 rad/s, and the pair shoved 0.15 m about once a minute; ideal sensors), keep held the band in 9 of
  11 runs against open loop's 0 of 11 — a condition not run here.

### What is new

Two capabilities. Neither is possible for one unit, and in both the sensing does the work that the link alone does
not do.

1. **An unloaded rigid carry** (ease, phase). Two units carry a 1 m bar with no force in it while each runs its
   whole programme. Without sensing the rod pair never gets there (0 of 8). It fights at 6 N: each unit's hub is
   slowed by 22–24 % and its turn by 23–27 %, while one unit is pushed about 15 % faster and the other held about
   15 % slower. With sensing cut, the state is lost in one to two minutes. The state has two forms, because two
   identical force-free programmes keep their pins one rod length apart only as translates of each other or on one
   shared circle. As translates, the bar is carried without ever turning, like the bar of a drafting machine (phase
   8 of 8; ease and the hub reflex alone 7 of 8). On the shared circle, the bar turns with the chassis (from
   `crossed`, for ease and the reflex alone).
2. **Joined at a distance on a cord** (keep). Two units on a cord that can only pull (the cord is both the pull and,
   through the assumed reel, keep's sensor) end with the cord between 0.86 and 1.0 m, never overlapping after the
   first 7 s, from all eight starts. Without sensing that happens from three (the early tugs happen to align the two
   headings there), and in five of eight the slack cord ends up hanging as short as 0.21–0.69 m. Here the sensing's
   work is mostly the REACHING. Once there, the identical programmes repeat the same relative motion. After the 2°
   kick with the sensing cut, the cord's tugs settle the pair into a nearby pose in six of eight, the six where keep
   was idle anyway, and a seventh stays in the band by chance. keep's push half is needed to hold the state in two of
   eight here, and in the Python twin once the motors differ and the pair is shoved.

**Levels**, by Palle's three. One unit, and the unlinked pair: level 1. The rod without sensing, and the tendon
while it tugs: level 2. The sensing arms are level 3 in a minimal sense. Each unit changes its own command from what
it senses at its own pin, and the joint state is reached (and, for the rod, held) because of those rules: the
ablations and the switch-off show it. ease (a leaky integrator) and keep (a filter and a threshold) carry memory.
phase's hub reflex is a fixed, memoryless map from force to rate. By the model file's criterion of memory or
choice, that is level 2. We place it at level 3 on a different criterion: it answers a load the passive hub cannot
feel, since the pull along its own hub arm does no work on the hub. The finished states LOOK like level 1, no force
and each motor on its programme. For the rod that look is held by level-3 feedback that level-2 mechanics cannot
hold. For keep's six idle runs it is level 1, two programmes in a pose that level-3 feedback brought them to, and
after a kick the cord's tugs, level 2. We do not call the states emergent. They are known states of two identical
programmes: for the rod the parallel-crank linkage and the co-rotating circle; for the cord a near-translated pair
(headings within 0.3°, hubs 2–7° apart, the slack cord swinging 1–4 cm below its length on each hub turn), one of a
continuum of such poses. The local rules make them reachable, and for the rod they restore the state after the one
kick tried (2° about unit 1's pin).

## Where it stops working

- **Identical programmes.** The zero-force states exist only because both units run the same programme. In the
  Python twin, a 2–5 % mismatch leaves ease at a median 0.4–2.5 N mean force (8 of 66 pass the strict test; window
  peaks up to 26 N, above open loop's 14–25 N), against open loop's 6–11 N. On three starts, phase's bar wanders
  2.5–6.3° at a 4–5 % mismatch and 7.6–11° at a 10 % speed mismatch, with jolts near the wheels' grip limit.
- **Ideal sensors.** No noise, latency or gyro bias. With 1 N of load-cell noise, ease passes 2 of 11 (Python). A
  gyro bias would leave phase's bar turning at about minus the bias (untested).
- **The band edge.** keep's 8 of 8 rests on the test's 0.85 m lower edge. In the two runs where keep still acts in
  the window, the cord dips to 0.86 m; with the edge at 0.90 m keep passes 6 of 8 (the six idle runs) and no
  sensing 2 of 8.
- **Chains.** A unit keeps a distance only from what it is tied to. In a three-unit chain the ends, which share no
  cord, touch at some point in 19 of 20 runs (Python twin). In the settled window the chain still passes 8 of 10
  with identical motors and no shoves, and 1 of 10 in the twin's 'real' condition (mismatched motors and shoves;
  ideal sensors in both).
- **Drawing.** None of this makes a richer drawing. In the synchronised runs (22 of 24 rod runs, and approximately
  in keep's six idle runs) the pen draws a single unit's own figure, translated; the two co-rotating runs draw the
  midpoint of two units on one circle. The capabilities are carrying, holding and keeping, not drawing.

## Reproduce

```
godot --headless --path . --xr-mode off --script res://commons/testing/unit_lab.gd -- --exp=1
godot --headless --path . --xr-mode off --script res://commons/testing/unit_lab.gd -- --exp=2
godot --headless --path . --xr-mode off --script res://commons/testing/unit_lab.gd -- --exp=2h
godot --headless --path . --xr-mode off --script res://commons/testing/unit_gallery.gd
python tools/unit_lab_stats.py
python tools/unit_lab_plots.py ada_run/workstation/unit_lab/exp2
python tools/unit_lab_poster.py ada_run/workstation/unit_lab/exp2 --out=ada_run/workstation/unit_lab/exp2/poster_exp2.png
python tools/unit_gallery_poster.py ada_run/workstation/unit_lab/gallery
```

Deterministic: fixed starts and seeds, fixed step. Every count, median, range, timing and pose in this report that
is not marked as the Python twin's is printed by `tools/unit_lab_stats.py` from the lab's run files; what the
drawings look like is read off the posters. The Python design studies (with their own held-out seeds and ablations)
ran in the session scratchpad and are summarised here only where marked. The model's probe
(`commons/testing/probe_the_unit.tscn`) still passes its model checks A–J and L after these changes. Check K, the
stations in the tower, needs a windowed run for its screenshots and was not rerun.

## Next

Experiment 3 (a third unit attaching and detaching while the group works, recording the transition) and Experiment
4 (motor and torque limits, traction, compliance — when the mechanism would be physically realisable). Two things
this report leaves open belong to those: unequal programmes (the Python mismatch results above), and contact, which
the model does not have. The exhibit under the floor-210 court could gain a station with a sensing switch, so the
capability and its ablation can be seen side by side in the tower.
