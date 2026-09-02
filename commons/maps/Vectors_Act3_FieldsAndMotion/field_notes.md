# Vectors_Act3_FieldsAndMotion — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## The hinge, and why it reads whole

The triage named this the forces hinge: Acts I–II treat vectors as objects and
operations; here they gain extent (a field) and history (motion). The text is
built on the room's own symmetry line, *a field is force spread over space;
motion is force spread over time*, and the two halves meet on the bubble gun,
which the artifact's own description hands over: "every emitter is a little
vector field."

## Exactness decisions

- **The chamber is calm by default.** `weather_vector_field` places bare, and
  its `weather` enum defaults to `calm`; the text says "it is calm when you
  arrive. The weather is yours to make, and it is made by addition," rather
  than describing a storm that is not running.
- **144 arrows** (`arrow_grid_size 12`), **five metres** (`world_size 5.0`),
  the windsock that turns to heading and stretches with magnitude, the
  anemometer that spins at speed: all from the script.
- **The slant is the ratio**, proven: equal down and across give 45.0°
  (`probe_act3_tutorial.gd`). Range peaks at 45° and 30/60 tie; the parabola's
  apex is at vy/g and the landing at 2vy/g; components recompose to v0²;
  integrating a constant acceleration for a second gives p = a/2 exactly; a
  vertical launch has zero range and the full v0²/2g apex.
- **`VectorMotion`'s arrows are the colours the script gives them**: green
  position from the origin, cyan velocity, orange acceleration (grabbable),
  and a 50-point fading trail. `drive` defaults to `constant`, so the trail is
  a parabola, and the text says so.
- **`field_at` and `advect` are quoted but not probed**: they depend on scene
  constants (`SWIRL_GAIN`, `RADIAL_GAIN`) the tutorial does not define. Only
  the pure functions are probed.
- The tutorial was left as it is; it already carries the argument block by
  block, as the triage found.

## The sequence problem this room sits in

`forces.json` files this room's flow console and storm as "belonging to rung
5" (`content`: "its flow console belongs to rung 5 and says so"), i.e. the
field idea is stated here at room 7, dropped for six rooms, and picked up by
VFM_04_Fields at room 14. That is a sequence-order problem, not a room
problem, and it is part of the compression case for forces (see the sequence
notes in the blog and the ruling to come).

## Open

- The `_physics_process` block is engine code, not a pure function; it is
  quoted for the chain and read as prose, and its claim ("only acceleration is
  driven") is verified by the integration check rather than by running a
  RigidBody headless.
