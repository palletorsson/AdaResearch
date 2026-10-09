# FormFinding_Equilibrium — field notes

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

- **The mobile does not move.** No `_process` and no `_physics_process` in 248
  lines. `blurb.md` and `walked.md` both have it turning on a breath. It is
  5.93 m wide and 3.52 m tall, and each disc carries a nameplate in grams.
- **All four tokens are bare**, no registry entry declares `default_params`, so
  `apply_grid_config` is never called. The `lever:halved` variant is real in the
  code and unreachable from this map, so the first draft's "you can ask it to
  fail" was wrong and is cut.
- **The tensegrity has no cables and is not a tensegrity.** Three struts meet at
  three joints: a plain rigid triangle. The load pulse scales the whole node.
- **The truss is not a strut made of struts.** The recursion halves the tower
  vertically, and 24 of its 28 leg cylinders are drawn inside the four visible
  legs.
- All four `.tscn` files are bare script roots with no overrides, so here the
  `@export` defaults really are the effective values — checked, not assumed.
- The screen matches the triangle by name, refuses it because its children are
  not named the way the scan needs, and falls back to a radar scope.

## Open

- Reader landed and its findings are applied. Originally written before it returned: The lever crossover and the aluminium mass formula are read from the tutorial and the identity header; confirm `lever:halved` is reachable from a map token and what the tilt actually looks like.
