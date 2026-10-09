# Carousel of Soft Collisions — Summary

The second Soft Bodies map attaches compliant materials to a spinning carousel, introducing rotational kinematics to the spring-mass framework. A rigid hub rotates at constant angular velocity while cloth straps, soft mushrooms, and interactive objects hang from its arms through PinJoint3D constraints. Centripetal acceleration (a = omega^2 * r) creates a force gradient across each soft body — vertices farther from the axis experience greater outward pull, producing directionally dependent deformation that gravity alone cannot reveal.

Cloth straps pinned at their top edges extend and flutter under rotation, their two-dimensional topology offering no resistance to folding along their length. Soft mushrooms deform asymmetrically — wider caps swinging further than narrow stems. The swing angle where gravity and centripetal force balance varies across the body, producing a continuous curve rather than a single pendulum angle. Angular velocity functions as a material probe: at low speed, all materials behave similarly; at high speed, stiff and soft bodies diverge visibly, with compliant materials stretching dramatically while rigid ones barely extend.

Collision at rotational velocity adds kinetic energy to deformation. Soft bodies striking obstacles mid-spin compress more violently than in static contact. The grab_long_stick and pick_up_cube artifacts introduce VR hand interaction — the learner can swing tools into the carousel's path or throw objects at rotating soft bodies, creating three-way physics scenarios between rigid rotation, player intervention, and soft compliance.

Through Ahmed's lens, the carousel imposes an orientation the soft body did not choose — the pin joint is the moment of interpellation, and the body's material response is its only form of agency. Through Merleau-Ponty, the cloth straps that part around the walking learner demonstrate the reversibility of flesh: toucher and touched exchange roles at the point of contact.

**Artifacts:** revolving_joy_ride (carousel hub), cloth_straps (fabric strips), soft_mushroom (volumetric soft bodies), grab_long_stick, pick_up_cube (interactive tools).
**Sequence position:** 2 of 9 in Soft Bodies (integration phase). Follows SoftBodies_Soft_Body_Deformation, leads to SoftBodies_Obsticals.
