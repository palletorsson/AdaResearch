# 🎨 Sound Suite Sequencer

**Bridge between Audio Catalog and Pattern Sequencing**

The Sound Suite Sequencer allows you to:
- **Select different sound suites** from the audio catalog (trap beats, tech noir, liturgical, etc.)
- **Control individual sound parameters** for each sound in the suite
- **Deploy sound suites into sequencer patterns** for automated playback
- **Switch suites and patterns dynamically** during playback

---

## 🎯 Core Concept

Instead of hardcoding specific sounds into a sequencer, the Sound Suite Sequencer lets you:

1. **Choose a sound suite** (collection of related sounds)
2. **Customize each sound's parameters** (pitch, decay, tone, etc.)
3. **Load a pattern** (from presets, PatternSequencer, or custom)
4. **Play and control in real-time** (BPM, swing, mute, etc.)

---

## 🚀 Quick Start

### Basic Usage

```gdscript
# Create sequencer
var sequencer = SoundSuiteSequencer.new()
add_child(sequencer)

# Initialize with trap beats
sequencer.initialize({
    "suite": "trap_beats",
    "pattern": "minimal_trap",
    "bpm": 85.0,
    "swing": 0.15
})

# Customize kick sound
sequencer.set_sound_params("kick", {
    "pitch": 55.0,
    "decay": 1.5
})

# Start playback
sequencer.start()
```

### Switch Suites

```gdscript
# Switch to tech noir sounds
sequencer.change_suite("tech_noir")

# Load ambient pattern
sequencer.load_pattern("ambient_sparse")

# Customize drone sound
sequencer.set_sound_params("drone", {
    "base_frequency": 60.0,
    "harmonic_count": 8
})
```

---

## 🎨 Available Sound Suites

### 1. Trap Beats (`trap_beats`)

**Classic trap drum sounds:**

| Track | Sound | Parameters |
|-------|-------|------------|
| `kick` | 808_kick | pitch, decay |
| `snare` | trap_snare | decay, noise_amount |
| `hihat_closed` | trap_hihat | decay, noise_tone |
| `hihat_open` | open_hihat | decay, noise_tone |
| `clap` | trap_clap | decay |
| `rim` | 808_rim | pitch, decay |
| `tom` | trap_tom | pitch, decay |
| `cowbell` | 808_cowbell | pitch, decay |

**Example patterns:**
- `minimal_trap` - Sparse, chill (85 BPM)
- `hard` - Aggressive, hard-hitting
- `four_floor` - Classic four-on-floor

### 2. Tech Noir (`tech_noir`)

**Atmospheric/ambient sounds:**

| Track | Sound | Parameters |
|-------|-------|------------|
| `drone` | endless_drone | base_frequency, harmonic_count |
| `city` | city_ambience | base_frequency, modulation_depth |
| `siren` | distant_siren | base_pitch, duration |
| `static` | static_burst | duration |
| `rain` | rain_segment | drop_density, filter_frequency |
| `mechanical` | mechanical_whir | base_frequency, rpm |
| `typing` | typing_segment | key_count, typing_speed |
| `hum` | electric_hum | frequency, harmonic_count |
| `heartbeat` | heartbeat_segment | bpm, peak_frequency |

**Example patterns:**
- `ambient_sparse` - Very minimal, atmospheric
- Custom patterns for layered soundscapes

### 3. Future Suites (Planned)

- `liturgical` - Liturgical ambient sounds (organ, bells, etc.)
- `dark_game_track` - Dark game atmospheric sounds
- `industrial` - Industrial/mechanical percussion

---

## 🎼 Pattern System

### Load Preset Patterns

```gdscript
# Built-in patterns
sequencer.load_pattern("minimal_trap")
sequencer.load_pattern("four_floor")
sequencer.load_pattern("ambient_sparse")
```

### Create Custom Patterns

```gdscript
# Manual pattern definition
sequencer.load_pattern({
    "length": 16,
    "kick": [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
    "snare": [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
    "hihat_closed": [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0]
})
```

### Use PatternSequencer Integration

The Sound Suite Sequencer automatically integrates with `PatternSequencer.gd` for algorithmic pattern generation:

```gdscript
# These patterns are generated algorithmically:
sequencer.load_pattern("minimal")   # Uses PatternSequencer
sequencer.load_pattern("hard")      # trap-style kicks, snares, rolls
sequencer.load_pattern("drill")     # UK drill patterns (32-step)
```

**Available algorithmic styles:**
- `minimal` - Four-on-floor + sparse snares + eighth note hats
- `hard` - Trap kicks + trap snares + trap rolls
- `drill` - Drill kicks + trap snares + trap rolls (32-step)

---

## 🎛️ Sound Parameter Control

### Set Parameters

```gdscript
# Set multiple parameters at once
sequencer.set_sound_params("kick", {
    "pitch": 55.0,
    "decay": 1.5
})

# Update single parameter
var kick_params = sequencer.get_sound_params("kick")
kick_params["pitch"] = 60.0
sequencer.set_sound_params("kick", kick_params)
```

### Get Current Parameters

```gdscript
var kick_params = sequencer.get_sound_params("kick")
print("Kick pitch: ", kick_params.get("pitch", 60.0))
```

### Real-time Parameter Changes

Parameters can be changed while the sequencer is playing. New values will be applied to the next triggered sound.

```gdscript
# Sweep kick pitch up during playback
func _process(delta):
    if sequencer.is_playing:
        var params = sequencer.get_sound_params("kick")
        var pitch = params.get("pitch", 60.0)
        pitch += delta * 10.0  # +10 Hz per second
        sequencer.set_sound_params("kick", {"pitch": pitch})
```

---

## ⏱️ Playback Control

### Basic Control

```gdscript
# Start/stop
sequencer.start()
sequencer.stop()

# BPM
sequencer.set_bpm(120.0)  # Range: 40-200

# Swing (0.0 = straight, 1.0 = max swing)
sequencer.set_swing(0.3)

# Variation (0.0 = no variation, 1.0 = max random)
sequencer.set_variation(0.2)
```

### Per-Track Control

```gdscript
# Mute/unmute
sequencer.mute_track("kick", true)
sequencer.mute_track("kick", false)

# Volume (in dB)
sequencer.set_track_volume("snare", -6.0)
sequencer.set_track_volume("hihat_closed", -12.0)
```

---

## 📡 Signals

### Beat Triggered

```gdscript
sequencer.beat_triggered.connect(_on_beat)

func _on_beat(beat_number: int):
    print("Beat: ", beat_number)
    # Sync visuals, effects, etc.
```

### Pattern Changed

```gdscript
sequencer.pattern_changed.connect(_on_pattern_changed)

func _on_pattern_changed(pattern_name: String):
    print("Now playing: ", pattern_name)
```

### Suite Changed

```gdscript
sequencer.suite_changed.connect(_on_suite_changed)

func _on_suite_changed(suite_name: String):
    print("Switched to suite: ", suite_name)
    # Update UI, available controls, etc.
```

### BPM Changed

```gdscript
sequencer.bpm_changed.connect(_on_bpm_changed)

func _on_bpm_changed(new_bpm: float):
    print("BPM: ", new_bpm)
```

---

## 🎮 Test Scene

### Run the Test Scene

1. Open Godot
2. Navigate to `commons/audio/tests/`
3. Find `test_sound_suite_sequencer.tscn`
4. **Right-click** → **Run Scene** (F6)

### Controls

**Suite Selection:**
- **1** - Trap Beats
- **2** - Tech Noir

**Pattern Selection (Trap Beats):**
- **Q** - Minimal trap
- **W** - Hard trap
- **E** - Four-on-floor

**Pattern Selection (Tech Noir):**
- **Q** - Ambient sparse
- **W** - Atmospheric layers

**Playback:**
- **SPACE** - Play/Stop
- **UP/DOWN** - BPM ±5
- **LEFT/RIGHT** - Swing ±0.05

**Sound Parameters (Trap Beats only):**
- **K/J** - Kick pitch ±5
- **S/A** - Snare decay ±0.1
- **H/G** - Hihat tone ±1000 Hz

---

## 🔧 Integration Examples

### Map Integration

Add to `map_data.json`:

```json
{
  "audio": {
    "sequencer": {
      "type": "SoundSuiteSequencer",
      "suite": "trap_beats",
      "pattern": "minimal_trap",
      "bpm": 85.0,
      "swing": 0.15,
      "sound_params": {
        "kick": {"pitch": 55.0, "decay": 1.2},
        "snare": {"decay": 0.3, "noise_amount": 0.7}
      }
    }
  }
}
```

### Dynamic Suite Switching

```gdscript
# Switch suite based on game state
func _on_area_entered(area):
    if area.name == "TrapZone":
        sequencer.change_suite("trap_beats")
        sequencer.load_pattern("hard")
        sequencer.set_bpm(140.0)
    elif area.name == "AmbientZone":
        sequencer.change_suite("tech_noir")
        sequencer.load_pattern("ambient_sparse")
        sequencer.set_bpm(60.0)
```

### Parameter Automation

```gdscript
# Automate parameters based on gameplay
func _process(delta):
    var intensity = get_gameplay_intensity()  # 0.0 - 1.0

    # Increase kick pitch with intensity
    var kick_pitch = lerp(50.0, 80.0, intensity)
    sequencer.set_sound_params("kick", {"pitch": kick_pitch})

    # Increase BPM with intensity
    var bpm = lerp(85.0, 140.0, intensity)
    sequencer.set_bpm(bpm)
```

### Multi-Suite Composition

```gdscript
# Create multiple sequencers for layering
var trap_seq = SoundSuiteSequencer.new()
trap_seq.initialize({
    "suite": "trap_beats",
    "pattern": "minimal_trap",
    "bpm": 85.0
})

var ambient_seq = SoundSuiteSequencer.new()
ambient_seq.initialize({
    "suite": "tech_noir",
    "pattern": "ambient_sparse",
    "bpm": 85.0
})

# Both play simultaneously
trap_seq.start()
ambient_seq.start()
```

---

## 🎓 Advanced Usage

### Custom Sound Suites

You can extend the system with your own sound suites:

```gdscript
# Add to SoundSuiteSequencer.gd
const SOUND_SUITES = {
    # ... existing suites ...

    "custom_suite": {
        "bass": "my_bass_sound",
        "lead": "my_lead_sound",
        "pad": "my_pad_sound"
    }
}
```

Make sure your sounds are registered in `SoundBankSingleton.gd`.

### Pattern Generation

Integrate with `PatternSequencer.gd` for advanced pattern generation:

```gdscript
# Load PatternSequencer
var PatternSeq = load("res://commons/audio/compositions/systems/PatternSequencer.gd")
var ps = PatternSeq.new()

# Generate euclidean rhythm
var pattern = ps.create_pattern("custom", 16)
ps.generate_euclidean_rhythm(pattern, 5, 16)  # 5 hits in 16 steps
ps.apply_swing(pattern, 0.3)
ps.apply_humanization(pattern, 0.1)

# Convert and load
var converted = sequencer._convert_pattern_sequencer_pattern(pattern)
sequencer.load_pattern(converted)
```

### Sound Parameter Envelopes

Animate parameters over time:

```gdscript
var envelope_time = 0.0

func _process(delta):
    if sequencer.is_playing:
        envelope_time += delta

        # Sine wave pitch modulation
        var pitch_offset = sin(envelope_time * 2.0) * 10.0
        var base_pitch = 60.0

        sequencer.set_sound_params("kick", {
            "pitch": base_pitch + pitch_offset
        })
```

---

## 📋 API Reference

### Methods

| Method | Description |
|--------|-------------|
| `initialize(config: Dictionary)` | Initialize with configuration |
| `change_suite(suite_name: String)` | Switch to different sound suite |
| `load_pattern(pattern)` | Load pattern (String name or Dictionary) |
| `set_sound_params(sound_name: String, params: Dictionary)` | Set parameters for a sound |
| `get_sound_params(sound_name: String) -> Dictionary` | Get current parameters |
| `start()` | Start playback |
| `stop()` | Stop playback |
| `set_bpm(new_bpm: float)` | Set BPM (40-200) |
| `set_swing(amount: float)` | Set swing (0.0-1.0) |
| `set_variation(amount: float)` | Set variation (0.0-1.0) |
| `mute_track(track_name: String, muted: bool)` | Mute/unmute track |
| `set_track_volume(track_name: String, volume_db: float)` | Set track volume |
| `get_available_suites() -> Array` | Get list of available suites |
| `get_suite_sounds() -> Array` | Get sounds in current suite |

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `current_suite` | String | Current sound suite name |
| `current_pattern` | Dictionary | Current pattern data |
| `is_playing` | bool | Playback state |
| `bpm` | float | Current BPM |
| `swing_amount` | float | Current swing amount |
| `variation` | float | Current variation amount |
| `pattern_length` | int | Current pattern length (steps) |

### Signals

| Signal | Parameters | Description |
|--------|------------|-------------|
| `beat_triggered` | `beat_number: int` | Emitted every 4 steps |
| `pattern_changed` | `pattern_name: String` | Emitted when pattern changes |
| `suite_changed` | `suite_name: String` | Emitted when suite changes |
| `bpm_changed` | `new_bpm: float` | Emitted when BPM changes |

---

## 🐛 Troubleshooting

### No Sound?

1. **Check SoundBank**: Make sure `SoundBankSingleton.gd` is registered as AutoLoad
   - Project → Project Settings → AutoLoad
   - Name: `SoundBank`
   - Path: `res://commons/audio/SoundBankSingleton.gd`

2. **Check Console**: Look for warnings about missing sounds or generators

3. **Verify Suite**: Make sure the suite name is correct
   ```gdscript
   print(sequencer.get_available_suites())  # ["trap_beats", "tech_noir"]
   ```

### Sound Not Changing?

Parameters only affect newly generated sounds. If you change a parameter and the sound doesn't change, it will update on the next trigger.

### Pattern Not Loading?

Check pattern format:
```gdscript
# Must have "length" and track arrays
{
    "length": 16,
    "kick": [1, 0, 0, 0, ...],  # 16 values
    "snare": [0, 0, 0, 0, ...]  # 16 values
}
```

### Suite Switch Fails?

Make sure suite exists:
```gdscript
if "my_suite" in sequencer.get_available_suites():
    sequencer.change_suite("my_suite")
else:
    print("Suite not found!")
```

---

## 🎵 Next Steps

1. **Try the test scene** - Get familiar with switching suites and patterns
2. **Experiment with parameters** - Find your sound
3. **Create custom patterns** - Build your own rhythms
4. **Integrate into your maps** - Add dynamic audio to gameplay
5. **Extend the system** - Add your own sound suites

---

**For more information:**
- Trap Beats: `TRAP_BEATS_INTEGRATION.md`
- Tech Noir: `TECH_NOIR_INTEGRATION.md`
- Pattern Sequencer: `commons/audio/compositions/systems/PatternSequencer.gd`
- Audio Catalog: `addons/audio_catalog_editor/`

**Happy sequencing!** 🎵🔥
