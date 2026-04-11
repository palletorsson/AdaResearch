# Disco Floor

Array-learning disco floor system — teaches array indexing through animated tile patterns with optional music.

## Key Files
- `DiscoGridAlgorithm.gd` — Core algorithm with 8 progressive lessons: corner blink, row lighting, column lighting, snake pattern, spiral inward, pulse center, wave diagonal, disco celebration; emits `lesson_changed`, `algorithm_finished`
- `StandaloneDiscoFloor.gd` — Self-contained floor with MultiMesh tiles (does NOT modify main GridSystem); 10 patterns (solid, checkerboard, wave, pulse, spiral, snake, sparkle, rainbow); exports for grid_width/depth, tile_size, walkable, auto_start
- `DiscoFloorController.gd` — Simple controller instantiating DiscoGridAlgorithm; applies grid_config
- `DiscoFloorInteractable.gd` — Map-spawnable wrapper via `standalone_disco#width:8#depth:8`; implements `apply_grid_config()`
- `DiscoControlPanel.gd` — VR control panel using rack interactables (push buttons, sliders) to control the floor
- `DiscoSequencerBridge.gd` — Connects StepSequencer beats to StandaloneDiscoFloor; pulses tiles per beat
- `DiscoMusicGenerator.gd` — Synthesizes disco beats: 4-on-floor kick, syncopated hi-hat, bass line, funk chords
- `SimpleDiscoMusic.gd` — Authentic disco vibes with multiple styles (classic, funk, eurobeat)
- `discofloor.tscn` — Minimal scene with DiscoGridAlgorithm
- `standalone_disco_floor.tscn` — Standalone floor variant
