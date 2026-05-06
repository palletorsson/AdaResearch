# Animated Cube Builder

## Scene
- `animatedcubebuilder.tscn`: procedural cube build sequence in-world (no UI dependency).

## Registry Key
- `animatedcubebuilder`

## Map Token Examples
- `animatedcubebuilder`
- `animatedcubebuilder:0:0:0.5`

## Behavior
- Builds cube in phases: vertices -> edges -> triangle faces.
- Uses grabbable point handles for post-build deformation.
- Emits `animation_step_completed` and `animation_completed` signals.

## VR Notes
- Mesh and edge objects are pre-created, then toggled visible over time.
- Keep multiple instances sparse to avoid overdraw from transparent faces.
- Default pacing is set for readable in-headset observation, not speedrun timing.
