# Slot Machine -- Independence and Uniform Distribution

A VR-interactive slot machine with three reels that teaches **statistical independence** and **convergence toward uniform distribution**. Each reel is an independent uniform trial over 6 symbols. The combination space grows multiplicatively (6^3 = 216 outcomes), and a running histogram shows how empirical frequencies converge to the theoretical uniform distribution as the number of pulls increases.

## How It Works

The machine is built procedurally in `_ready()`: a pedestal, a cabinet with gold trim, three reel pivots with 6 symbols each arranged around a cylinder circumference, a glass viewing window with a payline indicator, and VR push-button controls.

When the lever is pulled:
1. Each reel is assigned a random target index (`randi() % 6`), independently.
2. All reels spin at `spin_speed` radians/second with staggered initial offsets.
3. After an initial spin period (1.2s), reels stop one by one (left to right) with a deceleration curve, snapping to their target angle.
4. When all reels stop, the result is recorded -- symbol counts for reel 1 are tracked in a histogram, and triple matches are counted.

The stats panel displays:
- Total pulls and triple-match count with observed percentage
- Theoretical triple rate (6/216 = 2.78%)
- A text-bar histogram of reel 1's symbol distribution

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `cabinet_width` | float | 0.50 | Cabinet width in meters |
| `cabinet_height` | float | 0.55 | Cabinet height in meters |
| `cabinet_depth` | float | 0.30 | Cabinet depth in meters |
| `cabinet_color` | Color | (0.6, 0.08, 0.12) | Cabinet body color |
| `trim_color` | Color | (0.85, 0.75, 0.2) | Gold trim color |
| `reel_count` | int | 3 | Number of reels |
| `symbols_per_reel` | int | 6 | Symbols on each reel |
| `spin_speed` | float | 12.0 | Reel spin speed (rad/s) |
| `stop_delay` | float | 0.7 | Seconds between each reel stopping |
| `pedestal_height` | float | 0.85 | Height of the pedestal base |

## Features

- Fully procedural cabinet, reels, window, and control panel construction
- Independent per-reel random outcomes with deceleration animation
- Running histogram showing convergence to uniform distribution
- Triple-match detection with visual flash feedback
- VR push-button controls: PULL, AUTO (timed repeat), RESET
- Auto-spin mode with configurable interval (3.5s)

## Files

- `slot_machine.gd` -- Complete slot machine implementation (class_name SlotMachine)
