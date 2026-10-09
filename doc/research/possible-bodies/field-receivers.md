# The arrow does not decide

[Working route](index.html#Vectors_Act3_FieldsAndMotion) · [Book primary](/necklace/thread?map=Vectors_Act3_FieldsAndMotion&role=primary) · [Previous: Motion](motion-chamber.html) · [Forces plan](vectors-forces-plan.html)

**Fields and Motion now opens with one field and two ways of receiving it.** Stand between the control banks. Both markers begin at the same planar address. In the opening inward field, cyan approaches the centre while pink crosses it. Reveal the arrows and equations after observing the difference.

![Two receivers inside the full-scale field, with central controls](field_receivers_overview.png)

## The comparison

Cyan **sets velocity** from the current sample. Pink **adds acceleration** to its existing velocity. Each samples the same spatial rule at its own position. This builds directly on Motion: the next influence meets a body carrying the result of earlier influences.

These are collision-free numerical markers. Their heights, 1.45 and 1.9 m, separate two views of an X-Z calculation. This chamber does not apply force to the player. Its point is to make the receiver rule inspectable before connecting later fields to physical bodies.

| Control | What changes | What remains |
| --- | --- | --- |
| RUN | Start or pause the local experiment | Current positions and velocities |
| RESET | Return to the shared start and pause | Chosen field, gain, sign and reveal settings |
| FIELD | Inward SINK, SWIRL, UNIFORM | Current state |
| REVERSE | Reverse the spatial samples | Existing accumulated velocity |
| GAIN | Cycle 0.5 / 1 / 1.5 | Current state |
| ARROWS | Reveal 63 field samples | The same moving-body calculation |
| TRAILS | Reveal recent floor paths and wall histories | Motion continues if running |
| RULE | Show the two update equations and units | The experiment's state |

![Current marker positions and a shared history projection on the wall](field_receivers_inside.png)

## What the new body can do

The two rules differ at `=` and `+=`. A field value becomes velocity in one adapter and acceleration in the other. At gain one in UNIFORM, cyan travels about 0.8 m during its first second; pink travels about 0.4 m and reaches 0.8 m/s. In SINK, pink's existing velocity carries it through the centre even though the sample there is zero.

In SWIRL, a circular arrangement of arrows does not promise a circular orbit for both receivers. Reverse during a run: cyan accepts its new velocity on the next update, while pink receives a contribution that first has to change its existing velocity.

The model advances at 120 fixed steps per model second. Its histories keep 240 samples at 10 Hz, and the same samples supply both floor-space paths and wall projections. The wall scales X by 0.5 and Z by 0.28; it is a diagram with declared scales. Long stalls cap catch-up to 0.25 model seconds per update. A marker crossing the gold frame freezes with its outgoing state: this is an observation cutoff, not a collision response.

## Space, book and evidence

The room has **one book primary: VectorFieldFlow**. Its map-specific variant now contains the two-receiver comparison. The compact legacy version remains available elsewhere; it blends velocity toward the field and damps it, a third update rule. VectorMotion remains supporting here after its full-scale primary encounter in the preceding hall.

All **13 artifact identities remain**. The hall grows from 18 × 30 to 18 × 44 cells, adding a fourteen-row arrival. Twelve supporting artifacts retain their relative cell positions beyond it. The old 15 × 15 × 15 blue `vector_field` is reduced to scale 0.18 and raised as a compact specimen; the first capture exposed its glyphs spilling across the new controls. [Placement ledger](field-receivers-placements.json).

The revised book, tutorial and critical text replace the old claim that all fields are forces or that the flow controller has no memory. Previous manuscripts and placements are preserved in the project record.

[**39 desktop checks pass**](field-receivers-check.json): pointer controls, inward overshoot, uniform predictions, parameter changes, reversal with state preservation, pause/reset, 30/60 Hz partition agreement, bounded history, frame exits, stable geometry, standing control heights, sampled approaches, linked wall markers, display height and legacy scene creation. Actual Godot captures are shown above. Headset reach, comfort and sustained performance remain untested. Supporting exhibits have not all been recertified.

**Next: [Kinetic Forces](kinetic-forces.html).** What does each vector measure, which body receives it, and what changes in that body's movement?

## Book chapter

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
