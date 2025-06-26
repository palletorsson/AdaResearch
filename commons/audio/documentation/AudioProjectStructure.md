# 🎵 Audio Project Restructuring Guide

## Overview
This guide shows how to separate your audio development tools from the game runtime while maintaining a JSON-driven workflow.

## 📁 Project Structure

### **Development Project: `AdaAudioTools`**
```
AdaAudioTools/
├── interfaces/
│   ├── SoundDesignerInterface.gd           # Full design interface
│   ├── sound_interface.tscn
│   ├── ModularSoundDesignerInterface.gd    # Modular interface
│   ├── modular_sound_interface.tscn
│   └── components/
│       ├── AudioVisualizationComponent.gd
│       ├── ParameterControlsComponent.gd
│       ├── FileManagerComponent.gd
│       └── SoundParameterManager.gd
├── generators/
│   ├── CustomSoundGenerator.gd             # Full generator with all sounds
│   ├── AudioSynthesizer.gd                 # Full synthesizer
│   └── AdvancedSynthesis.gd                # Extended synthesis methods
├── presets/
│   ├── sound_parameters/                   # JSON configurations
│   ├── user_presets/                       # User-created presets
│   └── examples/                           # Example configurations
├── documentation/
│   ├── README_SoundDesignerTutorial.md
│   ├── README_EnhancedTrackSystem.md
│   └── synthesis_guides/
├── export/
│   └── exported_sounds/                    # Pre-rendered .tres/.wav files
└── tools/
    ├── batch_export.gd                     # Batch export script
    ├── json_validator.gd                   # Validate JSON configs
    └── parameter_optimizer.gd              # Optimize parameters
```

### **Game Project: `AdaResearch` (Lean Runtime)**
```
AdaResearch/commons/audio/
├── LeanAudioRuntime.gd                     # NEW: Minimal runtime
├── sound_parameters/                       # JSON configs (synced)
│   ├── pickup_mario.json
│   ├── teleport_drone.json
│   ├── ghost_drone.json
│   ├── power_up_jingle.json
│   ├── shield_hit.json
│   └── basic_sine_wave.json
├── presets/                                # Ready-to-use audio files
│   ├── pickup_mario.tres
│   ├── teleport_drone.tres
│   └── (other pre-rendered sounds)
├── CubeAudioPlayer.gd                      # Game integration (updated)
└── configs/                                # High-level track configs
    ├── dark_ambient_track.json
    └── dark_game_track.json
```

## 🔄 JSON Workflow

### 1. **Development Phase**
```gdscript
# In AdaAudioTools project - experiment with sounds
var interface = SoundDesignerInterface.new()
# Adjust parameters in real-time
# Export JSON when satisfied

# Example: Creating a new teleport sound
var teleport_params = {
    "base_freq": 180.0,
    "mod_freq": 0.8, 
    "mod_depth": 45.0,
    "amplitude": 0.25,
    "duration": 3.5
}
# Export to teleport_drone.json
```

### 2. **JSON Configuration Format**
```json
{
    "_metadata": {
        "sound_type": "teleport_drone",
        "description": "Portal teleportation ambient effect",
        "created_at": "2024-12-24T12:00:00Z",
        "version": "1.0",
        "is_default": true
    },
    "parameters": {
        "duration": {
            "value": 3.0,
            "min": 1.0,
            "max": 10.0,
            "step": 0.1
        },
        "base_freq": {
            "value": 220.0,
            "min": 50.0,
            "max": 500.0,
            "step": 5.0
        },
        "mod_freq": {
            "value": 0.5,
            "min": 0.1,
            "max": 5.0,
            "step": 0.1
        },
        "mod_depth": {
            "value": 30.0,
            "min": 0.0,
            "max": 100.0,
            "step": 1.0
        },
        "amplitude": {
            "value": 0.2,
            "min": 0.0,
            "max": 1.0,
            "step": 0.01
        }
    }
}
```

### 3. **Runtime Usage**
```gdscript
# In AdaResearch game project - use lean runtime
LeanAudioRuntime.initialize()

# Simple usage
var pickup_sound = LeanAudioRuntime.play_pickup_sound()
audio_player.stream = pickup_sound
audio_player.play()

# Custom parameters
var custom_teleport = LeanAudioRuntime.play_teleport_sound({
    "base_freq": 150.0,  # Lower pitch
    "duration": 5.0      # Longer duration
})
```

## 📦 Migration Steps

### Step 1: Create Development Project
```bash
# Create new Godot project: AdaAudioTools
mkdir AdaAudioTools
cd AdaAudioTools
# Copy development files from AdaResearch/commons/audio/
```

### Step 2: Move Development Files
**Move to AdaAudioTools:**
- `SoundDesignerInterface.gd` + `.tscn`
- `ModularSoundDesignerInterface.gd` + `.tscn`  
- `components/` folder
- Tutorial/documentation files
- Complex synthesis methods

### Step 3: Create Lean Runtime
**Keep in AdaResearch:**
- `LeanAudioRuntime.gd` (new minimal system)
- `sound_parameters/` (JSON configs)
- `CubeAudioPlayer.gd` (update to use LeanAudioRuntime)
- Pre-rendered `.tres` files for performance

### Step 4: Update Game Integration
```gdscript
# Replace old AudioSynthesizer calls with LeanAudioRuntime
# Old:
var sound = AudioSynthesizer.generate_sound(AudioSynthesizer.SoundType.PICKUP_MARIO, 0.5)

# New:
var sound = LeanAudioRuntime.play_pickup_sound({"duration": 0.5})
```

## 🔧 Sync Tools

### JSON Sync Script
```gdscript
# sync_json_configs.gd
# Run in AdaAudioTools to sync configs to game project

extends ScriptableObject

const DEV_PATH = "user://sound_parameters/"
const GAME_PATH = "../AdaResearch/commons/audio/sound_parameters/"

func sync_configs():
    var dir = DirAccess.open(DEV_PATH)
    if not dir:
        return
        
    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    while file_name != "":
        if file_name.ends_with(".json"):
            var source = DEV_PATH + file_name
            var dest = GAME_PATH + file_name
            dir.copy(source, dest)
            print("Synced: %s" % file_name)
        file_name = dir.get_next()
```

### Export Tool
```gdscript
# batch_export_tool.gd
# Pre-render audio files for performance

func export_all_sounds():
    var configs = load_all_json_configs()
    
    for config_name in configs.keys():
        var params = configs[config_name]
        var sound = generate_sound_from_config(config_name, params)
        
        # Save as .tres for game
        var output_path = "export/" + config_name + ".tres"
        ResourceSaver.save(sound, output_path)
        print("Exported: %s" % output_path)
```

## 🎯 Benefits

### **Development Benefits:**
- ✅ Full creative freedom with complex interfaces
- ✅ Real-time parameter tweaking and visualization
- ✅ Educational content and tutorials
- ✅ Advanced synthesis techniques
- ✅ Version control for audio development

### **Runtime Benefits:**
- ✅ Minimal code footprint in game
- ✅ Fast loading with JSON configs
- ✅ Easy parameter customization at runtime
- ✅ No UI overhead in game builds
- ✅ Cacheable pre-rendered audio

### **Workflow Benefits:**
- ✅ Clean separation of concerns
- ✅ Independent project evolution
- ✅ JSON-driven parameter sharing
- ✅ Automated sync and export tools
- ✅ Maintainable codebase

## 🚀 Advanced Features

### Dynamic Parameter Loading
```gdscript
# Load specific sound variations at runtime
var boss_teleport = LeanAudioRuntime.play_teleport_sound({
    "base_freq": 80.0,      # Deep, menacing
    "mod_depth": 60.0,      # More chaotic
    "duration": 4.0         # Longer buildup
})

var fairy_teleport = LeanAudioRuntime.play_teleport_sound({
    "base_freq": 400.0,     # High, magical
    "mod_depth": 15.0,      # Gentle modulation
    "duration": 1.5         # Quick and light
})
```

### Performance Optimization
```gdscript
# Pre-load common sounds for performance
LeanAudioRuntime.preload_sound("pickup_mario")
LeanAudioRuntime.preload_sound("teleport_drone")

# Use cached versions during gameplay
var cached_pickup = LeanAudioRuntime.get_cached_sound("pickup_mario")
```

This structure gives you the best of both worlds: powerful development tools separate from a lean, efficient runtime system that still uses your JSON-driven parameter approach! 