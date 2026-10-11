# The same floor, another palette

Do you recognise the floor in its new colours?

The checker is navy and pink now. Its twelve-by-twelve squares return in the same arrangement. Step onto one and wait for its colour to change. It keeps supporting you. After the coloured rooms, this familiar floor gives us somewhere to try what we have learned.

<!-- @disco_controls -->

Hold the floor and stop the sequencer. Choose CHECKER, then press COLOUR. Keep your eye on one square as the palette changes. Its neighbours change with it. Which colour seems to come forward? Does your chosen square still seem to belong to the same figure?

Nothing has moved, and the square's calculated value is still the same zero or one. Press ONE STEP. Now those values exchange places across the checker, while the palette stays fixed. Return to the previous arrangement with another step, then change COLOUR again. You have two ways to change what you see.

The separation is small enough to find in the code:

```gdscript
PALETTES[palette][value_at(x,z,floor_node.grid_width,floor_node.grid_depth)]
```

For the square-cell patterns, `value_at` returns zero or one for the address `x,z`. The first pair of brackets selects a palette; the second selects one of its two colours. A square can keep its value and receive another colour because we have changed the pair it draws from.

![Two palettes on the same held checker, seen from the same place on the museum floor.](/book-images/iterations/2026-09-28-disco-colour-in-step/checker-pair.png)

In the earlier palette grid, you could leave one square changed. Here one choice reaches every square carrying the same value. The four pairs are prepared for us, including black and white. We can choose among them, but this console does not let us give a single square a colour of its own. The reach of a choice belongs to the way the tool has been made.

Leave the palette alone and change PATTERN. ROWS, DIAGONALS and SNAKE return from the earlier floor. COLOUR preserves the current phase. PATTERN starts its new arrangement at phase zero. SPEED changes how long a step takes. Try following one band through a slower and a faster passage.

After SNAKE comes SUPER TRIANGLE. The two colours can now meet inside a square. Hold it during a turn, when the diagonals have not yet settled into chevrons or diamonds. Change COLOUR there. The unfinished turn stays unfinished. Does the same edge still draw your attention?

A shader draws these divisions across the existing floor. Its palette supplies the two colours, while its movement changes how they meet. The square joints remain beneath the larger figures your eye can follow.

<!-- @standalone_disco -->

Start the floor and walk towards an approaching band. Let it pass underneath you. Its passage does not push your body. Walk with it for a moment, then across it. Can an invitation to move be felt without a force being applied?

Return to black and white while it runs. The paired values are familiar again. Notice whether you follow the same parts of the pattern. Changing back cannot undo the coloured versions you have just seen beside it.

<!-- @step_sequencer -->

Bring in one repeating note, then another. Watch a chosen column brighten briefly when a sounding step reaches it. Hold the floor's pattern and listen: the notes continue, and their flashes can still appear. Stop the sequencer too when you want both instruments to settle.

The score has its own clock; the moving pattern has another. Even at the same tempo, they can reach their beginnings at different moments. Let them run for a while. Look away from the floor and keep moving. When you look back, where do you find the beat?

Your footsteps are not written into the score. You can move with a pulse, miss it, or keep another rhythm across it. The room can repeat its invitation without knowing what you make of it.

<!-- @ -->

We have been choosing among patterns and palettes already offered. In the Foundry ahead, we can change the source that the copies draw from. What would you put there for the room to repeat?
