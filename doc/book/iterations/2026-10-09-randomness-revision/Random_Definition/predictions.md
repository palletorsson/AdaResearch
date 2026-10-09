# Predictions saved before execution

RGB: identical procedures give equal panels, 48 draws each. One discard changes only the right panel: first colour uses draws 2,3,4, and generator ends after 49 draws. Replay must preserve the selected difference; waiting must not advance the study RNG.

Edited assignments: gray and red/blue swap retain the same draw counts. Transfer: side=2, seed=731, shifted right uses 13 draws; original instance stays unchanged.

Faults: resetting inside the cube loop destroys stream progression; discarding after colouring fails the shifted assignment even when the final draw count is correct.
