# Dice Throw

A VR dice-throwing experiment. Grab a physical die from a felt-topped table, throw it, and see the result. Rolling a 6 rains 96 reward balls from the sky; rolling a 1 drops just 16. A statistics panel tracks the frequency of each face, the running mean (which converges toward the theoretical 3.50), and a visual bar chart of the distribution.

## Concept Taught

**Discrete uniform distribution and expected value.** A fair six-sided die is the canonical example of a discrete uniform distribution: each face has probability 1/6, and the expected value is (1+2+3+4+5+6)/6 = 3.5. This artifact makes those abstractions tangible. The reward ball shower gives proportional physical feedback -- rolling high is visually dramatic, rolling low is sparse. The statistics panel shows the empirical mean converging toward 3.50 and the frequency bars leveling out toward equal heights (16.7% each). The QFEP connection is equiprobability as fairness: each face is equally likely because the die is physically symmetric. Fairness is not imposed; it emerges from symmetry.

## How It Works

1. A table with felt top, wooden rim, and four legs is built procedurally. The die is placed on the table.
2. The die is an XRTools pickable RigidBody3D with a box collision shape, six faces of pips (spheres), and proper Western die layout (opposing faces sum to 7: 1/6, 2/5, 3/4).
3. When the die is dropped, it enters rolling mode. Each frame, linear and angular velocities are checked.
4. Once both are below threshold for 0.8 seconds, the die is considered settled.
5. The top face is determined by transforming each of the six face normal vectors through the die's current basis and finding which one has the highest dot product with world UP. That face's number (1-6) is the result.
6. Statistics are updated: total rolls, per-face counts, running mean, and percentage bar chart.
7. Reward balls spawn: `result * balls_per_pip` (default 16 per pip, so a 6 spawns 96 balls). Each ball is a RigidBody3D with slight color variation and emission glow, dropped from a cloud above the table.
8. Reward balls auto-clean after 8 seconds or when they fall too far.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `dice_size` | float | 0.08 | Size of the die (edge length) |
| `dice_mass` | float | 0.15 | Mass of the die |
| `dice_bounce` | float | 0.4 | Bounce coefficient |
| `dice_color` | Color | near-white | Die body color |
| `pip_color` | Color | near-black | Pip (dot) color |
| `ball_radius` | float | 0.025 | Reward ball radius |
| `ball_drop_height` | float | 3.0 | Height from which reward balls drop |
| `ball_color` | Color | orange | Base reward ball color |
| `balls_per_pip` | int | 16 | Reward balls per pip on the rolled face |
| `table_width` | float | 0.8 | Table width |
| `table_depth` | float | 0.6 | Table depth |
| `table_height` | float | 0.85 | Table height |
| `table_color` | Color | dark brown | Table body color |
| `felt_color` | Color | green | Table felt top color |

## Features

- Standard Western die with proper pip layout (opposing faces sum to 7)
- XRTools pickable die with freeze-on-grab, release-to-throw physics
- Highlight ring for VR hover/selection feedback
- Face detection via basis-transformed normal vectors dotted with world UP
- Proportional reward ball shower: result * 16 balls rain from the sky
- Reward balls with per-ball color variation and emission glow
- Running mean display converging toward theoretical 3.50
- Per-face frequency bar chart as ASCII art on Label3D
- Table with felt top (high friction), wooden rim, and four legs
- RESET button returns die to table; CLEAR button resets statistics
- Auto-cleanup of reward balls after 8 seconds

## Files

| File | Purpose |
|------|---------|
| `dice_throw.gd` | Complete dice experiment -- die construction, pip placement, physics, face detection, reward balls, statistics, VR controls |
