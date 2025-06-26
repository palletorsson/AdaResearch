# Sound Parameters System

This directory contains individual JSON files for each sound type, making it easy to organize, share, and modify sound parameters.

## How It Works

Each sound type has its own JSON file (e.g., `pickup_mario.json`, `teleport_drone.json`) with the following structure:

```json
{
  "_metadata": {
    "sound_type": "pickup_mario",
    "description": "Classic video game pickup sound with frequency sweep",
    "created_at": "2024-12-24T08:57:00Z",
    "version": "1.0",
    "is_default": true
  },
  "parameters": {
    "duration": {
      "value": 0.5,
      "min": 0.1,
      "max": 3.0,
      "step": 0.01
    },
    "start_freq": {
      "value": 440.0,
      "min": 100.0,
      "max": 1000.0,
      "step": 5.0
    },
    "wave_type": {
      "value": "square",
      "options": ["sine", "square", "sawtooth"]
    }
  }
}
```

## Parameter Types

### Numeric Parameters
- `value`: Current value
- `min`: Minimum allowed value
- `max`: Maximum allowed value  
- `step`: Step size for sliders

### Option Parameters
- `value`: Currently selected option
- `options`: Array of available options

## Available Sound Types

- `basic_sine_wave.json` - Pure sine wave with fundamental frequency control
- `pickup_mario.json` - Classic video game pickup sound with frequency sweep
- `teleport_drone.json` - Sci-fi teleportation sound with modulation and noise
- `lift_bass_pulse.json` - Mechanical bass pulse for elevators and machinery
- `ghost_drone.json` - Atmospheric drone with multiple harmonic layers
- `melodic_drone.json` - Complex harmonic drone with tremolo modulation
- `laser_shot.json` - Sci-fi laser weapon sound with frequency decay
- `power_up_jingle.json` - Uplifting musical power-up sound
- `explosion.json` - Multi-layered explosion with low/mid/high frequency components
- `retro_jump.json` - 8-bit style jump sound with duty cycle modulation
- `shield_hit.json` - Impact sound with metallic ring characteristics
- `ambient_wind.json` - Natural wind ambience with filtered noise

## File Locations

- **Default Parameters**: `res://commons/audio/sound_parameters/` (read-only, part of project)
- **User Customizations**: `user://sound_parameters/` (writable, saved locally)

## How Parameters are Loaded

The system uses a priority system:

1. **User Directory First**: `user://sound_parameters/filename.json`
2. **Resource Directory**: `res://commons/audio/sound_parameters/filename.json` 
3. **Built-in Defaults**: Hardcoded fallback parameters

## Creating New Sound Types

1. Create a new JSON file with your sound type name
2. Follow the parameter structure shown above
3. Add the sound type to `SoundParameterManager.sound_type_files`
4. Implement the sound generation in `AudioSynthesizer.gd`

## Benefits

✅ **Organized**: Each sound in its own file  
✅ **Shareable**: Easy to copy/paste individual sound configs  
✅ **Versionable**: Each file can be tracked in git  
✅ **Editable**: Modify parameters in any text editor  
✅ **Extendable**: Add new sounds without touching existing files  
✅ **Cacheable**: Fast loading with intelligent caching  
✅ **Fallback Safe**: Always works even if files are missing  

## Example Usage

```gdscript
# Load parameters for a specific sound
var params = SoundParameterManager.get_sound_parameters("pickup_mario")

# Save modified parameters
SoundParameterManager.save_sound_parameters("pickup_mario", modified_params)

# Get all available sound types
var types = SoundParameterManager.get_available_sound_types()

# Reload parameters from files (clear cache)
SoundParameterManager.reload_parameters("pickup_mario")
```

## Development Workflow

1. **Modify Parameters**: Use the sound designer interface
2. **Auto-Save**: Parameters are automatically saved to user directory
3. **Export**: Use the file manager to export configurations
4. **Share**: Copy JSON files to share with others
5. **Version Control**: Commit default parameter files to git 