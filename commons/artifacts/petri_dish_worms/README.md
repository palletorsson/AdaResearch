# Petri Dish Worms

Simulates a colony of oscillating sine worms crawling inside a transparent petri dish. Each worm follows a random walk with sinusoidal lateral oscillation, bouncing off the dish boundary. Teaches agent-based simulation, sine wave motion, and boundary reflection.

## How It Works

Each worm moves forward along its heading direction at a randomized speed. Lateral sine-wave oscillation is applied perpendicular to the heading, creating the characteristic undulating crawl motion. When a worm approaches the dish boundary (85% of dish radius), its direction vector is reflected off the boundary normal to keep it contained. Random small turns (1% chance per frame) add wandering behavior. Worms are rendered as tapered triangle-strip ribbons using ImmediateMesh, with per-vertex alpha fading from head to tail and width tapering for a natural appearance.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `num_worms` | int | 8 |
| `worm_length` | int | 20 |
| `worm_speed` | float | 0.3 |
| `oscillation_speed` | float | 1.5 |
| `oscillation_amplitude` | float | 0.02 |
| `worm_radius` | float | 0.012 |
| `dish_radius` | float | 0.15 |
| `dish_height` | float | 0.02 |
| `medium_color` | Color | (0.9, 0.85, 0.7, 0.4) |

## Features

- Up to 30 independent worm agents with randomized speed, color, and phase
- Sine-wave lateral oscillation for realistic crawling motion
- Boundary reflection to keep worms inside the dish
- Triangle-strip ribbon rendering with head-to-tail alpha fade and width taper
- Transparent glass dish and agar medium materials
- VR speed slider for global simulation speed control
- Varied worm colors (pinks, oranges, greens) for visual contrast

## Files

- `petri_dish_worms.gd` — Main script
- `petri_dish_worms.tscn` — Scene file
