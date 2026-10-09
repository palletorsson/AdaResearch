# The arrow does not decide

<!-- @VectorFieldFlow -->

Two small bodies wait beyond the controls. They share an address on the floor, one held a little higher so you can distinguish them. One is cyan, the other pink.

Stand between the control banks and press **RUN**. Both head inward. Watch the centre.

Cyan approaches and slows. Pink crosses it, keeps going, then begins to turn back. They started together. What did the second body bring through a place where the first was coming to rest?

Use RUN again to pause. **TRAILS** leaves their recent paths in the space and draws the same histories on the wall. In this first example the lines lie along the same diagonal. A line alone does not tell you which body crossed the centre, how quickly, or whether it came back. Run them again. Movement gives the shared line different histories.

Now reveal **ARROWS**. Sixty-three samples point inward across the floor. Their lengths diminish toward the centre, where the rule returns zero. Each moving body asks this same rule for a value at its own current position. The arrows are places where we have sampled the rule for you; a body can also ask between them.

In Motion, a pulse ended while its acquired velocity remained. Pink carries that possibility into a field. The next contribution depends on where it arrives. Near the centre the contribution shrinks, but the velocity it has already acquired is still present. Past the centre the field points back. It takes time to turn that velocity around.

Cyan receives the sample differently. It uses the current field value as its velocity. As the arrows shorten, its speed decreases directly. It has a position and a history of positions, but the next velocity replaces the previous one.

Press **RULE**. The first receiver performs this assignment:

```gdscript
velocities[i] = sample
```

The other adds a contribution over one model step:

```gdscript
velocities[i] += sample * STEP
```

Both then move:

```gdscript
positions[i] += velocities[i] * STEP
```

An equals sign and a plus-equals sign give the same spatial rule different consequences. The second line meets a velocity already there. The first supplies a new velocity each time.

This apparatus starts with dimensionless field values. Cyan interprets one field unit as one metre per second. Pink interprets one field unit as one metre per second squared. Those choices belong to the receivers. We cannot read a bare arrow and know whether it names a direction, a velocity, an acceleration or a force.

**FIELD** changes the inward rule to **SWIRL**. RESET, then RUN. The samples now point across the radius rather than along it. Cyan follows the turning directions. Pink adds those directions to its existing velocity. Look for the growing difference between their paths. A field drawn with circular symmetry does not, by itself, promise every body a circular orbit.

The next FIELD setting is **UNIFORM**. Every address returns the same value. Reset and compare the first second: at gain one, cyan travels about 0.8 metres. Pink, starting with zero velocity, travels about 0.4 metres and reaches about 0.8 metres per second. One travelled at the speed the other was still acquiring.

Try **REVERSE** during a run. The arrows reverse immediately. Does each body reverse with them? Cyan accepts the new velocity on its next update. Pink first receives an acceleration opposing the velocity it already has. Changing the rule does not erase that velocity.

GAIN cycles through 0.5, 1 and 1.5; field, gain and reverse edits keep the current state. For a comparison from the same beginning, RESET pauses both bodies at their starting address while keeping your chosen settings. RUN resumes the local experiment. The museum's clock is elsewhere, continuing.

At the gold perimeter a marker may stop. This apparatus has reached the edge of the comparison and freezes that receiver, retaining its outgoing velocity as a readout. No wall bounced it and no friction slowed it. Reset to begin another run. In the previous chamber a boundary computed a collision; here a boundary ends an observation. The line on the floor cannot tell us that difference without the implementation.

The markers pass through furniture and through your position. Their different heights are display offsets: both calculations take place in X and Z. We are standing inside a representation, with access to controls that change it. These controls do not push the player's body. That would require another receiver, with its own movement rules and limits.

The model advances in steps of one hundred and twentieth of a second. Its traces keep 240 samples at ten samples per model second. The fixed steps make comparisons repeatable across ordinary display rates; they do not make a numerical curve exact. Even cyan's circular path can drift slightly as straight steps approximate a turn. Long stalls advance at most a quarter of a model second per update, so the experiment can fall behind wall time.

We have chosen what to keep: a position, a velocity for each body, and a short history for drawing. We have also chosen how to receive the next sample. The difference between these two bodies is something we can locate in code, change, and watch unfold.

Beyond this opening, the earlier field, weather and motion exhibits remain. Read their mechanisms against this comparison. A wind arrow may drive a visual instrument, a particle update or a physical response. Similar arrows do not guarantee the same operation.

<!-- @ -->

Next are kinetic forces. Carry two questions into the room: what does this vector measure, and what does the receiving body do with it?
