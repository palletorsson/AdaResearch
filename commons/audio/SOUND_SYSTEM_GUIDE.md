# Sound System Integration Guide

## Overview

The Ada Research VR educational system now has a **centralized, hierarchical sound system** that manages all ambient audio and sound effects across maps and sequences.

## Architecture

### Three-Level Hierarchy

```
1. Global Defaults (audio_defaults in map_sequences.json)
   ↓
2. Sequence Level (audio section per sequence)
   ↓
3. Map Level (audio section in individual map_data.json)
```

Each level **overrides** the previous level, allowing fine-grained control.

### Key Components

1. **SoundBankSingleton** (`commons/audio/SoundBankSingleton.gd`)
   - AutoLoad singleton (add as `/root/SoundBank`)
   - Manages all sound generation and caching
   - Loads ambient presets from JSON
   - Provides centralized sound registry

2. **AmbientSoundController** (`commons/audio/AmbientSoundController.gd`)
   - Per-map controller (instantiate in each map)
   - Loads and plays ambient presets
   - Manages continuous layers and random events
   - Handles audio buses

3. **ambient_presets.json** (`commons/audio/ambient_presets.json`)
   - Defines all ambient sound presets
   - Configures continuous layers, random events, and audio buses

4. **map_sequences.json** (updated)
   - Contains `audio_defaults` for global settings
   - Each sequence can have `audio` section to override defaults
   - Individual maps can further override in their `map_data.json`

---

## Setup Instructions

### 1. Add SoundBankSingleton as AutoLoad

**In Godot Project Settings:**

1. Go to: **Project → Project Settings → AutoLoad**
2. Add new entry:
   - **Name**: `SoundBank`
   - **Path**: `res://commons/audio/SoundBankSingleton.gd`
   - **Enable**: ✓ (checked)
3. Click "Add"

### 2. Integrate into Map Loading System

In your map loading code, add:

```gdscript
# After loading map data
var audio_config = get_audio_config_for_map(sequence_id, map_name)

# Create and configure ambient controller
var ambient_controller = AmbientSoundController.new()
ambient_controller.name = "AmbientSound"
map_root.add_child(ambient_controller)

# Load the preset
var preset = audio_config.get("ambient_preset", "silent")
var volume = audio_config.get("volume", 0.0)
var fade = audio_config.get("crossfade_duration", 2.0)

ambient_controller.load_preset(preset, volume, fade)
```

### 3. Audio Resolution Function

Add this helper function to resolve audio configuration:

```gdscript
func get_audio_config_for_map(sequence_id: String, map_name: String) -> Dictionary:
    var config = {}

    # 1. Start with global defaults
    if "audio_defaults" in map_sequences:
        config = map_sequences["audio_defaults"].duplicate(true)

    # 2. Apply sequence-level overrides
    if sequence_id in map_sequences["sequences"]:
        var sequence = map_sequences["sequences"][sequence_id]
        if "audio" in sequence:
            config.merge(sequence["audio"], true)

    # 3. Apply map-level overrides (if map_data.json has audio section)
    var map_data = load_map_data(map_name)
    if "audio" in map_data:
        if map_data["audio"].get("override_sequence", false):
            config.merge(map_data["audio"], true)

    return config
```

---

## Usage Examples

### Example 1: Use Sequence Default

If `wavefunctions` sequence has `audio: { "ambient_preset": "techno_noir_subtle" }`, all maps in that sequence will use that preset unless they override it.

### Example 2: Map-Specific Override

In `WaveFunctions_John_Cage/map_data.json`:

```json
{
  "map_info": { ... },
  "audio": {
    "ambient_preset": "techno_noir_full",
    "volume": -6.0,
    "override_sequence": true
  },
  "layers": { ... }
}
```

This map will use `techno_noir_full` instead of the sequence's `techno_noir_subtle`.

### Example 3: Custom Interactive Sounds

```json
{
  "audio": {
    "ambient_preset": "lab_scientific",
    "interactive_sounds": {
      "teleport": "AudioSynthesizer.TELEPORT_WHOOSH",
      "pickup": "AudioSynthesizer.PICKUP_MARIO",
      "activate": "AudioSynthesizer.SHIELD_HIT"
    }
  }
}
```

---

## Creating New Presets

### 1. Add Preset to ambient_presets.json

> [!TIP]
> You can use the **Audio Catalog Editor** plugin to browse, preview, and edit sound parameters visually instead of editing JSON files manually.


```json
{
  "presets": {
    "my_custom_preset": {
      "description": "My custom ambient atmosphere",
      "continuous_layers": [
        {
          "sound_id": "AudioSynthesizer.MOOG_MINIMOOG_BASS",
          "volume_db": -18,
          "bus": "Ambient"
        }
      ],
      "random_events": [
        {
          "sound_pool": [
            "AudioSynthesizer.KRAFTWERK_ROBOTIC",
            "AudioSynthesizer.APHEX_TWIN_GLITCH"
          ],
          "interval_range": [10.0, 30.0],
          "volume_range": [-20, -15],
          "bus": "Effects"
        }
      ],
      "buses": {
        "Ambient": {
          "effects": [
            {"type": "Reverb", "room_size": 0.6, "wet": 0.4}
          ]
        }
      }
    }
  }
}
```

### 2. Use the Preset

In `map_sequences.json`:

```json
{
  "sequences": {
    "my_sequence": {
      "audio": {
        "ambient_preset": "my_custom_preset",
        "volume": -10.0
      }
    }
  }
}
```

---

## Sound ID Format

Sound IDs follow the format: `Generator.sound_name`

### Available Generators

1. **SyntheticSoundGenerator** - Platform/interaction sounds
   - `detection_sound`
   - `lift_start_sound`
   - `lift_loop_sound`
   - `lift_stop_sound`
   - `warning_sound`
   - `ambient_sound`

2. **AudioSynthesizer** - Vintage synth library (47+ sounds)
   - `MOOG_MINIMOOG_BASS`
   - `ACID_TB303_SQUELCH`
   - `DX7_ELECTRIC_PIANO`
   - `C64_SID_PULSE`
   - `GAMEBOY_PULSE`
   - `KRAFTWERK_ROBOTIC`
   - `APHEX_TWIN_GLITCH`
   - ... and many more

3. **techno_noir** - Cyberpunk ambient (coming soon)
   - `drone`
   - `city_ambience`
   - `distant_siren`
   - `static_burst`
   - `rain_segment`
   - `mechanical_whir`

4. **liturgical** - Sacred/cathedral sounds (coming soon)
   - `choral_foundation`
   - `organ_foundation`
   - `string_atmosphere`
   - `cathedral_bell`
   - `gregorian_phrase`

---

## API Reference

### SoundBankSingleton

```gdscript
# Get a sound (generates if needed, caches result)
var stream = SoundBank.get_sound("AudioSynthesizer.MOOG_MINIMOOG_BASS")

# Get preset definition
var preset = SoundBank.get_preset("techno_noir_full")

# Pre-generate all sounds for a preset
SoundBank.pregenerate_preset_sounds("lab_scientific")

# Setup audio buses for a preset
SoundBank.setup_buses_for_preset("liturgical_cathedral")

# Cross-scene ambient tracking
SoundBank.set_current_ambient("prog_synth_70s", controller)
var current = SoundBank.get_current_ambient()  # Returns preset name

# Check if same preset during transition (skip regeneration)
if SoundBank.should_skip_generation("prog_synth_70s"):
    # Take over existing audio instead of regenerating
    pass

# Register/unregister players for pause tracking
SoundBank.register_music_player(my_player)
SoundBank.unregister_music_player(my_player)

# Clear cache
SoundBank.clear_cache()

# Get info
SoundBank.print_info()
```

### AmbientSoundController

```gdscript
# Create controller
var controller = AmbientSoundController.new()
add_child(controller)

# Load preset (async by default - non-blocking)
controller.load_preset("techno_noir_full", -6.0, 2.0)

# Load preset synchronously (blocking - legacy)
controller.load_preset("techno_noir_full", -6.0, 2.0, false)

# Start ambient (usually called automatically)
controller.start_ambient()

# Stop ambient
controller.stop_ambient()

# Pause/Resume (for map transitions)
controller.pause_ambient()   # Pauses players, saves positions
controller.resume_ambient()  # Resumes from saved positions

# Adjust volume
controller.set_volume(-10.0)

# Crossfade to new preset
controller.crossfade_to_preset("lab_scientific", 3.0)

# Get info
controller.print_info()

# Signals
controller.loading_started.connect(_on_loading_started)
controller.loading_progress.connect(_on_loading_progress)  # (progress, sound_name)
controller.loading_complete.connect(_on_loading_complete)
controller.ambient_paused.connect(_on_paused)
controller.ambient_resumed.connect(_on_resumed)
```

---

## Audio Bus Effects

### Available Effect Types

- **Reverb**: `{"type": "Reverb", "room_size": 0.6, "wet": 0.4, "damping": 0.3}`
- **Delay**: `{"type": "Delay", "dry": 0.8, "tap1_delay_ms": 250, "tap1_level": 0.3}`
- **LowPassFilter**: `{"type": "LowPassFilter", "cutoff_hz": 2000}`
- **HighPassFilter**: `{"type": "HighPassFilter", "cutoff_hz": 200}`
- **Chorus**: `{"type": "Chorus", "dry": 0.8, "wet": 0.3}`
- **Distortion**: `{"type": "Distortion", "mode": 0, "drive": 0.3}`

---

## Troubleshooting

### No Sound Playing

1. **Check AutoLoad**: Ensure `SoundBank` is registered in Project Settings → AutoLoad
2. **Check Preset**: Verify preset name exists in `ambient_presets.json`
3. **Check Volume**: Make sure volume isn't set too low (< -80 dB is effectively silent)
4. **Check Logs**: Look for `⚠️` warnings in console output

### Sound Not Generating

1. **Check Sound ID**: Verify format is `Generator.sound_name`
2. **Generator Exists**: Check if generator is implemented in `SoundBankSingleton._generate_sound()`
3. **Check Logs**: Look for generation errors in console

### Audio Buses Not Working

1. **Preset Buses**: Ensure preset defines buses in `buses` section
2. **Bus Setup**: Call `SoundBank.setup_buses_for_preset()` before loading preset
3. **Bus Names**: Check that bus names match between preset and player configuration

---

## Async Generation & Scene Transitions

### Non-Blocking Audio Loading

Audio generation now happens in background threads to prevent blocking scene loading.

**Key Components:**

1. **AsyncAudioGenerator** (`commons/audio/AsyncAudioGenerator.gd`)
   - Thread-based sound generation
   - Queue-based processing
   - Progress signals for loading UI

2. **AmbientSoundController** (updated)
   - Uses `AsyncAudioGenerator` by default
   - Emits `loading_started`, `loading_progress`, `loading_complete` signals
   - Supports `pause_ambient()` / `resume_ambient()` for seamless teleportation

### How It Works

```
Scene Load Request
       ↓
┌──────────────────┐
│ load_preset()    │ ← Returns immediately (non-blocking)
└────────┬─────────┘
         │
         ├──→ Check SoundBank cache
         │         ↓
         │    ┌────────────────┐
         │    │ Sounds cached? │
         │    └───────┬────────┘
         │         Yes│    No
         │            ↓     ↓
         │    Start    Background
         │    immediately  Thread
         │                  ↓
         │           ┌──────────────┐
         │           │ Generate     │
         │           │ sounds...    │
         │           └──────┬───────┘
         │                  ↓
         │           Cache in SoundBank
         │                  ↓
         └──────────→ start_ambient()
```

### Pause/Resume During Teleportation

When teleporting between maps in the same sequence, the audio **pauses instead of restarting**:

```gdscript
# Automatic (connected to SceneManager signals):
# - scene_transition_started → pause_ambient()
# - scene_transition_completed → resume_ambient()

# Manual control:
ambient_controller.pause_ambient()   # Pauses all players, saves positions
ambient_controller.resume_ambient()  # Resumes from saved positions
```

### Cross-Scene Tracking

`SoundBankSingleton` tracks the current ambient preset across scene changes:

```gdscript
# Check if we should skip regeneration
if SoundBank.should_skip_generation("prog_synth_70s"):
    # Same preset during transition - just take over
    pass

# Register current ambient
SoundBank.set_current_ambient("prog_synth_70s", controller)

# Get current playing preset
var preset = SoundBank.get_current_ambient()
```

### Configuration

In preset JSON, enable persistence:

```json
{
  "presets": {
    "prog_synth_70s": {
      "generation": {
        "persist_across_maps": true
      },
      "continuous_layers": [ ... ]
    }
  }
}
```

### Loading UI Integration

Connect to signals for loading feedback:

```gdscript
ambient_controller.loading_started.connect(_on_loading_started)
ambient_controller.loading_progress.connect(_on_loading_progress)
ambient_controller.loading_complete.connect(_on_loading_complete)

func _on_loading_progress(progress: float, sound_name: String):
    loading_bar.value = progress * 100
    status_label.text = "Loading: " + sound_name
```

---

## Song Preview & Timeline

### SongTimeline Component

Interactive timeline for debugging and discussing sounds:

**Features:**
- Visual section markers (color-coded by type)
- Click-to-seek functionality
- Layer annotations with parameter values
- Selectable text (copy/paste parameters)
- Real-time playhead tracking

**Usage:**
```gdscript
var timeline = SongTimeline.new()
add_child(timeline)

# Load from AudioStreamInteractive
timeline.load_interactive_stream(my_song)

# Or load custom metadata
timeline.load_song_metadata({
    "sections": [
        {"name": "Intro", "start": 0.0, "end": 8.0, "layers": [...]},
        {"name": "Verse", "start": 8.0, "end": 24.0, "layers": [...]}
    ],
    "total_duration": 60.0
})

# Update playhead
timeline.set_current_time(player.get_playback_position())

# Handle seek
timeline.seek_requested.connect(func(time): player.seek(time))
```

### SongPreviewDesktop

Standalone scene for testing songs with timeline:

**Location:** `commons/audio/catalog/SongPreviewDesktop.tscn`

**Features:**
- All 7 procedural songs (prog_synth_70s, ambient_works, etc.)
- Pause/Resume controls
- Full timeline with layer annotations
- Selectable parameter text for discussion

---

## Future Enhancements

### Phase 2: Refactor Generators

- Extract techno noir generation from `john_cage_tech_noir.gd`
- Extract liturgical generation from `liturgicalambientgenerator.gd`
- Create `TechnoNoirGenerator.gd` and `LiturgicalGenerator.gd`
- Integrate with SoundBankSingleton

### Phase 3: Advanced Features

- Real-time crossfading between presets
- Per-map audio bus customization
- Sound parameter system (entropy, queer_factor, etc.)
- LRU cache with configurable size limits
- Disk caching for very large sounds
- Streaming generation for endless ambient

---

## Quick Reference

**File Locations:**
- Presets: `commons/audio/ambient_presets.json`
- Singleton: `commons/audio/SoundBankSingleton.gd`
- Controller: `commons/audio/AmbientSoundController.gd`
- Global Config: `commons/maps/map_sequences.json`
- Map Config: `commons/maps/[MapName]/map_data.json`

**Key Concepts:**
- **Preset**: Named collection of ambient sounds and effects
- **Sound ID**: `Generator.sound_name` format for referencing sounds
- **Cascade**: Global → Sequence → Map hierarchy for configuration
- **Controller**: Per-map instance that plays ambient preset
- **Singleton**: Global sound bank that caches all generated sounds

---

*Last updated: 2026-01-30*

**Changelog:**
- 2026-01-30: Added async generation, pause/resume for teleportation, cross-scene tracking, SongTimeline component
- 2025-01-20: Initial sound system guide
