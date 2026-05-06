# Ambient Presets

JSON preset definitions for the `AmbientSoundController`. Each file configures ambient audio for a specific map mood.

## Contents

67 preset files covering environments such as:

- **Sci-fi**: `blade_runner_minimal`, `deep_void`, `heptapod_chamber`, `space_station`
- **Industrial**: `abandoned_factory`, `industrial_machine`, `asteroid_processing_plant`
- **Nature**: `desert_outpost`, `arrakis_desert`, `bio_dome_greenhouse`, `hydro_garden_complex`
- **Lab**: `empty_lab`, `lab_scientific`, `computational_hum`, `half_life_science`
- **Musical**: `eccojam_drift`, `autechre_flutter`, `ikeda_dataplex`
- **Atmospheric**: `cyberpunk_night_market`, `liturgical_cathedral`, `contradictory_world`

## Subdirectories

- `soundscapes/` — Extended soundscape presets (multi-layer environments)

## Usage

Referenced by map configurations. `AmbientSoundController.load_preset()` reads these files and configures the audio synthesizer accordingly. Preset names correspond to filenames without the `.json` extension.
