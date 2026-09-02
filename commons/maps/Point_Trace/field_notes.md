# Point_Trace — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## The editorial read that shaped it (2026-09-02)

An outside read judged this the strongest of the first three rooms and
tightened the technical language. Everything below was taken, and two of the
points were outright errors of ours, not tightenings.

- **"Nothing in this room is transmissible" was false.** A trace is one of the
  most transmissible things there is (a GPS track, a mocap take). The sentence
  that replaced it is the room's fork: *the trace is transmissible as data and
  irrecoverable as event.*
- **"The residue the line erases" contradicted the room's own precise claim**
  two paragraphs earlier ("there is nowhere in a line for them to be").
  Erasure implies it was once there. Now "has no place to keep."
- **Sampling is not interpolation.** The loss happened when the samples were
  taken; the lines perform a second operation and *invent* what happened
  between them. The visible trace is part record, part fabrication, with no
  seam. This became its own paragraph and is the room's deepest point.
- **Even forgetting has a frame rate.** The 200-frame buffer is frame-based, so
  if the machine slows down, your past gets longer. Taken verbatim.
- **Derrida is nearby, not equivalent.** The computational trace is not the
  Derridean trace; the text no longer implies it is.
- **A digital whiteboard also samples.** The distinction is retention policy,
  not sampling versus not. Fixed.

## We were both wrong about 10 / 40 / 80

The reviewer said the code under the three "densities" was retention code, and
proposed a sampling-rate fix. Both wrong. `draw_dot.resolution_mm` is a
**spatial lattice pitch**, not a sampling rate; `min_segment_distance` (grain)
is the WHEN. So the three installations are one gesture told where it is allowed
to land, and 10 mm is the fine one, 80 mm the blocky one, the reverse of what
the first draft said. The truth is better: *the room you did not choose is
already in this one*; the grid is visible from inside the trace.

## The map moved to match the argument

The `resolution:80` installation stood at row 11, six rows from the others. Now
four in a row at row 5, coarsening as you walk: continuous, 10, 40, 80, then
`draw_stick`. Ink runs red → green → blue as the lattice coarsens.

## The chain

Event → measurement → sample → buffer → interpolation → visualisation →
archive. At every arrow something is kept and something is invented or
discarded. The room teaches `Array[Vector3]`; underneath it teaches that data is
what survived a sequence of decisions about what could count as having
happened. That sentence is a candidate for the sequence's own truth line.
