# B12 — the ground keeps the colour

Implemented 2026-10-13 after Palle confirmed that a ball striking the ground should change the floor.

Both the formed hand sphere and the existing held catalyst send their real projectile. In Colour, the released ball receives a palette colour fixed at release. A tile impact keeps Transformation’s ×0.8 scale and +22.5° rotation, and colours that same tile. The skull’s coloured balls recolour tiles as before. The nominal grid cell is 2 × 2 m; the tile may already have shrunk or turned. Another impact replaces the tile's colour. Cover, head, player and revealed-backing impacts do not paint through to a tile. Colour is attached to the actual collider hit, not guessed from its old grid footprint.

Marked tiles retain their material while untouched disco tiles continue cycling. The background palette is dimmer and steps every four seconds, so marks remain distinguishable. REST and victory retain marks. RESET or a new START clears them; changing stage also starts fresh. These marks are encounter state, not saved across game sessions.

## Scope

- `commons/hazards/biome_ladder/ladder_encounter.gd`: tile addressing, retained materials, reset, local projectile colouring and scoped signal connections.
- `commons/hazards/biome_ladder/ladder_skull.gd`: emits its newly created ball for encounter-specific effects.
- `commons/hazards/catalyst_counterpart/head_ball.gd`: exposes an impact signal with the actual contact point. Existing player damage and projectile movement are unchanged.
- `tools/probes/biome_colour_floor.gd`: actual input, held-object use, projectile collision, material lifetime and cleanup checks.

The earlier stages remain monochrome. The shared hand ability's Colour connection is removed on exit, and the saved museum unlock is restored. Player health, head defeat, cover geometry and projectile speeds are unchanged.

## Evidence

40/40 new rendered Godot checks, exit 0. Covers real mouse shooting, grabbing/firing the held sphere, actual skull balls, exact receiving tiles, replacement colour, palette independence, REST/RESET, stage gates, translated arena coordinates and removal of the global ability callback. No test invokes the painting callback directly.

Native before/after captures and report: `ada_run/biome_colour_floor/`. The capture's bright tiles were coloured by actual projectile flights. One head has been defeated in the after view. Camera and disco/motion phase are matched.

Existing stage regression: 54/54; desktop regression including the mature biome: 47/47. Both processes exit 0. Logs: `ada_run/biome_colour_floor/biome_ladder.log` and `desktop_biome_catalyst.log`. An existing ObjectDB cleanup warning remains; headset feel and performance have not been tested.

## Next

Tiling can copy a retained source mark. Palle also specified actual walkable sine relief for Waves, rougher random ground, then smoother correlated ground for Noise. See TERRAIN-LINEAGE.md. Those terrain stages are planned, not implemented here.
