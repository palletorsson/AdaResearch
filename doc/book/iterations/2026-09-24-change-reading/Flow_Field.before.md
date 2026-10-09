# A path made by its next step

Where will this particle look next?

In the previous hall, we chose addresses along a fixed interval, measured changes, and added contributions. Here an update changes a particle's position. That position becomes the address used by its next update. The loop starts making its own route through the field.

<!-- @flow_field_painter -->

Begin with the little canvas. Eighty particles leave coloured trails. Follow one through a bend before trying to read the whole picture. Do its neighbours continue beside it? Predict the next turn.

The display says **FIELD HELD**. The particles are moving, but the field's time coordinate is held still. Press **ARROWS**. Twenty-four arrows appear over the canvas. Find one near a particle and compare their directions. An arrow gives the instruction at its own address; a particle a little farther away samples a different address. They need not point exactly alike.

The arrows and particles call the same function. The particle update can be condensed into this teaching sketch:

```gdscript
var direction = field_direction(position)
position += direction * speed * delta
```

The sum has begun to move. At the accumulation bench, the loop added a height times a width. Here `direction * speed` is a velocity: how fast, and which way. `delta` is the time since the previous frame, in seconds. Their product gives a displacement to add to the position.

The clock has entered the calculation. For this small interval, the program treats the sampled direction as fixed. Then it asks again at the new position. What changes if the interval spans a bend? The accumulated answer chooses the next address, and the trail remembers a limited sequence of those answers. It cannot remember an infinitely detailed movement between them.

Keep SCALE fixed and move SPEED. What changes about the spacing of the samples? Now keep SPEED fixed and change SCALE. Look at the arrows as well as the trails. You have changed how the directional rule varies across space. Existing trails still contain earlier instructions, so give the particles time to replace that history, or use RESET.

The field starts from a noise value: one number at each address. Here noise gives us smoothly varying values across space, with the same address returning the same value while the field is held. The program turns that value into an angle, then takes its cosine and sine to obtain a unit direction. That turn can be written as:

```gdscript
var angle = noise_value * TAU * 2.0
var direction = Vector2(cos(angle), sin(angle))
```

That construction makes a vector from a value. It does not calculate the noise function's gradient. A gradient would require measuring spatial changes in that scalar value, returning us to the first hall's question about rates. Similar-looking swirls can conceal different operations.

Press **FIELD TIME**. The field's time coordinate now advances too. The arrows refresh ten times per second while particles update every rendered frame. Can an arrow appear to lag a nearby turn? The shared rule is real, and the display still has a sampling schedule. Press again to hold field evolution at its current time; particles continue moving.

RESET scatters new starting positions and clears their trails without choosing a new noise seed. SEED chooses a different noise field and resets the particles. Neither button rewinds every clock. Distinguish a new starting distribution from a new rule before comparing their pictures.

Watch an edge. A particle leaving one side wraps to the opposite side. A long stroke across the canvas can be the trail renderer joining its last position before that wrap to its first position after it. The line suggests a crossing the update did not make. We have encountered another gap between an operation and its picture.

<!-- @ -->

What kind of body can exist here? This particle has a position and receives a prescribed direction and speed. It has no mass in this calculation, no accumulated velocity and no collision negotiation with the other particles. Its neighbours can influence what we see without influencing how it moves.

The opposite edges are joined by the wrapping rule. Directions on those edges are not guaranteed to match: the noise is not made periodic merely because the particle's coordinates wrap. A world can provide a return route and still contain a seam. Follow one return and look for it.

The pattern may recall a fluid. Its beauty invites that association; the code lets us ask how far the association holds. Changing a boundary rule or adding interactions would permit other kinds of movement, and ask for other quantities to be stored.

In **Forces**, we will distinguish a prescribed direction from an acceleration that changes velocity. A body will carry more of its previous motion into the next update. What possibilities appear when it cannot simply take the new direction immediately?
