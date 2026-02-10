# Audio Parameters

Last updated: 2026-02-10

This folder contains JSON data used by generators, catalog tools, song builders, and suit mapping.

## Main paths

- `res://commons/audio/parameters/basic/`
- `res://commons/audio/parameters/drums/`
- `res://commons/audio/parameters/synthesizers/`
- `res://commons/audio/parameters/retro/`
- `res://commons/audio/parameters/ambient/`
- `res://commons/audio/parameters/experimental/`
- `res://commons/audio/parameters/pop_edm/`
- `res://commons/audio/parameters/songs/`
- `res://commons/audio/parameters/genre_intent/`
- `res://commons/audio/parameters/word_synthesis_map.json`

## Loader behavior

Two loaders are active in this repo:

### 1. `SoundParameterManager`
File: `res://commons/audio/components/SoundParameterManager.gd`

Used mainly for legacy/basic sound parameter flow:
- prefers `user://sound_parameters/*.json`
- falls back to `res://commons/audio/parameters/basic/*.json`
- merges with built-in defaults

### 2. `EnhancedParameterLoader`
File: `res://commons/audio/runtime/EnhancedParameterLoader.gd`

Used for broad catalog loading across categories.

Accepted JSON patterns:
1. `{"_metadata": {...}, "parameters": {...}}`
2. `{"sound_name": {"_metadata": {...}, "parameters": {...}}}`
3. direct param dictionary where entries have a `value` field

## Special parameter sets

### Songs

`res://commons/audio/parameters/songs/*.json` holds song-level configuration and variants.
Archive snapshots are under:
- `res://commons/audio/parameters/songs/archive/`

### Genre intent (advisory)

`res://commons/audio/parameters/genre_intent/*.json` stores research guidance for genre suits.

Intent files are:
- non-blocking
- non-strict
- optional for downstream systems

Used by:
- `res://commons/audio/soundbanks/SuitToSoundbankMapper.gd`

### Semantic word map

`res://commons/audio/parameters/word_synthesis_map.json` is used by:
- `WordSynthBridge`
- `SoundIdentity`
- trait calibration and word UI panels

It defines:
- word groups
- opposites/conflict metadata
- param mapping to live UI controls
- trait rules

## Adding a new parameter file

1. Place JSON in the correct category folder.
2. Keep parameter names consistent with target generator/tool.
3. If it is for semantic control, update `word_synthesis_map.json`.
4. Validate from a desktop tool:
   - `SongDevTools.tscn`
   - `AudioCatalogDesktop.tscn`
   - or headless test scripts in `res://commons/audio/tests/`.

## Non-goal

This folder is not enforcing one strict schema across all subsystems. Different subsystems have different contracts by design.
