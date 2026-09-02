# FormFinding_Annealing — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## The chapter

Formfinding's own truth line: *a form is the answer to a minimisation problem.
The hanging chain, the soap film, the settling mesh, the balanced mobile — none
were drawn; each is the shape that costs the least. Nature computes form by
being lazy, and the calculus of variations is that laziness written down.*

Five rooms, written in one scope on 2026-09-02, in this order: Descent (a body
that reads only the local slope), Catenary (matter solving exactly, with no
solver), Relaxation (the discrete version, nudged not solved), Equilibrium
(forces that cancel), Annealing (willing to get worse, and then the turn).

## The probe

`commons/testing/probe_formfinding_tutorials.gd` (PROBE OK) carries the five
tutorials' arithmetic and puts the chapter's spine in two numbers: gradient
descent from beside the shallow well settles there, 0.88 from a well three
times deeper, and never goes; simulated annealing from the same start reaches
the deeper well in 14 runs of 20. Also measured: the bowl's central difference
matches the analytic slope exactly; learning rate 0.30 runs away to 459 while
0.02 lands on the centre; the catenoid is cosh and the hall's laundry cable is
a parabola differing from a matched catenary by up to 6.2 cm; Verlet's first
step from rest falls exactly g·dt²; the mobile's two moments are equal to six
decimals and a rod cut in the middle tilts 13.2°; a move costing 0.05 is
accepted 1556/2000 times at T=0.20 and 0/2000 at T=0.002.

One finding worth the Relaxation room, which I did not expect: with a pinned
chain, more constraint passes always improve the chain **as a whole**, but the
worst single link gets worse before better — 0.75, 0.90, 0.76, 0.58 — because
a sweep fixes each link in turn and every fixed link pulls its neighbour out.
Relaxation is not locally monotone.


## Corrected by its reader

- **The room's hero is on the ceiling.** `max_q_basin_room` shares its cell with
  the spawn, so it was bumped a level, and the grounding pass then lifted it
  clear of the walls: the 7 m plate hangs 3.30 m up and the frozen cube in the
  dead well dangles at about eye level. You cannot walk it, whatever the
  description and `eye_shot.md` say.
- **Its wells**: dead at local x −2.0, rim 0.9, depth 2.2, steep `sqrt` profile,
  one rigid 0.5 m cube at the bottom; alive at +2.0, broad and shallow.
- **The annealing table's relief is the Rastrigin function**, 2A + Σ(x² − A·cos
  τx) with A = 10, on a 1.4 m ImmediateMesh in a milled basin at deck height
  0.90 m.
- **The bench is a 22 × 22 = 484-instance MultiMesh** of the field
  amp·(sin 9x·0.6 + cos 7z·0.5 + sin 5(x+z)·0.4).
- **Nothing in the room is solid.** `HangarKit.box_collider` is never called by
  any of the five.
- The registry overstates the annealing table's footprint about ninefold
  (declared [1, 18, 13] against a measured 1.86 × 1.00 × 1.92 m).
- The screen locks to its fallback about a second in and prints zeros.

## Open

- Reader landed and its findings are applied. Originally written before it returned: Confirm the TEMP and RATE sliders are real UI, and that `max_q_basin_room` builds both wells with a live body in the shallow one.
