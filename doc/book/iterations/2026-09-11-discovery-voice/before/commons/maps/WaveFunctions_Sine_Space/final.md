# What the walls agree on

Two walls face each other across a passage and neither is straight. Enter at the west mouth and stop after a few steps. Is the passage narrow here because the left wall came in, or because the right one did?

<!-- @sine_wall_corridor -->

Look at the two surfaces separately before you look at the space between them. Each has crests about a step and a half apart, with a finer ripple riding on them. Choose a crest on the left and find the nearest crest on the right. They do not sit opposite each other; the right wall runs a little ahead. Now stand still for half a minute. The crests come toward you, slowly, out of the far mouth. You did not move. Walk to the panel at the mouth and press FREEZE, then walk the same stretch again. The frozen crests pass you because you move. Return to the mouth and run the walls again. Follow a small ripple across a broad crest: the layers do not travel together at one speed. Walking the frozen shape and advancing its phase can both bring a crest to you, but they do not carry the whole layered pattern in the same way.

Slide PHASE to the top of its travel. The walls now copy each other: where one bends in, the other bends out by the same amount, and the readout's gap reads 2.00 to 2.00 metres. The passage has become a snake whose two sides stay two metres apart along the local x axis. The readout calls this `x-gap`. It compares matching positions along the passage; it does not measure the shortest distance across a bend. Slide it back to the bottom. The walls agree, they bulge inward together, and the crosswise gap varies, roughly from 1.4 to 2.6 metres at this amplitude. The wall formula and its amplitude stay the same. The one number you changed is the offset between them, and it decides what kind of passage this is: a pinch or a swerve.

Each wall is one sum of three sines, and this is the line that adds one of them:

```gdscript
offset += base_amplitude * amp_multiplier * amp_mul * sin((base_frequency * freq_multiplier * freq_mul) * z_norm * PI + phase_shift + phase_layer)
```

`z_norm` runs from -1 at the west mouth to 1 at the east. The fundamental layer makes 4.5 cycles over seven metres: a spatial wavelength of about 1.56 metres. The other layers add more crests. The caller supplies the current `phase` as `phase_shift` for the left wall, and adds the PHASE offset for the right. That running phase advances at 0.35 radians per second, once in the formula, so the whole pattern repeats at a fixed position after about eighteen seconds. The second and third layers add the finer ripple at 1.8 and 2.6 times the spatial frequency. Then the sum is placed:

```gdscript
var x_pos: float = base_x - side * displacement
```

`side` is -1 for the left wall and 1 for the right, so a positive displacement moves either wall inward. An offset of half a turn flips the sign of every sine, which is why the walls copy each other there: one moves in by exactly what the other moves out.

Now bring AMP up. Both walls come in further, and at the top of the slider the narrowest gap is roughly 0.7 metres across the local x axis. Walk into the pinch. You pass through the crest. The wall is a surface drawn each frame from those two lines and it carries no collision; the floor of the passage is a slab a hair above the museum's deck, and that slab is what holds you up. A visible wall and a colliding wall are two different powers, and this passage has only the first. Put a hand through a crest before you trust one.

Press RESET and the declared values return, handles included. Then run the walls with PHASE at half a turn and stand in the snake. The bend crawls toward the entrance and passes through you without touching you, which is the whole of what a surface can do here.

<!-- @ -->

Below the bridge the older floor of spheres still rises and falls. That one is a product of two sines and it is under you rather than beside you; the remaining case in the antechamber's west nook offers a smaller view of the wall rule.

In the next hall the same rule is not laid along a passage but inside a sound: one oscillation changes the character of another, and the offset you slid here becomes something you hear.
