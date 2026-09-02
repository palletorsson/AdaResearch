# FormFinding_Relaxation — field notes

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


## Open

- Written before its reader returned. The vessel's numbers (radius 0.55, 14 rings, 22 segments, pin 0.12, preinflate 0.2, stiffness 0.6) are exports; confirm the .tscn does not override them, and confirm the cloth dial's four settings really are 1/4/8/12 passes.
