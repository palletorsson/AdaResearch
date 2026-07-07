# VFM 02 Operations — Artifacts
*Vectors & Forces: From Direction to Dynamics · oscillation · 12 artifacts*

> Dot, cross, projection — the operations, walk-around scale.

The map, read through what it holds — its artifacts in the order you meet them:

## Dot Product (Walk-Inside)
![Dot Product (Walk-Inside)](/scene-catalog/vector_dot_product_xl.png)

STAND between two arrows and watch the dot value swing from full agreement to zero as the angle between them opens to a right angle

`vector_dot_product_xl`

## Cross Product (Walk-Inside)
![Cross Product (Walk-Inside)](/scene-catalog/vector_cross_product_xl.png)

WALK around two arrows and watch the cross product pop straight up perpendicular to both, its length the area of the parallelogram you stand on

`vector_cross_product_xl`

## Dot-Aligner (aim · foe = mercy)
![Dot-Aligner (aim · foe = mercy)](/scene-catalog/dot_aligner.png)

The dot product made playable, and the embodied vectors-forces arc's operations toy. A swivel turret on a pedestal aims at a drifting foe-cube; the gold AIM vector (a) and the cyan DIRECTION-TO-FOE vector (b) meet at an angle, and a*b = cos(theta) is the charge. As alignment rises the angle closes, a lock BEAM ignites, and the foe converts FOE -> FRIEND (red -> green) - agreement here is mercy, not a kill. DNA: alignment 0..1 sets how locked the aim is (drives cos(theta), the beam, the conversion); seed jitters the foe bearing; color_a steel rig, color_b vectors, accent lock beam, foe_color/friend_color the conversion.

`dot_aligner`

## Torque Crank (r × F you can feel)
![Torque Crank (r × F you can feel)](/scene-catalog/torque_crank.png)

The cross product made playable - the operations pair to dot_aligner. A lever arm r and a push F meet at the hub of a flywheel; the torque tau = r x F = |r||F|sin(theta) points up the axle and spins the wheel. Force along the arm does nothing (sin 0); force across it spins hardest (sin 90). Shows r (cyan), F (orange), the tau torque axis (gold, up the axle), spin arrows and an rpm readout. DNA: leverage 0..1 sets the angle between r and F (0 = along the arm, 1 = perpendicular); seed jitters the arm bearing; color_a steel rig, color_b arm, force_color push, accent torque axis + flywheel glow.

`torque_crank`

## Vector Workbench
![Vector Workbench](/scene-catalog/VectorWorkbench.png)

Universal vector sandbox - two draggable vectors with all operations (add, subtract, dot, cross, projection) computed live

`VectorWorkbench`

## Projection & Reflection (Walk-Inside)

WALK onto the plane and watch an incident arrow split into the part that lies flat and the part that bounces back across the normal

`vector_projection_reflection_xl`

## Projection Shadow ((a·n̂)n̂ as a shadow)
![Projection Shadow ((a·n̂)n̂ as a shadow)](/scene-catalog/projection_shadow.png)

Vector projection made playable - the third operations toy with dot_aligner (dot) and torque_crank (cross). A sun overhead, an object floating off a rail; the object's shadow lands on the rail, and the shadow's distance from the origin IS a*n_hat - the projection of the object's position onto the axis n_hat. The perpendicular drop from object to shadow is the rejection (what doesn't live along n_hat). DNA: projection 0..1 swings the object from perpendicular (a perp n, no shadow) to along the rail (a parallel n, full shadow); seed jitters length; color_a rail/axis, color_b the vector a, accent the projection shadow, sun_color the light.

`projection_shadow`

## Agreement Gauge
![Agreement Gauge](/scene-catalog/agreement_gauge.png)

Dark slate plinth + brass rim + etched integer ground-lattice. Two grabbable arrows (a amber, b orange) from the origin; a dotted slerp arc with a live theta label between their tips. A floating formula slab renders the three-line self-substituting equation plus the |a||b|cos(theta) geometric form, both landing on the same value. A red->grey->green agreement rail carries a sliding puck driven to cos(theta) (pure transform, scale-pulse at the 90-degree zero crossing). A |b| dial isolates magnitude-scaling at fixed angle; a SNAP 90 button parks b perpendicular to a. The derived number (cyan-violet) is computed, not grabbable. DNA: initial_a, initial_b, bar_half_width, slider_min_mag, slider_max_mag.

`agreement_gauge`

## Work-Energy Demo
![Work-Energy Demo](/scene-catalog/work_energy_demo.png)

Dot product as physical work — force dotted with displacement gives energy transfer. See why pushing perpendicular to motion does zero work.

`work_energy_demo`

## Torque Demo
![Torque Demo](/scene-catalog/torque_demo.png)

Cross product as torque — force applied at a lever arm produces rotation perpendicular to both. The right-hand rule determines which way things spin.

`torque_demo`

## Normal Force & Reflection Demo
![Normal Force & Reflection Demo](/scene-catalog/normal_force_demo.png)

Vector projection and reflection — decompose velocity into normal and tangent components, then reflect. The math behind every bouncing ball and billiard shot.

`normal_force_demo`

## Angle Between Vectors
![Angle Between Vectors](/scene-catalog/exercise_5_9_angle_between.png)

Exercise exploring angle calculations between steering vectors.

`exercise_5_9_angle_between`
