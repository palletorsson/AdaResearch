# The museum wall joins the Entropy experiment

The west wall of `Random_Entropy`, map rows 23–28, is replaced by 144 individual masonry blocks. This replaces both the map wall and the museum's outer skin, including collision. It is an application of the existing `entropy_ruin` rule to architecture.

The section starts paused. Its compact console runs/pauses, moves one stone, or restores the original wall and local seed. Only exposed top stones can be selected; 120 can move, leaving 24 low blocks above a fixed footing. The floor and the exit stay supported. Rubble lands in a bounded apron inside the hall. This is staged dismantling, not a structural or thermal simulation.

## Reusing it

The map owns the declaration:

```json
"museum": {
  "weathering_wall": {"side": "west", "start_z": 23, "length": 6, "seed": 79}
}
```

Currently supported: a straight west wall, 4–12 cells long, with every selected cell already a wall. Invalid declarations leave normal architecture in place. `em_weathering_wall.gd` owns the replacement stones; `_wall_at` excludes the original cells before batching or wall-run merging, and the detail pass keeps furnishings out of the opening. Other halls are unchanged unless they opt in.

The live map read and Python plan derivation both carry the declaration. Gallery data and exported museum plans were updated together.

## Evidence

Run `python doc/space/entropy-wall-2026-09-16/run_probe.py`. The actual museum probe passed 56 checks: high wall rays before/after/restore, retained low courses, all stones finite and present, full seeded replay, real console buttons and reach, entrance/exit and floor support. Captures include intact, 60 displaced stones, 120 displaced stones, and restored states.

The recovered four-work gallery has separate evidence in `../random-gallery-2026-09-16/`. Its text, primary roles and route are aligned before `Random_Game`; the earlier 10 PRINT hall remains in the route. Global content generation still reports the pre-existing `Tutorial_Disco` and `Noise_Inside_Noise` layer-size warnings.

Headset comfort has not been verified. Use `publish.py --publish` to publish the local review after the museum capture checks have passed.
