# Force Preview — Artifacts
*Vectors & Forces: From Direction to Dynamics · oscillation · 12 artifacts*

> A first taste of forces before the arc begins — a preview room where pushes, pulls and launches are shown but not yet explained. Walk it to feel what the coming sequence will teach.

The map, read through what it holds — its artifacts in the order you meet them:

## Vector Addition (Laser, 4 m+)
![Vector Addition (Laser, 4 m+)](/scene-catalog/vector_addition_xl_laser.png)

Stand inside a 4 m+ vector-addition exhibit and move the arrow tips with the VR laser pointer — point, hold trigger, sweep, and the green sum diagonal follows across the room

`vector_addition_xl_laser`

## Vector Subtraction (Laser, 4 m+)
![Vector Subtraction (Laser, 4 m+)](/scene-catalog/vector_subtraction_xl_laser.png)

Stand inside a 4 m+ vector-subtraction exhibit and move the arrow tips with the VR laser pointer — watch a − b appear as the arrow from b's tip to a's tip

`vector_subtraction_xl_laser`

## Force Pad
![Force Pad](/scene-catalog/force_pad.png)

1x1 m glowing launch pad. An Area3D on the player_body layer fires on contact, setting the player CharacterBody3D's velocity to forward+up. Pulsing surface, forward chevrons, live launch-vector arrow. DNA: forward_force (6), up_force (7), cooldown_time.

`force_pad`

## Weather Vector Field — Storm Chamber
![Weather Vector Field — Storm Chamber](/scene-catalog/weather_vector_field.png)

A walkable storm chamber (~5x5 m) built on vector addition — two grabbable wind vectors combine in real-time. Drag arrow endpoints to feel how wind directions sum, then watch a real GPUParticles3D storm answer the resultant: rain streaks slant at the true gravity + wind angle, wind-blown debris streaks downwind (the vector in flight), drifting cloud slabs and swaying ground mist advect on the wind, and forked lightning strikes downwind in stormy weather. A MultiMesh field of arrows plus classic instruments — a yawing windsock, a spinning 3-cup anemometer, a ground compass rose, and fading streamlines — all read the same live summed vector. Four weather modes (calm / breezy / storm / blizzard) swap density, scale, colour, drift and lightning; calm adds a sun shaft with rising motes; blizzard turns the rain to slow white snow. Pressure zones distort the field; the ground tints warm/cool with the wind's vertical sign.

`weather_vector_field`

## Mortar Vector Siege
![Mortar Vector Siege](/scene-catalog/mortar_vector_siege.png)

Grabbable mortar tube (XRToolsPickable) on a base, over a ground disc, facing a wandering swarm of flying drones. Aim = -tube.basis.z; muzzle Marker3D = p0. Hold trigger to charge _force (min->max over ~1.2s), release to fire a RigidBody shell (gravity_scale=g/9.8, contact_monitor, continuous arc). Live velocity/gravity arrows + dotted parabola + analytic floor AoE ring. Shell detonates on floor contact OR y<=floor_y, popping drones within aoe_radius. Grip or cooldown reloads the cosmetic shell. Scoring on drone_destroyed. DNA: min_force, max_force, gravity_magnitude, aoe_radius, drone_count.

`mortar_vector_siege`

## Force Vortex
![Force Vortex](/scene-catalog/force_vortex.png)

Rotating whirlpool force field. An Area3D (cylinder, player_body layer) captures the player; each physics frame the field overwrites their velocity with inward pull + tangential spin + gentle lift, spiralling them toward the core; crossing eject_radius throws them outward + up, then a cooldown. Rotating spiral arms + glowing core + boundary ring. DNA: field_radius (3.5), pull/spin/lift, eject_force/up.

`force_vortex`

## Reflection Hall
![Reflection Hall](/scene-catalog/reflection_hall.png)

Six StaticBody3D walls (floor, ceiling, +X, -X, +Z) enclose a 5x5x3 m room; the -Z wall is two side panels + a lintel leaving a 1.2x2.2 m entrance you walk through. An invisible doorway curtain on the ball-only collision layer keeps thrown balls inside while letting the player pass. Balls are RigidBody3D with a bouncy physics material (engine bounces; we visualise). Each ball caches its pre-contact velocity every physics frame; on wall contact it recovers the incident d, looks up the wall's inward normal n̂, computes r = d - 2(d.n̂)n̂, and spawns a ~1.5 s fading d/n̂/r arrow cluster + live formula at the hit point, verifying r against the post-bounce velocity. Fading per-ball trails via ImmediateMesh line strips. A grab-throw ball rack (primary VR) plus an optional ANGLE/FORCE/FIRE console; on desktop/headless the console auto-fires every ~3 s so captures show live bounces. DNA: ball_bounce, gravity_scale, launch_speed, room dimensions.

`reflection_hall`

## Human Catapult
![Human Catapult](/scene-catalog/human_catapult.png)

Heavy timber frame + throwing arm + a player-sized basket (StaticBody floor you stand on, low walls, harness). An Area3D (player_body layer) arms the seat when you step in; ANGLE/FORCE sliders + a FIRE button launch you. Live velocity arrow + parabola preview. DNA: launch_force, launch_angle, gravity_magnitude.

`human_catapult`

## The Adder's Drafting Board
![The Adder's Drafting Board](/scene-catalog/adder_board.png)

Dark slate pedestal with a brass rim and a black drafting slab tilted ~20deg toward the player, etched with an integer lattice and a glowing origin pin. Two grabbable GrabSphere tip-pucks set a (amber) and b (orange); emissive catapult-style arrows redraw the tip-to-tail chain + the cyan-violet resultant + dashed parallelogram ghosts every frame. Two precision sliders set |a|,|b| to clean integers; a push-button toggles chain-glow vs parallelogram-glow. Live two-column formula plate + billboarded readouts including the triangle-inequality |a+b| <= |a|+|b| with a brass equality needle. DNA: a_start, b_start, snap_to_grid, pedestal_height.

`adder_board`

## Length Lantern
![Length Lantern](/scene-catalog/length_lantern.png)

Dark slate pedestal + brass rim + etched integer ground lattice on a 0.6 m bench plate. One grabbable amber vector whose GrabSphere2 tip carries a glass lantern bead; pulling it redraws the faint x,y,z component legs, the explicit Pythagoras box, the floor diagonal sqrt(x^2+z^2), live numbers (components, squares, running sum, |v|), the lantern glow, and a vertical magnitude ruler. x/y/z precision sliders + a SNAP button trigger a 1.2 s eased two-stage resolve animation that makes sqrt-inside-sqrt temporally legible. DNA: reach, max_magnitude, degenerate_threshold, show_sliders, arrow_thickness.

`length_lantern`

## Stretch Bench
![Stretch Bench](/scene-catalog/stretch_bench.png)

Dark slate pedestal + brass rim + graduated rail (the number line for k). A grabbable brass crank slides along the rail to set k in [-3,+3]; the amber base vector v is grabbable (re-aim the reference line), the derived twin k*v snaps to it and is never grabbable — cyan-violet when k>=0, red when k<0, a glowing dot at k=0. Etched integer ground-lattice (-3v..3v), a bead + brass 'k' dial needle, live k*v and |k||v| readout, SNAP integer-lock button, and a slider_horizontal desktop fallback. DNA: default_k, min_k, max_k, base_vector.

`stretch_bench`

## Agreement Gauge
![Agreement Gauge](/scene-catalog/agreement_gauge.png)

Dark slate plinth + brass rim + etched integer ground-lattice. Two grabbable arrows (a amber, b orange) from the origin; a dotted slerp arc with a live theta label between their tips. A floating formula slab renders the three-line self-substituting equation plus the |a||b|cos(theta) geometric form, both landing on the same value. A red->grey->green agreement rail carries a sliding puck driven to cos(theta) (pure transform, scale-pulse at the 90-degree zero crossing). A |b| dial isolates magnitude-scaling at fixed angle; a SNAP 90 button parks b perpendicular to a. The derived number (cyan-violet) is computed, not grabbable. DNA: initial_a, initial_b, bar_half_width, slider_min_mag, slider_max_mag.

`agreement_gauge`
