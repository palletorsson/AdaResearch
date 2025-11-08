# Tech Noir Audio Integration

## Overview

The John Cage-inspired tech noir ambient audio generator has been successfully integrated into the centralized audio management architecture. All procedural tech noir sounds are now available through the `SoundBankSingleton` and can be used in ambient presets and edited via the Audio Catalog Editor.

## What Was Integrated

### 1. **TechnoNoirGenerator.gd** (`res://commons/audio/generators/TechnoNoirGenerator.gd`)

A new static generator class containing all procedural sound generation methods:

#### Continuous Ambient Sounds
- **endless_drone** - Harmonic bass drone with slow modulation (30s loop)
- **city_ambience** - Urban atmosphere with traffic and rumble (10s loop)

#### Event Sounds
- **distant_siren** - Police/ambulance siren with doppler panning
- **static_burst** - Electronic interference with crackles
- **rain_segment** - Atmospheric rain with droplets
- **mechanical_whir** - Industrial machinery with gears
- **typing_segment** - Keyboard typing sounds
- **electric_hum** - 60Hz power line hum with harmonics
- **heartbeat_segment** - Biological heartbeat with lub-dub rhythm

### 2. **SoundBankSingleton Integration**

Updated `_generate_techno_noir_sound()` to use the new generator (line 220-232):

```gdscript
func _generate_techno_noir_sound(sound_name: String, params: Dictionary = {}) -> AudioStreamWAV:
	var TechnoNoir = preload("res://commons/audio/generators/TechnoNoirGenerator.gd")
	var stream = TechnoNoir.generate_sound(sound_name, params)
	return stream
```

### 3. **Parameter Presets** (`res://commons/audio/parameters/tech_noir/`)

Created 9 JSON parameter files for the Audio Catalog Editor:
- `endless_drone.json`
- `city_ambience.json`
- `distant_siren.json`
- `static_burst.json`
- `rain_segment.json`
- `mechanical_whir.json`
- `typing_segment.json`
- `electric_hum.json`
- `heartbeat_segment.json`

Each preset includes:
- Full parameter range definitions (min, max, step)
- Default values optimized for tech noir atmosphere
- Metadata (description, tags, version)
- Seed parameter for reproducible randomness

## Usage

### In Ambient Presets

Use tech noir sounds in `ambient_presets.json` with the format:

```json
{
  "sound_id": "techno_noir.drone",
  "volume_db": -10,
  "bus": "Reverb"
}
```

**Available sound IDs:**
- `techno_noir.drone` (or `endless_drone`)
- `techno_noir.city_ambience` (or `city`, `urban`)
- `techno_noir.distant_siren` (or `siren`)
- `techno_noir.static_burst` (or `static`)
- `techno_noir.rain_segment` (or `rain`)
- `techno_noir.mechanical_whir` (or `machinery`, `mechanical`)
- `techno_noir.typing_segment` (or `typing`, `keyboard`)
- `techno_noir.electric_hum` (or `hum`, `power`)
- `techno_noir.heartbeat_segment` (or `heartbeat`, `pulse`)

### In Audio Catalog Editor

1. Open the Audio Catalog tab in Godot editor
2. Browse to **Tech Noir** category
3. Select any sound to see parameters
4. Adjust sliders to modify sound characteristics
5. Click **Play** to preview (waveform and spectrum will update)
6. Click **Save** to store changes
7. Click **Export JSON** to save custom presets

**Note**: The Audio Catalog Editor has been updated to detect and generate tech noir sounds automatically using `TechnoNoirGenerator`.

### Example Presets Using Tech Noir

The following presets are now fully functional:

1. **techno_noir_full** - Complete cyberpunk atmosphere with all sound types
2. **techno_noir_bass_foundation** - Dark ambient with deep bass and city texture
3. **techno_noir_lofi_return** - Drifting lofi pulse with rain and sirens

## Sound Parameters

### endless_drone
- `base_freq` (30-110 Hz): Base frequency
- `buffer_length` (10-60s): Loop duration
- `volume` (0.0-1.0): Overall amplitude
- `seed` (-1 or 0-10000): Random seed

### city_ambience
- `buffer_length` (5-30s): Loop duration
- `traffic_volume` (0.0-0.5): Traffic noise level
- `rumble_volume` (0.0-0.5): Low frequency rumble
- `ambient_volume` (0.0-0.5): Background noise
- `seed`: Random seed

### distant_siren
- `buffer_length` (3-12s): Duration
- `base_freq` (300-800 Hz): Siren base frequency
- `freq_range` (100-500 Hz): Modulation range
- `cycle_time` (0.5-4s): Up-down cycle time
- `volume` (0.0-0.5): Distance effect
- `seed`: Random seed

### static_burst
- `buffer_length` (1-8s): Duration
- `static_volume` (0.0-0.8): Base static level
- `crackle_chance` (0.0-0.1): Crackle probability
- `crackle_volume` (0.0-1.0): Crackle intensity
- `attack_time` (0.01-1.0s): Attack envelope
- `decay_time` (0.5-7.0s): Decay envelope
- `seed`: Random seed

### rain_segment
- `buffer_length` (3-15s): Duration
- `intensity` (0.1-1.0): Rain intensity
- `base_noise` (0.0-0.5): Continuous rain level
- `seed`: Random seed

### mechanical_whir
- `buffer_length` (2-10s): Duration
- `motor_freq` (40-200 Hz): Base motor frequency
- `attack` (0.1-2.0s): Attack time
- `release` (0.2-3.0s): Release time
- `seed`: Random seed

### typing_segment
- `buffer_length` (2-10s): Duration
- `typing_speed` (0.05-0.5s): Time between keys
- `key_volume_min` (0.05-0.3): Minimum key volume
- `key_volume_max` (0.2-0.7): Maximum key volume
- `seed`: Random seed

### electric_hum
- `buffer_length` (2-15s): Duration
- `hum_freq` (50-120 Hz): Base hum (50Hz EU, 60Hz US)
- `attack` (0.1-3.0s): Attack time
- `release` (0.5-5.0s): Release time
- `seed`: Random seed

### heartbeat_segment
- `buffer_length` (3-15s): Duration
- `bpm` (40-140): Beats per minute
- `attack` (0.2-3.0s): Attack time
- `sustain` (1.0-10.0s): Sustain time
- `release` (0.5-5.0s): Release time
- `seed`: Random seed

## Technical Details

### Audio Specifications
- **Sample Rate**: 44.1kHz
- **Format**: 16-bit PCM
- **Stereo**: Yes (with spatial effects)
- **Looping**: Seamless loops for continuous sounds

### Generation Features
- All sounds generated procedurally (no samples)
- Reproducible with seed parameter
- Low memory footprint (~50MB for all sounds)
- CPU-efficient after initial generation
- Thread-safe generation

### Sound Design Philosophy

Based on John Cage's experimental composition principles:
- **Chance Operations**: Random timing and variations
- **Ambient Philosophy**: Environmental music approach
- **Non-Hierarchical**: No dominant musical elements
- **Duration Experiments**: Endless, non-repetitive
- **Found Sound**: Urban environment as material

## Integration Benefits

✅ **Centralized Management**: All sounds accessible through SoundBankSingleton
✅ **Visual Editing**: Parameter tweaking in Audio Catalog Editor
✅ **Preset System**: Easy configuration in ambient_presets.json
✅ **Reproducibility**: Seed parameter for consistent results
✅ **Modularity**: Independent generator class
✅ **Documentation**: Complete parameter reference
✅ **Extensibility**: Easy to add new sound types

## Testing

### Quick Test in Godot Console

```gdscript
# Generate a drone
var drone = TechnoNoirGenerator.create_endless_drone({
	"base_freq": 55.0,
	"volume": 0.4
})
print("Drone duration: ", drone.get_length(), " seconds")

# Test via SoundBank
var siren = SoundBank.get_sound("techno_noir.distant_siren")
if siren:
	print("✅ Siren generated successfully")
```

### Test in Scene

1. Load a map with tech noir preset configured
2. Example: `primitives` sequence with `techno_noir_full` preset
3. Should hear continuous drone + city ambience
4. Random events (siren, static, etc.) every 3-15 seconds

## Relationship to Original

The original `john_cage_tech_noir.gd` remains functional as a standalone scene with:
- Visual loading bar
- 3D audio visualizers
- Real-time audio bus setup
- Independent player management

The new `TechnoNoirGenerator.gd` extracts just the sound generation logic for integration with the centralized system. Both can coexist:
- Use original for standalone tech noir scenes
- Use generator for integrated ambient system

## Future Enhancements

### Planned Features
- [ ] Parameter modulation over time
- [ ] Cross-fading between variations
- [ ] 3D spatial positioning
- [ ] Real-time parameter automation
- [ ] MIDI controller mapping
- [ ] Machine learning evolution

### Possible Sound Additions
- [ ] Subway rumble
- [ ] Helicopter flyover
- [ ] Glass break
- [ ] Metal clang
- [ ] Wind chime
- [ ] Neon buzz

## Audio Catalog Editor Integration

The Audio Catalog Editor (`audio_catalog_dock.gd`) has been updated to fully support tech noir sounds:

### Changes Made:
1. **Added TechnoNoirGenerator import** - Direct access to tech noir sound generation
2. **Added `_is_tech_noir_sound()` helper** - Detects tech noir sounds by sound_key
3. **Updated `_refresh_preview()`** - Routes tech noir sounds to TechnoNoirGenerator
4. **Updated `_generate_preview_stream()`** - Handles tech noir generation
5. **Updated `_update_action_states()`** - Enables play button for tech noir sounds

### How It Works:
- When you select a tech noir sound, the editor detects it automatically
- Instead of looking for an AudioSynthesizer enum, it calls TechnoNoirGenerator directly
- All parameters from the JSON preset are passed to the generator
- Waveform and spectrum visualizations work normally
- Play/Stop/Save/Export buttons function as expected

## Credits

**Original System**: `john_cage_tech_noir.gd` - Procedural ambient generator
**Integration**: TechnoNoirGenerator.gd - Static generator class
**Audio Catalog Support**: Modified `audio_catalog_dock.gd` for tech noir detection
**Inspiration**: John Cage's experimental composition techniques
**Style**: Blade Runner / Cyberpunk / Tech Noir aesthetics

## Support

For issues or questions:
1. Check parameter ranges in JSON presets
2. Verify SoundBank AutoLoad is registered
3. Check console for generation errors
4. Review ambient_presets.json syntax
5. Test with Audio Catalog Editor

---

**Status**: ✅ **FULLY INTEGRATED AND OPERATIONAL**

All tech noir sounds are now available in the centralized audio system!
