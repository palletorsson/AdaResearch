# Sound Collections

JSON files defining curated sets of sounds grouped by theme or genre.

## Files

23 collection files including:

- `audio_synthesizer.json` — General synthesizer presets
- `drum_and_bass.json` — D&B sound collection
- `metropolis_noir.json` — Dark urban soundscapes
- `sacred_sounds.json` — Liturgical and sacred audio
- `sci_fi_lab.json` — Science fiction laboratory sounds
- `game_world.json` — General game world sounds
- `body_sounds.json` — Organic body sounds
- `machine_sounds.json` — Mechanical sounds
- `synth_history.json`, `synth_legends.json` — Historical synth recreations
- `synthetic_suite.json` — Synthetic sound suite
- `weather_and_urban.json` — Environmental sounds
- `space_dystopia_previews.json`, `space_dystopia_track_*.json` — Space dystopia album tracks

## Usage

Collections are loaded by `SoundCollection.gd` and browsed via the catalog UI (`AudioCatalogDesktop`, `SoundBrowser`). Each JSON file defines a list of sounds with parameter references for the audio synthesizer.
