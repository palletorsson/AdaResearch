# Visual Aid HUD Modules

A collection of 3D HUD display elements for VR and desktop overlays. Each module is a self-contained Node3D scene that renders real-time information using Label3D nodes.

## Modules

| Module | Directory | Description |
|--------|-----------|-------------|
| Frames Display | `frames/` | Frames-per-second counter |
| Health Display | `gameplay/` | Player health with color-coded warnings |
| Hits Reset Display | `gameplay/` | Hits taken toward reset threshold |
| Memory Display | `memory/` | Static memory usage in MB |
| Draw Calls Display | `performance/` | Per-frame draw call counter |
| Player Position | `playerposition/` | XR origin world coordinates |
| Score Display | `score/` | Incrementable score counter with flash animation |
| Speed Display | `speed/` | Engine time scale readout |
| Spit Text 3D | `spittext/` | Typewriter-style text reveal triggered by VR input |
| Game Time Display | `time/` | Session elapsed time (HH:MM:SS) |

## Usage

Each module is a standalone `.tscn` scene. Add it as a child of your HUD or world-space UI container. Most modules update every frame via `_process` and require no external wiring. The gameplay modules connect to `GameManager` signals automatically.
