# Chapter 5 (Steering Behaviors) VR Translation Notes

## Example: noc_5_01_seek
- **2D focus**: Single vehicle steering toward a target using seek behavior.
- **VR fish tank layout**: Vehicle begins near front-bottom corner; target orb oscillates near center-top. Visualize velocity as pink arrow meshes trailing the vehicle.
- **Light pink palette**: Vehicle body uses primary pink; velocity arrow brightens with speed.
- **Line-derived controller**: Slider adjusts max force; knob toggles target drift speed.
- **Testing notes**: Confirm steering force clamping and frame-stable target updates.

## Example: noc_5_02_arrive
- **2D focus**: Arrive behavior decelerating near the target.
- **VR fish tank layout**: Target sphere hangs above center; vehicle glides in from tank edge with trail fading inside cube.
- **Light pink palette**: Use gradient pink trail with white tip to highlight braking.
- **Line-derived controller**: Slider modifies deceleration radius; second control toggles arrival acceleration curve.
- **Testing notes**: Validate slowdown distance and ensure physics remains smooth at VR timestep.

## Example: noc_5_03_stay_within_walls
- **2D focus**: Vehicle steers to remain inside boundaries.
- **VR fish tank layout**: Vehicle loops within fish tank; render walls as faint pink energy planes.
- **Light pink palette**: Tank edges glow accent pink when vehicle nears boundary.
- **Line-derived controller**: Slider sets look-ahead distance; knob adjusts wall force multiplier.
- **Testing notes**: Check predictive steering and performance of collision avoidance.

## Example: noc_5_04_flow_field
- **2D focus**: Flow field steering based on Perlin noise vectors.
- **VR fish tank layout**: Populate cube with volumetric arrow glyphs representing flow; vehicle strafes through, aligning with vectors.
- **Light pink palette**: Flow arrows animate between light and medium pink to show direction.
- **Line-derived controller**: Slider morphs noise scale; dial rotates entire field.
- **Testing notes**: Ensure 3D Perlin sampling matches 2D logic and vectors render efficiently.

## Example: noc_5_05_path_following_simple
- **2D focus**: Vehicle follows predefined path.
- **VR fish tank layout**: Extrude path into pink ribbon running around interior perimeter; vehicle follows ribbon centerline.
- **Light pink palette**: Path ribbon emits soft pink; vehicle trail slightly brighter.
- **Line-derived controller**: Slider adjusts path radius tolerance; button resets vehicle to start.
- **Testing notes**: Validate projection onto path and choose 3D offset computations.

## Example: noc_5_07_separation
- **2D focus**: Vehicles maintain separation distance.
- **VR fish tank layout**: Swarm of vehicles moves within tank with translucent pink bubbles showing personal space.
- **Light pink palette**: Bubbles intensify when neighbors encroach.
- **Line-derived controller**: Slider controls desired separation, additional control toggles neighbor visualization.
- **Testing notes**: Confirm neighbor search efficiency and 90 FPS under larger swarm.

## Example: noc_5_08_path_following
- **2D focus**: Combined path following with forward prediction.
- **VR fish tank layout**: Create 3D ribbon path with vertical variation; vehicles predict ahead via pink ghost markers.
- **Light pink palette**: Ghost markers glow accent pink; main path remains medium pink.
- **Line-derived controller**: Slider tunes prediction distance; knob sets path segment speed.
- **Testing notes**: Validate prediction point logic and ensure ghost markers update smoothly.

## Example: noc_5_08_separation_and_seek
- **2D focus**: Vehicles seek targets while maintaining separation.
- **VR fish tank layout**: Mix of moving targets and vehicles within central volume; visualize combined force vectors as layered pink arrows.
- **Light pink palette**: Seek forces bright pink, separation forces desaturated magenta.
- **Line-derived controller**: Dual sliders for seek weight and separation weight.
- **Testing notes**: Confirm weighted behaviors sum correctly and clamp forces.

## Example: example_5_9_flocking
- **2D focus**: Classic boids with separation, alignment, cohesion.
- **VR fish tank layout**: 3D flock of boids whirls around player within cube, leaving faint pink trails.
- **Light pink palette**: Use varying pink shades per boid to show role; alignment arrows share accent color.
- **Line-derived controller**: Panel with three sliders for separation/alignment/cohesion weights.
- **Testing notes**: Stress-test boid count and ensure trail rendering does not drop frame rate.

## Example: example_5_9_flocking_with_binning
- **2D focus**: Flocking optimized with spatial partitioning.
- **VR fish tank layout**: Same as above but display partition grid as semi-transparent pink lattice when debug mode active.
- **Light pink palette**: Lattice lines lighten to show active bins.
- **Line-derived controller**: Slider toggles bin size; button switches debug lattice on/off.
- **Testing notes**: Confirm quadtree/octree search speeds and validate debug visualization toggles.

## Example: 5_6_path_segments_only & nature_of_code_example_5_5_path_only
- **2D focus**: Path representation utilities.
- **VR fish tank layout**: Floating pink bezier segments demonstrating corridor width without agents.
- **Light pink palette**: Segments glow medium pink with white control points.
- **Line-derived controller**: Slider cycles through stored path presets.
- **Testing notes**: Ensure segment rendering handles 3D transforms.

## Example: exercise_5_2
- **2D focus**: Vehicle seeking moving target with random jitter.
- **VR fish tank layout**: Vehicle chases dancing target sphere within mid-air plane.
- **Light pink palette**: Target pulses between pink tones as jitter increases.
- **Line-derived controller**: Slider modifies jitter magnitude.
- **Testing notes**: Confirm target noise path matches design and vehicle remains stable.

## Example: exercise_5_4_wander
- **2D focus**: Wander behavior using projected circle.
- **VR fish tank layout**: Render wander circle as floating disc ahead of vehicle with pink indicator showing chosen point.
- **Light pink palette**: Disc semi-transparent pink; chosen wander point bright accent.
- **Line-derived controller**: Sliders for wander radius and displacement.
- **Testing notes**: Ensure wander offset updates in 3D and remains bounded within tank.

## Example: exercise_5_9_angle_between
- **2D focus**: Visualizing angle between vectors.
- **VR fish tank layout**: Large 3D arrows anchored at tank center with interactive plane showing angle arc.
- **Light pink palette**: Angle arc highlighted in bright pink with subtle gradient fill.
- **Line-derived controller**: Slider rotates reference vector; knob scales magnitude.
- **Testing notes**: Confirm angle computation consistent with 3D vector math.

## Example: exercise_5_13_crowd_path_following
- **2D focus**: Multiple agents following crowd path.
- **VR fish tank layout**: Multi-agent crowd circles along elevated path ring; highlight lane discipline with pink guide rails.
- **Light pink palette**: Crowd agents use alternating pink shades to show lane positions.
- **Line-derived controller**: Sliders adjust crowd size and spacing.
- **Testing notes**: Validate crowd stability and ensure path rails update with slider changes.

## Example: example_5_12_sine_cosine_lookup_table
- **2D focus**: Demonstrates optimization via lookup tables.
- **VR fish tank layout**: Mount rotating pink waveform ribbons inside tank showing lookup vs. actual calculations.
- **Light pink palette**: Lookup curve bright pink; actual curve pale pink.
- **Line-derived controller**: Slider toggles lookup resolution; button recomputes table.
- **Testing notes**: Ensure lookup updates correctly and visualization remains smooth.

## Example: 5_11_quadtree_part_1
- **2D focus**: Spatial partitioning using quadtree for point queries.
- **VR fish tank layout**: Display 3D octree adaptation dividing fish tank into pink wireframe cells with points as glowing orbs.
- **Light pink palette**: Active subdivisions glow brighter pink; inactive cells fade.
- **Line-derived controller**: Slider sets capacity threshold; button runs query highlight.
- **Testing notes**: Benchmark octree insert/query times and ensure visualization toggles recompute efficiently.
