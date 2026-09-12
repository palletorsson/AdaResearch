# Random_Walk — Summary

What does a trail remember that the next step does not use? Coming in from the north door, a visitor finds a dark cabinet on the right with a glass tank on top, its keypad turned toward the door strip and a wing bolted to its far side carrying a plate of text. Five beads drift in the tank; one is red, four are dimmed grey, so a single trail can be followed before the population is read. The keypad says 2D, 3D, LEVY and RESET. The wing's plate keeps six lines: the rule and its dimension, steps and the simulation time they add up to, the frame clock beside it with the catch-up cap, how much trail is kept and who is followed, the seed and what RESET does with it, and the glass rule. Beside the plate, ONE, ALL and NEW SEED.

Watch the red bead for a dozen steps, predict the next one, and watch the prediction fail at the rate chance sets. Press 2D and the beads stay in the tank's middle plane; 3D frees the height; LEVY keeps the direction rule and draws a length as well, most steps as short as before and about one in eighty a leap of several step-lengths, never more than ten. RESET redraws the same walk from the middle because the seed is named and re-seeded first; NEW SEED names another. The glass folds an overshooting step back by the distance it overshot, so the walks stay bounded and the cabinet's mean squared displacement stalls at the walls.

## Spatial layout

- **Dimensions**: 13 × 14 cells, walls on the perimeter, doors at columns 5–7 on the north and south edges.
- **The ring**: forty-one platform cells a metre above the floor, the 10 September recovery's deck; unreachable on foot from the floor in the museum, a ledge round the arena.
- **The arena**: a 9 × 9 floor from (2,2) to (10,10). Until this hall was staged the arena was `0`, which the museum read as holes: a starry void with a one-cell strip of floor down column 7. It is floor now.
- **The route**: north door strip → the arena's west half (the lab room stands east of column 7) → the south door strip.

## Key elements

- **random_walk_terrarium** (4,1), facing east: the primary and the book's hero. The cabinet (0.92 m), the tank (0.5 × 0.4 × 0.5 m), the keypad at 0.78 m, the seated stats screen at 0.57 m, and under `#stand:logbook` the wing with its plate at 1.03 m and three buttons at 0.76 m.
- **random_walk_128** (3,4), at a fifth of its size: a two-metre floor drawing of six-centimetre cubes rising where a lattice walk has visited, west of the route.
- **random_walk_collection** (3,7): a rack of grab papers, several walk laws side by side.
- **lab_room** (9,4): a Monte Carlo workshop — dice, a fishbowl with a walker's trail, scales, a running mean — whose signage no longer claims Gaussian steps.
- **random_walk_leash** (8,8): one walk in the hand.
- **dark_sphere** (5,7): a reference body.
- **pixel_cloud** (11,1), (1,11), (11,11): three self-avoiding walks built as towers of one-metre cubes on the ring's corners.
- **catalyst_pickup** (6,10), **catalyst_vent** (9,0), **catalyst_prompter_box** (2,0): the bracelet sequence; the vent stays silent until the bracelet is taken.

## The encounter

1. Enter from the north; the cabinet is on the right, the keypad toward you.
2. Follow the red bead; predict; watch. Read the plate: steps, simulation time, the clock, the trail kept.
3. 2D against 3D under the same fixed step; then LEVY against 3D under the same dimension.
4. RESET: the same walk again, because the seed is named. NEW SEED: another. ONE and ALL.
5. Find a bead at the glass; compare its next positions with one in the interior. Find a doubling-back and look for the wall behind it.
6. Under 3D, find an apparent crossing and step to the side of the tank.
7. Walk on: the floor drawing, the rack, the workshop, the leash, the south door.

## Connection to the sequence

Random_Definition made an arrangement repeatable from a seed; Random_Entropy showed a number keep the shares of a sample and lose its order; Random_Remove showed chance acting inside a set a rule chose first. This room turns the changing set into a path — the places a walker can reach are decided one draw at a time and again at every wall — and separates the step, the accumulated position and the stored drawing. Random_Gaussian takes up the distribution of many draws.

## Historical context

Robert Brown watched pollen grains jitter in water in 1827 and could not say why; Einstein's 1905 account made the jitter evidence of molecules. Karl Pearson posed "the problem of the random walk" in Nature the same year: a man walks l yards, turns through any angle, walks l yards again. Pearson's walker takes fixed-length steps in random headings, which is exactly the tank's 2D rule; Brown's grains are the Gaussian case the lab room's old signage borrowed. The room keeps the two apart.

## QFEP connection

Entropy enters at every step and the state persists as a sum: complex trajectories without design. The room's addition is the observer's share — the trail that makes the complexity visible is the display's record, not the walker's, and the sense of purpose it produces is the reader's contribution. What the trail remembers, the walker never knew.

## Sources

- Brown, R. (1828). "A brief account of microscopical observations."
- Einstein, A. (1905). "Über die von der molekularkinetischen Theorie der Wärme geforderte Bewegung von in ruhenden Flüssigkeiten suspendierten Teilchen."
- Pearson, K. (1905). "The Problem of the Random Walk." Nature 72.
- `commons/artifacts/random_walk_terrarium/random_walk_terrarium.gd`; `commons/maps/Random_Walk/field_notes.md`.
