# Grid System - Component-Based Architecture

## Overview

The Grid System is a modular, component-based architecture for dynamically building VR environments from JSON data. Rather than using monolithic code, the system uses focused components that each handle a specific responsibility.

## Core Philosophy

> **Data-Driven & Modular**: All configuration comes from external JSON files, and each component has a single, clear responsibility.

## Architecture

### 🎯 **GridSystem.gd** (Main Orchestrator ~150 lines)
The central coordinator that manages component lifecycle and signal routing.

**Responsibilities:**
- Component initialization and management
- Signal routing between components  
- Scene data processing from AdaSceneManager
- Public API for external access

**Key Features:**
- Component-based architecture instead of monolithic code
- Automatic map loading from scene metadata
- Clear error handling and debugging support

### 📊 **GridDataComponent.gd** (~100 lines)
Handles loading and parsing map data from JSON files.

**Responsibilities:**
- Load JSON map data from `res://commons/maps/{map_name}/map_data.json`
- Parse and validate map structure
- Provide data access to other components
- Extract settings, spawn points, and utility definitions

**External Dependencies:**
- Uses `JsonMapLoader.gd` for JSON parsing
- Validates data structure and reports errors clearly

### 🧱 **GridStructureComponent.gd** (~120 lines)
Manages the physical 3D grid structure and cube placement.

**Responsibilities:**
- Initialize 3D grid arrays
- Place cubes based on structure data from JSON
- Track cube positions and occupancy
- Provide height calculation utilities

**Key Features:**
- Grid bounds checking and validation
- Efficient cube instance management
- Height-based placement algorithms

### 🔧 **GridUtilitiesComponent.gd** (~200 lines)
Handles utility object placement and configuration.

**Responsibilities:**
- Place utility objects (teleports, doors, lifts, spawn points)
- Load utility scenes from `res://commons/scenes/mapobjects/`
- Apply utility parameters and properties from JSON
- Connect utility signals to SceneManager

**External Dependencies:**
- Uses `UtilityRegistry.gd` for utility type definitions
- Loads utility definitions from map JSON files
- Connects teleporters directly to AdaSceneManager for scene transitions

**Supported Utilities:**
- `t` - Teleporters (with destination parameters)
- `s` - Spawn points (with height and rotation)
- `l` - Platform lifts (with height and speed)
- `d` - Doors, `w` - Windows, `a` - Walls, `b` - Tables
- `sub` - Subtitle triggers (Portal 2-style text popups)

### 📝 **Subtitle Trigger System**

The subtitle system shows Portal 2-style text when the player walks over trigger points. Triggers display as transparent "i" spheres that the player must physically walk through.

**Grid Syntax:**
```
sub:map                    - Shows blurb.md or JSON description for the map
sub:intro                  - Looks up "intro" in map_data.json "subtitles" section
sub:Welcome_text           - Direct text (underscores become spaces)
sub:tt:point_axioms        - Looks up key in tutorial_text.json
sub:key:speaker            - Text with custom speaker name
sub:key:speaker:1          - Text + speaker + level (1=essential, 2=info, 3=verbose)
```

**Map-Specific Subtitles in map_data.json:**
```json
{
  "subtitles": {
	"intro": "Welcome to this map!",
	"hint1": {"text": "Try jumping here", "speaker": "Guide"},
	"point_zero": "Point Zero? Point One."
  }
}
```

**Example utilities layer:**
```json
"utilities": [
  [" ", "sub:map", " "],
  [" ", "sub:intro", " "],
  [" ", "sub:hint1", " "]
]
```

**Trigger Behavior:**
- Small collision area (0.5m) - player must walk directly over the "i" sphere
- One-shot by default (triggers once per map load)
- Plays soft "pling" notification sound
- 1.5 second startup delay to prevent triggering during spawn
- Distance check: player must be within 0.75m horizontally

**Text Levels:**
- Level 1 (Essential): Always shown
- Level 2 (Info): Default level, shown for most players
- Level 3 (Verbose): Extra details for players who want more context

### 🎮 **GridInteractablesComponent.gd** (~180 lines)
Manages interactive artifacts and objects.

**Responsibilities:**
- Load artifact definitions from `res://commons/artifacts/grid_artifacts.json`
- Place interactive artifacts at grid positions
- Handle artifact activation and interaction signals
- Apply artifact transforms (position, rotation, scale)

**External Dependencies:**
- Artifact registry loaded from JSON (replaces complex AlgorithmRegistry)
- Scene loading for artifact .tscn files
- Simple, JSON-driven artifact system

**Example Artifacts:**
- `XYZ_coordinates` - Coordinate system gadget
- `trigger:grid_reveal` - Grid reveal triggers

### 🎯 **GridSpawnComponent.gd** (~120 lines)
Handles VR player spawn positioning.

**Responsibilities:**
- Find spawn points in utility grid (type "s")
- Position VR player at spawn locations
- Handle spawn transition effects
- Fallback to JSON-defined spawn points

**Features:**
- Grid-based spawn point detection
- JSON spawn point fallback
- VR origin positioning with height and rotation
- Smooth spawn transition effects

## Data Sources

### **Map Data Structure**
```
res://commons/maps/{map_name}/map_data.json
```

**JSON Format:**
```json
{
  "map_info": {
	"name": "Tutorial_Start",
	"description": "Tutorial level"
  },
  "layers": {
	"structure": [["1", "1"], ["1", "2"]],
	"utilities": [["s", " "], [" ", "t"]],
	"interactables": [["XYZ_coordinates", " "], [" ", " "]]
  },
  "utility_definitions": {
	"s": {"properties": {"height": 1.8, "player_rotation": 0}},
	"t": {"properties": {"destination": "next_map"}}
  },
  "spawn_points": {
	"default": {"position": [0, 1.5, 0], "rotation": [0, 0, 0]}
  }
}
```

### **Artifact Definitions**
```
res://commons/artifacts/grid_artifacts.json
```

**JSON Format:**
```json
{
  "artifacts": {
	"XYZ_coordinates": {
	  "name": "XYZ Coordinates",
	  "scene": "res://commons/context/XYZcoordinates/xyz_gadget.tscn",
	  "category": "educational",
	  "scale": [0.5, 0.5, 0.5]
	}
  }
}
```

## Component Initialization Flow

1. **GridSystem** checks for scene data from AdaSceneManager
2. **GridDataComponent** loads JSON map data
3. **GridStructureComponent** builds the 3D grid and places cubes
4. **GridUtilitiesComponent** places utility objects and connects signals
5. **GridInteractablesComponent** places artifacts from JSON registry
6. **GridSpawnComponent** positions the VR player at spawn points

## Signal Flow

### **Teleporter Activation:**
1. Teleporter scene emits `teleporter_activated`
2. GridUtilitiesComponent receives signal
3. Component finds AdaSceneManager in scene tree
4. Calls `request_transition()` with sequence advancement
5. AdaSceneManager processes transition and loads next map

### **Component Communication:**
- Components communicate through the main GridSystem orchestrator
- Each component emits completion signals for coordination
- Clear error reporting and debugging throughout the chain

## Key Benefits

### **🎯 Single Responsibility**
Each component handles one specific aspect of grid generation:
- Data → GridDataComponent
- Structure → GridStructureComponent  
- Utilities → GridUtilitiesComponent
- Artifacts → GridInteractablesComponent
- Spawning → GridSpawnComponent

### **📁 Data-Driven Configuration**
All configuration comes from external JSON files:
- No hardcoded map structures
- No hardcoded utility types
- No hardcoded artifact definitions
- Easy to modify without code changes

### **🔧 Easier Debugging**
Issues are isolated to specific components:
- Data loading problems → Check GridDataComponent
- Missing cubes → Check GridStructureComponent
- Teleporter issues → Check GridUtilitiesComponent
- Artifact problems → Check GridInteractablesComponent
- Spawn positioning → Check GridSpawnComponent

### **🧪 Better Testing**
Components can be tested independently:
- Mock data for structure testing
- Isolated utility placement testing
- Artifact loading validation
- Spawn positioning verification

### **📈 Improved Maintainability**
Smaller, focused files are easier to understand and modify:
- ~150 lines per component vs 776-line monolith
- Clear interfaces between components
- Easy to add new functionality to specific areas

## Integration with External Systems

### **AdaSceneManager Integration**
- Automatic scene data processing for map transitions
- Teleporter signals connected directly to scene manager
- Sequence progression through JSON-defined sequences

### **Utility Registry Integration**
- Centralized utility type definitions
- Parameter parsing and validation
- Scene path resolution for utility objects

### **VR System Integration**
- Automatic VR origin detection and positioning
- Spawn point positioning with height and rotation
- Smooth transition effects for player orientation

## Error Handling

The system provides clear error reporting at each level:
- **Data Loading**: Missing JSON files, invalid structure
- **Scene Loading**: Missing .tscn files, broken scene references  
- **Component Issues**: Initialization failures, connection problems
- **Integration Problems**: Missing SceneManager, VR origin issues

**Debug Methods:**
```gdscript
# Check component status
grid_system.print_component_status()

# Get error information
var error_info = grid_system.get_error_info()

# Check for load errors
if grid_system.has_load_error():
	print("Grid system failed to load properly")
```

## Migration from Legacy System

This component-based architecture replaces the previous 776-line monolithic GridSystem with:
- **6 focused components** instead of one large file
- **External JSON configuration** instead of hardcoded structures
- **Clear error handling** instead of silent failures
- **Component isolation** instead of mixed responsibilities

The system maintains full compatibility with existing map data while providing a much cleaner and more maintainable foundation for future development.
