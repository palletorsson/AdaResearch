# Audio Catalog Architecture

Last updated: 2026-02-10

This document covers the desktop audio app surfaces in `res://commons/audio/catalog/`.

## Scope

Main entry scenes:
- `res://commons/audio/catalog/AudioCatalogDesktop.tscn`
- `res://commons/audio/catalog/SongDevTools.tscn`
- `res://commons/audio/catalog/SongPreviewDesktop.tscn`

Main scripts:
- `res://commons/audio/catalog/AudioCatalogDesktop.gd`
- `res://commons/audio/catalog/SongDevTools.gd`
- `res://commons/audio/catalog/SongPreviewDesktop.gd`
- `res://commons/audio/catalog/WordSynthBridge.gd`
- `res://commons/audio/catalog/SoundIdentity.gd`

## Runtime flows

### Flow A: Semantic words -> audible change

1. User edits words in `WordSynthDisplay`.
2. `WordSynthBridge.words_to_live_params()` maps words to live parameter keys.
3. `SongDevTools.live_params` is updated.
4. `SongDevTools` applies values to AudioServer bus effects in real time.

Source file for semantics:
- `res://commons/audio/parameters/word_synthesis_map.json`

### Flow B: Song selection -> timeline playback

1. User selects a song in `SongDevTools` or `SongPreviewDesktop`.
2. Song is generated via `AudioSynthesizer` and/or `SoundbankGenerator`.
3. `AudioStreamInteractive` is loaded into player.
4. Timeline metadata is built and sent to `SongTimeline`.
5. Section and layer views are updated for editing/analysis.

### Flow C: Genre suit -> sequencer playback

1. `GenreSynthBrowser` defines suite roles/elements by genre.
2. `SuitToSoundbankMapper` maps those elements to real soundbank sound names.
3. Runtime suite payload (including optional `intent`) is produced.
4. `SoundSuiteSequencer` runs patterns and triggers generators/scripts.

## Component responsibilities

| Component | Responsibility |
|---|---|
| `AudioCatalogDesktop.gd` | Desktop catalog shell, playback dispatch, generator routing |
| `SongDevTools.gd` | Deep editing surface, transport, timeline, semantic controls |
| `SongPreviewDesktop.gd` | Fast track preview, export-oriented playback |
| `WordSynthBridge.gd` | Word-to-parameter and reverse analysis support |
| `SoundIdentity.gd` | Derives traits/features from synth parameter dictionaries |
| `SoundIdentityPanel.gd` | Displays sound identity analysis in UI |
| `SynthConfigRegistry.gd` | Known layer config references used by analysis UI |

## Data contracts

### Word map contract

`word_synthesis_map.json` provides:
- parameter specification metadata
- word groups and opposites
- conflict resolution metadata
- mapping from namespaced synth params to live UI params

### Runtime suite contract

`SuitToSoundbankMapper.build_runtime_suite()` returns:
- `id`, `source_genre`, `soundbank_id`
- `bpm`
- `sounds` dictionary with generator metadata
- `patterns` and `default_pattern`
- `sections`
- `intent` (advisory profile, optional)

### Intent profile contract

Intent files in `res://commons/audio/parameters/genre_intent/*.json` are advisory:
- they guide arrangement and harmony decisions
- they do not block generation
- they do not enforce fixed structures

## Why SongDevTools and SongPreview can sound different

They use overlapping but not identical playback surfaces:
- different UI defaults and control states
- different per-scene effect setup behavior
- different generator selection paths for some songs

For regressions, compare both scenes with the same song and check:
- active bus effects on `Master`
- whether reference/preview mode is enabled
- song path (soundbank generator vs direct synthesizer path)
