# Roland Emulation Soundbank

Procedural sound scripts emulating classic Roland hardware — TR-808, TR-909, Juno, Jupiter, D-50.

## Sounds

**Drum machines:**
- `tr808_kick.gd`, `tr808_snare.gd`, `tr808_clap.gd`, `tr808_hihat.gd` — TR-808
- `tr909_kick.gd`, `tr909_hihat.gd` — TR-909

**Synthesizers:**
- `juno_bass.gd`, `juno_pad.gd` — Juno-106/60
- `d50_fantasia.gd` — D-50 Fantasia patch

## Reference

- `ROLAND_SYNTHESIS_REFERENCE.md` — Technical synthesis reference for Roland emulations

## Usage

Loaded by `SoundbankLoader.load_genre("roland_emulation")`. Configuration in `brief.json`.
