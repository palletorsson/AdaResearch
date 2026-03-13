# Flag Dancer

A skeletal-animation pride flag system that teaches **bone-driven mesh deformation, wind simulation, and procedural animation**. A flat flag mesh is rigged to a chain of bones, and a `_process()` loop applies sine-wave and noise-based transforms to each bone, producing a realistic fluttering cloth effect. Seven pride flag variants are included, and a celebration mode amplifies the motion and spawns colored particles.

## How It Works

1. **Skeleton and skinned mesh** -- A `Skeleton3D` is created with one bone per horizontal segment (17 bones for 16 segments). Each bone's rest transform places it at its corresponding X position along the flag width. A `SurfaceTool`-built mesh is skinned to these bones using linear weight blending between adjacent bones.

2. **Vertex coloring** -- Each vertex is colored by interpolating between the active flag's color stripe array. The stripe position is computed from the vertex's Y coordinate, and adjacent stripes are blended smoothly.

3. **Wind simulation** -- Each frame, every bone receives:
   - A **base wave** -- `sin(t * 2.0 + bone_offset) * 0.4 * wind_strength` displaces along Z.
   - A **noise wave** -- a second sine at a different frequency adds irregularity.
   - **Stretch factors** -- slight X and Y scale oscillation creates a breathing effect.
   - A global Z rotation sways the entire flag subtly.

4. **Celebration mode** -- Pressing SPACE toggles celebration. In this mode:
   - Wave amplitudes multiply by `celebration_intensity`.
   - Stretch oscillations increase dramatically.
   - Per-bone rotation is added around the forward axis.
   - A burst of 80 `CPUParticles3D` in the flag's colors erupts from the flag.

5. **Flag parade** -- The `create_flag_parade()` helper spawns four different flag types side by side, each with slightly randomized wind strength.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `flag_type` | FlagType enum | RAINBOW | Which pride flag to display |
| `wind_strength` | float | 1.0 | Multiplier on wind wave amplitudes |
| `celebration_intensity` | float | 1.0 | Multiplier on celebration mode effects |

### Flag Types

| Enum Value | Colors |
|------------|--------|
| `RAINBOW` | Red, Orange, Yellow, Green, Blue, Purple |
| `TRANS` | Light Blue, Pink, White, Pink, Light Blue |
| `BISEXUAL` | Magenta, Magenta, Purple, Blue, Blue |
| `NONBINARY` | Yellow, White, Purple, Black |
| `PANSEXUAL` | Pink, Yellow, Blue |
| `LESBIAN` | Orange, Light Orange, White, Light Pink, Dark Pink |
| `ASEXUAL` | Black, Gray, White, Purple |

## Features

- Seven pride flag color palettes with smooth inter-stripe blending.
- Bone-chain skeletal animation for realistic cloth deformation.
- Dual-sine wind model with per-bone phase offset for wave propagation.
- Celebration mode with amplified motion and per-bone rotation.
- `CPUParticles3D` burst using the active flag's gradient as a color ramp.
- `@tool` annotation allows the flag to animate in the Godot editor.
- `create_flag_parade()` spawns multiple flag variants in a line.
- SurfaceTool mesh with bone indices and weights for GPU skinning.
- No external assets -- the entire flag is procedural.

## Files

| File | Purpose |
|------|---------|
| `flagdancer.gd` | Main script -- skeleton setup, skinned mesh, wind animation, celebration particles |
