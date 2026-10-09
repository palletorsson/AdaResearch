# Coming back takes you through

[Working route](index.html#Vectors_Act4b_Oscillation) · [Book primary](/necklace/thread?map=Vectors_Act4b_Oscillation&role=primary) · [Previous: Kinetic Forces](kinetic-forces.html) · [Timing machines](timing-machines.html) · [Next: Gravity](gravity-relations.html)

**Restoring Forces and Balance now has one main encounter: a spring you can displace and release.** The cube returns to the zero line, then passes through it. Reveal the opposing contributions on its body and on the wall, change the damping, and compare another release.

![The horizontal spring, two control banks and a wall displaying its current force contributions](restoring_overview.png)

## What this hall adds

Motion introduced accumulated velocity. Kinetic Forces introduced resistance opposing velocity. Here a restoring force opposing displacement joins that resistance:

```gdscript
var force: float = -stiffness * displacement - damping_coefficient() * velocity
velocity += (force / mass_value) * STEP
displacement += velocity * STEP
```

The new spring integrates a one-dimensional numerical state at 120 steps per model second. Its handle is a frozen pickable displaying that state; it is not an independently colliding rigid body. The horizontal rail assumes support, without gravity or contact friction. This preserves a clear comparison between displacement and velocity before adding further forces.

| Control | Action |
| --- | --- |
| PULL | Cycle held starting displacements: -1.25, +0.625, +1.25 m. |
| RELEASE | Begin from the current position with zero velocity. |
| RESET | Restore the opening +1.25 m displacement and hold; keep parameters. |
| DAMP | Compare FREE, LIGHT, CRITICAL and HEAVY damping. |
| MASS | Cycle 2 / 4 / 1 kg, keeping current position and velocity. |
| SPRING | Cycle 8 / 16 / 4 N/m, keeping current position and velocity. |
| PARTS | Reveal the spring force, damping force and their sum. |
| RULE | Reveal the state update and display scale. |

You can also grab the cube. The handle projects the hand's requested position onto horizontal X, limited to ±1.5 m. Dropping starts from rest; throwing speed and the other axes are deliberately discarded. These are concrete choices for the experiment, and possible variations for a later body.

## The comparison to try

Release with FREE damping. Reset, choose LIGHT and release again. The second motion still crosses zero, but its excursions shrink. Compare CRITICAL and HEAVY from the same displaced rest state: neither crosses, and HEAVY takes longer to approach equilibrium.

The damping ratios are 0, 0.25, 1 and 2.5. The coefficient is recalculated as `2 * ratio * sqrt(k * m)`, so the comparison remains tied to the selected mass and stiffness. Parameter edits retain position and velocity; changing mass or stiffness can change the calculated energy. An edit is an intervention, not a conservation promise.

![Inside the experiment: force arrows on the body and the same instantaneous values on the wall](restoring_inside.png)

The wall carries the current force budget, with the same 0.04 m/N scale as the body arrows. It carries no time-history plot. At equilibrium, the spring contribution can be zero while the body still moves; damping may still oppose that movement.

## Its relation to the later oscillation chapter

| Here: Restoring Forces and Balance | Later: Wavefunctions |
| --- | --- |
| What makes a displaced body return? | What can returning motion become? |
| Restoring force, inertia, damping and the release policy. | Sampling, phase, spatial waves, interference and sound. |
| Inspect the current contributions to movement. | Walk beside a retained history and combine rhythms. |

The later [WaveFunctions_Pendulum book view](/necklace/thread?map=WaveFunctions_Pendulum&role=primary) already develops the pendulum's sampled history. This hall supplies a force-based foundation for that return. The existing tall pendulum remains supporting here and prescribes its motion with cosine; visual resemblance does not establish the same mechanism.

## What changed, and what remains open

All **22 artifact identities remain**. The hall grows from 30 × 30 to 30 × 46 cells. Spring moves into a sixteen-row arrival; the other 21 placements shift together. One oversized kinetic sculpture is compacted to scale 0.12, raised 0.7 m and given an opt-in museum presentation that disables its standalone lights, cameras and screen overlays. Three supporting billboard-label placements now respect walls. [Placement and configuration ledger](restoring-forces-placements.json).

The map title is **Restoring Forces and Balance**; its stable identifier remains `Vectors_Act4b_Oscillation`. **spring_tower is its sole book primary.** The new final, tutorial and critical text distinguish an integrated state from prescribed periodic motion. Original manuscripts and placements are preserved in the project record.

[**48 checks pass**](restoring-forces-check.json): analytical free-spring response, bounded energy error, damping regimes, mass response, 30/60 Hz agreement, actual pointer signals, supplied XRTools pickup/drop, release from rest, retained state, force signs, wall/body correspondence, reused geometry, sampled approaches, control heights and supporting presentation. The two images are actual Godot captures.

Headset reach, comfort and sustained performance remain untested. Supporting exhibits await a fuller review. The numerical frame freezes outgoing state beyond ±2.25 m, rather than inventing a collision, and long stalls cap catch-up to a quarter of a model second.

**Next:** revisit [the timing machines](timing-machines.html), then continue with [Gravity](index.html#VFM_07_Gravity).

## Book chapter


# Coming back takes you through

<!-- @spring_tower -->

A cube waits to one side of a line. A coil connects it to the frame. The line continues across the floor, where your feet can find it too.

Press **RELEASE**. The cube moves towards the line. Watch what happens when it arrives.

It goes through.

The spring has brought it back to a place where the spring's own force is zero. It has not brought it to rest. The movement gathered on the way still belongs to the body. Beyond the line the coil begins to oppose that movement, slows it, and brings it back from the other side.

Press **RESET**. The cube waits at its opening position again. **PULL** offers other starting displacements, or you can take the cube and move it yourself. Your hand can move in three dimensions; the handle keeps only the horizontal part, limited to one and a half metres on either side. Letting go starts from rest. This experiment deliberately leaves out the speed of your throw.

That is already a choice about the body we are making. A release could carry your hand's velocity into the next movement. Here it carries a position, while velocity begins at zero. Compare two releases before choosing which would be useful for another machine.

Try **DAMP** once, from FREE to LIGHT. RESET and RELEASE give it the same beginning. The cube still crosses the line, but its excursions shrink.

Now reveal **PARTS**. The cyan spring arrow points towards the resting place. The orange damping arrow points against the current velocity. On the way in, the arrows oppose one another. After the cube crosses the line, both can point back against its continuing journey. The gold arrow is their sum. The wall shows the same three signed forces, at the same scale, without following the cube.

The drag rule from the previous room has joined another rule:

```gdscript
var force: float = -stiffness * displacement - damping_coefficient() * velocity
velocity += (force / mass_value) * STEP
displacement += velocity * STEP
```

**RULE** brings those updates onto the wall. One term asks where the body is relative to rest. The other asks how it is moving. Divide their sum by mass and acceleration appears; add its contribution to velocity, then use the new velocity to change position.

The cube does not consult a cosine to find its next address. This one-dimensional model computes the next state from the current one, at 120 steps per model second. Its pickable cube displays that state. It is not a second, freely colliding physics body, and its coil does not push the visitor. The rail assumes vertical support; gravity and contact friction have been left out.

The opening mass is two kilograms and the spring stiffness is eight newtons per metre. With damping off, RESET and RELEASE, then compare a heavier **MASS** from the same start. It takes longer to cross the line. Return to two kilograms and increase **SPRING**: a stiffer spring brings it through sooner. The buttons cycle through one, two and four kilograms, and four, eight and sixteen newtons per metre.

Changing those values during motion keeps position and velocity. It does not promise to keep energy. Stiffening a stretched spring changes the energy attributed to that state; replacing mass while keeping velocity does too. The edit is an intervention in the apparatus, not a free transformation of an isolated system.

Continue through the DAMP settings. At CRITICAL, release from rest on one side and watch it approach without crossing. At HEAVY, it also approaches without crossing, but more slowly. Extra resistance has delayed the return. Try the comparison from the same displacement: the setting that removes movement most strongly need not bring the body to its resting place soonest.

Those names are tied to the chosen mass and stiffness. The damping coefficient is computed from a ratio:

```gdscript
return 2.0 * RATIOS[damping_index] * sqrt(stiffness * mass_value)
```

FREE, LIGHT, CRITICAL and HEAVY use ratios of zero, a quarter, one and two and a half. Changing mass or stiffness changes the coefficient required to keep that ratio. The names describe this linear, undriven model; the return we compared begins from rest. They do not prescribe a good rhythm for every body.

The word *restoring* gives a direction a purpose. Back to what? Here there is a visible line and an explicit displacement measured from it. We can inspect the chosen centre. A system that calls its preferred state normal may make its reference harder to see. The useful question is not whether returning is always desirable. It is which differences the apparatus returns, which it damps, and which it never allowed to enter.

The hand's sideways travel was discarded. Its throwing speed was discarded. The cube's horizontal velocity, once released, is precisely what lets it pass through the place it was being brought back to. What was excluded and what was retained both helped make this body possible.

There are further limits. A long computer stall advances at most a quarter of a model second on the next update. If an intervention sends the cube outside the observation frame, beyond 2.25 metres of displacement, FRAME EXIT holds its outgoing state. No imaginary collision is supplied to make the frame seem like a wall. And the finite update can introduce numerical error even when damping is off. The recurring movement is something to examine, not a promise of perfect repetition.

Other balances, springs and pendulums remain farther into this hall. A similar swing may be prescribed directly from time; the older tall pendulum does exactly that. Looking alike does not establish the same mechanism. The question follows you from one apparatus to the next.

<!-- @ -->

We will return to oscillation in Wavefunctions. There a pendulum leaves a history we can walk beside, and returning motion becomes material for sampling, phase, spatial patterns and sound. Here we have established a smaller thing to carry: a force can bring a body back without telling it to stop there.

Next, the timing machines. What happens when several returning movements share a clock, or begin to fall out of step?
