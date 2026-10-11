# A path made by its next step

<!-- @flow_field_painter -->

A coloured line bends across the large wall screen. At its leading end, a particle keeps moving. Choose one and stay with it while its neighbours spread into the picture.

A label above the screen says FIELD HELD. Something is held still here, but it is not the particles.

Press **ARROWS**. Directions appear across the canvas. An arrow stays at its address while a particle passes nearby. The particle asks for a direction where it is now, moves a little, then asks again from the place it has reached.

The bridge and the benches before it read addresses chosen along an interval. Here the calculation can be condensed into two lines:

```gdscript
var direction = field_direction(position)
position += direction * speed * delta
```

The second line changes the input to the first. Read them again with that new position. A route begins without a list of destinations.

`direction * speed` gives a velocity: how fast, and which way. `delta` is the time since the previous frame, in seconds. Multiplying by that small interval gives the displacement added to the position. The clock has entered the sum.

During each step the program uses the direction sampled at its beginning. Then it looks again. Raise SPEED while leaving SCALE alone. Longer steps cross more of the field before the next reading. The arrows have stayed where they were, but the particle is visiting a different sequence of addresses.

The trail lets us follow what those questions produced. It keeps a limited number of positions, joining them into a line. Older positions leave as new ones arrive. The particle needs its present address to continue; the recent past is kept for us to look at.

## Where a direction comes from

The field supplies one noise value at each address. With its time held, the same address returns the same value, and nearby values vary smoothly. The program turns each into an angle, then obtains a direction from that angle:

```gdscript
var angle = noise_value * TAU * 2.0
var direction = Vector2(cos(angle), sin(angle))
```

`TAU` names a full turn in radians. Cosine and sine give the two components of a unit direction. We will return to the circle that makes this possible in Wavefunctions, and to the noise supplying the values later still.

For now, look at what the conversion chose. This particle does not compare neighbouring values to find a downhill slope. It receives an angle made from one value. A similar-looking swirl could have come from another rule.

A gradient would instead describe how that scalar value changes across space. We would return to the first hall's question about rates, now asking it in more than one direction.

Change SCALE. The directions now vary across space differently. The existing trails still carry the earlier arrangement; give them time to leave the picture. Or use RESET to scatter new starting positions and clear their trails. RESET keeps the field's seed; SEED chooses another field as well. Changing a beginning and changing what waits there are different interventions.

Press **FIELD TIME**. Now the field changes while the particles move through it. A particle returning to an address can receive a different direction. Press again and the field holds at this later moment. Movement continues through what it has become.

## The edge returns you

Watch a particle reach the frame. It leaves one side and returns on the opposite side. The boundary has been made into a connection.

A long stroke can suddenly cross the canvas. The recorder has joined the last position before the wrap to the first one after it. Its line suggests a journey through the middle that the particle did not make. The same drawing operation that helped us follow a bend has drawn across this jump too.

![Arrows and particle trails on the wall monitor inside the Flow Field hall](/book-images/figures/change/flow-field-wall-monitor-museum.png)

*The arrows keep their places. Long strokes across the canvas join positions on opposite sides of its frame.*

Opposite edges are joined for movement, but their field values need not match. Follow a return and look for a change of direction. A world can provide a return route and still contain a seam.

<!-- @ -->

Elsewhere in this hall, two arrow displays, a particle swarm and steering agents offer other ways to follow a field. The Grand Zoetrope puts twelve poses around a turning drum. Compare its repeated return with a particle’s path across the canvas.

Back at the canvas, the trails can suggest a current from a little distance. Come closer and follow two particles passing near one another. Neither has to make room. They read the field without reading each other; their proximity changes the picture without changing their instructions.

What would it take for one to disturb another's route? We would have to give the neighbour a part in the next calculation. The flowing image makes that possibility tempting before the bodies possess it.

There is another relation missing from their movement. Each new direction replaces the last; no accumulated velocity resists the turn. Later in Forces, a push will end and a cube will keep going. Something it received earlier will still be crossing the room.
