# Soundbanks

Last updated: 2026-02-10

Soundbanks provide genre-local sound script sets for procedural generation.

## Current model

Each soundbank folder contains:
- `brief.json` metadata and sound list
- one script per sound (`kick.gd`, `snare.gd`, `bass.gd`, etc.)

Key loader:
- `res://commons/audio/soundbanks/SoundbankLoader.gd`

Key mapper:
- `res://commons/audio/soundbanks/SuitToSoundbankMapper.gd`

## Active soundbank folders

Examples currently present:
- `detroit_techno`
- `synthwave`
- `rave`
- `dub_house`
- `nineties_rnb`
- `kraftwerk`
- `moroder_disco`
- `burial`
- `aphex_twin`
- `boards_of_canada`
- plus additional project-specific banks

## How soundbank loading works

`SoundbankLoader.load_genre(<id>)`:
1. loads `<id>/brief.json`
2. reads the `soundbank` array
3. loads each corresponding `<sound_name>.gd`
4. exposes accessors for scripts, BPM, sections, and brief metadata

## How suit mapping works

`SuitToSoundbankMapper` converts genre suite elements into runtime-ready sound names:
- resolves element aliases to sound names
- checks availability in the chosen soundbank
- builds `roles`, `sections`, and default `patterns`
- attaches optional advisory `intent` profile from `parameters/genre_intent`

Output of `build_runtime_suite()` is consumed by:
- `res://commons/audio/sequencer/SoundSuiteSequencer.gd`

## brief.json minimum contract

At minimum, include:
- `meta` (id/name/bpm context)
- `soundbank` array

Optional but useful:
- `sections`
- `forbidden`
- `identity`

## Add a new soundbank

1. Create folder `res://commons/audio/soundbanks/<genre_id>/`.
2. Add `brief.json` with `soundbank` entries.
3. Add `<sound_name>.gd` for each sound.
4. Validate with:
   - `res://commons/audio/tests/test_sound_suite_sequencer.tscn`
   - `res://commons/audio/catalog/SongDevTools.tscn`
5. If used in suit mapping, add aliases/mappings in `SuitToSoundbankMapper.gd`.

## Design note

Soundbanks preserve genre identity while still allowing experimentation in higher-level tools. Intent profiles are advisory and do not hard-block creative variation.
