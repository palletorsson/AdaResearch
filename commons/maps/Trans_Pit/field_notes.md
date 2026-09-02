# Trans_Pit — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## Exactness decisions

- **The grower breathes.** `grower_block.gd`: `_time += delta * grow_speed *
  TAU; scale = lerp(min_scale, max_scale, t)`, a cycle, with `hot` colouring
  from small (safe) to big (danger). Tokens: min 0.3, max 3.5, speed 0.3
  cycles/s ≈ one breath per 3.3 s. The tutorial's `GrowerBlock` climbs once to
  max and stops; the first draft followed the tutorial. The text now says the
  blocks breathe and that the tutorial's grower differs.
- **pusher_block**: tokens axis z, distance 3, speeds 1.5 / 2 / 1.8, pauses
  1.5 / 1 / 1.2; `push_axis`, `push_distance`, `push_speed`, `pause_time`
  read in apply_grid_config. Probe item 9: the triangle wave stays in [0, 3].
- **Revolving walls** are the `rc` rotation-cube utility (`rc:90:y:4:-0.6`,
  `rc:90:y:3:-0.6`): "rotates to create walkable ramps/surfaces". The text
  says a quarter turn about a vertical axis, four cells and three.
- **Fire**: `h:fire` utilities; DeathEffect handles the reload (CLAUDE.md:
  35 dmg per 0.3 s tick).
- Structure heights: 5 walls, 3 floor, lower cells around the hazards.
