# Chapter 3 (Oscillation) VR Translation Notes

## Example: example_1_10_accelerating_towards_the_mouse
- **2D focus**: Mover accelerates toward cursor using vector math.
- **VR fish tank layout**: Position mover near tank center while a pink target orb follows an invisible head-tracked cursor proxy around the cube interior.
- **Light pink palette**: Mover sphere uses medium pink; acceleration arrow fades from accent pink to white.
- **Line-derived controller**: Slider scales acceleration gain; button recenters target proxy.
- **Testing notes**: Ensure target proxy respects tank bounds and accelerations remain smooth in 3D.

## Example: example_3_1_angular_motion_using_rotate
- **2D focus**: Demonstrates angular rotation using trigonometry.
- **VR fish tank layout**: Mount rotating beam inside tank with pivot at center; beam sweeps overhead.
- **Light pink palette**: Beam emits soft pink gradient with brighter tip indicator.
- **Line-derived controller**: Slider adjusts angular velocity.
- **Testing notes**: Validate rotation math in 3D and maintain beam within tank bounds.

## Example: example_3_2_forces_with_arbitrary_angular_motion
- **2D focus**: Movers orbit an attractor combining forces and angular velocity.
- **VR fish tank layout**: Central attractor glows at cube center; movers orbit in varying planes.
- **Light pink palette**: Attractor bright accent pink; movers medium pink trails.
- **Line-derived controller**: Sliders adjust attractor strength and angular damping.
- **Testing notes**: Confirm force combining and ensure stable orbits without clipping walls.

## Example: example_3_3_pointing_in_the_direction_of_motion
- **2D focus**: Aligns mover orientation with velocity vector.
- **VR fish tank layout**: Arrow-shaped mover cruises around tank, always pointing along motion.
- **Light pink palette**: Arrow body medium pink, outline bright accent.
- **Line-derived controller**: Slider modifies thrust magnitude.
- **Testing notes**: Verify orientation updates frame-synchronously.

## Example: example_3_4_polar_to_cartesian
- **2D focus**: Converts polar coordinates to Cartesian oscillation.
- **VR fish tank layout**: Orbiting particle traces pink circle around origin within tank center.
- **Light pink palette**: Trail uses translucent pink ribbon.
- **Line-derived controller**: Slider sets radius; knob tunes angular speed.
- **Testing notes**: Confirm conversions and ensure orbit stays inside fish tank.

## Example: example_3_5_simple_harmonic_motion & example_3_6_simple_harmonic_motion_ii
- **2D focus**: Basic SHM with sine/cosine.
- **VR fish tank layout**: Suspended bob oscillates along X-axis; second variant introduces multiple axes.
- **Light pink palette**: Bob uses primary pink with glowing trail showing amplitude.
- **Line-derived controller**: Sliders for amplitude and frequency.
- **Testing notes**: Validate sinusoidal motion and no drift over time.

## Example: example_3_7_oscillator_objects
- **2D focus**: Multiple oscillators with varying phase.
- **VR fish tank layout**: Array of pink rods anchored to floor oscillate with differing offsets.
- **Light pink palette**: Each rod tinted slightly different pink to show phase.
- **Line-derived controller**: Slider randomizes phases; knob adjusts global speed.
- **Testing notes**: Ensure independent oscillators remain performant.

## Example: example_3_8_static_wave & example_3_9_wave series (a, b, c)
- **2D focus**: Generates sine-wave-based static and dynamic waves.
- **VR fish tank layout**: Horizontal ribbon across tank displays waveform displacement along Y-axis.
- **Light pink palette**: Wave crest accent pink; trough pale pink.
- **Line-derived controller**: Sliders for wavelength and amplitude; button toggles wave variant.
- **Testing notes**: Confirm vertex updates run efficiently.

## Example: example_3_10_swinging_pendulum
- **2D focus**: Pendulum swinging via gravitational torque.
- **VR fish tank layout**: Pendulum suspended from tank ceiling, bob staying within cube interior.
- **Light pink palette**: Rod semi-transparent pink; bob bright accent.
- **Line-derived controller**: Slider modifies gravity magnitude; button resets angle.
- **Testing notes**: Validate period calculations and collision with tank walls avoided.

## Example: example_3_11_a_spring_connection
- **2D focus**: Spring connecting bob to fixed anchor.
- **VR fish tank layout**: Anchor at ceiling, bob oscillating vertically inside tank.
- **Light pink palette**: Spring rendered as glowing pink helix stretching with tension.
- **Line-derived controller**: Slider adjusts spring constant; knob sets damping.
- **Testing notes**: Ensure spring integration stable at VR timestep.

## Exercise: exercise_3_1_baton
- **2D focus**: Rotating baton with endpoints tracing circles.
- **VR fish tank layout**: Baton floats horizontally, endpoints leaving pink circular trails.
- **Light pink palette**: Endpoints accent pink; bar medium pink.
- **Line-derived controller**: Slider controls rotation speed.
- **Testing notes**: Confirm consistent angular motion.

## Exercise: exercise_3_5_spiral
- **2D focus**: Drawing expanding spiral via oscillation.
- **VR fish tank layout**: Generate spiral ribbon growing outward from center floor.
- **Light pink palette**: Spiral transitions from light to dark pink as radius increases.
- **Line-derived controller**: Slider adjusts growth rate.
- **Testing notes**: Ensure spiral remains within tank volume.

## Exercise: exercise_3_6_asteroids
- **2D focus**: Spaceship rotates and thrusts; demonstrates angular velocity.
- **VR fish tank layout**: Ship navigates mid-air plane inside cube with asteroids as floating rocks.
- **Light pink palette**: Ship outline accent pink; thruster exhaust bright bloom.
- **Line-derived controller**: Slider adjusts thrust force; knob tunes rotational acceleration.
- **Testing notes**: Verify ship wrap/clamp within fish tank; ensure inputs map to VR-friendly controls.

## Exercise: exercise_3_11_oop_wave & exercise_3_12_additive_wave
- **2D focus**: OOP wave classes and additive waveform composition.
- **VR fish tank layout**: Stack multiple wave ribbons vertically to show combined effect.
- **Light pink palette**: Each component wave tinted distinct pink shade; sum wave bright accent.
- **Line-derived controller**: Panel of sliders toggles amplitude/frequency per wave.
- **Testing notes**: Confirm additive updates remain performant and visually readable.

## Exercise: exercise_3_15_double_pendulum
- **2D focus**: Chaotic double pendulum rendered with WEBGL.
- **VR fish tank layout**: Double pendulum hangs from ceiling with motion trails painting pink arcs inside cube.
- **Light pink palette**: Links medium pink; end bob bright accent leaving long-lasting trail.
- **Line-derived controller**: Slider changes energy input; button resets initial conditions.
- **Testing notes**: Ensure numerical integration stable and WebGL effects port to Godot.





