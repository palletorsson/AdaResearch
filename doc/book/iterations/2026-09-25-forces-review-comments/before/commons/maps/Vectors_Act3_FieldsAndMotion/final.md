# The arrow does not decide

<!-- @VectorFieldFlow -->

Two small bodies wait beyond the controls. They share an address on the floor, one held a little higher so you can distinguish them. One is cyan, the other pink.

Press **RUN**. Both head inward. Watch the centre.

Cyan approaches and slows. Pink crosses it, keeps going, then begins to turn back. They started together. What did the second body bring through a place where the first was coming to rest?

Pause with RUN and reveal **TRAILS**. On the wall plan, both paths lie on one diagonal. Pink's extends beyond the centre, but its return draws over ground it has already marked. Start them again. A line can keep the places visited without showing how often, or in which direction, the body passed.

With **ARROWS**, samples of the field appear across the floor. They point inward and shorten toward the centre, where the rule returns zero. Each moving body asks this same rule for a value at its current position. The displayed arrows are only some of the places we have sampled; a body can ask between them too.

The field extends across the room, but it has not settled how either body will receive it.

## What reaches the centre

In Motion, a pulse ended while its acquired velocity remained. Pink carries that possibility here. Near the centre the new contribution shrinks, but the velocity it has acquired is still present. Past the centre the field points back. It takes time to turn that velocity around.

Cyan uses the current field value as its velocity. As the arrows shorten, its speed decreases directly. The next sample replaces the velocity it had before.

Behind **RULE**, cyan receives the sample through an assignment:

```gdscript
velocities[i] = sample
```

Pink adds a contribution over one model step:

```gdscript
velocities[i] += sample * STEP
```

Both then move:

```gdscript
positions[i] += velocities[i] * STEP
```

An equals sign and a plus-equals sign give the same spatial rule different consequences. The second meets a velocity already there; the first supplies a new velocity each time. Once the bodies separate, each also asks the field from a different place.

The samples begin without units. Cyan interprets one field unit as one metre per second. Pink interprets it as one metre per second squared. The receiver gives the number its physical meaning. A bare arrow cannot tell us whether it names a direction, a velocity, an acceleration or a force.

The centre has become somewhere to approach for one body and somewhere to cross for the other. Pink's persistence may look like reluctance to follow. We can locate it in a velocity the program allows to continue. Both ways of moving have been made possible by a rule.

## Changing the field

**FIELD** changes the inward rule to **SWIRL**. Reset, then run. The arrows point across the radius rather than along it. Cyan follows the turning directions. Pink adds them to its existing velocity. A circular arrangement of arrows has given us different paths through the room.

At the next setting, **UNIFORM**, every address returns the same value. Reset and compare the first second. At gain one, cyan travels about 0.8 metres. Pink starts from rest, travels about 0.4 metres and reaches about 0.8 metres per second. One travelled at the speed the other was still acquiring.

Now **REVERSE** during a run. The arrows reverse immediately. Cyan accepts the new velocity on its next update. Pink receives an acceleration against the velocity it already has. For a while, it continues into a field pointing the other way.

Field, gain and sign can change without clearing that state. RESET returns both bodies to their starting address and pauses them, keeping the chosen settings. It gives us another comparison from a shared beginning. A reversal gives us something else: the new rule meeting a movement already under way.

## Where the observation ends

At the gold perimeter a marker may stop. Its outgoing velocity remains in the readout. The apparatus has frozen that receiver at the edge of the comparison.

In Motion, a boundary made the cube rebound. Here the line ends an observation. Similar marks on a floor can belong to different kinds of world.

The markers pass through furniture and through our position. Their two heights separate the views of one horizontal calculation. We can stand inside this field without being moved by it. Another way for our body to receive it would have to be built.

The paths are made in small numerical steps, and the trails retain only a recent history. The drawing cannot recover everything that led here. What we can examine is how the present position and velocity meet the next sample, and how changing that relation changes the movement.

The earlier field, weather and motion exhibits remain beyond this opening. A similar arrow may turn an instrument, guide a particle or reach a physical body. Follow it to what receives it.

<!-- @ -->

Next, three cubes enter strips named air, water and honey. The influence will depend on the movement it is slowing. The body has become part of the rule that acts on it.
