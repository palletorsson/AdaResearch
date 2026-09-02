# FormFinding_Descent — field notes

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

An agent read all five scripts and overturned five things in the first draft,
all now fixed in the text:

- **The room is inside one artifact.** `gradient_descent` builds a 20 m terrain
  in a room 14.7 × 12.6 m, so it swallows the walls, the spawn and the exit —
  and it has no collision, so you walk through the hillside.
- **Nothing in this room can be touched.** All five artifacts grepped for
  Area3D, StaticBody3D, CollisionShape3D, RigidBody, XRTools nodes and _input:
  zero hits. The registry's "a HELD marble-in-a-bowl" and the identity's "TIP IT
  and the marble rolls" are both false.
- **`settling_tremble` does not tremble.** No `_process`, no tween: 177 lines
  that draw the amber catenary and seventeen scattered blue nodes once, from a
  fixed seed. It is a wall chart of the tremble, which the text now says.
- **The screen finds nothing.** No `#mode:` token, so it auto-scans, and not one
  of the four neighbours matches any predicate. It stands lit and empty, facing
  away from the entrance.
- **There is no `intent.md` in this map directory** — only blurb, tutorial,
  walked, eye_shot and map_data. Anything quoting a "Concept:" line for this
  room is quoting a file that does not exist.


## Open

- The 20 m terrain in a 14 m room is a real placement fault, not just a writing problem. Worth a ruling: shrink `grid_size`, or give the room to the artifact.
