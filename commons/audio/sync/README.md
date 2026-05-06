# Beat Sync

Precise beat synchronization controller for tempo-locked audio events.

## Files

- `BeatSyncController.gd` — Emits `beat`, `bar`, and `sixteenth` signals synchronized to audio playback. Works with both `AudioStreamPlayer` and `AudioStreamPlayer3D`. Supports hardware clock for tight timing.

## Usage

Attach to any node that needs tempo-aware behavior. Connect to its signals to trigger events on musical subdivisions — used by the sequencer, composition system, and any rhythm-driven gameplay elements.
