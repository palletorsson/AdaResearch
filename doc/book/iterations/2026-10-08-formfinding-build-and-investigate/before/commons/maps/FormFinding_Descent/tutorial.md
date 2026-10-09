# One local update, several endings

**Learning elements**

- Cost functions
- Finite-difference gradients
- Search steps
- Stopping reasons

Primary: descent_landscape_lab. Ask for a predicted next position, press STEP, then RUN. Reveal PARTS and RULE after observing. RUN performs one discrete optimisation update per presentation interval of at least 0.22 seconds; there is no physical delta in the descent equation.

The parameter domain is x,z in [-3,3]. Bowl cost: 0.25*(x*x+z*z). Two valleys: 0.08*(x*x-4)^2+0.25*z*z+0.15*x. Central differences sample the analytic cost at offsets +/-0.03 along each axis. The drawing has 48 by 48 cells; height is 0.40+0.22*cost. Its surface has no collision; the pedestal does. The arrow shows negative gradient horizontally, capped at one metre.

Rates: 0.2, 0.7, 2.5, 5.0. Slope tolerances: 0.01, 0.08, 0.3. Starts: (-2.8,-2), (2.8,-2), (0,-2). Default rate 0.7 and tolerance 0.01. Settings reset the run; RESET preserves settings. PARTS and RULE reveal representations without resetting. STEP pauses continuous playback.

At each update, reaching 160 moves reports STEP LIMIT; a sampled gradient below tolerance reports SMALL SLOPE; a proposed address outside the domain reports LEFT FRAME without committing the move. Otherwise position changes by -rate*gradient and the trail gains a sample. No velocity, momentum, mass or gravity participates. At most 161 samples are retained in a reused ImmediateMesh.

Compare first and second starts on two valleys: observed final costs -0.304257 and 0.295496 with identical rate/tolerance. Compare loose versus tight tolerance on the bowl. Large finite steps can increase cost or leave the domain despite following a locally descending direction.

Five earlier exhibits remain secondary. The marble toy retains velocity and periodically receives random kicks; it is not a hand-tipped rigid marble or this optimiser. Legacy gradient_descent is scaled to 0.14 and raised 0.8 to contain its original 20-metre surface in a side exhibit. The well has momentum and multiple starts. Science Screen has not been connected to the new lab; the lab has its own display. Do not claim those exhibits share a single solver or stopping rule.
