# The half the colour throws away

Is the restless thing a field, a surface, or our way of reading it?

<!-- @noisetorus -->

Two rings stand on a bench, the same size, the same stone-grey posts, side by side. They are wearing the same shader and sampling the same field at the same scale. One of them is allowed to spend that field as relief, and the other is allowed to spend it as colour, and neither is allowed to do both.

Look at the coloured one first. It is banded — red where the field is high, and black in wide patches between. Now look at the other: a pale ring with a corrugation running round it, ridges and hollows, no colour at all. They do not look like readings of the same thing, and that is the room's question rather than its failure.

A small lamp stands on each ring at the same coordinate of the field. Press SAMPLE and both lamps step round together. The plate reads:

    sample  x +0.261  z +0.329   field value +0.370
    relief  +0.007 m of surface
    colour  brightness 0.370 of the hue

One value, spent twice. Step round to another coordinate and the plate will eventually say something else:

    sample  x -0.095  z +0.409   field value -0.562
    relief  -0.011 m of surface
    colour  black — the reading clamps at zero and loses this half

There it is. The field runs from minus one to plus one. The relief spends the whole of it, pushing the surface outward where the value is positive and inward where it is negative. The colour cannot: brightness has no negative, and the shader multiplies the hue by the value, so everywhere the field is below zero the ring goes black and stays black however far below zero it goes.

```glsl
    vec3 displacement = NORMAL * noise_value * height_multiplier * show_relief;
```

```glsl
    ALBEDO = mix(plain_albedo, rainbow_color * noise_value, show_colour);
```

So the black bands are not places where nothing is happening. They are places where the reading has run out of room. Half of this field is invisible in colour and perfectly legible in relief, and neither ring is lying: they are spending the same number under different rules.

Press FREEZE. Both rings stop — and it is worth knowing exactly what that sentence covers, because this shader has two clocks. One moves the coordinate the field is sampled at; the other rotates the hue. A ring whose colours had stopped cycling might still be sliding its sample, and you would be looking at a still picture of a moving thing. Every use of time in the shader passes through one of those two speeds, and FREEZE sets both to zero, so the value under the lamp does not move while you walk round the bench and look at it from the other side.

Then the two remaining buttons, which are not the same kind of thing at all. AMPLITUDE changes how much the surface does with the value: the corrugation deepens, the plate's `relief` figure grows, and the `field value` beside it does not move a digit. FREQUENCY changes the field: the same coordinate now holds a different value, both rings change together, and the plate says so. One of those buttons is a reading, and the other is the thing being read. The plate names which was touched last, in those words.

One more fact the room says out loud. The corrugation on the left ring lives in the vertex stage of a shader, and a collider cannot see a vertex shader. There is no collision shape on either ring at all. What you can see is not what you could touch, and a room that let you believe otherwise would have taught you something false about where a surface is.

<!-- @ -->

Noise Voxel follows, and asks the same value to make a harder decision than brightness or height: whether a place is occupied at all.
