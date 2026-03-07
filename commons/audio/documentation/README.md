# AdaResearch Audio System

Last updated: 2026-02-11

This folder contains the audio app stack used by AdaResearch:
- procedural song and sound generation
- genre suit to soundbank mapping
- timeline and semantic editing tools
- runtime ambient and interaction audio

## Canonical docs

Use these files as source of truth:
- `commons/audio/README.md` (this file)
- `commons/audio/catalog/ARCHITECTURE.md`
- `commons/audio/SOUND_SUITE_SEQUENCER.md`
- `commons/audio/parameters/README.md`
- `commons/audio/soundbanks/README.md`
- `commons/audio/SOUND_SYSTEM_GUIDE.md` (ambient/runtime path)

Historical notes in other markdown files can still be useful, but they are not the contract.

## Current architecture

### 1. Catalog and song authoring path

`AudioCatalogDesktop` and `SongDevTools` are the main desktop tools:
- browse sounds and synth elements
- preview and compare songs
- map words to synthesis parameters
- export WAV and MIDI

Key scenes:
- `res://commons/audio/catalog/AudioCatalogDesktop.tscn`
- `res://commons/audio/catalog/SongDevTools.tscn`
- `res://commons/audio/catalog/SongPreviewDesktop.tscn`

### 2. Genre suit to playback path

Suit path (used for genre-oriented sequencing):

`GenreSynthBrowser` -> `SuitToSoundbankMapper` -> `SoundSuiteSequencer` -> `SoundbankLoader`/`Soundbank scripts`

This path is intentionally open-ended:
- genre intent profiles are advisory
- no build-time lock or forced arrangement template
- tools can use intent when useful and ignore it when exploration is needed

### 3. Runtime ambient path

Map/runtime ambient path:

`SoundBankSingleton` + `AmbientSoundController` + preset/config JSON

This path is mainly for in-world audio behavior and scene transitions.

## Directory map

- `catalog/`: desktop tools, preview UIs, semantic word bridge
- `soundbanks/`: isolated genre sound scripts + loader + mapper
- `sequencer/`: suite sequencer and step sequencer
- `generators/`: core synthesis and export helpers
- `parameters/`: JSON parameter libraries, song configs, genre intent profiles
- `presets/`: runtime preset sets
- `tests/`: validation scenes and scripts

## Quick start

1. Open `res://commons/audio/catalog/SongDevTools.tscn` for iterative authoring.
2. Open `res://commons/audio/catalog/SongPreviewDesktop.tscn` for fast track preview/export.
3. Open `res://commons/audio/tests/test_sound_suite_sequencer.tscn` for suite sequencing checks.

## Practical update rule

When behavior changes in code, update docs in this order:
1. `commons/audio/README.md`
2. `commons/audio/catalog/ARCHITECTURE.md`
3. Feature-specific doc (`SOUND_SUITE_SEQUENCER.md`, `parameters/README.md`, or `soundbanks/README.md`)

If docs and code disagree, code wins until docs are patched.

## Current QA baseline

Latest static audit report:
- `commons/audio/documentation/SUITE_QA_MATRIX_2026-02-11.md`

It captures:
- song routing parity across `SongDevTools` and `SongPreviewDesktop`
- suite-to-soundbank parity status per genre
- current mapper runtime scope in `SoundSuiteSequencer`
