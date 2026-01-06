# 🗂️ Audio Folder Restructuring Plan
> **STATUS: COMPLETED (January 2025)**
> This plan has been fully executed. The directory structure below reflects the current state of the project.


## Current Structure Issues
- 70+ files mixed together in root audio folder
- No clear separation between runtime and development tools
- Documentation scattered throughout
- Generated files mixed with source files
- No clear categorization of functionality

## 📁 New Proposed Structure

```
commons/audio/
├── 🎮 runtime/                         # GAME RUNTIME ONLY
│   ├── LeanAudioRuntime.gd            # Minimal runtime system
│   ├── CubeAudioPlayer.gd             # Game integration
│   ├── SyntheticSoundGenerator.gd     # Basic synthesis
│   └── presets/                       # Pre-rendered audio files
│       ├── pickup_mario.tres
│       ├── teleport_drone.tres
│       ├── ghost_drone.tres
│       ├── lift_bass_pulse.tres
│       └── melodic_drone.tres
│
├── 🎛️ interfaces/                      # DEVELOPMENT INTERFACES
│   ├── SoundDesignerInterface.gd      # Full educational interface
│   ├── sound_interface.tscn           
│   ├── ModularSoundDesignerInterface.gd # Modular professional interface
│   ├── modular_sound_interface.tscn
│   └── components/                     # UI components
│       ├── AudioVisualizationComponent.gd
│       ├── ParameterControlsComponent.gd
│       ├── FileManagerComponent.gd
│       ├── SoundParameterManager.gd
│       └── README_ModularAudioInterface.md
│
├── 🔧 generators/                      # SOUND GENERATION ENGINES
│   ├── AudioSynthesizer.gd            # Core synthesizer
│   ├── CustomSoundGenerator.gd        # Advanced generator
│   ├── test_parameter_connection.gd
│   └── create_default_parameters.gd
│
├── 🎵 compositions/                    # MUSICAL COMPOSITIONS & TRACKS
│   ├── players/                       # Track players
│   │   ├── DarkGameTrackPlayer.gd
│   │   ├── DarkGameTrackPlayerJSON.gd
│   │   ├── DarkBladeRunner128TrackPlayer.gd
│   │   ├── SyncopatedTrackPlayer.gd
│   │   ├── StructuredTrackPlayer.gd
│   │   └── PolymeterTrackPlayer.gd
│   ├── scenes/                        # Track scene files
│   │   ├── dark_game_track.tscn
│   │   ├── syncopated_track.tscn
│   │   ├── structured_track.tscn
│   │   └── polymeter_track.tscn
│   ├── systems/                       # Track systems
│   │   ├── EnhancedTrackSystem.gd
│   │   ├── EnhancedTrackExample.gd
│   │   ├── EnhancedDarkTrack.gd
│   │   ├── TrackLayer.gd
│   │   ├── PatternSequencer.gd
│   │   ├── EffectsRack.gd
│   │   ├── TrackConfigExample.gd
│   │   └── TrackConfigLoader.gd
│   └── configs/                       # Track configurations
│       ├── dark_ambient_track.json
│       ├── dark_game_track.json
│       ├── dark_game_track_simple.json
│       └── simple_beat.json
│
├── 📊 parameters/                      # SOUND PARAMETER DEFINITIONS
│   ├── basic/                         # Basic game sounds
│   │   ├── basic_sine_wave.json
│   │   ├── pickup_mario.json
│   │   ├── teleport_drone.json
│   │   ├── ghost_drone.json
│   │   ├── lift_bass_pulse.json
│   │   ├── power_up_jingle.json
│   │   ├── laser_shot.json
│   │   ├── shield_hit.json
│   │   ├── explosion.json
│   │   ├── retro_jump.json
│   │   └── ambient_wind.json
│   ├── drums/                         # Drum machine sounds
│   │   ├── dark_808_kick.json
│   │   ├── acid_606_hihat.json
│   │   ├── tr909_kick.json
│   │   ├── linn_drum_kick.json
│   │   ├── synare_3_disco_tom.json
│   │   └── synare_3_cosmic_fx.json
│   ├── synthesizers/                  # Classic synthesizer emulations
│   │   ├── moog_bass_lead.json
│   │   ├── tb303_acid_bass.json
│   │   ├── dx7_electric_piano.json
│   │   ├── jupiter_8_strings.json
│   │   ├── korg_m1_piano.json
│   │   ├── arp_2600_lead.json
│   │   ├── ppg_wave_pad.json
│   │   └── moog_kraftwerk_sequencer.json
│   ├── retro/                         # Retro computer sounds
│   │   ├── c64_sid_lead.json
│   │   ├── amiga_mod_sample.json
│   │   ├── gameboy_dmg_wav.json
│   │   └── ambient_amiga_drone.json
│   ├── experimental/                  # Experimental/artist signatures
│   │   ├── aphex_twin_modular.json
│   │   ├── flying_lotus_sampler.json
│   │   └── herbie_hancock_moog_fusion.json
│   ├── ambient/                       # Ambient/atmospheric
│   │   ├── dark_808_sub_bass.json
│   │   ├── ambient_amiga_drone.json
│   │   ├── melodic_drone.json
│   │   └── ghost_drone.json
│   └── README.md                      # Parameter documentation
│
├── 🧪 testing/                         # TESTING & DEVELOPMENT
│   ├── AudioTestScene.gd
│   └── test_scenes/
│
└── 📚 documentation/                   # DOCUMENTATION
    ├── README.md                      # Main audio system overview
    ├── README_SoundDesignerTutorial.md
    ├── README_EnhancedTrackSystem.md
    ├── AudioProjectStructure.md       # Project organization guide
    └── guides/                        # Additional guides
        ├── synthesis_guide.md
        ├── parameter_guide.md
        └── integration_guide.md
```

## 🔄 Migration Steps

### Phase 1: Create New Directory Structure
```bash
cd commons/audio/

# Create main directories
mkdir -p runtime/presets
mkdir -p interfaces/components
mkdir -p generators
mkdir -p compositions/{players,scenes,systems,configs}
mkdir -p parameters/{basic,drums,synthesizers,retro,experimental,ambient}
mkdir -p testing/test_scenes
mkdir -p documentation/guides
```

### Phase 2: Move Files by Category

#### Runtime Files (Game Essential)
```bash
# Core runtime
mv LeanAudioRuntime.gd runtime/
mv CubeAudioPlayer.gd runtime/
mv SyntheticSoundGenerator.gd runtime/

# Pre-rendered audio files
mv *.tres runtime/presets/
```

#### Interface Files (Development Tools)
```bash
# Main interfaces
mv SoundDesignerInterface.gd interfaces/
mv sound_interface.tscn interfaces/
mv ModularSoundDesignerInterface.gd interfaces/
mv modular_sound_interface.tscn interfaces/

# Components (already in subfolder, just move whole folder)
mv components/ interfaces/
```

#### Generator Files (Sound Creation)
```bash
mv AudioSynthesizer.gd generators/
mv CustomSoundGenerator.gd generators/
mv test_parameter_connection.gd generators/
mv create_default_parameters.gd generators/
```

#### Composition Files (Music & Tracks)
```bash
# Players
mv *TrackPlayer.gd compositions/players/

# Scenes
mv *_track.tscn compositions/scenes/

# Systems
mv EnhancedTrackSystem.gd compositions/systems/
mv EnhancedTrackExample.gd compositions/systems/
mv EnhancedDarkTrack.gd compositions/systems/
mv TrackLayer.gd compositions/systems/
mv PatternSequencer.gd compositions/systems/
mv EffectsRack.gd compositions/systems/
mv TrackConfigExample.gd compositions/systems/
mv TrackConfigLoader.gd compositions/systems/

# Move configs folder
mv configs/ compositions/
```

#### Parameter Files (JSON Configurations)
```bash
cd sound_parameters/

# Basic game sounds
mv basic_sine_wave.json ../parameters/basic/
mv pickup_mario.json ../parameters/basic/
mv teleport_drone.json ../parameters/basic/
mv ghost_drone.json ../parameters/basic/
mv lift_bass_pulse.json ../parameters/basic/
mv power_up_jingle.json ../parameters/basic/
mv laser_shot.json ../parameters/basic/
mv shield_hit.json ../parameters/basic/
mv explosion.json ../parameters/basic/
mv retro_jump.json ../parameters/basic/
mv ambient_wind.json ../parameters/basic/

# Drum sounds
mv dark_808_kick.json ../parameters/drums/
mv acid_606_hihat.json ../parameters/drums/
mv tr909_kick.json ../parameters/drums/
mv linn_drum_kick.json ../parameters/drums/
mv synare_3_disco_tom.json ../parameters/drums/
mv synare_3_cosmic_fx.json ../parameters/drums/

# Synthesizer sounds
mv moog_bass_lead.json ../parameters/synthesizers/
mv tb303_acid_bass.json ../parameters/synthesizers/
mv dx7_electric_piano.json ../parameters/synthesizers/
mv jupiter_8_strings.json ../parameters/synthesizers/
mv korg_m1_piano.json ../parameters/synthesizers/
mv arp_2600_lead.json ../parameters/synthesizers/
mv ppg_wave_pad.json ../parameters/synthesizers/
mv moog_kraftwerk_sequencer.json ../parameters/synthesizers/

# Retro computer sounds
mv c64_sid_lead.json ../parameters/retro/
mv amiga_mod_sample.json ../parameters/retro/
mv gameboy_dmg_wav.json ../parameters/retro/
mv ambient_amiga_drone.json ../parameters/retro/

# Experimental sounds
mv aphex_twin_modular.json ../parameters/experimental/
mv flying_lotus_sampler.json ../parameters/experimental/
mv herbie_hancock_moog_fusion.json ../parameters/experimental/

# Ambient sounds
mv dark_808_sub_bass.json ../parameters/ambient/
mv melodic_drone.json ../parameters/ambient/

# Move documentation
mv README.md ../parameters/

cd ..
rmdir sound_parameters/  # Remove empty directory
```

#### Documentation Files
```bash
mv README.md documentation/
mv README_SoundDesignerTutorial.md documentation/
mv README_EnhancedTrackSystem.md documentation/
mv AudioProjectStructure.md documentation/
```

#### Testing Files
```bash
mv AudioTestScene.gd testing/
```

### Phase 3: Update Path References

#### Update import paths in files:
```gdscript
# OLD paths:
"res://commons/audio/CustomSoundGenerator.gd"
"res://commons/audio/components/AudioVisualizationComponent.gd"

# NEW paths:
"res://commons/audio/generators/CustomSoundGenerator.gd"
"res://commons/audio/interfaces/components/AudioVisualizationComponent.gd"
```

#### Update parameter loading paths:
```gdscript
# OLD:
var json_directory = "res://commons/audio/sound_parameters/"

# NEW:
var json_directory = "res://commons/audio/parameters/basic/"
```

## 🎯 Benefits of New Structure

### **For Developers:**
- ✅ **Clear separation**: Runtime vs development tools
- ✅ **Logical grouping**: Related files are together
- ✅ **Easy navigation**: Find files by purpose, not alphabetically
- ✅ **Scalable**: Easy to add new categories

### **For Game Runtime:**
- ✅ **Minimal footprint**: Only runtime/ folder needed in builds
- ✅ **Clear dependencies**: Easy to see what's essential
- ✅ **Fast loading**: Pre-rendered files in dedicated location

### **For Project Management:**
- ✅ **Better version control**: Changes grouped by area
- ✅ **Easier collaboration**: Clear ownership of sections
- ✅ **Maintenance**: Find and update related files easily

### **For Education/Learning:**
- ✅ **Progressive complexity**: Start with basics, advance to experimental
- ✅ **Clear examples**: Each category shows different techniques
- ✅ **Organized documentation**: All guides in one place

## 🔧 Implementation Scripts

### Automated Migration Script
```gdscript
# migrate_audio_structure.gd
# Run this script to automatically reorganize the audio folder

extends RefCounted

const AUDIO_PATH = "res://commons/audio/"

func migrate_structure():
    print("🔄 Starting audio folder migration...")
    
    _create_directory_structure()
    _move_runtime_files()
    _move_interface_files()
    _move_generator_files()
    _move_composition_files()
    _move_parameter_files()
    _move_documentation_files()
    _move_testing_files()
    _update_path_references()
    
    print("✅ Migration complete!")

func _create_directory_structure():
    var dirs = [
        "runtime/presets",
        "interfaces/components", 
        "generators",
        "compositions/players",
        "compositions/scenes",
        "compositions/systems",
        "compositions/configs",
        "parameters/basic",
        "parameters/drums",
        "parameters/synthesizers",
        "parameters/retro", 
        "parameters/experimental",
        "parameters/ambient",
        "testing/test_scenes",
        "documentation/guides"
    ]
    
    for dir in dirs:
        DirAccess.open(AUDIO_PATH).make_dir_recursive(dir)
        print("📁 Created: %s" % dir)
```

This restructuring will make your audio system much more maintainable and easier to navigate! 