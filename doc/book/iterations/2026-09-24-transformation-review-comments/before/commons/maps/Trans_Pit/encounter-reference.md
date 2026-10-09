# Trans_Pit — current encounter settings

21 September 2026. These notes retain implementation details moved out of [final.md](final.md). The current map contains level-ground translation, rotation and timed scaling studies, followed by the transformation airlock. The older technical chapter describes an earlier catalyst chamber and is not the reference for this configuration.

## Pusher rhythm

All three pushers travel two metres. The two along positive Z use speeds 1.5 and 2 m/s and endpoint pauses 1.5 and 1 seconds. The third moves along negative Z at 1.8 m/s with a 1.2-second pause. Travel therefore takes approximately 1.333, 1 and 1.111 seconds respectively. The eastern passage bypasses the lanes.

```gdscript
var speed_normalized: float = push_speed / push_distance
_t += _direction * speed_normalized * delta
_t = clampf(_t, 0.0, 1.0)
var target_pos: Vector3 = _start_pos.lerp(_end_pos, _t)
_body.global_position = target_pos
```

Speed divided by distance converts metres per second to a fraction of this journey per second. The pusher waits at each endpoint before reversing direction.

## Turning slabs

Both slabs take two seconds for a quarter-turn. Their endpoint pauses are four and three seconds. The collision body's transform follows the visible mesh. The upright wall profile changes the clearance beside it; the centre route remains available.

## Shared growth

The floor-anchored growers use `grow_speed=0.15`, with `_time` advanced by `delta * grow_speed * TAU`. Their cosine-driven factor varies from 0.3 to 3.5, a period of approximately 6.667 seconds. All three share that rate. Mesh and collision dimensions agree; their centres are half a side-length above the floor. This is clock-driven growth, unlike the preceding hall's proximity-driven shrinking.

## The final welcome

The airlock combines position and angle on an AnimatableBody3D via `Transform3D(turn, at)`. It scales the visual child and resizes the collision resource's vertices, preserving unit scale on the physical body. A compact combined-matrix derivation can be a later tutorial comparison; the current chapter follows the opening the visitor can use.

The literary revision changes no mechanics, placements or timings. See [the applied review](../../../doc/book/iterations/2026-09-21-transformation-return/index.html) for this pass's separate Rotation placement evidence.
