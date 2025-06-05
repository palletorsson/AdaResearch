# LabGrid System

## 🚀 Quick Reference (Claude's Notes)

**What**: Thin layer on GridSystem for lab environments with off-white cubes and progression
**Files**: `LabGridSystem.gd` (extends GridSystem), `LabGridScene.gd` (controller), `lab_grid.tscn`
**Key Diff**: `lab_cube_color = Color(0.95, 0.95, 0.98)`, progressive artifact unlocking, lab lighting
**JSON**: Same 3-layer structure as grid (structure/utilities/interactables), lives in `commons/maps/Lab/`
**Integration**: Drop-in replacement for lab.tscn, works with existing AdaSceneManager/artifacts
**Progression**: rotating_cube → array_tutorial → unlocks xyz_coordinates+grid_display → etc.

---

## Overview

The LabGrid System is a specialized laboratory environment built as a thin layer on top of the existing GridSystem. It provides a clean, scientific laboratory aesthetic with off-white cubes and progressive artifact unlocking, while reusing all the robust infrastructure of the grid system.

## ✨ Key Features

- **Off-white Laboratory Aesthetic**: Clean, scientific look with customizable cube colors
- **Progressive Artifact System**: Artifacts unlock as educational sequences are completed
- **Zero Code Duplication**: Extends GridSystem rather than reimplementing functionality
- **JSON-Driven Configuration**: Same familiar 3-layer structure as tutorial maps
- **Seamless Integration**: Drop-in replacement for existing lab scenes

## 🏗️ Architecture

### Core Components

```
LabGridSystem.gd          # Extends GridSystem, adds lab styling & progression
├── Lab Visual Styling    # Off-white cubes, lab lighting, clean aesthetic
├── Progression Manager   # Artifact unlocking based on sequence completion
└── Lab Signal Handling   # Lab-specific artifact and sequence triggers

LabGridScene.gd           # Scene controller for SceneManager integration
├── Scene Data Processing # Handles completion data from returning sequences
├── Debug Commands        # Testing progression and unlocks
└── SceneManager Bridge   # Connects lab events to scene transitions
```

### File Structure

```
res://commons/
├── scenes/
│   ├── LabGridSystem.gd      # Main lab system (extends GridSystem)
│   ├── LabGridScene.gd       # Scene controller
│   └── lab_grid.tscn         # Lab scene file
└── maps/
	└── Lab/
		└── map_data.json     # Lab layout and configuration
```

## 🎨 Visual Styling

### Default Lab Colors
- **Cube Color**: `Color(0.95, 0.95, 0.98, 1.0)` - Clean off-white
- **Ambient Light**: `Color(0.9, 0.9, 1.0, 0.4)` - Cool laboratory lighting
- **Grid**: Hidden for cleaner aesthetic

### Lab Variants
```gdscript
# Research Lab (cool, clinical)
lab_cube_color = Color(0.95, 0.98, 1.0, 1.0)

# Teaching Lab (warm, inviting)
lab_cube_color = Color(1.0, 0.98, 0.95, 1.0)

# High-tech Lab (neutral, bright)
lab_cube_color = Color(0.98, 0.98, 0.98, 1.0)
```

## 🔄 Progression System

### Unlock Sequence
1. **Initial State**: Only `rotating_cube` visible
2. **Array Tutorial Complete**: Unlocks `xyz_coordinates` + `grid_display`
3. **Randomness Exploration Complete**: Unlocks `probability_sphere` + `randomness_sign`
4. **Geometric Algorithms Complete**: Unlocks `disco_floor`

### Visual Feedback
- Hidden artifacts become visible with unlock animation
- Scale-up effect when new artifacts appear
- Persistent progression saved to `user://lab_progression.save`

## 📋 JSON Configuration

### Lab Map Structure
```json
{
  "map_info": {
	"name": "Lab",
	"description": "Central Science Lab",
	"dimensions": {"width": 7, "depth": 7, "max_height": 2}
  },
  "layers": {
	"structure": [
	  ["1", "1", "1", "1", "1", "1", "1"],
	  ["1", "1", "2", "2", "2", "1", "1"],
	  ...
	],
	"utilities": [
	  ["s", " ", " ", " ", " ", " ", " "],
	  [" ", " ", " ", " ", " ", " ", "t:Tutorial_Single"]
	],
	"interactables": [
	  [" ", " ", " ", "rotating_cube", " ", " ", " "],
	  [" ", " ", "xyz_coordinates", " ", "grid_display", " ", " "]
	]
  },
  "settings": {
	"lab_mode": true,
	"show_grid": false
  }
}
```

### Layer Types
- **Structure**: Floor heights (1=floor, 2=platform)
- **Utilities**: Spawn points (`s`) and teleporters (`t:destination`)
- **Interactables**: Artifacts referenced by `lookup_name` from registries

## 🚀 Quick Setup

### 1. Add Lab System Files
```bash
# Add these files to your project:
res://commons/scenes/LabGridSystem.gd
res://commons/scenes/LabGridScene.gd
res://commons/scenes/lab_grid.tscn
res://commons/maps/Lab/map_data.json
```

### 2. Create Lab Scene
1. Instance `base.tscn` as root
2. Add `LabGridSystem` node with script
3. Instance `cube_scene.tscn` as child of LabGridSystem
4. Add `LabGridScene` node with controller script
5. Configure properties:
   - `lab_mode = true`
   - `map_name = "Lab"`
   - `lab_cube_color = Color(0.95, 0.95, 0.98, 1)`

### 3. Update VR Staging
```gdscript
@export var main_lab_scene: String = "res://commons/scenes/lab_grid.tscn"
```

## 🎮 Usage

### Initialization
The lab automatically:
- Loads map data from `commons/maps/Lab/map_data.json`
- Applies off-white materials to all cubes
- Sets up lab lighting
- Filters artifacts based on progression state
- Connects to SceneManager for sequence transitions

### Artifact Interaction
- **Rotating Cube**: Auto-triggers array tutorial after 5 seconds
- **Teleporter**: Takes player to Tutorial_Single map
- **Progressive Artifacts**: Unlock as sequences complete

### Sequence Integration
```gdscript
# When returning from completed sequence:
lab_grid_system.complete_sequence("array_tutorial")
# → Unlocks xyz_coordinates and grid_display
# → Shows unlock animation
# → Saves progression
```

## 🔧 API Reference

### LabGridSystem Methods
```gdscript
# Progression Management
complete_sequence(sequence_name: String)          # Complete sequence, unlock artifacts
is_artifact_unlocked(artifact_id: String) -> bool # Check unlock status
get_unlocked_artifacts() -> Array[String]         # Get unlocked artifact list

# Testing/Debug
force_unlock_artifact(artifact_id: String)       # Force unlock for testing
reset_lab_progression()                           # Reset all progression
print_lab_status()                                # Debug status output

# Info
get_lab_info() -> Dictionary                      # Get lab info + progression
```

### LabGridScene Methods
```gdscript
# Testing
force_complete_sequence(sequence_name: String)   # Force complete for testing
reset_lab_progression()                          # Reset progression

# Debug Keys (in lab scene)
# Space: Force complete array_tutorial
# Escape: Reset all progression
```

## 🎯 Integration Points

### SceneManager Integration
- Artifact activations trigger sequence starts
- Teleporter activations request map transitions
- Sequence completions update lab progression
- Returns from sequences unlock new artifacts

### Existing Systems
- **Artifact Registry**: Uses existing `grid_artifacts.json` and `lab_artifacts.json`
- **Utility Registry**: Uses existing `UtilityRegistry.gd` for teleporters/spawns
- **Base Scene**: Inherits VR functionality from `base.tscn`
- **Grid Components**: Reuses all GridSystem infrastructure

## 🔍 Debugging

### Console Commands
```gdscript
# In Godot's remote debugger or script:
var lab = get_node("LabGridSystem")

# Check status
lab.print_lab_status()

# Force progression
lab.complete_sequence("array_tutorial")
lab.force_unlock_artifact("disco_floor")

# Reset for testing
lab.reset_lab_progression()
```

### Expected Output
```
LabGridSystem: Initializing lab variant of grid system...
LabGridSystem: Applying lab styling - off-white cubes
GridSystem: ✅ Grid generation completed successfully
LabGridSystem: Applying lab materials to 25 cubes
LabGridSystem: Lab lighting applied
LabGridSystem: Filtering artifacts by progression
  Hidden locked artifact: xyz_coordinates
  Hidden locked artifact: grid_display
```

## 🎨 Customization

### Creating Lab Variants
1. **Copy Lab Map**: Duplicate `commons/maps/Lab/` to `commons/maps/TeachingLab/`
2. **Modify JSON**: Change dimensions, artifact positions, colors
3. **Set Map Name**: Update `map_name = "TeachingLab"` in scene
4. **Custom Colors**: Adjust `lab_cube_color` and `lab_ambient_color`

### Custom Progression Rules
```gdscript
# In LabGridSystem.gd, modify:
func _get_artifacts_to_unlock(sequence_name: String) -> Array[String]:
	match sequence_name:
		"custom_sequence":
			return ["special_artifact"]
		"advanced_tutorial":
			return ["research_tool", "analysis_display"]
		_:
			return []
```

## ⚡ Performance

### Efficiency Benefits
- **Memory**: Same as GridSystem (no duplication)
- **Processing**: Only adds material application step (~1ms)
- **Maintenance**: Grid improvements automatically benefit lab
- **Code Size**: ~200 lines vs 2000+ for separate system

### Optimization Notes
- Materials applied once after generation
- Progression filtering done on unlock only
- Visual effects use efficient tweens
- Save/load only on progression changes

## 🚀 Future Enhancements

### Planned Features
- **Runtime Customization**: Change colors/lighting through UI
- **Lab Templates**: Predefined configurations for different purposes
- **Advanced Progression**: Complex unlock requirements and branching
- **Lab-Specific Artifacts**: Tools that only appear in laboratory environments

### Extension Points
- Override `_apply_lab_cube_materials()` for custom styling
- Extend `_get_artifacts_to_unlock()` for custom progression
- Add new lab signals for custom interactions
- Create lab-specific utility types

## 📄 License & Credits

Built on the GridSystem architecture, inheriting its robust component-based design while adding laboratory-specific functionality. Part of the Ada Research VR educational platform.
