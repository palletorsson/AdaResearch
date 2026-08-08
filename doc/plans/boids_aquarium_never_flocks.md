# boids_aquarium never flocks — WITHDRAWN, THE CLAIM WAS FALSE

**Status:** RETRACTED 2026-08-08, same day it was filed. The artifact is fine.
**Kept** rather than deleted, because how the claim was made is the useful part.

## What was claimed

That `boids_aquarium` has no `_process` and no `_physics_process`, that nothing integrates
velocity, and that its identity block promises motion the implementation cannot deliver.

## What is true

`boids_aquarium.gd` has a `_process(delta)` at **line 752**. It calls `_update_boids(delta)`,
which is a complete Reynolds implementation over a spatial hash — separation, alignment,
cohesion, speed limiting, Euler integration, boundary bounce — and then `_update_multimesh()`.
The school flocks. Photographed three seconds apart, every boid is in a different place.

## The two errors, because they are different mistakes

**1. A truncated read presented as a whole one.** The grep that produced "no `_process`" was
piped through `head -20` and stopped at line 564. `_process` is at 752. The output was
consistent with the claim only because it was cut off before the evidence. Nothing about the
command said so; the number 20 did all the damage.

**2. An instrument that could not see a small mover.** `temporal_lint` thresholded on the
FRACTION OF THE FRAME that changed. Thirty boid specks, a few pixels each, inside a large
glass tank change 0.14% of a 640x640 frame while changing *completely*. The verdict said
"stable" and the number was correct — it was measuring the wrong thing.

The tell was there and unread: **max delta 164**. A genuinely stable artifact differs by a few
levels of sensor noise. Anything that moved leaves pixels differing by a lot, however few.
`temporal_lint` now counts pixels differing by more than 60 and reports it beside the
fraction; `boids_aquarium` reads MOVES, and the four artifacts that really are stable still
read stable.

## Why the second error was likelier than it looks

Every check written this week — `render_lint`, the A/B sheets, the bite critic — expresses its
answer as a percentage of frame. That unit is right for an artifact that fills its frame and
wrong for a small part inside a large housing, which is a common shape here: an instrument in
a cabinet, a readout on a rack, a school in a tank. The unit was inherited without being
questioned.

## What survives

- `random_transformations` really was rebuilding itself 90 times a second, and is fixed.
- `line_builder_3d` really did roll a fresh material every frame, confirmed in source, and its
  own comment admitted it while pinning only the measurement branch.
- The instrument is real and now has one more axis than it did.

The finding that produced this document was wrong. The two fixes it sat next to were not.
