# Random Bubbles

A continuous particle system that spawns translucent, glowing bubbles inside a glass petri dish. Each bubble rises with a randomized speed, drifts horizontally, wobbles sinusoidally, and fades out over its lifetime. The artifact demonstrates how layering multiple random parameters on simple objects produces natural-looking emergent behavior.

## Concept Taught

Natural phenomena like boiling water, carbonation, and underwater vents produce bubbles whose sizes, speeds, and trajectories vary stochastically. This artifact teaches that realistic visual effects emerge not from complex physics simulations but from combining several independent random variables -- size, speed, drift, wobble frequency, wobble amplitude -- each drawn from a simple range. The result looks organic because real-world bubble behavior is itself driven by many small independent random factors.

## How It Works

1. **Petri dish construction** -- On `_ready()`, a glass-like cylindrical container is built from three nested cylinders (bottom plate, outer wall, inner wall with inverted culling) using a transparent, refractive `StandardMaterial3D`. A pink-tinted `OmniLight3D` adds subtle illumination.
2. **Timed spawning** -- A spawn timer fires at `spawn_rate` bubbles per second. Each spawn creates a `SphereMesh` instance at a random position within the `spawn_area_size` volume.
3. **Randomized properties** -- Each bubble receives:
   - A random scale between `min_bubble_size` and `max_bubble_size`
   - A random rise speed between `min_rise_speed` and `max_rise_speed`
   - A random horizontal drift vector
   - Random wobble amplitude and frequency for sinusoidal side-to-side motion
4. **Bubble lights** -- With probability `bubble_light_probability`, a bubble gets an attached `OmniLight3D` (up to `max_bubble_lights` total). Light energy fades proportionally to remaining lifetime.
5. **Lifetime management** -- Each bubble ages over `bubble_lifetime` seconds. During the final `bubble_fade_time` seconds, its alpha fades to zero. Once expired, the bubble and any attached light are freed.
6. **Audio system** -- An optional sound system supports both synthesized and pre-recorded bubble pop sounds. Pitch scales inversely with bubble size (smaller = higher pitch), and volume scales proportionally.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `spawn_area_size` | Vector3 | (6, 1, 6) | Volume where bubbles spawn |
| `min_bubble_size` | float | 0.2 | Smallest bubble scale |
| `max_bubble_size` | float | 0.8 | Largest bubble scale |
| `min_rise_speed` | float | 0.5 | Slowest upward speed |
| `max_rise_speed` | float | 2.0 | Fastest upward speed |
| `max_bubble_count` | int | 200 | Maximum simultaneous bubbles |
| `spawn_rate` | float | 2.0 | Bubbles spawned per second |
| `bubble_lifetime` | float | 10.0 | Seconds before a bubble expires |
| `bubble_fade_time` | float | 2.0 | Fade-out duration at end of life |
| `bubble_scale_down_rate` | float | 0.05 | Shrink rate as bubbles rise |
| `enable_bubble_lights` | bool | true | Whether some bubbles emit light |
| `bubble_light_probability` | float | 0.35 | Chance a bubble gets a light |
| `max_bubble_lights` | int | 24 | Maximum concurrent bubble lights |
| `bubble_light_energy` | float | 0.22 | Brightness of bubble lights |
| `bubble_light_range` | float | 1.8 | Range of bubble lights |
| `bubble_light_color` | Color | (1.0, 0.75, 0.92) | Color of bubble lights |
| `petri_dish_radius` | float | 3.5 | Radius of the glass dish |
| `petri_dish_height` | float | 0.25 | Height of dish walls |
| `petri_dish_thickness` | float | 0.04 | Wall thickness |
| `petri_dish_color` | Color | (1.0, 0.7, 0.9, 0.4) | Glass tint color |
| `use_synthesized_sounds` | bool | true | Use generated vs pre-recorded audio |
| `sound_variations` | int | 5 | Number of distinct generated sounds |
| `min_pitch_scale` | float | 0.8 | Lowest pitch multiplier |
| `max_pitch_scale` | float | 1.5 | Highest pitch multiplier |
| `min_volume_db` | float | -15.0 | Quietest volume |
| `max_volume_db` | float | -5.0 | Loudest volume |
| `max_concurrent_sounds` | int | 4 | Audio player pool size |
| `sound_play_chance` | float | 0.3 | Probability of playing a sound per bubble |
| `bubble_sounds` | Array[AudioStream] | [] | Pre-recorded sounds (alternative to synthesis) |

## Features

- Continuous bubble spawning with per-bubble randomized size, speed, drift, and wobble
- Glass petri dish with transparency, refraction, and rim lighting
- Optional per-bubble point lights with energy fade over lifetime
- Alpha fade-out and scale-down as bubbles age
- Sinusoidal wobble motion for organic lateral movement
- Audio system with size-dependent pitch and volume scaling
- Performance-optimized low-poly sphere meshes (8 radial segments, 4 rings)

## Files

| File | Description |
|------|-------------|
| `BubblesRandom.gd` | Main script -- bubble spawning, physics, petri dish, audio |
| `bubbles_random.tscn` | Scene file |
