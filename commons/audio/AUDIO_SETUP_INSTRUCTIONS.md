# Audio System Setup Instructions

## ✅ What Was Implemented

The audio system is now **fully integrated** into GridSystem! Here's what was added:

### New Files Created
1. **`GridAudioComponent.gd`** - Component-based audio management
2. **This instructions file**

### Files Modified
1. **`GridSystem.gd`** - Integrated audio component into generation flow
2. **`ambient_presets.json`** - Updated `techno_noir_subtle` to use working AudioSynthesizer sounds

---

## 🚀 Setup Steps

### Step 1: Add SoundBank as AutoLoad

**CRITICAL**: You must register `SoundBankSingleton` as an AutoLoad for audio to work.

1. Open Godot
2. Go to: **Project → Project Settings → AutoLoad**
3. Click **Add** and configure:
   - **Path**: `res://commons/audio/SoundBankSingleton.gd`
   - **Name**: `SoundBank`
   - **Enable**: ✅ (checked)
4. Click **Add**
5. Click **Close**

### Step 2: Test in Primitives Sequence

The audio system is already configured in `map_sequences.json`:

```json
"primitives": {
  "audio": {
    "ambient_preset": "techno_noir_subtle",
    "volume": -8.0
  }
}
```

**To test:**
1. Load the Lab map
2. Use teleporter marked `t:primitives`
3. You should hear:
   - **Continuous**: Deep 808 sub-bass + Amiga drone
   - **Random Events**: Laser shots, shield hits, glitchy sounds (every 20-60 seconds)

---

## 🎵 How It Works

### Audio Flow
```
Map Loads
  ↓
GridSystem._on_data_loaded()
  ↓
audio_component.initialize()
  ↓
Reads audio config from:
  1. map_sequences.json (global + sequence)
  2. map_data.json (map-specific)
  ↓
_on_spawn_complete()
  ↓
audio_component.start_ambient()
  ↓
Creates AmbientSoundController
  ↓
Loads preset from SoundBank
  ↓
Generates sounds with AudioSynthesizer
  ↓
Plays ambient layers + random events
```

### Audio Hierarchy
```
Global defaults (map_sequences.json)
  ↓ (overrides)
Sequence audio (map_sequences.json → sequences → [name] → audio)
  ↓ (overrides)
Map audio (map_data.json → settings → audio)
```

---

## 🎛️ Configuration Options

### In `map_sequences.json`

**Global defaults:**
```json
{
  "audio_defaults": {
    "ambient_preset": "silent",
    "volume": 0.0,
    "crossfade_duration": 2.0
  }
}
```

**Sequence-level:**
```json
{
  "sequences": {
    "primitives": {
      "audio": {
        "ambient_preset": "techno_noir_subtle",
        "volume": -8.0
      }
    }
  }
}
```

### In Individual `map_data.json`

```json
{
  "settings": {
    "audio": {
      "ambient_preset": "lab_scientific",
      "volume": -10.0,
      "crossfade_duration": 3.0
    }
  }
}
```

---

## 🎼 Available Presets

### Currently Working Presets (use AudioSynthesizer)

1. **`silent`** - No audio
2. **`techno_noir_subtle`** ✅ - Dark ambient with 808 bass + drone
3. **`lab_scientific`** - Clean lab ambience
4. **`computational_hum`** - Computational atmosphere
5. **`minimal_drone`** - Minimal ambient wind
6. **`fractal_exploration`** - Mathematical tones
7. **`particle_physics`** - Energetic physics atmosphere

### Not Yet Working (need sound generation implementation)

- **`techno_noir_full`** - Uses unimplemented `techno_noir.*` sounds
- **`liturgical_cathedral`** - Uses unimplemented `liturgical.*` sounds
- **`dark_game_808`** - Uses unimplemented `DarkGameTrack.*` sounds

---

## 🔧 Debugging

### Check if SoundBank is loaded
```gdscript
var sound_bank = get_node_or_null("/root/SoundBank")
if sound_bank:
    sound_bank.print_info()
```

### Check audio component status
```gdscript
var grid_system = get_node("GridSystem")
var audio = grid_system.get_audio_component()
audio.print_info()
```

### Expected Console Output
```
GridSystem: Starting ambient audio...
GridAudioComponent: Applied global audio defaults
GridAudioComponent: Applied sequence audio config: primitives
GridAudioComponent: Final audio config - Preset: techno_noir_subtle, Volume: -8.0 dB
GridAudioComponent: Starting ambient preset: techno_noir_subtle (volume: -8.0 dB)
AmbientSoundController: Started continuous layer: AudioSynthesizer.DARK_808_SUB_BASS on bus Ambient
AmbientSoundController: Started continuous layer: AudioSynthesizer.AMBIENT_AMIGA_DRONE on bus Ambient
GridSystem: 🎵 Ambient audio started - techno_noir_subtle
```

### Common Issues

**1. No sound playing**
- Check AutoLoad: Is `SoundBank` registered?
- Check preset: Does it exist in `ambient_presets.json`?
- Check volume: Is it too low (< -80 dB)?

**2. "SoundBank singleton not found" error**
- You forgot Step 1! Add SoundBank as AutoLoad

**3. Sounds generating but not playing**
- Check Godot's Audio panel (bottom right)
- Verify audio buses exist
- Check master volume isn't muted

---

## 🎯 Next Steps

### To Add More Presets

1. Edit `commons/audio/ambient_presets.json`
2. Use sound IDs from **AudioSynthesizer** (they work)
3. Format: `"AudioSynthesizer.SOUND_NAME"`

### To Use Per-Map Audio

Add to any `map_data.json`:
```json
{
  "settings": {
    "audio": {
      "ambient_preset": "lab_scientific",
      "volume": -12.0
    }
  }
}
```

### To Implement Techno Noir Sounds

The `techno_noir.*` sounds are defined in `ambient_presets.json` but not implemented yet. To implement:

1. Extract generation code from `algorithms/wavefunctions/technoirgameaudio/john_cage_tech_noir.gd`
2. Add to `SoundBankSingleton._generate_techno_noir_sound()`
3. Update presets to use the sounds

---

## 📚 Documentation

- **Full Guide**: `commons/audio/SOUND_SYSTEM_GUIDE.md`
- **Presets**: `commons/audio/ambient_presets.json`
- **Component Code**: `commons/grid/GridAudioComponent.gd`
- **Integration**: `commons/grid/GridSystem.gd` (lines 21, 108-110, 140-144, 173-180, 274-297)

---

**Status**: ✅ **READY TO TEST**

After completing Step 1 (AutoLoad), the audio system will automatically work for all maps with audio configuration!
