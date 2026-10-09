# What the walls agree on

Two walls face each other across a passage and neither is straight. Enter at the west mouth and stop after a few steps. Is the passage narrow here because the left wall came in, or because the right one did?

<!-- @sine_wall_corridor -->

Look at the two surfaces separately before you look at the space between them. Each has crests about a step and a half apart, with a finer ripple riding on them. Choose a crest on the left and find the nearest crest on the right. They do not sit opposite each other; the right wall runs a little ahead. Now stand still for half a minute. The crests come toward you, slowly, out of the far mouth. You did not move. Walk to the panel at the mouth and press FREEZE, then walk the same stretch again. The crests pass you again, now at exactly the speed you walk. There are two ways for a crest to arrive, a change in where you are and a change in the rule's phase, and the passage looks the same under both.

Slide PHASE to the top of its travel. The walls now copy each other: where one bends in, the other bends out by the same amount, and the readout's gap reads 2.00 to 2.00 metres. The passage has become a snake of constant width. Slide it back to the bottom. The walls agree, they bulge inward together, and the gap breathes between about 1.45 and 2.55 metres. Same walls, same amplitude, same spacing of crests. The one number you changed is the offset between them, and it decides what kind of passage this is: a pinch or a swerve.

Each wall is one sum of three sines, and this is the line that adds one of them:

```gdscript
offset += base_amplitude * amp_multiplier * amp_mul * sin((base_frequency * freq_multiplier * freq_mul) * z_norm * PI + phase + phase_shift + phase_layer)
```

`z_norm` runs from -1 at the west mouth to 1 at the east, so `base_frequency`, 5.2 here, is the number of crests along the eight metres, not a rate in hertz: a crest every 1.54 metres. `phase` is in radians and advances at 0.35 radians per second while the walls run, which is why a crest takes about eighteen seconds to give way to the next. `phase_shift` is zero for the left wall and the PHASE offset for the right. The second and third layers add the finer ripple at 1.8 and 2.6 times the spacing. Then the sum is placed:

```gdscript
var x_pos: float = base_x - side * displacement
```

`side` is -1 for the left wall and 1 for the right, so a positive displacement moves either wall inward. An offset of half a turn flips the sign of every sine, which is why the walls copy each other there: one moves in by exactly what the other moves out.

Now bring AMP up. Both walls come in further, and at the top of the slider the narrowest gap is about three quarters of a metre. Walk into the pinch. You pass through the crest. The wall is a surface drawn each frame from those two lines and it carries no collision; the deck under you is the museum's, and it is what holds you up. A visible wall and a colliding wall are two different powers, and this passage has only the first. Put a hand through a crest before you trust one.

Press RESET and the declared values return, handles included. Then run the walls with PHASE at half a turn and stand in the snake. The bend crawls toward the entrance and passes through you without touching you, which is the whole of what a surface can do here.

<!-- @ -->

Below the bridge the older floor of spheres still rises and falls. That one is a product of two sines and it is under you rather than beside you; the cases in the antechamber's corners show both rules small enough to hold.

In the next hall the same rule is not laid along a passage but inside a sound: one oscillation changes the character of another, and the offset you slid here becomes something you hear.
