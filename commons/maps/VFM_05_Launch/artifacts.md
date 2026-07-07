# VFM 05 Launch — Artifacts
*Vectors & Forces: From Direction to Dynamics · oscillation · 13 artifacts*

> Ballistics: every way to throw something — including yourself.

The map, read through what it holds — its artifacts in the order you meet them:

## Catapult
![Catapult](/scene-catalog/catapult.png)

Procedural wooden catapult: A-frame base, torsion pivot, a long throwing arm with a basket at the tip and a counterweight at the short end. A console with ANGLE + FORCE sliders and a FIRE push-button sits in front. Changing a control retilts the arm and redraws a live predicted-trajectory parabola; FIRE swings the arm and launches a ball that follows the arc. Always-on velocity (green) and gravity (red) vector arrows with labels make the parabola = initial velocity + constant gravity legible.

`catapult`

## Half-Life Turret - Vector Compendium
![Half-Life Turret - Vector Compendium](/scene-catalog/hl_turret_vectors.png)

Half-Life inspired sentry turret demonstrating ALL vector operations in one coherent system: subtraction (direction to target), magnitude (distance/range check), normalization (unit direction), dot product (FOV check), cross product (rotation axis), projection (ground plane), scalar multiplication (bullet velocity), and velocity integration (bullet physics). Fires tracer rounds with visible velocity vectors!

`hl_turret_vectors`

## Turret-Boll Vector Diagram
![Turret-Boll Vector Diagram](/scene-catalog/turret_boll_infoboard.png)

3m × 6m semi-transparent infoboard showing ALL vector operations in one static diagram: subtraction (direction), magnitude (range), normalization (aim), dot product (lock), projection (prediction). Visual reference for turret targeting math.

`turret_boll_infoboard`

## Mortar Vector Siege
![Mortar Vector Siege](/scene-catalog/mortar_vector_siege.png)

Grabbable mortar tube (XRToolsPickable) on a base, over a ground disc, facing a wandering swarm of flying drones. Aim = -tube.basis.z; muzzle Marker3D = p0. Hold trigger to charge _force (min->max over ~1.2s), release to fire a RigidBody shell (gravity_scale=g/9.8, contact_monitor, continuous arc). Live velocity/gravity arrows + dotted parabola + analytic floor AoE ring. Shell detonates on floor contact OR y<=floor_y, popping drones within aoe_radius. Grip or cooldown reloads the cosmetic shell. Scoring on drone_destroyed. DNA: min_force, max_force, gravity_magnitude, aoe_radius, drone_count.

`mortar_vector_siege`

## Launch Arc (projectile motion)
![Launch Arc (projectile motion)](/scene-catalog/launch_arc.png)

Projectile motion made playable - the launch / F=ma toy for the embodied vectors-forces arc (the pad that throws you). A launch pad fires at angle theta with speed v; gravity bends the straight launch vector into a parabola. The launch velocity decomposes into a horizontal vx (carries you) and a vertical vy (fights gravity); the trade between them sets the range = v^2 sin(2theta)/g - which peaks at 45 degrees. Shows the tilted glowing pad, the stroboscopic projectile arc, the launch vector + its vx/vy components, and apex / range markers. DNA: angle 0..1 sets the launch angle (flat to steep), power 0..1 the launch speed; color_a pad + components, color_b the arc + launch vector, accent pad glow + apex/range.

`launch_arc`

## Firework Burst (projectile fountain)
![Firework Burst (projectile fountain)](/scene-catalog/firework_burst.png)

The firework as pure projectile motion - a mortar throws sparks up in a cone and gravity arcs every one into a parabola. The console rebuild of the firework launcher. burst 0..1 from a tight low column to a wide high canopy of falling embers.

`firework_burst`

## VectorThrowing
![VectorThrowing](/scene-catalog/VectorThrowing.png)

p(t) = p0 + v0*t + 0.5*g*t^2. Projectile motion. Horizontal = constant velocity; vertical = constant acceleration. Your hand writes the initial conditions.

`VectorThrowing`

## Firework Launcher
![Firework Launcher](/scene-catalog/firework_launcher.png)

SEE that a firework is a population explosion — one event becomes many independent paths, each obeying the same law

`firework_launcher`

## Human Catapult
![Human Catapult](/scene-catalog/human_catapult.png)

Heavy timber frame + throwing arm + a player-sized basket (StaticBody floor you stand on, low walls, harness). An Area3D (player_body layer) arms the seat when you step in; ANGLE/FORCE sliders + a FIRE button launch you. Live velocity arrow + parabola preview. DNA: launch_force, launch_angle, gravity_magnitude.

`human_catapult`

## Force Pad
![Force Pad](/scene-catalog/force_pad.png)

1x1 m glowing launch pad. An Area3D on the player_body layer fires on contact, setting the player CharacterBody3D's velocity to forward+up. Pulsing surface, forward chevrons, live launch-vector arrow. DNA: forward_force (6), up_force (7), cooldown_time.

`force_pad`

## Drag Lane (F = -b·v you feel)
![Drag Lane (F = -b·v you feel)](/scene-catalog/drag_lane.png)

Friction / drag made felt - a forces toy for the embodied vectors-forces arc. A runner enters a resistant medium at full tilt and slows under F = -b*v, so its velocity decays v ~ e^(-bt). Frozen stroboscopically, the runner's snapshots bunch together and its velocity arrows shrink as the drag eats the motion - run through air, water, honey and each pulls back harder. DNA: drag 0..1 sweeps from glide (snapshots evenly spread) to dead-stop (piled up fast); seed jitters the medium motes; color_a lane, color_b runner + velocity, accent drag particles, medium_color the resistant volume.

`drag_lane`

## Circle Train (centripetal force, a = v²/r)
![Circle Train (centripetal force, a = v²/r)](/scene-catalog/circle_train.png)

Centripetal force made playable - a sci-fi intermezzo for the embodied vectors-forces arc. A high-speed neon maglev loop: the train's velocity is always tangent to the ring (grows with v) and its force always points inward toward the centre (grows with v^2/r). The payoff you can dial: double the speed and the inward force quadruples - the velocity arrow stretches linearly while the centripetal force arrow explodes. Glowing torus track, a banking train of cars, speed streaks, the tangent + inward vectors, and a v / a / F_c readout. DNA: speed 0..1 dials the train (velocity ~v linear, centripetal force ~v^2 quadratic); seed sets the train position; color_a neon track, color_b velocity, accent centripetal force, train_color the cars.

`circle_train`

## Slingshot Launcher
![Slingshot Launcher](/scene-catalog/slingshot_launcher.png)

Step onto the platform and get catapulted! A charging catapult mechanism detects the player, builds power, then fires you (and demo balls) along a parabolic trajectory. Adjustable launch angle and power with a visible trajectory preview. Shows impulse, projectile motion, and the visceral thrill of Newton's third law.

`slingshot_launcher`
