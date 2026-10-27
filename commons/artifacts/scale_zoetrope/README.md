# Hand wheel / scale zoetrope

The floor59 study is an open five-metre black-steel disk with its top two metres
above the floor. Twenty-four permanently sized off-white cubes ride around it. A steel centre support holds the
disk, while the hand crank stays at 1.18 m and the control face at 1.98 m on its own
narrow stand. The starting setting is 60 RPM with a 12 Hz local clock, matching the
player's selected setting. No cube is dynamically resized or replaced.

Drag around the wheel rim on desktop. In XR, grip the pink crank and move
the hand around its axle. The motor stops while the hand owns the wheel and
resumes after 0.65 s following release. Turn RUN off to hold the chosen phase.

The control face above the crank uses the existing physical faders and buttons:

- RPM sets 0..3600 RPM, with extra precision at low speeds.
- CLOCK chooses display frames, or a local 6/12/24/30/60/90/120 Hz sampling clock.
  The local clock updates only this disk; it does not cap game or headset FPS.
- RUN pauses/resumes automatic motion. SHUTTER toggles the physical sector plate;
  it starts off for the open-view comparison. REVERSE changes direction.
- MATCH aligns a cube and sets one cube advance per sample. At 12 Hz, that is 30 RPM;
  at 24 Hz, 60 RPM. Display mode uses measured average FPS at the moment of pressing,
  so changes in real frame timing cause drift instead of a fabricated lock.

The readout separates RPM, cube passages per second, local sample clock, measured
render FPS and cube advances per sample. A local clock faster than the renderer
cannot create extra rendered states: overdue steps advance together.
Monitor refresh or headset presentation can sample those rendered frames again;
the FPS readout is not a physical display-refresh measurement. Real-time
motor speed uses elapsed time; lowering the render rate does not slow the motor.

The disk is open, with no central black drum or radial dividers. Each cube keeps its
own fixed size and local pose while the disk loops; only the disk rotates.
Opposite cubes can now be seen across the disk. An optional real opaque sector
shutter turns twenty-four times per disk turn. This is ideal gearing:
hand angle drives both meshes; there is no force-based belt or gearbox solver.
The missing sector provides interrupted exposure without flashing room lights.
Slow turning reveals separate steps. A continuous illusion depends on turning
speed and display timing; static views and supplied XR poses cannot establish
physical-headset perceptual quality.

Two groups are independently editable in the shared lab editor: `DiskAndCrank`
and `PlaybackControls`. Keep the coupled disk/crank/shutter assembly together
for operation. The preview is actual exported geometry in a static pose, not a
browser simulation. The floor and prefab use `only_parts` to omit the old
`RoomShell` and `ServicePanel`, including all enclosure colliders and lights.
The source retains these legacy groups for old saved sketches.

`initial_angle` chooses a starting phase. `service_open` chooses the panel state.
`auto_run`, `motor_rpm`, `sample_hz`, `shutter_enabled` and `reverse` choose playback.
The standard `parts` and `only_parts` configuration supports isolated copies.

Native evidence is in `ada_run/scale-zoetrope-playback/`. FPS is Godot's measured
average: https://docs.godotengine.org/en/4.6/classes/class_engine.html#class-engine-method-get-frames-per-second

The shared `machine_finish.gd` continues the Point Lines pink and off-white palette.
Black steel carries the structure; pink marks grips, control caps and index ticks;
ivory cubes have twelve physical dark edges merged into one mesh per cube. The
hand-driven sine yoke uses the same finish. Controls move outside the larger disk;
all original floor object positions remain unchanged. At the retained 60 RPM and
12 Hz setting, two cubes advance per sample; MATCH selects one instead.
