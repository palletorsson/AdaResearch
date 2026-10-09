# Random Game — state, time, position and support

Builds on Random_Mushrooms' distinction between construction and sampled choices; prepares for Noise_Types and relations between neighbouring samples. These excerpts come from the implemented crossing and falling-field scripts.

## Crossing

`commons/primitives/cubes/random_cycle_cube.gd` supplies the `r_c` token. The map uses `r_c#stand:chasm#cue:advance` at (3,4), in its existing five-by-three pit of zero structure cells. It is a cycling cube, not a score controller.

The fixed order is IDLE → GOING_OUT → HIDDEN → COMING_IN. The wait bands in this hall are [2.4,4.6] and [1.1,2.2] seconds. Despite its name, `wait_span_seconds` is the upper endpoint, not an amount added to the lower endpoint.

```gdscript
var min_wait: float = max(0.1, wait_min_seconds)
var max_wait: float = max(min_wait, wait_span_seconds)
```

The sampled duration is recorded once. The display subtracts engine uptime from a stored deadline:

```gdscript
var left: float = max(0.0, float(_step_until_ms - Time.get_ticks_msec()) / 1000.0)
```

The display is refreshed about every 0.12 seconds and rounds its values. SceneTree timers and tweens execute at engine frame boundaries. The stored millisecond deadline is a display estimate, not proof of exact wall-clock transition times. Changing Engine.time_scale or pausing the tree would require revisiting this clock agreement; those conditions are not this room's controls.

`step_state()` now exposes the actual state separately from the last wait kind. LEAVES and RETURNS retain the last wait at zero; the tablet no longer calls sinking STANDS or rising GONE. The crown checks IDLE and a positive remaining interval of at most 1.2 seconds. All three stones keep during-motion beacons, including when CUE removes the rings. The tablet remains present in both conditions.

The collider is disabled after the 0.5-second sink and 0.2-second delay; after the hidden wait, another 0.2-second delay precedes enabling collision and the 0.2-second rise. State, position and collider must be inspected independently.

REPLAY reseeds the same assignment of streams and restores position/support. `_restart_cycle_loop` invalidates old tickets immediately and kills an active movement tween before starting the replacement loop. NEW SEED excludes the present five-digit number but keeps no history of earlier names. The sequence of draws is replayed; exact wall-clock timestamps and the rest of the museum are not.

The hall floor is root-local CH_FLOOR = 0.28, bed top CH_BED = −0.74, and stone tops CH_PROUD = 0.22 above the hall floor. CH_SINK = 1.22 leaves a sunken stone top 0.02 above the bed. The standing-top-to-bed difference is 1.24 m; floor-to-bed is 1.02 m. CH_PITCH = 1.12 gives 0.12 m gaps between one-metre stones.

The artifact supplies the bed, side/end walls, thresholds and west recovery ramp. `_process` cancels the moving root's displacement out of its staging child. The east corridor is an alternative route through the hall; a map flood fill does not prove absence of attacks from other artifacts.

## Falling field

`commons/primitives/cubes/CubeSpawner.gd` is configured at (6,12) with `mode:field`, an 8×8 region, launch height 8, fall range 1.6–2.6, drift 0.25, jitter 0.25, jitter interval 0.45, vertical variation 0.2, spawn interval 0.5 and a maximum of 24 projectiles. `stand:field` adds a panel and initial-position boundary strips; default placements add neither.

```gdscript
var initial_velocity = Vector3(
    _rng.randf_range(-field_initial_horizontal_speed, field_initial_horizontal_speed),
    -fall_speed,
    _rng.randf_range(-field_initial_horizontal_speed, field_initial_horizontal_speed)
)
```

This mode samples x and z in world axes around the spawner's world origin, not rotated local axes. Its initial height is constant. Positions are continuous samples rather than selection of 64 grid cells. A regular Timer attempts launches; at the active-body cap the attempt is skipped. Existing global desktop P/O/C shortcuts remain, but the new panel provides local pointer controls.

RUN / STOP toggles the timer. STOP leaves active bodies; CLEAR queues those bodies for deletion and clears their account without changing the running state. Repeated toggles cancel the prior pulse tween instead of stacking animations. Configuration can arrive before `_ready`, so the interval setter must retain the number even when its Timer node is not yet bound.

`ProjectileCube.gd` gives each body its own randomized generator. Every jitter update selects a new lateral velocity and a downward speed near that body's base fall speed. Gravity is disabled in field mode, and the integration callback imposes the current velocity. This is prescribed velocity with collision response, not a freely accelerating rain model.

```gdscript
velocity.x = _rng.randf_range(-horizontal_jitter_strength, horizontal_jitter_strength)
velocity.z = _rng.randf_range(-horizontal_jitter_strength, horizontal_jitter_strength)
velocity.y = -new_fall_speed
linear_velocity = velocity
```

`field_seed` controls initial positions and velocities only. The review repeats those records while checking that projectile jitter streams remain independent. No distribution-mode panel, survival-score controller or per-frame performance measurement is claimed. The legacy empty audio placeholders are omitted rather than treated as playable sounds.

## Remaining company and validation limits

Six folding creatures and `monte_carlo` remain secondary. The latter's π sampling implementation exists; its integration, option-pricing and random-walk alternatives are stubs. Its camera/input arrangement and staging need a separate pass before promotion. Enemies can detect and pursue; moving their map cells does not establish isolation. Combat balance and a controlled encounter activation scheme remain open.

The independent desktop run checks museum placement, floor rays, recovery, real pointer controls, reset during movement, cue invariance, initial launch records and the cap. Headset approach, comfort, legibility and performance remain for a later visit.

The map still names `monte_carlo`, but the current museum loader reports no living scene for it and omits that body. It is a secondary candidate, not a verified encounter in this lane. Eight of the nine requested artifact placements currently build.
