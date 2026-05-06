# Audio Runtime

Lightweight, in-game audio playback and generation — the minimal set needed for gameplay sounds.

## Files

| Script | Purpose |
|--------|---------|
| `LeanAudioRuntime.gd` | Minimal runtime for game-essential sounds — JSON config-based loading for PICKUP, TELEPORT, AMBIENT_DRONE, UI_CLICK, POWER_UP, IMPACT, NOTIFICATION |
| `SyntheticSoundGenerator.gd` | Real-time procedural sound generation for immediate playback |
| `CubeAudioPlayer.gd` | Audio playback for transport cubes |
| `EnhancedParameterLoader.gd` | Flexible JSON parameter loading with merging and defaults |

## Subdirectories

- `presets/` — Pre-built `.tres` audio resources for common game sounds

## Usage

`LeanAudioRuntime` is the lightweight alternative to the full `SoundBankSingleton` — use it when you only need basic game sounds without the full synthesis pipeline. It loads sound definitions from JSON and plays them on demand.
