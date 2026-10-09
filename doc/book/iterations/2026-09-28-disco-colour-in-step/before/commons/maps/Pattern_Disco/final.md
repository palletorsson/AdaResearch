# The same floor, another palette

Do you recognise the floor in its new colours?

The layout is familiar: the same twelve-by-twelve floor, the same console near the entrance, the same sequencer beside it. Before Colour, black and white made a checker, a travelling row, diagonal bands, a snaking passage and the turning combinations of SUPER TRIANGLE. Those rules have returned. Their values can now wear another palette.

<!-- @disco_controls -->

Hold the floor and stop the sequencer. Choose CHECKER, then press COLOUR without changing anything else. Follow one tile through the palette choices. Does it still seem to belong to the same band? The binary value at its address is unchanged, but its relation to its neighbours may feel different.

The separation is small enough to find in the code:

```gdscript
PALETTES[palette][value_at(x,z,floor_node.grid_width,floor_node.grid_depth)]
```

For the square-cell patterns, the function returns zero or one. The selected palette supplies the colour at that index. This floor offers four pairs, including the old black and white. It is a deliberately limited instrument: two values, five pattern modes, four palettes. The choices make a comparison possible before we ask the next machines to author more.

Now leave the palette alone and change PATTERN. Then change SPEED. Changing the palette preserves the current phase. Changing the pattern starts that pattern at phase zero. The controls have different consequences; watch the step number as well as the image.

SUPER TRIANGLE lets the two colours meet inside a tile. Follow an edge as diagonals turn into chevrons and diamonds. Here a shader draws the divisions across the same floor, instead of giving each whole tile one colour. The palette still supplies the pair; the supporting floor stays where it was.

<!-- @standalone_disco -->

Start the floor and walk towards an approaching band. Let it pass underneath you. Its passage does not push your body. The tiles receive changing colours while the supporting surface remains in place. Can an invitation to move be felt without a force being applied?

Return to black and white while it runs. You have taken away a palette, not undone the rules you learned in Colour. Brightness, contrast, neighbourhood and attention are still at work.

<!-- @step_sequencer -->

Bring in one repeating note, then another. The sequencer owns its musical clock and briefly brightens floor columns when events arrive. It does not read your footsteps. The visual pattern has its own tempo; matching the two tempos is not a guarantee that their phases coincide. Listen while watching one chosen column, then look away and keep moving.

Holding the floor leaves the musical events active. Stop both instruments if you want a motionless comparison. Otherwise let them disagree. Is the disagreement distracting, useful, pleasurable? A regular score can support a movement that does not repeat it.

<!-- @ -->

The return has given us a way to distinguish an arrangement from its colours and from the time taken to read it. None of those choices has rebuilt the floor. In the Foundry ahead, we will make a source pattern ourselves and let the surrounding architecture receive it. The field will no longer end at our feet.
