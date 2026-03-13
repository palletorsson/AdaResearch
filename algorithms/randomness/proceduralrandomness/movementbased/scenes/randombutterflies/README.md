# Random Butterflies -- Entropy-Seeking Movement

A butterfly spawner and movement system where butterflies wander randomly but are drawn to entropy gradient artifacts in the scene. This artifact teaches the concept of **biased random walk** -- how mixing pure random wandering with probabilistic goal-seeking (toward entropy_axiom nodes) creates movement that feels both natural and purposeful, demonstrating the interplay between randomness and attraction.

## How It Works

### butterflies.gd -- Spawner

1. A timer spawns new butterfly instances at `spawn_interval` seconds.
2. The spawner checks the `entropy_butterfly` group count and only spawns if below `max_butterflies`.
3. Each spawned instance is added to the "remove" group for cleanup, and the fly animation is started automatically.

### randommovementbutterfly.gd -- Movement Controller

1. **Random wander** -- The butterfly picks a random 3D direction (with reduced vertical range) and flies for a random duration between `min_move_time` and `max_move_time` seconds.

2. **Entropy seeking** -- With probability `entropy_seek_chance` (default 55%), the butterfly targets an `entropy_axiom` node instead of wandering:
   - Discovers entropy nodes via group lookup ("entropy_axiom") or recursive name scan.
   - Picks a random node, samples a random point within its grid (biased toward higher-entropy regions using `pow(z, 0.7)`).
   - Computes a target wing color based on the entropy level at that point (blue = low entropy, red = high entropy via HSV interpolation).
   - Flies toward the target and sits for `entropy_sit_duration` seconds, gradually tinting its wings toward the entropy color.

3. **Sitting behavior** -- Butterflies land at sitting points (predefined NodePaths or randomly generated positions) with a 30% chance, pausing their fly animation.

4. **Wing tinting** -- A shared StandardMaterial3D is applied to both wing meshes. While sitting on an entropy point, the material's albedo_color lerps toward the target entropy color at `wing_tint_speed`.

5. **VR interaction** -- The `on_released()` function handles VR grab-and-release: the butterfly immediately seeks a new entropy point, demonstrating that releasing randomness leads to new discoveries.

6. **Bounds enforcement** -- The butterfly is constrained to an `area_size` bounding box centered on a configurable `area_center` node, changing direction when it hits a boundary.

## Parameters

### butterflies.gd (Spawner)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `butterfly_scene` | -- | PackedScene to instantiate |
| `spawn_interval` | 10.0 | Seconds between spawn attempts |
| `max_butterflies` | 8 | Maximum concurrent butterflies |

### randommovementbutterfly.gd (Movement)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `area_size` | (20, 10, 20) | Bounding box for movement |
| `min_move_time` / `max_move_time` | 5.0 / 10.0 | Wander duration range |
| `speed` | 3.0 | Movement speed |
| `area_center` | -- | NodePath for bounding center |
| `sitting_points` | [] | Predefined landing positions |
| `use_random_sitting_points` | true | Generate random sitting positions |
| `num_random_sitting_points` | 5 | Count of random sitting spots |
| `sitting_duration` | 3.0 | Normal sit time in seconds |
| `entropy_seek_chance` | 0.55 | Probability of seeking entropy vs wandering |
| `entropy_sit_duration` | 4.0 | Sit time on entropy points |
| `wing_tint_speed` | 0.8 | Color lerp speed for wing tinting |
| `entropy_search_radius` | 50.0 | Max distance to scan for entropy nodes |

## Features

- Biased random walk mixing pure wandering with goal-seeking behavior
- Entropy gradient sampling with bias toward higher-entropy regions
- HSV-based wing color tinting reflecting local entropy level
- Group-based and recursive-scan discovery of entropy_axiom nodes
- VR grab-and-release interaction triggering new entropy searches
- AnimationPlayer integration for fly/sit state transitions
- Bounding box enforcement with direction change on boundary contact

## Files

| File | Description |
|------|-------------|
| `butterflies.gd` | Butterfly spawner with population cap |
| `randommovementbutterfly.gd` | Random walk + entropy-seeking movement controller |
| `butterflies.tscn` | Spawner scene |
| `butterfly.tscn` | Individual butterfly scene with mesh and animation |
| `pngegg.png` | Butterfly wing texture |
