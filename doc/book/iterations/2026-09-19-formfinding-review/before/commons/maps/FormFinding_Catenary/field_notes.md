# FormFinding_Catenary — field notes

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

- **Neither minimal surface can be picked up**, though the catenoid extends
  `XRToolsPickable`, the registry tags it pickable and `walked.md` says to move
  the rings. Both `.tscn` files are bare `RigidBody3D` roots, so they keep
  collision layer 1, Static World, and both VR grab masks exclude layer 1.
- **Nothing re-solves except the cable.** The catenoid, the helicoid and the
  laundry all build once in `_ready` and have no `_process`.
- **Sizes**: the catenoid is 1.21 m across and 0.36 m tall, low on the floor;
  the helicoid is 0.2 m across and 0.377 m high, six thousand triangles in a
  thing the size of a mug, in a slot between pillars.
- **The beads are grabbable** and at ankle height, and the cable's belly grazes
  the floor. That is the only interaction in the room.
- **Two of the three washing lines have no pole under either end.**
- **The screen misses by 0.66 m**: the laundry is the only name matching a scan
  keyword and it stands 8.658 m away against a scan radius of 8.0.
- `tutorial.md` describes the `spline` slack value, which this map does not set.
  `eye_shot.md` is stale by six weeks and reports an overlap that no longer exists.

## Open

- Reader landed and its findings are applied. Originally written before it returned: `cable_builder`'s spline-vs-true-catenary claim, the catenoid waist of 0.5 and the helicoid's two turns come from the exports; the reader should confirm the grab on the control points and whether the laundry ghost arches are built as claimed.
