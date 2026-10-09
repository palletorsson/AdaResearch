# Random_Definition — Summary

The Randomness sequence opens with a pattern that returns. The room is a 13×22 hall; near its far end two short raised platforms flank the sequence's catalyst pickup, restored as one-metre decks by `museum.wall_height: 3` (they are interior `2` cells, built as two-cube stacks by the standalone grid).

The primary encounter is `seed_replay_demo:0:-0.5#comparison:replicas`: two 8×8 grids of coloured cubes built from the same seed and the same draw order, a seed slider, and three buttons — REPLAY, RANDOM and +1 DRAW. Under the headline the panel prints the draw count: 192 draws per grid, three per cell, row by row. REPLAY reconstructs; RANDOM picks a new seed from an artifact-local generator, so the game's global RNG is left alone; +1 DRAW makes the right-hand grid consume one value before colouring, so the same seed paints a different grid until the button is pressed again.

The lesson separates three things: how the grid looks (unpredictable), how it was made (a definite procedure), and what names the picture (the seed together with the generator and the draw order, not the seed alone).

Secondary: the PRNG crank machine, the TRNG/PRNG comparison, the entropy axiom, jar and butterflies, the 1955 RAND page, the slot machine, the glitch specimen and the science screen. The catalyst pickup is labelled RANDOMNESS CATALYST. The next room, Random_Entropy, asks what one number can retain from a sequence.
