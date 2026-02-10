# Sound System Guide

Last updated: 2026-02-10

This guide covers the runtime ambient path used during map/scene playback.

For catalog and song authoring, see:
- `commons/audio/catalog/ARCHITECTURE.md`

For suit sequencing, see:
- `commons/audio/SOUND_SUITE_SEQUENCER.md`

## Runtime audio path

Core components:
- `res://commons/audio/SoundBankSingleton.gd`
- `res://commons/audio/AmbientSoundController.gd`
- `res://commons/audio/ambient_presets.json`

Typical flow:
1. Resolve map/sequence audio config.
2. Instantiate `AmbientSoundController`.
3. Call `load_preset(preset_id, volume_db, crossfade_seconds)`.
4. Controller pulls sounds/preset data via `SoundBankSingleton`.

## Configuration cascade

Recommended override order:
1. global defaults
2. sequence-level audio config
3. map-level audio config

Use explicit map overrides only where needed.

## Required setup

Add singleton autoload:
- name: `SoundBank`
- path: `res://commons/audio/SoundBankSingleton.gd`

## Minimal integration snippet

```gdscript
var ambient_controller := AmbientSoundController.new()
ambient_controller.name = "AmbientSound"
map_root.add_child(ambient_controller)

ambient_controller.load_preset(
    audio_config.get("ambient_preset", "silent"),
    float(audio_config.get("volume", 0.0)),
    float(audio_config.get("crossfade_duration", 2.0))
)
```

## Async loading and transitions

Ambient loading can run asynchronously and should not block scene transitions.

Key support files:
- `res://commons/audio/AsyncAudioGenerator.gd`
- `res://commons/audio/AmbientSoundController.gd`

Recommended transition behavior:
- pause ambient on transition start
- resume or hand off if next map uses the same preset

## Troubleshooting

### No audio

Check:
1. `SoundBank` autoload registration
2. preset id exists in `ambient_presets.json`
3. bus routing and volume levels

### Missing generated sounds

Check:
1. generator route inside `SoundBankSingleton`
2. sound id format used by preset entries
3. console warnings from loader/generator code

## Related scenes for quick verification

- `res://commons/audio/catalog/SongPreviewDesktop.tscn`
- `res://commons/audio/catalog/SongDevTools.tscn`
- `res://commons/audio/tests/soundscape_preview.tscn`
