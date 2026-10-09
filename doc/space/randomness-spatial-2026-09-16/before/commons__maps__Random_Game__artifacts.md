# Random Game — room inventory

Revised 16 September 2026. 2 placed artifacts in a 15×20 m source grid.

The central crossing samples waits; a separate rear bay samples falling-cube positions and velocities. Both remain book encounters.

## r_c

Central hero / primary · (7, 5)

Three stones follow a fixed state order with sampled waits. Test the advance cue, cross the basin or take the side route.

Placement: `r_c#stand:chasm#cue:advance`

## cube_projectile_spawner

Second book encounter / primary · (7, 13)

A separate eight-by-eight field samples launch positions and velocities on a regular clock. Its control stand is outside the launch region.

Placement: `cube_projectile_spawner#mode:field#field_size:8x8#field_height:8#fall_min:1.6#fall_max:2.6#drift:0.25#jitter:0.25#jitter_interval:0.45#vertical_variation:0.2#spawn_interval:0.5#max_projectiles:24#stand:field`

## Retained archive

The previous layout and removed placements are preserved in `doc/space/randomness-staging-2026-09-16/before/`. No artifact scenes were deleted. The seven active rooms have no repeated artifact lookup; the wider stored map library remains available for later curation.
