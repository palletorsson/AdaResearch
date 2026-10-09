# Who gets to stay still?

[Working route](index.html#VFM_07_Gravity) · [Book primary](/necklace/thread?map=VFM_07_Gravity&role=primary) · [Previous: Restoring Forces](restoring-forces.html) · [Timing machines](timing-machines.html)

**Gravity now has two room-scale experiments.** Change the beginning of an orbit around a held source, then let two and three bodies respond to one another. Each experiment has standing controls, a floor plan you can enter, bounded traces and a rule reveal.

![An orbit around a held source, with a floor trail and standing controls in the actual museum](gravity_orbit.png)

## From a held reference to a moving relation

The spring introduced a fixed equilibrium. Gravity asks what happens when the reference has a body and can move. The first experiment deliberately holds its 12 kg source still. The next starts with two equal 4 kg bodies, both responding, then lets a third join. The pair's original starting positions and velocities remain the same when the third is added.

| First encounter: orbital_mechanics_demo | Second encounter: three_body_problem |
| --- | --- |
| RUN, pause, RESET | RUN, pause, RESET |
| SPEED prepares four initial speeds | BODIES resets with two or three masses |
| REVERSE negates current satellite velocity | NUDGE changes only the last body's initial X in a comparison copy |
| A held source and one moving satellite | Equal and opposite pair forces; all bodies respond |
| PARTS, PATH and RULE | PARTS, PATH and RULE, paired separation and centres of mass |

The shared law uses G=1 and quarter-metre softening. Both opt-in variants integrate with velocity Verlet at 240 steps per model second. The shared law does not make the two experiments identical: the first omits the source's reaction and uses different masses. The controlled two-to-three comparison happens within the second station.

![Three mutually attracting bodies and a translucent comparison with one changed initial coordinate](gravity_mutual.png)

## An experiment to try

1. Run the mutual pair before adding anything; follow both bodies and the white centre-of-mass cross.
2. Press BODIES, then RUN. The original pair begins as before, with a third mass initially at rest.
3. Press NUDGE once, then RUN. Copy B differs only by 0.03 m in the third body's starting X.
4. Compare corresponding trajectories and the RMS difference at the same model time; reset to repeat.

The checked run reaches a paired RMS position difference of approximately **0.0758 m after four seconds**. Its initial RMS difference is 0.03/√3 m, because only one of three bodies is displaced. Copy B is drawn 0.65 m higher for comparison; both calculations are planar and the copies do not interact. Their centres of mass are not artificially aligned.

This is a specified comparison, not proof of chaos. The third body's presence changes the forces on the original pair without adding a new interaction law.

## What the room leaves open

The spheres have no collision surfaces in the model and do not apply force to the player. Epsilon changes close attraction. Trails retain at most 240 samples at 20 Hz, roughly twelve seconds; acceleration arrows stop growing at two metres, with their scale and the baseline's numerical maximum stated. The golden frame pauses both calculations on an outgoing state rather than pretending an observation cutoff is a physical wall or proof of escape.

The hall grows from 22 × 16 to 22 × 48 cells. All eleven artifact identities remain. The two primaries precede nine supporting pieces; the old oversized force-directed graph becomes a compact specimen with its standalone lighting and screen overlay disabled only in this museum configuration. Those supporting solvers have their own rules.

**51 desktop checks pass in the actual museum.** Tests cover circular motion, current-velocity reversal, mutual responses, conservation tolerances, controlled nudges, replay under 30/60 Hz frame partitions, bounded trails and arrows, live pointer buttons, standing control height and sampled body-sized approaches. The measured baseline momentum residual at four seconds is 0.00001985 kg m/s; energy is 0.99992286 of its starting value. These are finite-interval checks, not a promise for every possible trajectory.

[Desktop report](gravity-relations-check.json) · [Placement ledger](gravity-relations-placements.json)

Headset legibility, reach, comfort and sustained performance remain pending. The illustrated captures are desktop views from the actual museum. Existing boot UID and shader-cache warnings remain outside this pass.

**Next: [VFM_09_Legs](legs-support.html).** We have allowed an attracting reference to move. What lets a body stand, push against a floor, and take a step?

---

## Book draft

# Who gets to stay still?

<!-- @orbital_mechanics_demo -->

The spring had an address to return to. You could move its body through that address without moving the address itself. Here the reference has acquired a body: a pink sphere, apparently untroubled by the small gold one waiting beside it.

Press RUN. Let the gold body go round. Then change SPEED and start again. The attraction has not changed; something about the beginning has. A circle narrows into a closer passage, or opens toward the golden frame. Which part of the path did the starting speed decide? Which part is being decided now?

Walk into the drawing. The spheres pass through you. You are inside its spatial explanation, but you have not become one of its masses. Already the room contains two kinds of body.

Reveal PARTS. The arrow on the satellite points toward the source even when the satellite travels across that direction. Motion keeps what the previous moments gave it; acceleration changes what comes next. The turn is made again at every step.

```gdscript
var arm: Vector3 = state.p[j] - state.p[i]
var pair_force: Vector3 = G * masses[i] * masses[j] * arm / pow(arm.length_squared() + EPS * EPS, 1.5)
```

The subtraction we learned as a gap now gives an interaction its direction. Distance also enters its strength. This room chooses G = 1, a source of 12 kg and a satellite of 1 kg. At three metres, the opening sideways speed is calculated for a circular orbit under this particular softened law. SPEED offers four multiples of that beginning. It does not push the current body; it prepares another run.

Try REVERSE while the satellite is moving. Its velocity changes sign, its position stays, and the clock continues forward. In this isolated model it can retrace the path it has just made. The earlier spring with damping could not offer the same experiment merely by reversing velocity: resistance would keep dissipating motion. A return depends on what the update preserves.

Look again at the pink body. Why has it not moved?

```gdscript
if mutual or i!=0:a[i] += pair_force / masses[i]
if mutual or j!=0:a[j] -= pair_force / masses[j]
```

Here `mutual` is false and body zero receives no acceleration. The source is held in place by the implementation. Its stillness is useful: it lets us learn one moving body's relation to a fixed reference. It also withholds a response. What happens if the thing we called the centre is allowed to answer?

<!-- @three_body_problem -->

The next floor begins with two equal masses. Press RUN before adding anything. Both move. Neither has the privilege the pink source had. A small white cross marks their centre of mass; it can remain still while the two bodies travel around it. A reference need not be occupied.

Now press BODIES. Time returns to zero and a third body waits above the pair in the floor plan. The original two keep their starting positions and velocities; the newcomer starts at rest. Run again. Follow one of the original paths. Where does it first cease to be the path you expected?

No new instruction says “be complicated.” Each pair contributes the same softened attraction, with an equal and opposite force on its partner. All three masses are 4 kg. The arrangement has changed, so the forces summed at each body change. The original pair's circular beginning is no longer a promise about its future.

```gdscript
var a=accelerations(state)
for i in state.p.size():
    state.v[i] += a[i] * (STEP * 0.5)
    state.p[i] += state.v[i] * STEP
a=accelerations(state)
for i in state.p.size():state.v[i] += a[i] * (STEP * 0.5)
```

A little change of velocity. A step in position. Read every relation again. Another little change of velocity. The code advances all bodies through these shared stages, 240 times per model second.

NUDGE prepares a second beginning. Only the last body's X coordinate changes, by three centimetres on the first press. Velocities remain identical. The translucent bodies belong to that second calculation; they are drawn higher so we can distinguish the copies, although both calculations stay in the X–Z plane. They do not attract the solid bodies below them.

Watch a corresponding pair, then read the displayed difference. It combines the distances between corresponding bodies as a root mean square. In the checked three-body run, three centimetres added to one initial coordinate gave about 7.6 centimetres of this paired difference after four seconds. Reset and compare again. This is a measured departure under specified conditions. A tangled trail alone would not establish chaos, and this short comparison does not establish an exponential rate of separation.

There are two white crosses now. Moving that one initial coordinate also moved its copy's centre of mass. We did not secretly recentre it. Even an experiment about difference has to decide which differences it will retain.

Return to `EPS * EPS`. The quarter-metre softening keeps close encounters finite by changing the attraction near coincidence. The visible spheres have no hard surfaces in this calculation: they neither collide nor merge. Their glow suggests bodies with skins; the rule offers positions and masses. What kind of encounter could we make by adding a skin?

The floor keeps at most 240 samples for each trail, taken twenty times a second: roughly twelve seconds of visible past. Hiding PATH does not stop this recording. Large acceleration arrows stop growing at two metres, while the numerical acceleration continues beyond that drawing limit. At the golden frame the whole experiment pauses with its outgoing state intact. The edge says our observation has ended; it does not prove that a body has escaped its partners.

We have allowed the centre to move and the third body to alter a relation already underway. Your feet, meanwhile, have remained on the museum floor. Gravity in the next encounter will need an answer from the ground. What lets a body stand?
