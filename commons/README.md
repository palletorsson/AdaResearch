# 🏗️ Commons - Shared Systems & Components

The `commons/` directory contains all shared systems, utilities, and components used throughout the AdaResearch project. These modules are designed to be reusable across different scenes and contexts.

## 📁 Module Overview

### 🎵 **Audio System** - *Recently Restructured (Dec 2024)*
**Status**: ✅ Production Ready  
**Location**: `commons/audio/`

Comprehensive audio synthesis system with real-time parameter editing, multiple JSON format support, and educational content.

**Key Features**:
- 70+ organized sound parameters across 6 categories
- Real-time audio interfaces with waveform visualization
- Educational content with music theory integration
- Multi-format JSON parameter loading
- Professional-grade sound design tools

**Quick Start**: Open `commons/audio/interfaces/SoundDesignerInterface.gd` as main scene

### 🎯 **Grid System**
**Status**: ✅ Stable  
**Location**: `commons/grid/`

Component-based grid interaction system for VR and desktop.

**Components**:
- `GridSystem.gd` - Core grid functionality
- `GridDataComponent.gd` - Data management
- `GridInteractablesComponent.gd` - Interaction handling
- `GridSpawnComponent.gd` - Object spawning
- `GridUtilitiesComponent.gd` - Utility functions

### 🎲 **Primitives**
**Status**: ✅ Stable  
**Location**: `commons/primitives/`

Basic 3D objects and interaction components.

**Cube System**:
- Basic cubes with physics and interaction
- Animation components (rotation, scaling, transformation)
- Audio integration capabilities
- VR-compatible interaction controllers

### 🌍 **Context Systems**
**Status**: ✅ Stable  
**Location**: `commons/context/`

Environmental contexts and specialized interaction spaces.

**Available Contexts**:
- **Disco Floor** (`discofloor/`) - Musical interaction environment
- **Walk Grids** (`walkgrids/`) - Navigation and topology systems
- **Cube Create** (`cubecreate/`) - Creative building environment
- **XYZ Coordinates** (`XYZcoordinates/`) - 3D coordinate visualization

### 🎬 **Scene System**
**Status**: ✅ Stable  
**Location**: `commons/scenes/`

Reusable scene components and map objects.

**Core Scenes**:
- `base.tscn` - Base scene template
- `grid.tscn` - Grid-based interaction scene
- `lab.tscn` - Laboratory environment
- `vr_staging.tscn` - VR setup and staging

**Map Objects** (`mapobjects/`):
- Interactive cubes (pickup, teleport, reset, score)
- Information boards and annotations
- Platform lifts and doors
- Utility objects and spawn points

### 🗺️ **Maps & Progression**
**Status**: ✅ Stable  
**Location**: `commons/maps/`

Map data and progression system for structured learning experiences.

**Features**:
- JSON-based map configuration
- Progressive difficulty system
- Multiple map types (Tutorial, Geometric, Random)
- Lab progression tracking

### 🎯 **Managers**
**Status**: ✅ Stable  
**Location**: `commons/managers/`

Central management systems for game state and progression.

**Key Managers**:
- `AdaSceneManager.gd` - Scene transitions and state
- `GameManager.gd` - Overall game state management
- `LabManager.gd` - Laboratory environment control
- `VRGridSystemManager.gd` - VR-specific grid management

## 🚀 Getting Started with Commons

### For Audio Development
```gdscript
# Load audio parameters
var params = EnhancedParameterLoader.get_sound_parameters("basic_sine_wave")

# Create sound interface
var interface = preload("res://commons/audio/interfaces/SoundDesignerInterface.gd").new()
```

### For Grid Interactions
```gdscript
# Create grid system
var grid = preload("res://commons/grid/grid_system.tscn").instantiate()
add_child(grid)
```

### For Cube Interactions
```gdscript
# Add cube with audio
var cube = preload("res://commons/primitives/cubes/utility_cube.tscn").instantiate()
cube.setup_audio(AudioSynthesizer.SoundType.PICKUP_MARIO)
```

## 📚 Module Documentation

Each module contains its own detailed documentation:

- **Audio**: `commons/audio/documentation/README.md`
- **Grid**: `commons/grid/README.md`
- **Maps**: `commons/maps/README.md`
- **Cubes**: `commons/primitives/cubes/README.md`
- **Context Systems**: Individual README files in each context folder

## 🔧 Development Guidelines

### Architecture Principles
- **Modular Design**: Each system operates independently
- **Component-Based**: Use composition over inheritance
- **VR-First**: All systems work in both VR and desktop modes
- **Educational Focus**: Systems should teach while entertaining

### Code Standards
- **Defensive Programming**: Handle errors gracefully
- **Comprehensive Logging**: Use emoji prefixes for easy identification
- **Documentation**: Every public API needs usage examples
- **Testing**: Include validation scripts for major functionality

### Adding New Modules
1. Create subdirectory in `commons/`
2. Include `README.md` with module documentation
3. Follow existing naming conventions
4. Add to this overview document
5. Include test scenes where applicable

## 🎯 Current Development Status

### ✅ Production Ready
- **Audio System**: Complete restructuring and error resolution
- **Grid System**: Stable and well-tested
- **Scene System**: Mature and extensively used
- **Map System**: Robust progression handling

### 🔄 Active Development
- **Context Systems**: Ongoing expansion of interaction environments
- **VR Integration**: Continuous improvement of VR compatibility
- **Educational Content**: Expanding learning materials

### 🚀 Future Opportunities
- **AI Integration**: Machine learning assistance
- **Collaborative Features**: Multi-user experiences
- **Advanced Physics**: More sophisticated interaction models
- **Procedural Generation**: Dynamic content creation

## 🧪 Testing

Each module includes its own testing approach:

```bash
# Audio system validation
# Open in Godot: commons/audio/quick_test_fix.gd

# Grid system testing
# Open in Godot: commons/grid/grid_system.tscn

# Scene testing
# Open in Godot: commons/scenes/base.tscn
```

## 💡 Key Integration Points

### Audio + Grid
Grid interactions can trigger contextual audio feedback.

### Cubes + Audio
All cube primitives support integrated audio components.

### VR + All Systems
Every commons module is designed to work seamlessly in VR.

### Education + Everything
All systems include educational content and progressive learning features.

---

*The commons directory represents the foundational building blocks of the AdaResearch project. Each module is designed for reusability, maintainability, and educational value.* 