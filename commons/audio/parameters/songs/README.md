# Song Parameters

JSON song-level synthesis configurations — full track definitions with structure, layers, and effects.

## Files

Includes parameters for complete songs and artist-inspired tracks:

- `ada_theme.json` — Ada Research theme
- `acid_house.json`, `acid_techno_303.json` — Acid genre tracks
- `ambient_techno.json`, `ambient_works.json` — Ambient techno
- `blade_runner.json` — Blade Runner-inspired
- `boards_of_canada.json`, `boards_of_canada_v2.json` — BoC-inspired
- `burial.json`, `burial_v2.json` — Burial-inspired
- `chromatic_story.json` — Chromatic story track
- `dark_kraftwerk_ambience.json` — Dark Kraftwerk ambience
- `dark_wave_cathedral.json` — Dark wave cathedral
- `detroit_techno.json` — Detroit techno
- Plus soundbank-specific variants (`*_sb.json`)

## Subdirectories

- `archive/` — Archived/deprecated song parameters

## Usage

Loaded by `SongDevTools`, `SongRuntimeEngine`, and the `AudioSynthesizer` for full track generation. Each file defines the complete synthesis recipe for a multi-layer track.
