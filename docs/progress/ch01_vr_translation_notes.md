# Chapter 1 (Vectors) VR Translation Notes

## Example: example_1_1_bouncing_ball_with_no_vectors
- **2D focus**: Manual positional updates without vector abstraction.
- **VR fish tank layout**: Pink sphere bounces within transparent cube using basic position updates.
- **Light pink palette**: Sphere primary pink with white specular highlight; floor grid tinted pale pink.
- **Line-derived controller**: Slider toggles gravity magnitude; button resets position.
- **Testing notes**: Ensure direct positional updates respect tank bounds and maintain 90 FPS.

## Example: example_1_2_bouncing_ball_with_vectors
- **2D focus**: Introduces vector-based velocity.
- **VR fish tank layout**: Same bouncing sphere but velocity arrow rendered as pink vector glyph.
- **Light pink palette**: Velocity arrow accent pink; sphere medium pink.
- **Line-derived controller**: Slider adjusts bounce elasticity via vector scaling.
- **Testing notes**: Confirm vector operations reproduce 2D behavior in 3D.

## Example: example_1_3_vector_subtraction & example_1_4_vector_multiplication
- **2D focus**: Visualizing subtraction and scalar multiplication.
- **VR fish tank layout**: Display interactive arrow pair anchored at origin; resultant vector floats between controllers.
- **Light pink palette**: Source vectors light pink; resultant bright accent.
- **Line-derived controller**: Sliders modify scalar and target vector components.
- **Testing notes**: Ensure 3D vector math displays accurately from all player angles.

## Example: example_1_5_vector_magnitude & example_1_6_vector_normalize
- **2D focus**: Magnitude calculation and normalization.
- **VR fish tank layout**: Render vector arrow connected to magnitude meter (pink gauge) mounted on tank wall.
- **Light pink palette**: Gauge fill brightens as magnitude increases.
- **Line-derived controller**: Slider manipulates vector length; knob toggles normalization mode.
- **Testing notes**: Validate length calculations and ensure normalization updates the arrow in real time.

## Example: example_1_7_motion_101_velocity
- **2D focus**: Mover with velocity updates.
- **VR fish tank layout**: Pink mover glides diagonally through tank leaving fading trail.
- **Light pink palette**: Trail gradient from accent pink to translucent white.
- **Line-derived controller**: Slider adjusts max speed; button randomizes initial velocity.
- **Testing notes**: Confirm velocity clamping and trail lifetime stability.

## Example: example_1_8_motion_101_velocity_and_constant_acceleration
- **2D focus**: Adds constant acceleration toward target.
- **VR fish tank layout**: Target orb floats mid-air; mover accelerates toward it with pink acceleration vector.
- **Light pink palette**: Acceleration arrow pulsing bright pink.
- **Line-derived controller**: Slider controls acceleration magnitude; knob toggles acceleration direction.
- **Testing notes**: Ensure acceleration integrates correctly and mover stays inside tank.

## Example: example_1_9_motion_101_velocity_and_random_acceleration
- **2D focus**: Random acceleration forces.
- **VR fish tank layout**: Mover meanders around cube with jittering pink force arrows.
- **Light pink palette**: Random impulses represented by flashing accent bursts.
- **Line-derived controller**: Slider sets noise intensity; button reseeds randomness.
- **Testing notes**: Verify randomness remains bounded and comfortable for VR viewer.

## Example: example_1_10_accelerating_towards_the_mouse
- **2D focus**: Seek behavior toward mouse.
- **VR fish tank layout**: Target proxy follows player gaze; mover seeks within cube.
- **Light pink palette**: Target bright pink; mover medium pink with arrow.
- **Line-derived controller**: Slider adjusts force gain; button snaps target to center.
- **Testing notes**: Confirm target proxy mapping and ensure smooth acceleration.

## Exercise: exercise_1_3_solution_3_d_bouncing_ball
- **2D focus**: 3D bouncing ball using vectors and WEBGL.
- **VR fish tank layout**: Expand to full cube bouncing with depth-aware trail.
- **Light pink palette**: Ball uses accent pink with emissive glint when hitting walls.
- **Line-derived controller**: Slider modifies restitution; knob toggles gravity axis.
- **Testing notes**: Verify 3D collisions align with tank boundaries and remain performant.

## Exercise: exercise_1_5_solution_accelerate_and_decelerate
- **2D focus**: Vehicle accelerates and decelerates along a line.
- **VR fish tank layout**: Pink train cart moves along elevated rail inside tank.
- **Light pink palette**: Cart glow intensifies with speed.
- **Line-derived controller**: Slider sets acceleration profile; button triggers braking sequence.
- **Testing notes**: Ensure easing curves feel smooth in VR.

## Exercise: exercise_1_8_solution_attraction_magnitude
- **2D focus**: Mover attracted toward center with magnitude-based force.
- **VR fish tank layout**: Central attractor sphere with gradient halo; mover orbits then settles.
- **Light pink palette**: Halo brightness indicates attraction strength.
- **Line-derived controller**: Slider adjusts attraction falloff.
- **Testing notes**: Confirm force magnitude updates and collision with attractor avoided.
