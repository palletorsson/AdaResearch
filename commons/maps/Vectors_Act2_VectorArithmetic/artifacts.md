# Vectors Act2 VectorArithmetic — Artifacts
*Vectors & Forces: From Direction to Dynamics · oscillation · 10 artifacts*

> A wide gallery where every operation appears twice — once as a toy in your hand, once at the size of a room you step into. Add two pushes by walking them head to tail. Flip one and find the gap between them. Turn a dial and watch a direction keep its line but change its length. Then the products: close an angle until two directions agree (the dot), cast a shadow of one vector onto another's line (projection), and push across a lever instead of along it to find the turn left over (the cross). Arithmetic stops being symbols on a page and becomes things vectors do to each other.

The map, read through what it holds — its artifacts in the order you meet them:

## Vector Addition Walk (Room Scale)
![Vector Addition Walk (Room Scale)](/scene-catalog/vector_addition_walk.png)

Player-scale 3D vector addition. Walk inside a 3m coordinate grid, grab vector endpoints at body height, see parallelogram construction and component projections in real space.

`vector_addition_walk`

## Vector Addition (a + b, two-pad console)
![Vector Addition (a + b, two-pad console)](/scene-catalog/vector_add.png)

Vector addition made playable - the entry operation of the embodied vectors-forces arc, a ToyConsole with a TWO-PAD control surface (synthesised from three interaction-design passes). Two 2D pads on the front lip, one per vector: drag a pad and that vector's tip follows your hand (a grabbed handle in VR, a pointer-drag on desktop). The two arrows draw head-to-tail on the console top and the resultant a+b swings live; the monitor shows the full component breakdown (a, b, a+b, |a+b|, angle). The control IS the vector tip. seed sets the starting a and b.

`vector_add`

## Vector Subtraction (a − b, two-pad console)
![Vector Subtraction (a − b, two-pad console)](/scene-catalog/vector_sub.png)

Vector subtraction made playable - the same two-pad ToyConsole as vector_add, flipped to a - b = a + (-b). Two 2D pads place the tips of a and b; the demo draws a, then the negated b head-to-tail, and the resultant a-b, with a faint ghost of the original +b so the flip reads as the whole idea. The monitor shows a, b, a-b, |a-b| and the angle. The control IS the vector tip; seed sets the starting a and b.

`vector_sub`

## example_2_3_gravity_scaled_by_mass_vr
![example_2_3_gravity_scaled_by_mass_vr](/scene-catalog/example_2_3_gravity_scaled_by_mass_vr.png)

Gravity scaled by mass demonstration

`example_2_3_gravity_scaled_by_mass_vr`

## Dot-Aligner (aim · foe = mercy)
![Dot-Aligner (aim · foe = mercy)](/scene-catalog/dot_aligner.png)

The dot product made playable, and the embodied vectors-forces arc's operations toy. A swivel turret on a pedestal aims at a drifting foe-cube; the gold AIM vector (a) and the cyan DIRECTION-TO-FOE vector (b) meet at an angle, and a*b = cos(theta) is the charge. As alignment rises the angle closes, a lock BEAM ignites, and the foe converts FOE -> FRIEND (red -> green) - agreement here is mercy, not a kill. DNA: alignment 0..1 sets how locked the aim is (drives cos(theta), the beam, the conversion); seed jitters the foe bearing; color_a steel rig, color_b vectors, accent lock beam, foe_color/friend_color the conversion.

`dot_aligner`

## Dot Product (Walk-Inside)
![Dot Product (Walk-Inside)](/scene-catalog/vector_dot_product_xl.png)

STAND between two arrows and watch the dot value swing from full agreement to zero as the angle between them opens to a right angle

`vector_dot_product_xl`

## Projection Shadow ((a·n̂)n̂ as a shadow)
![Projection Shadow ((a·n̂)n̂ as a shadow)](/scene-catalog/projection_shadow.png)

Vector projection made playable - the third operations toy with dot_aligner (dot) and torque_crank (cross). A sun overhead, an object floating off a rail; the object's shadow lands on the rail, and the shadow's distance from the origin IS a*n_hat - the projection of the object's position onto the axis n_hat. The perpendicular drop from object to shadow is the rejection (what doesn't live along n_hat). DNA: projection 0..1 swings the object from perpendicular (a perp n, no shadow) to along the rail (a parallel n, full shadow); seed jitters length; color_a rail/axis, color_b the vector a, accent the projection shadow, sun_color the light.

`projection_shadow`

## Projection & Reflection (Walk-Inside)

WALK onto the plane and watch an incident arrow split into the part that lies flat and the part that bounces back across the normal

`vector_projection_reflection_xl`

## Torque Crank (r × F you can feel)
![Torque Crank (r × F you can feel)](/scene-catalog/torque_crank.png)

The cross product made playable - the operations pair to dot_aligner. A lever arm r and a push F meet at the hub of a flywheel; the torque tau = r x F = |r||F|sin(theta) points up the axle and spins the wheel. Force along the arm does nothing (sin 0); force across it spins hardest (sin 90). Shows r (cyan), F (orange), the tau torque axis (gold, up the axle), spin arrows and an rpm readout. DNA: leverage 0..1 sets the angle between r and F (0 = along the arm, 1 = perpendicular); seed jitters the arm bearing; color_a steel rig, color_b arm, force_color push, accent torque axis + flywheel glow.

`torque_crank`

## Cross Product (Walk-Inside)
![Cross Product (Walk-Inside)](/scene-catalog/vector_cross_product_xl.png)

WALK around two arrows and watch the cross product pop straight up perpendicular to both, its length the area of the parallelogram you stand on

`vector_cross_product_xl`
