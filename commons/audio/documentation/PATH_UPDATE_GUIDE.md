# 🔄 Path Update Guide for Audio Restructure

After running the migration script, you'll need to update import paths and references throughout your project. Here's a comprehensive guide:

## 📂 New Path Structure

| Old Path | New Path | Category |
|----------|----------|----------|
| `res://commons/audio/AudioSynthesizer.gd` | `res://commons/audio/generators/AudioSynthesizer.gd` | Generator |
| `res://commons/audio/CustomSoundGenerator.gd` | `res://commons/audio/generators/CustomSoundGenerator.gd` | Generator |
| `res://commons/audio/SoundDesignerInterface.gd` | `res://commons/audio/interfaces/SoundDesignerInterface.gd` | Interface |
| `res://commons/audio/ModularSoundDesignerInterface.gd` | `res://commons/audio/interfaces/ModularSoundDesignerInterface.gd` | Interface |
| `res://commons/audio/components/` | `res://commons/audio/interfaces/components/` | Components |
| `res://commons/audio/sound_parameters/` | `res://commons/audio/parameters/basic/` | Parameters |
| `res://commons/audio/configs/` | `res://commons/audio/compositions/configs/` | Configs |
| `res://commons/audio/CubeAudioPlayer.gd` | `res://commons/audio/runtime/CubeAudioPlayer.gd` | Runtime |

## 🔍 Files That Need Updates

### 1. Scene Files (.tscn)
Search for and update script paths in:
- Any scenes that use `SoundDesignerInterface.gd`
- Any scenes that use `ModularSoundDesignerInterface.gd`
- Component-based scenes

**Find and replace patterns:**
```
res://commons/audio/SoundDesignerInterface.gd
→ res://commons/audio/interfaces/SoundDesignerInterface.gd

res://commons/audio/ModularSoundDesignerInterface.gd
→ res://commons/audio/interfaces/ModularSoundDesignerInterface.gd
```

### 2. Script Imports (.gd files)
Update `extends` and `const` declarations:

**Before:**
```gdscript
extends "res://commons/audio/CustomSoundGenerator.gd"
const AudioSynthesizer = preload("res://commons/audio/AudioSynthesizer.gd")
```

**After:**
```gdscript
extends "res://commons/audio/generators/CustomSoundGenerator.gd"
const AudioSynthesizer = preload("res://commons/audio/generators/AudioSynthesizer.gd")
```

### 3. JSON Parameter Loading
Update parameter file paths:

**Before:**
```gdscript
var json_path = "res://commons/audio/sound_parameters/pickup_mario.json"
var parameter_dir = "res://commons/audio/sound_parameters/"
```

**After:**
```gdscript
var json_path = "res://commons/audio/parameters/basic/pickup_mario.json"
var parameter_dir = "res://commons/audio/parameters/basic/"
```

### 4. Audio Resource References
Update .tres file paths:

**Before:**
```gdscript
var sound = load("res://commons/audio/pickup_mario.tres")
```

**After:**
```gdscript
var sound = load("res://commons/audio/runtime/presets/pickup_mario.tres")
```

### 5. Config File References
Update track configuration paths:

**Before:**
```gdscript
var config_path = "res://commons/audio/configs/dark_game_track.json"
```

**After:**
```gdscript
var config_path = "res://commons/audio/compositions/configs/dark_game_track.json"
```

## 🛠️ Automated Find & Replace

Use your editor's global find and replace to batch update paths:

### VSCode / Cursor
1. Press `Ctrl+Shift+H` (Find & Replace in Files)
2. Set scope to your project directory
3. Use these patterns:

```
Find: res://commons/audio/AudioSynthesizer\.gd
Replace: res://commons/audio/generators/AudioSynthesizer.gd

Find: res://commons/audio/CustomSoundGenerator\.gd
Replace: res://commons/audio/generators/CustomSoundGenerator.gd

Find: res://commons/audio/SoundDesignerInterface\.gd
Replace: res://commons/audio/interfaces/SoundDesignerInterface.gd

Find: res://commons/audio/ModularSoundDesignerInterface\.gd
Replace: res://commons/audio/interfaces/ModularSoundDesignerInterface.gd

Find: res://commons/audio/components/
Replace: res://commons/audio/interfaces/components/

Find: res://commons/audio/sound_parameters/
Replace: res://commons/audio/parameters/basic/

Find: res://commons/audio/configs/
Replace: res://commons/audio/compositions/configs/

Find: res://commons/audio/CubeAudioPlayer\.gd
Replace: res://commons/audio/runtime/CubeAudioPlayer.gd
```

### Godot Editor
1. Use `Search > Find and Replace in Files`
2. Apply the same patterns as above

## 📋 Checklist After Migration

- [ ] **Run the migration script**
  ```gdscript
  # In Godot editor, run:
  migrate_audio_structure.migrate_structure()
  ```

- [ ] **Update import paths in scripts**
  - [ ] Generator imports (`AudioSynthesizer`, `CustomSoundGenerator`)
  - [ ] Interface imports (`SoundDesignerInterface`, `ModularSoundDesignerInterface`)
  - [ ] Component imports (anything from `components/`)
  - [ ] Runtime imports (`CubeAudioPlayer`, `LeanAudioRuntime`)

- [ ] **Update scene script assignments**
  - [ ] Interface scenes (`.tscn` files)
  - [ ] Audio test scenes
  - [ ] Any custom scenes using audio components

- [ ] **Update parameter loading paths**
  - [ ] JSON parameter file references
  - [ ] Directory scanning code
  - [ ] Parameter validation scripts

- [ ] **Update resource references**
  - [ ] Pre-rendered audio files (`.tres`)
  - [ ] Configuration files (`.json`)
  - [ ] Asset loading scripts

- [ ] **Test functionality**
  - [ ] Audio playback still works
  - [ ] Parameter loading works
  - [ ] Interface scenes load properly
  - [ ] No broken script references
  - [ ] Export builds work correctly

## 🔧 Quick Test Script

Create this test script to verify paths work:

```gdscript
# test_new_paths.gd
@tool
extends EditorScript

func _run():
    print("🧪 Testing new audio paths...")
    
    # Test core generators
    var synthesizer = load("res://commons/audio/generators/AudioSynthesizer.gd")
    var generator = load("res://commons/audio/generators/CustomSoundGenerator.gd")
    
    # Test interfaces
    var designer = load("res://commons/audio/interfaces/SoundDesignerInterface.gd")
    var modular = load("res://commons/audio/interfaces/ModularSoundDesignerInterface.gd")
    
    # Test runtime
    var cube_player = load("res://commons/audio/runtime/CubeAudioPlayer.gd")
    var lean_runtime = load("res://commons/audio/runtime/LeanAudioRuntime.gd")
    
    # Test parameter file
    var param_file = "res://commons/audio/parameters/basic/pickup_mario.json"
    var param_exists = FileAccess.file_exists(param_file)
    
    print("✅ Synthesizer: %s" % (synthesizer != null))
    print("✅ Generator: %s" % (generator != null))
    print("✅ Designer Interface: %s" % (designer != null))
    print("✅ Modular Interface: %s" % (modular != null))
    print("✅ Cube Player: %s" % (cube_player != null))
    print("✅ Lean Runtime: %s" % (lean_runtime != null))
    print("✅ Parameter file: %s" % param_exists)
    
    if synthesizer and generator and designer and modular and cube_player and lean_runtime and param_exists:
        print("🎉 All paths working correctly!")
    else:
        print("❌ Some paths are broken - check the migration")
```

## 🎯 Benefits After Migration

Once completed, you'll have:

✅ **Clear separation** between runtime and development tools  
✅ **Logical organization** with related files grouped together  
✅ **Easy navigation** - find files by purpose, not alphabetically  
✅ **Scalable structure** - easy to add new categories  
✅ **Minimal game footprint** - only `runtime/` needed for builds  
✅ **Better maintainability** - clear ownership of different areas  

The restructured audio folder will be much more professional and easier to work with! 