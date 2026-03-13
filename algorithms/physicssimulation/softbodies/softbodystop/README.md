# Soft Body Stop

A physics simulation artifact that demonstrates how to programmatically freeze Godot's `SoftBody3D` nodes mid-simulation. The scene places soft bodies in space, lets them deform under physics, then stops them at configurable times -- teaching the concept of **state freezing** in real-time simulations.

## Concept Taught

**Simulation state control** -- how a running physics simulation can be paused, frozen, or resumed for individual objects independently. This illustrates the difference between disabling processing entirely (`PROCESS_MODE_DISABLED`), cranking damping to an extreme value, and increasing stiffness to make a body rigid. The four-body variant shows how staggered timers create a visual timeline of deformation states captured at different moments.

## How It Works

1. **SoftBodyStopper** (`stopsoftbody.gd`) finds a single `SoftBody3D` in the scene tree and attaches a one-shot `Timer` to it. When the timer expires, the soft body is frozen using three simultaneous techniques: disabling its process mode, setting damping to 100.0, and raising linear stiffness to 1.0. Original physics values are stored in metadata for later restoration.

2. **FourSoftBodyController** (`fourstopsoftbody.gd`) instantiates four soft bodies in a 2x2 grid, each with its own timer set to a different stop time (default: 7.5s, 11.0s, 12.0s, 12.0s). This creates a side-by-side comparison of soft bodies frozen at different stages of deformation.

3. Both scripts support restart via `restart_soft_body()` / `restart_all()`, which re-enables processing and restores original damping and stiffness values.

## Parameters

### SoftBodyStopper (`stopsoftbody.gd`)

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `stop_after_seconds` | float | 4.0 | Seconds before the soft body freezes |
| `soft_body_scene_path` | String | `res://.../softbodybody.tscn` | Path to the soft body scene |
| `auto_start` | bool | true | Start the timer automatically on ready |
| `show_timer` | bool | true | Display a countdown label on screen |

### FourSoftBodyController (`fourstopsoftbody.gd`)

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `soft_body_scene_path` | String | `res://.../softbodybody.tscn` | Path to the soft body scene |
| `spacing` | float | 3.0 | Distance between soft bodies in the grid |
| `stop_times` | Array[float] | [7.5, 11.0, 12.0, 12.0] | Per-body stop times in seconds |
| `show_timers` | bool | true | Display countdown labels |

## Features

- Freezes soft bodies using three complementary methods (process disable, extreme damping, full stiffness)
- Stores and restores original physics values via node metadata
- Color-coded countdown UI (white > yellow > red)
- Keyboard controls: Space to restart, Enter for status report, number keys 1-4 to manually stop individual bodies
- Escape key applies a random impulse for interactive testing
- Fallback creation of basic soft bodies if the scene file fails to load

## Files

| File | Description |
|------|-------------|
| `stopsoftbody.gd` | Single soft body stopper with timer, UI, and restart support |
| `fourstopsoftbody.gd` | Four-body controller with staggered stop times in a 2x2 grid |
