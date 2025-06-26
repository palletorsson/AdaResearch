# AdaResearch
A meta quest into the world of algorithms

AdaResearch is a VR/desktop research platform built in Godot 4 for exploring algorithms, audio synthesis, and interactive learning environments. The project combines educational content with hands-on experimentation tools.

## 🏗️ Project Structure

### Core Modules

- **`algorithms/`** - Algorithm implementations and visualizations
  - `randomness/` - Random number generation and statistical algorithms
  - `spacetopology/` - Spatial relationship algorithms
  - `wavefunctions/spectralanalysis/` - Audio analysis and spectral processing

- **`commons/`** - Shared systems and utilities
  - `audio/` - **[Recently Restructured]** Comprehensive audio synthesis system
  - `grid/` - Grid-based interaction systems
  - `primitives/` - Basic 3D objects and animations
  - `scenes/` - Reusable scene components
  - `context/` - Environmental contexts (disco floor, walk grids, etc.)

- **`doc/`** - Documentation and guides
- **`tests/`** - Test scenes and validation scripts

## 🎵 Audio System (Recently Updated - Dec 2024)

The audio system has been completely restructured for better organization and maintainability:

### Current Status: ✅ FULLY FUNCTIONAL
- **70+ audio parameter files** organized into 6 logical categories
- **Multiple JSON formats** supported automatically
- **Real-time parameter editing** with visual feedback
- **Professional-grade interfaces** for sound design
- **Educational content** with music theory integration

### Audio Module Structure
```
commons/audio/
├── runtime/           # Game runtime components
├── interfaces/        # Development sound design tools
├── generators/        # Audio synthesis engines
├── compositions/      # Track players and systems
├── parameters/        # Organized JSON configs
│   ├── basic/        # Simple sounds (sine waves, pickups)
│   ├── drums/        # Drum machines and percussion
│   ├── synthesizers/ # Classic synth emulations
│   ├── retro/        # Retro/chiptune sounds
│   ├── experimental/ # Advanced synthesis techniques
│   └── ambient/      # Atmospheric and drone sounds
├── documentation/     # Guides and tutorials
└── testing/          # Validation and test scenes
```

### Recent Achievements
- ✅ Automated migration from mixed folder structure
- ✅ Fixed "Invalid access to property 'value'" errors across all sounds
- ✅ Enhanced parameter loading supporting 3 different JSON formats
- ✅ Smart emoji-based sound categorization
- ✅ Real-time audio visualization (waveform + spectrum)
- ✅ Comprehensive educational content with interactive exercises

## 🎮 Getting Started

### Prerequisites
- Godot 4.x
- VR headset (optional, for VR features)

### Quick Start
1. Open the project in Godot
2. Try the audio interfaces: `commons/audio/interfaces/`
3. Explore algorithm visualizations: `algorithms/`
4. Test grid interactions: `commons/scenes/grid.tscn`

## 🧪 Testing
- Audio system: Run `commons/audio/quick_test_fix.gd`
- Grid systems: `tests/` folder contains validation scenes
- VR compatibility: `tests/vr_test_simple.tscn`

## 📚 Documentation

### Key Documentation Files
- `commons/audio/documentation/README.md` - Audio system overview
- `commons/audio/documentation/FOLDER_RESTRUCTURE_PLAN.md` - Migration details
- `doc/LAB_GRID_GUID.md` - Grid interaction systems
- `doc/PROGRESSION_SYSTEM.md` - Learning progression mechanics

## 🔄 Development Status

### Recently Completed
- **Audio System Restructuring** (Dec 2024)
  - Complete folder reorganization
  - Multi-format JSON parameter loading
  - Enhanced error handling and validation
  - Real-time interface improvements

### Next Development Areas
- Algorithm visualization enhancements
- VR interaction improvements
- Grid system optimizations
- Educational content expansion

## 🤝 Contributing

The project is designed for iterative development with clear module separation. Each system (audio, grid, algorithms) can be developed independently.

### Development Notes
- Audio system is production-ready and fully documented
- Grid systems use component-based architecture
- VR features are optional and gracefully degrade
- All major systems include comprehensive testing

---

*For detailed information about specific modules, see the README files in each subdirectory.*
