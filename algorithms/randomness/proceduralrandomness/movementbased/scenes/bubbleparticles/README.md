# Bubble Particles

A real-time bubble particle system that continuously spawns translucent spheres rising upward with wobble, drift, fade, and optional spatialized sound. This artifact teaches the concept of **randomized motion parameters** -- how assigning each particle its own random speed, wobble frequency, drift direction, and lifetime creates a naturalistic, organic simulation from simple per-frame update rules.

## How It Works

1. **Spawning** -- A timer spawns new bubbles at a configurable rate until the maximum count is reached. Each bubble is placed at a random position within a 3D spawn area.

2. **Per-bubble randomness** -- Each bubble gets its own:
   - Rise speed (between `min_rise_speed` and `max_rise_speed`)
   - Initial scale (between `min_bubble_size` and `max_bubble_size`)
   - Horizontal drift direction (random 2D vector)
   - Wobble amount and speed (sinusoidal X/Z motion)

3. **Per-frame update** -- Every frame, each bubble:
   - Rises upward at its own speed
   - Drifts horizontally
   - Wobbles using `sin()` and `cos()` with its age and wobble speed
   - Gradually shrinks based on `bubble_scale_down_rate`
   - Fades out (alpha decreases) during the final `bubble_fade_time` seconds of its lifetime
   - Is removed when its age exceeds `bubble_lifetime`

4. **Sound system** -- A pool of AudioStreamPlayer3D nodes is pre-created. When a bubble spawns, there is a `sound_play_chance` probability of playing a sound. Pitch is inversely proportional to bubble size (small = high pitch), and volume scales with size. Supports both synthesized and pre-recorded sound arrays.

5. **Material** -- Each bubble uses a transparent pink material with slight emission, low roughness, and metallic specular for a glass-like appearance.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `spawn_area_size` | (10, 1, 10) | 3D bounds for bubble spawning |
| `min_bubble_size` | 0.2 | Smallest bubble scale |
| `max_bubble_size` | 0.8 | Largest bubble scale |
| `min_rise_speed` | 0.5 | Slowest upward speed |
| `max_rise_speed` | 2.0 | Fastest upward speed |
| `max_bubble_count` | 200 | Maximum simultaneous bubbles |
| `spawn_rate` | 2.0 | Bubbles spawned per second |
| `bubble_lifetime` | 10.0 | Seconds before a bubble is removed |
| `bubble_fade_time` | 2.0 | Seconds of fade-out at end of life |
| `bubble_scale_down_rate` | 0.05 | Shrink rate as bubbles age |
| `use_synthesized_sounds` | true | Use synthesized vs pre-recorded sounds |
| `sound_variations` | 5 | Number of synthesized sound variants |
| `min_pitch_scale` | 0.8 | Pitch for largest bubbles |
| `max_pitch_scale` | 1.5 | Pitch for smallest bubbles |
| `min_volume_db` | -15.0 | Volume for smallest bubbles |
| `max_volume_db` | -5.0 | Volume for largest bubbles |
| `max_concurrent_sounds` | 4 | Audio player pool size |
| `sound_play_chance` | 0.3 | Probability of sound per bubble |

## Features

- Inner `Bubble` class encapsulates per-particle state and material
- Sinusoidal wobble motion with per-bubble frequency and amplitude
- Alpha fade-out during final seconds of lifetime
- AudioStreamPlayer3D pool with automatic recycling on playback finish
- Size-dependent pitch and volume for natural sound variation
- Low-polygon sphere mesh (8 segments, 4 rings) for performance

## Files

| File | Description |
|------|-------------|
| `bubble_particles.gd` | Bubble particle system with wobble, fade, and sound |
| `bubble_particles.tscn` | Scene file for the bubble particle system |
