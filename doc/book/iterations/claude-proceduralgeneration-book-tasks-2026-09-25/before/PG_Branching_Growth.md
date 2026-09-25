# One nearest invitation

<!-- @branching_growth_algorithm -->

Eight points wait. You have met their arrangement in Space Colonization. There, several requests could contribute to a direction. Before pressing STEP here, find the nearest point to the root. Does the branch listen to the others?

The first segment leans left. In local coordinates the nearest target is (-2, 1.5, 0), two and a half metres away. Normalizing its direction and taking a half-metre step gives (-0.4, 0.3, 0). We can predict this small displacement before we have a tree to admire.

The running program searches unreached attractors inside `attraction_distance`. Each active branch site chooses the nearest one. Its construction begins with:

```gdscript
var direction = (attractor.position - branch.position).normalized()
```

That direction receives optional jitter. A pulsing multiplier can change the segment length. The opening suppresses both so that we can distinguish the choice of target from these additional variations. Press TEN STEPS. It performs ten calls to the same growth operation, without making you hold a button for every generation.

Now compare the readout's records with its distinct positions. They need not agree. Older active sites can produce another child; with no variation, an old site can choose the same target and put that child where it put the last one. Several records may occupy one place. A count of parents with multiple children therefore tells us about the stored tree, not necessarily about visibly separate branches.

This is a useful failure of our first description. We said a branch had appeared; the database agreed. The space may have acquired nothing new. The remainder is not always an extravagant shape. Sometimes it is redundant work concealed by a familiar outline.

Press HOLD to keep a separate mesh witness, displayed at 0.4 scale beside the desk. Then press VARIATION. The root and eight targets return, with jitter and pulsing enabled. Advance again. These settings can separate previously coincident paths, but their presence does not make a biological explanation. They are explicit additions to a directional rule. RESET removes those variations and starts the comparison again; the witness remains.

The museum study caps the record count at 192. The counter includes coincident children. That limit tells us something about what this program spends, not how mature its tree has become. RULE reveals the operation after you have had a chance to follow it.

Keep the nearby organic_space in view. It obtains an organic appearance through a different construction: geometric shells, tunnels and detail. A resemblance does not establish a common method. We are learning to ask what a form did to become available, rather than treating its appearance as its explanation.

Neither a parent record nor a drawn line has yet made a passage for us. In Percolation, next, we ask a narrower question first: under a stated rule of contact, what can reach what?

<!-- @ -->
