# What chance may change

Four works have returned to the gallery. Walk toward the painting on the floor, then take either side around its frame. The dartboard waits to the right, the pipes farther along to the left, and a changing particle study near the rear. Each gives chance a different job. The estimation the last room promised is the dartboard's job.

<!-- @pollock_painting_in_3d -->

Stand at the near edge of the canvas. Find a thin line, a broad mark and a cluster of small splatters. Wait for another layer, then follow the brush cursor as it traces a path. Walk around the frame. A mark that was distant is now close enough to inspect.

This is a Pollock-inspired generative homage, not a reconstruction of a particular painting. The program chooses positions, colours from a fixed palette, drip sizes and line widths. A line begins with a sampled direction, then turns by small sampled angles as it advances. At an edge, the direction reflects back toward the canvas. Chance can bend the route; it cannot enlarge the canvas or invent a colour outside the palette.

The marks are painted into a two-dimensional image shown on the floor. When a new layer appears, the small three-dimensional cursor retraces the path of one of its lines, which is already painted. It replays a procedure; it is not a brush whose movement you are controlling, and the drops are not a simulation of falling paint.

Choose a passage you like. Which part could have arrived differently? Which part was already decided by the palette, line rule, canvas and interval between additions? Calling the result random can make those authored choices disappear from view. The work becomes more interesting when we keep them visible.

<!-- @monte_carlo_dartboard -->

Move to the dartboard's console on the right. Press RESET. If new marks appear, press AUTO to pause them and RESET again. Press THROW and find the new point. Compare its location with the circle, then check which counter changed. Add a few more points individually before using AUTO to build a larger sample.

An inside point increases both the inside count and the total. An outside point increases the outside count and the total; the inside count stays where it was. Before requesting another point, predict what each possibility would do to the estimate. Check with THROW, and explain the change from the counters before looking at the distance from pi.

The circle is inscribed in a square. When points are sampled uniformly across that square, the fraction landing inside estimates the fraction of area occupied by the circle. Multiplying that fraction by four gives the displayed estimate of pi:

`estimate = 4 × inside / total`

A growing sample does not require every new estimate to improve. Repeat the prediction when many points are already present: one addition usually changes the ratio less. A steadier number still depends on how the points were sampled.

THROW requests a generated sample. You are not aiming a physical dart with your hand. A sampler that favoured the centre would tend to count too many points inside; adding more of those points would not repair the bias. Pause AUTO and RESET to compare another run. The counters stop at 500 darts, so RESET also begins a new sample once the count has filled. The board itself shows only the newest 300 marks: past that, the picture forgets points the numbers still include.

Here chance chooses the evidence. The circle's boundary and the counting rule remain fixed. Who gets to decide that the sampling procedure covers the space fairly enough for the answer we want?

<!-- @pipe_dream -->

Cross to the pipe study on the left. Follow a length to its next corner, then look for a place where the path doubles back near an earlier passage. If growth has finished by the time you arrive, the whole retained path is still available to inspect. The colour shifts gradually from one length to the next, swinging between cyan and magenta twice over the run, so two neighbouring passages in clearly different colours were not laid one after the other: the pipe came back to that place later in the run.

The pipe advances in one of six axis directions. A preference sometimes keeps it moving straight; otherwise the program shuffles possible turns and takes a direction that stays inside its bounds. It rejects an immediate reversal. It does not keep a list of occupied cells, so crossing an earlier route is allowed.

The default run stops after 180 segments. A dense tangle therefore does not certify that the volume has been filled, or that every corner was reached. The limit ends the run whether or not its shape looks complete to us.

Look across the empty spaces between pipes. The same local rules could have left different gaps. What would change if a previous visit made a place forbidden? That would add a memory and a new restriction, not merely turn up the amount of randomness.

<!-- @extreme_randomness -->

The particle study occupies the last bay on the right. Stay through a full cycle. Its five chapters change about every ten seconds. Watch for a change in the particles' arrangement as well as their movement; the chapter transition restages them.

For this gallery, every chapter stays inside the same spherical boundary. A particle that would escape is brought back to the edge and its outward velocity reflected. This added limit keeps the changing study above the floor and within its bay.

In the first chapter, random forces change velocities that persist from one frame to the next. Damping slows them, and a boundary turns escaping particles back. Successive positions retain a history. They are not independent points redrawn across the whole volume.

The noise chapter follows a smooth field made from sine and cosine functions in this implementation. No random draw enters that motion, and its caption says it is not Perlin noise. The last room's coherent heights changed with SEED; this field has no seed to change. The pattern chapter adds spiral motion and oscillation to its opening arrangement. The emergence chapter combines separation, alignment and cohesion with small random nudges. The evolution chapter ranks particles by their distance from a moving target; the leading tenth influence the others.

These are five sketches of different procedures, not five strengths of the same white noise. Nor is the final chapter a population that breeds: the same fixed set of particles keeps moving under a selection rule. A title gives us a starting question; the update rule tells us what is actually happening.

<!-- @ -->

Look back toward the painting. In one work, chance chose marks; in another, samples to count. It chose permitted directions for the pipe and different kinds of variation within the particle study. In every case something decided what a random choice was permitted to change.

Carry that question into the pheromone terrain. The pipe did not remember which places it had passed; the next walkers will leave a signal that can enter a later decision. What changes when a visit helps recruit another visit? Random Game still waits ahead, where such distinctions will become questions of support and timing.
