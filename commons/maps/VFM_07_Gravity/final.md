# Who gets to stay still?

The timing machines gave bodies their paths. In this hall, the PointBody spheres continually change one another's motion. The installed mutual-attraction field offers PAIR / FIVE; in FIVE, entering the field adds your position as another source. The collection comparison below isolates a fixed source and a three-body beginning. Its RUN, SPEED and NUDGE controls belong to those separate studies, which are not placed in the current hall.

## Collection comparison — a fixed centre, then a moving one

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

Look again at the pink body. Why has it not moved? Press **RULE** to inspect which body receives the acceleration.

```gdscript
if mutual or i!=0:a[i] += pair_force / masses[i]
if mutual or j!=0:a[j] -= pair_force / masses[j]
```

Here `mutual` is false and body zero receives no acceleration. The source is held in place by the implementation: its response to the opposite force is not integrated. This is a constrained source, not an isolated pair whose total momentum we can expect to remain unchanged. Its stillness is useful: it lets us learn one moving body's relation to a fixed reference. It also withholds a response. What happens if the thing we called the centre is allowed to answer?

<!-- @three_body_problem -->

The next floor begins with two equal masses. Press RUN before adding anything. Both move. Neither has the privilege the pink source had. A small white cross marks their centre of mass; it can remain still while the two bodies travel around it. A reference need not be occupied.

Now press BODIES. Time returns to zero and a third body waits above the pair in the floor plan. The original two keep their starting positions and velocities; the newcomer starts at rest. Run again. Follow one of the original paths. Where does it first cease to be the path you expected?

No new instruction says “be complicated.” Each pair contributes the same softened attraction, and both bodies receive their equal and opposite forces. All three masses are 4 kg. The arrangement has changed, so the forces summed at each body change. The original pair's circular beginning is no longer a promise about its future.

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

Adding a third body does not mean that order becomes impossible. In the Newtonian problem, three equal masses can follow a periodic figure-eight.[^three-body] Here we numerically step a softened force law; neither that theorem nor a claim that three bodies have no analytical solution describes what this apparatus has established. Each new body changes the relations we must read again. With N bodies, a direct pairwise calculation has N(N−1)/2 pairs.

There are two white crosses now. Moving that one initial coordinate also moved its copy's centre of mass. We did not secretly recentre it. Even an experiment about difference has to decide which differences it will retain.

Return to `EPS * EPS`. The quarter-metre softening, called Plummer softening, keeps close encounters finite by changing the attraction near coincidence.[^plummer] The visible spheres have no hard surfaces in this calculation: they neither collide nor merge. Their glow suggests bodies with skins; the rule offers positions and masses. What kind of encounter could we make by adding a skin?

The floor keeps at most 240 samples for each trail, taken twenty times a second: roughly twelve seconds of visible past. Hiding PATH does not stop this recording. Large acceleration arrows stop growing at two metres, while the numerical acceleration continues beyond that drawing limit. At the golden frame the whole experiment pauses with its outgoing state intact. The edge says our observation has ended; it does not prove that a body has escaped its partners.

Return to the installed field. PAIR makes the exchange between two points available for study; FIVE lets your entry add a source to an arrangement already moving. Your feet remain on the museum floor while the points respond to your position. Gravity in the next encounter will need an answer from that floor. What lets a body stand?

[^plummer]: The added squared length softens the short-distance interaction. The [galpy Plummer potential documentation](https://docs.galpy.org/en/latest/reference/potentialplummer.html) gives the corresponding potential. The collection comparison uses 0.25 metres; the installed mutual-attraction field and the small tutorial study use 1.2 metres.

[^three-body]: Chenciner and Montgomery's [proof of the figure-eight orbit](https://arxiv.org/abs/math/0011268) concerns three equal masses under Newtonian attraction. Malte Henkel's [account of Sundman's solution](https://arxiv.org/abs/physics/0203001) explains why “the three-body problem has no analytical solution” is too broad. These mathematical results are distinct from this study's softened law and finite numerical steps.
