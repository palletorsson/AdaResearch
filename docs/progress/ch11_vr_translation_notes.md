# Chapter 11 (Neuroevolution) VR Translation Notes

## Example: 11_1_flappy_bird
- **2D focus**: Manual Flappy Bird clone with gravity, pipe spawning, and collision detection.
- **VR fish tank layout**: Position the bird near the front-center (0.2 m from the player) and animate pink-tinted ring pipes sliding along the +X axis inside the 1󪻑 m tank. Render transparent cube edges for context.
- **Light pink palette**: Bird uses primary pink body (`#FFC0E6`) with brighter wing trails; pipes blend secondary pink and translucent white to maintain visibility.
- **Line-derived controller**: Optional vertical `LineController3D` slider on tank exterior to adjust gravity/pipe speed for demos.
- **Testing notes**: Validate collision messages via floating Label3D, ensure frame pacing after converting to Godot physics.

## Example: 11_2_flappy_bird_neuro_evolution
- **2D focus**: Neuroevolved flock of birds using ml5 neural networks to learn flapping cadence.
- **VR fish tank layout**: Spawn cohort of holographic birds at varying heights; pipes share pink aesthetic but glow when the active genome succeeds.
- **Light pink palette**: Use alternating hues (`#FFC0E6`, `#E680CC`) to differentiate generation champions vs. learners.
- **Line-derived controller**: Place paired sliders (mutation rate, refresh interval) on opposite tank walls; slider caps pulse when grabbed.
- **Testing notes**: Simulate ml5 behavior via GDScript perceptron; log fitness progression in in-world readout and `/docs/progress` log.

## Example: 11_3_smart_rockets_neuro_evolution
- **2D focus**: Rockets with DNA (thrust vectors) evolving to reach a target around obstacles.
- **VR fish tank layout**: Target sphere floats top-back of tank; rockets launch from lower-front pad and arc upward while trails trace light pink ribbons.
- **Light pink palette**: Rockets tinted medium pink with emission trails; target uses bright accent pink and gentle bloom.
- **Line-derived controller**: Dial-style controller (extruded line) on left wall toggles mutation strength; second slider adjusts obstacle positions.
- **Testing notes**: Confirm DNA array maps to force impulses, verify obstacle collisions, and capture generation snapshots.

## Example: 11_4_neuro_evolution_steering_seek
- **2D focus**: Steering agents evolved to seek a goal while avoiding hazards.
- **VR fish tank layout**: Populate tank with glowing creatures that leave light-pink vector arrows; hazards materialize as translucent prisms.
- **Light pink palette**: Agents emit soft pink glow scaling with fitness; hazards shift to desaturated purple to remain distinct.
- **Line-derived controller**: Ceiling-mounted slider tunes sensor range; floor-mounted slider tweaks goal position along Z axis.
- **Testing notes**: Validate steering forces (seek, flee) inside 3D grid and ensure agents respect tank boundaries.

## Example: 11_5_creature_sensors
- **2D focus**: Single creature with forward sensors reacting to food items.
- **VR fish tank layout**: Creature orbits center with sensor beams visualized as pink volumetric cones; food nodes hover as sparkling cubes.
- **Light pink palette**: Sensor cones use semi-transparent accent pink; creature body primary pink with gradient fins.
- **Line-derived controller**: Slim slider controls sensor angle spread; knob variant adjusts sensor length.
- **Testing notes**: Check sensor raycasts in Godot match 2D logic and that food consumption triggers feedback.

## Example: 11_6_neuroevolution_ecosystem
- **2D focus**: Combined ecosystem of evolved creatures foraging on food within shared environment.
- **VR fish tank layout**: Fish-tank becomes miniature biosphere梒reatures roam with pink trails, food sprouts as glowing orbs that shrink on consumption.
- **Light pink palette**: Use layered pink fog plane near tank base to signal environment energy; highlight alpha creatures with accent halo.
- **Line-derived controller**: Panel of three line-derived sliders adjusts food spawn rate, mutation rate, and population cap.
- **Testing notes**: Stress-test with max population, ensure physics remains at 90 FPS, and document emergent behaviors.
