# What does the score notice?

<!-- @GeneticProgramming -->

Six boxes wait beyond the desk. One is pink. Before asking why it has been picked, choose a body you would want to keep. Perhaps the small one leaves more room around it. Perhaps you want the largest, though you have no use for it yet. Remember your reason.

We arrived here knowing how to rewrite a description and build from it. Now the program adds a judgement. Each candidate has a genome: a list of primitive names and parameters. A builder reads that list to make the visible body. An evaluator reads it to produce a number. These readers can notice different things.

Press HOLD. The current leader appears on the side plinth, a copy that will stay while the population changes. HOLD keeps the numerical leader; it cannot yet keep whichever candidate you preferred. That is already one limit of this instrument. Your other choice must remain in memory.

Now press TARGET. The number changes from 8 to 16. The boxes move into a different order and another becomes pink. Their descriptions have not changed; the generation counter has not advanced. The held box waits where you left it. What has happened to its claim to be best?

The label below each candidate reports an estimate and a score. With target 8, the box at scale 1 had estimate 8 and score 100. At target 16, the box at scale 1.25 leads: its estimate is 15.625 and its score about 72.73. The larger score means closer to the current target. It does not mean larger, older, more complex or more desirable.

Here is the comparison in the running source:

```gdscript
var volume = estimate_volume(genome)
fitness = 100.0 / (1.0 + abs(volume - target_volume))
```

Subtract the target from the estimate. `abs` keeps the distance without its sign: being one unit above or below incurs the same difference. Adding one prevents division by zero. An exact match scores 100; a difference of one scores 50. This is what fitness means in this room. We can inspect it without agreeing that it measures what we value.

Press RING. A loop appears on the leader. Look through its opening, then back at the score. The body acquired a conspicuous part. The number did not move.

RULE exposes the seam. The builder knows how to draw a torus. The volume estimator has cases for spheres, boxes and cylinders, and no case for a torus. The ring reaches the image but contributes nothing to this score. Removing it with RING leaves the score unchanged too.

Even the counted box asks for another look:

```gdscript
total_volume += scale.x * scale.y * scale.z * 8.0
```

The renderer starts from a unit box, but this estimate multiplies its scale product by eight. It also adds contributions without subtracting overlaps. The label therefore reports the program's proxy, not a measured volume of the completed solid. The missing ring is a defect we can name and repair. For the moment, holding it visible lets us see exactly where the two descriptions part company.

Leave the ring in place and press STEP. The generation advances. Two leading descriptions are copied unchanged; four more places are filled through parent selection, possible crossover and mutation. Each parent is the best of three random draws from the population. A draw can encounter the same candidate again. Selection gives some descriptions more chances to continue; it does not inspect the reason you gave for your first choice.

Find the ring again. An elite copy can carry it into the next generation although it earned no points. Survival does not tell us that every surviving feature was rewarded. The held witness still records the earlier box. RESET restores the six opening boxes and target 8, leaving that witness on its plinth. The opening is repeatable; later offspring depend on random choices and need not repeat.

Walk beyond the study and take the side ramp onto the raised structure. These decks carry you because the museum supplies their collision shapes. The generated candidates have no such support. A form can score well without offering a place to stand. To select for inhabitation we would have to construct and test that relation: an opening, a surface, a particular body attempting passage.

What would your earlier choice ask us to add? A different measurement, another representation, or permission to keep something without justifying it to the score? The question remains useful after this particular omission is fixed. In Space Colonization, next, the target becomes a distribution of points. We will follow the directions they request before changing which growing sites can respond.

<!-- @ -->
