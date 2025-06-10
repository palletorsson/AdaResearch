# JSON Configuration System for Enhanced Track System

## Overview

The JSON Configuration System allows you to define complete music tracks using simple JSON files. You can configure layers, patterns, effects, automation, and more without writing any code.

## Loading and Saving

### Basic Usage

```gdscript
# Load a configuration
var config = TrackConfigLoader.load_track_config("path/to/config.json")
TrackConfigLoader.apply_config_to_track(track_system, config)

# Save current configuration
TrackConfigLoader.save_track_config(track_system, "path/to/save.json", "Track Name")
```

### Real-time Configuration

```gdscript
# Apply partial configuration changes in real-time
var partial_config = {
    "layers": {
        "drums": {
            "kick": {
                "volume": -6.0,
                "effects": {
                    "filter": {"cutoff": 800.0}
                }
            }
        }
    }
}
TrackConfigLoader.apply_config_to_track(track_system, partial_config)
```

## JSON Schema

### Root Structure

```json
{
    "metadata": { ... },      // Track information and global settings
    "layers": { ... },        // Layer configurations
    "patterns": { ... },      // Pattern definitions
    "effects": { ... },       // Global effects settings
    "sections": { ... },      // Section-based arrangement
    "automation": { ... }     // Automation and dynamic effects
}
```

### Metadata Section

```json
{
    "metadata": {
        "name": "Track Name",
        "artist": "Artist Name",
        "version": "1.0",
        "bpm": 130,
        "key": "Am",
        "master_volume": -6.0,
        "description": "Track description"
    }
}
```

**Properties:**
- `name` (string): Track name
- `artist` (string): Artist name
- `version` (string): Configuration version
- `bpm` (number): Beats per minute
- `key` (string): Musical key (e.g., "Am", "C", "F#m")
- `master_volume` (number): Master volume in dB
- `description` (string): Track description

### Layers Section

```json
{
    "layers": {
        "drums": {
            "kick": {
                "enabled": true,
                "volume": -3.0,
                "solo": false,
                "pan": 0.0,
                "pattern": "kick_pattern_name",
                "effects": {
                    "compressor": {
                        "threshold": -12.0,
                        "ratio": 4.0,
                        "attack": 10.0,
                        "release": 100.0
                    },
                    "filter": {
                        "cutoff": 800.0,
                        "resonance": 1.2
                    },
                    "delay": {
                        "time": 375.0,
                        "feedback": -12.0
                    }
                },
                "lfo": {
                    "target": "filter_cutoff",
                    "rate": 0.25,
                    "depth": 300.0
                }
            }
        }
    }
}
```

**Layer Categories:**
- `drums`: kick, snare, hihat, etc.
- `bass`: sub, mid, etc.
- `synths`: lead, pad, arp, etc.
- `fx`: sweep, impact, etc.

**Layer Properties:**
- `enabled` (bool): Whether layer is active
- `volume` (number): Layer volume in dB
- `solo` (bool): Solo this layer
- `pan` (number): Pan position (-1.0 to 1.0)
- `pattern` (string): Pattern name to use
- `effects` (object): Effects configuration
- `lfo` (object): LFO modulation settings

**Effect Types:**
- `compressor`: threshold, ratio, attack, release
- `filter`: cutoff, resonance
- `delay`: time, feedback

**LFO Targets:**
- `filter_cutoff`: Modulate filter cutoff frequency
- `volume`: Modulate layer volume
- `pan`: Modulate pan position
- `pitch`: Modulate pitch

### Patterns Section

```json
{
    "patterns": {
        "kick_pattern": {
            "length": 16,
            "type": "kick",
            "style": "four_on_floor",
            "swing": 0.1,
            "humanization": 0.15,
            "probability": 0.9
        },
        "manual_pattern": {
            "length": 16,
            "steps": [
                {"active": true, "velocity": 1.0, "pitch": 0.0},
                {"active": false, "velocity": 0.0},
                {"active": true, "velocity": 0.8, "pitch": 2.0},
                false
            ]
        }
    }
}
```

**Pattern Generation Types:**
- `kick`: Kick drum patterns
- `snare`: Snare drum patterns
- `hihat`: Hi-hat patterns
- `bass`: Bass line patterns
- `arp`: Arpeggio patterns
- `euclidean`: Euclidean rhythm patterns

**Pattern Styles:**

*Kick:*
- `four_on_floor`: Standard 4/4 kick
- `breakbeat`: Breakbeat style
- `trap`: Trap style kicks

*Snare:*
- `backbeat`: Standard backbeat
- `syncopated`: Syncopated patterns
- `breaks`: Breakbeat snares

*Hi-hat:*
- `steady`: Steady 16th notes
- `offbeat`: Offbeat patterns
- `rolls`: Roll patterns

*Bass:*
- `steady`: Steady bass notes
- `rolling`: Rolling basslines
- `syncopated`: Syncopated bass

*Arp:*
- `up`: Ascending arpeggio
- `down`: Descending arpeggio
- `up_down`: Up-down arpeggio
- `random`: Random note order

**Manual Step Definition:**
```json
{
    "active": true,           // Whether step triggers
    "velocity": 1.0,          // Note velocity (0.0-1.0)
    "pitch": 0.0,            // Pitch offset in semitones
    "probability": 1.0,       // Trigger probability (0.0-1.0)
    "sound_index": 0,         // Sound bank index
    "duration": 1.0,          // Note duration multiplier
    "micro_timing": 0.0       // Timing offset in ms
}
```

### Effects Section

```json
{
    "effects": {
        "reverb": {
            "room_size": 0.9,
            "damping": 0.3,
            "wet": 0.4,
            "dry": 0.8
        },
        "delay": {
            "time": 375.0,
            "feedback": 0.3,
            "sync_to_bpm": true,
            "wet": 0.2
        },
        "compressor": {
            "threshold": -6.0,
            "ratio": 3.0,
            "attack": 10.0,
            "release": 100.0,
            "makeup_gain": 2.0
        },
        "eq": {
            "low_freq": 100.0,
            "low_gain": -2.0,
            "mid_freq": 1000.0,
            "mid_gain": 1.0,
            "high_freq": 8000.0,
            "high_gain": -1.0
        }
    }
}
```

### Sections Section

```json
{
    "sections": {
        "intro": {
            "length_bars": 8,
            "active_layers": ["drums.kick", "bass.sub"],
            "volume_multiplier": 0.7
        },
        "buildup": {
            "length_bars": 16,
            "active_layers": ["drums.kick", "drums.hihat", "bass.sub", "synths.pad"],
            "volume_multiplier": 0.85
        },
        "drop": {
            "length_bars": 32,
            "active_layers": "*",
            "volume_multiplier": 1.0
        }
    }
}
```

### Automation Section

```json
{
    "automation": {
        "filter_sweeps": [
            {
                "delay": 10.0,
                "target": "Layer_bass_sub",
                "start_freq": 200.0,
                "end_freq": 1200.0,
                "duration": 8.0
            }
        ],
        "volume_fades": [
            {
                "delay": 20.0,
                "target": "Layer_fx_sweep",
                "start_volume": -40.0,
                "end_volume": -10.0,
                "duration": 3.0
            }
        ],
        "parameter_changes": [
            {
                "delay": 15.0,
                "target": "Layer_drums_kick",
                "parameter": "filter_resonance",
                "start_value": 1.0,
                "end_value": 2.5,
                "duration": 5.0
            }
        ]
    }
}
```

## Example Configurations

### Simple Beat
See: `simple_beat.json` - Basic 4/4 beat with kick, snare, hi-hats, and bass

### Dark Ambient Track
See: `dark_ambient_track.json` - Complex dark ambient track with multiple layers, effects, and automation

## Advanced Features

### Pattern Chaining
```json
{
    "patterns": {
        "intro_kick": { "length": 16, "type": "kick", "style": "four_on_floor" },
        "buildup_kick": { "length": 16, "type": "kick", "style": "breakbeat" },
        "drop_kick": { "length": 32, "type": "kick", "style": "trap" }
    }
}
```

### Dynamic Layer Assignment
```json
{
    "layers": {
        "drums": {
            "kick": {
                "pattern": "intro_kick",  // Different patterns per section
                "volume": -3.0
            }
        }
    }
}
```

### Complex Automation
```json
{
    "automation": {
        "filter_sweeps": [
            {
                "delay": 0.0,
                "target": "Layer_bass_sub",
                "start_freq": 80.0,
                "end_freq": 1200.0,
                "duration": 16.0
            },
            {
                "delay": 16.0,
                "target": "Layer_synths_lead",
                "start_freq": 2000.0,
                "end_freq": 8000.0,
                "duration": 8.0
            }
        ]
    }
}
```

## Tips and Best Practices

### Volume Management
- Use negative dB values for volume (0dB = maximum, -6dB = half volume)
- Leave headroom for mastering (-6dB to -3dB master volume)
- Balance layers: drums (-3 to 0dB), bass (-2 to 0dB), leads (-12 to -6dB), pads (-20 to -12dB)

### Pattern Design
- Start with 16-step patterns for simplicity
- Use Euclidean patterns for complex rhythms
- Apply swing (0.05-0.2) for groove
- Use humanization (0.1-0.3) for organic feel

### Filter Settings
- Low-pass cutoff: 80Hz (sub) to 20kHz (air)
- Resonance: 0.5-1.0 (subtle), 2.0+ (pronounced)
- Use LFO modulation for movement

### Effect Chains
- Order: Compressor → Filter → Panner → Delay
- Compressor: -12dB threshold, 4:1 ratio for drums
- Delay: Use BPM-synced times (1/8, 1/4, 1/2 notes)
- Reverb: 0.1-0.4 wet for space

### Performance Tips
- Disable unused layers instead of deleting
- Use probability < 1.0 for variation
- Chain multiple short patterns vs. one long pattern
- Use sections for arrangement changes

## Keyboard Controls (when using TrackConfigExample)

- **1-6**: Toggle layers
- **F**: Apply filter sweep
- **R**: Random reverb settings
- **C**: Random compression settings
- **Ctrl+S**: Quick save
- **Ctrl+L**: Quick load
- **P**: Generate random pattern

## Error Handling

The system gracefully handles:
- Missing files
- Invalid JSON syntax
- Missing properties (uses defaults)
- Non-existent patterns or layers
- Invalid parameter ranges

## Integration with Existing System

JSON configurations work seamlessly with the Enhanced Track System:

```gdscript
# Create track system
var track = EnhancedTrackSystem.new()
add_child(track)

# Load configuration
var config = TrackConfigLoader.load_track_config("my_track.json")
TrackConfigLoader.apply_config_to_track(track, config)

# Start playing
track.play()

# Make real-time changes
var live_changes = {"layers": {"drums": {"kick": {"volume": -6.0}}}}
TrackConfigLoader.apply_config_to_track(track, live_changes)
```

This system provides complete flexibility for creating, sharing, and modifying music tracks through simple JSON files. 