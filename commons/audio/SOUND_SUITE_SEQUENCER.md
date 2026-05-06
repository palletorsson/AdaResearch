# Sound Suite Sequencer

Last updated: 2026-02-11

`SoundSuiteSequencer` (`res://commons/audio/sequencer/SoundSuiteSequencer.gd`) is the runtime sequencer for:
- built-in generator suites
- soundbank-backed suites produced by `SuitToSoundbankMapper`

## What it does

- plays step patterns with swing/variation
- switches suite and pattern at runtime
- supports per-track params, mute, and volume
- emits timing and state signals
- carries optional genre `intent` payload to downstream logic

## Current suite sources

### Built-in suites (in code)
- `trap_beats`
- `tech_noir`

### Mapper-injected suites
At startup, `_register_mapper_suite()` is called for:
- `detroit_techno`

This comes from:
- `res://commons/audio/soundbanks/SuitToSoundbankMapper.gd`
- `res://commons/audio/soundbanks/SoundbankLoader.gd`
- `res://commons/audio/soundbanks/detroit_techno/brief.json`

## QA snapshot (2026-02-11)

Reference report:
- `commons/audio/documentation/SUITE_QA_MATRIX_2026-02-11.md`

Key findings from the static audit:
- `SoundSuiteSequencer` runtime mapper registration is currently limited to `detroit_techno` in `_ready()`.
- `SuitToSoundbankMapper` can build suites for all `GenreSynthBrowser` genres, but most are not yet playable in sequencer because matching soundbanks are missing.
- `detroit_techno` and `synthwave` have soundbank folders, but parity still has gaps:
  - missing mapped sounds in bank (for example `sequence`, `sweep_up`, `sweep_down`, `impact`)
  - missing element aliases (for example `supersaw`, `arp_synth`)
- For suites where mapped sounds are present, the generated `main` pattern is structurally complete by construction.

Use this as the current contract: sequencer core is stable, but full per-genre mapper parity is still in-progress.

## Initialize contract

```gdscript
var sequencer := SoundSuiteSequencer.new()
add_child(sequencer)

sequencer.initialize({
    "suite": "detroit_techno",
    "pattern": "main",
    "bpm": 128.0,
    "swing": 0.0,
    "variation": 0.1,
    "sound_params": {
        "kick": {"duration": 0.3, "gain": 1.0}
    }
})
```

Accepted keys:
- `suite` (String)
- `pattern` (String)
- `bpm` (float, clamped 40..200)
- `swing` (float, clamped 0..1)
- `variation` (float, clamped 0..1)
- `sound_params` (Dictionary by track name)

## Pattern format

Patterns are dictionaries:

```json
{
  "length": 16,
  "kick": [1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0],
  "snare": [0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0]
}
```

Values can be:
- `0` for no hit
- `>0` for velocity/weight

## Public API

### Control
- `initialize(config: Dictionary)`
- `start()`
- `stop()`
- `change_suite(suite_name: String) -> bool`
- `load_pattern(pattern) -> bool` (`String` or `Dictionary`)

### Tempo and feel
- `set_bpm(new_bpm: float)`
- `set_swing(amount: float)`
- `set_variation(amount: float)`

### Track control
- `set_sound_params(sound_name: String, params: Dictionary)`
- `get_sound_params(sound_name: String) -> Dictionary`
- `mute_track(track_name: String, muted: bool)`
- `set_track_volume(track_name: String, volume_db: float)`

### Discovery
- `get_available_suites() -> Array`
- `get_suite_sounds() -> Array`
- `get_current_intent() -> Dictionary`

## Signals

- `beat_triggered(beat_number: int)`
- `pattern_changed(pattern_name: String)`
- `suite_changed(suite_name: String)`
- `bpm_changed(new_bpm: float)`
- `intent_changed(intent: Dictionary)`

## Intent behavior

Intent enters the sequencer through mapper-generated runtime suites:
- mapper loads `res://commons/audio/parameters/genre_intent/*.json`
- runtime suite includes `intent`
- sequencer stores it in `current_intent`
- sequencer emits `intent_changed`

Important: intent is advisory. It is not a hard validator.

## Test scene

Use:
- `res://commons/audio/tests/test_sound_suite_sequencer.tscn`

Current key controls in test script:
- `1`: trap_beats
- `2`: tech_noir
- `3`: detroit_techno
- `Space`: play/stop
- `Q/W/E`: pattern changes
- arrow keys: bpm/swing

## Extending with a new soundbank suite

1. Add a soundbank folder with `brief.json` and sound scripts in `res://commons/audio/soundbanks/<genre_id>/`.
2. Ensure sound names in `brief.json` match script filenames.
3. Add/match element aliases in `SuitToSoundbankMapper.gd` (`ELEMENT_TO_SOUND`).
4. Register mapper suite in `SoundSuiteSequencer._ready()` via `_register_mapper_suite(...)`.
5. Validate with `test_sound_suite_sequencer.tscn`.
