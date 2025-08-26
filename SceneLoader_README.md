# Algorithm Scene Loader with First-Person Player

This project provides a comprehensive scene loading system that allows you to explore various algorithm visualizations in a 3D environment with a first-person player controller.

## Features

### 🎮 First-Person Player Controller
- **Movement**: WASD keys for directional movement
- **Camera**: Mouse look with captured cursor
- **Jump**: Spacebar to jump
- **Mouse Control**: ESC to toggle mouse capture/release

### 🔄 Scene Loading System
- **Next Scene**: Press `N` to load the next algorithm scene
- **Previous Scene**: Press `P` to load the previous algorithm scene  
- **Reload Scene**: Press `R` to reload the current scene
- **Unload Scene**: Press `U` to unload the current scene and return to the main environment

### 🧠 Algorithm Scenes Included

The loader automatically discovers and includes scenes from various algorithm categories:

#### Physics Simulation
- Newton's Laws demonstration
- Verlet Integration cloth simulation

#### Space Topology & Computational Geometry  
- Marching Cubes isosurface extraction
- Organic Space generation

#### Quantum Algorithms
- Quantum Superposition visualization

#### Randomness & Noise
- Perlin Noise clouds and terrain
- Blue noise distribution
- True vs Pseudo Random Number Generation
- Distribution visualization

#### Procedural Generation
- Wave Function Collapse
- Reaction-Diffusion patterns
- Metaballs simulation
- Slime mold growth
- Voronoi diagrams
- Tree generation
- Mushroom growth

#### Alternative Geometries
- Rhizomatic maze space
- Organic space structures

#### Computational Biology
- Bucket of Tulips visualization

#### Machine Learning
- Random Walker Machine

## 🎯 Quick Start

1. **Launch the Project**: Open `MainSceneLoader.tscn` in Godot 4
2. **Navigate**: Use WASD to move around the 3D environment
3. **Load Scenes**: Press `N` to cycle through algorithm visualizations
4. **Explore**: Each algorithm scene loads in front of you for easy exploration
5. **Control**: Use ESC to release mouse cursor when needed

## 🔧 Technical Implementation

### Scene Structure
```
MainSceneLoader.tscn
├── Environment (floor, lighting)
├── Player (first-person controller)
├── UI (scene information display)
└── AlgorithmContainer (dynamically loaded scenes)
```

### Scripts
- **`MainSceneLoader.gd`**: Core scene management and loading logic
- **`FirstPersonPlayer.gd`**: First-person movement and camera controls

### Dynamic Loading
- Scenes are loaded/unloaded dynamically to maintain performance
- Automatic discovery of available algorithm scenes
- Error handling for missing or invalid scenes
- Real-time scene information display

## 🎨 Customization

### Adding New Algorithm Scenes
1. Add your scene path to the `scene_paths` array in `MainSceneLoader.gd`
2. Or place it in the `additional_paths` array in `discover_additional_scenes()`
3. The system will automatically validate and include working scenes

### Modifying Player Controls
- Edit `FirstPersonPlayer.gd` to adjust movement speed, sensitivity, or physics
- Modify input mappings in `project.godot` for custom key bindings

### UI Customization
- Update the `SceneInfo` label in the main scene for different information display
- Modify `update_scene_info()` in `MainSceneLoader.gd` for custom status messages

## 🔍 Scene Information
The UI displays:
- Current loaded scene name and index
- Available navigation controls
- Movement instructions
- Total number of available scenes

## 🛠️ Development Notes

- Built for Godot 4.4+
- Uses CharacterBody3D for robust physics-based movement
- Implements proper resource management with scene loading/unloading
- Mouse capture/release system for seamless interaction
- Modular design for easy extension and customization

## 🎯 Usage Tips

- Start by pressing `N` to load your first algorithm scene
- Use the mouse to look around and appreciate 3D visualizations from different angles
- Walk up to interesting algorithm features for closer examination
- Use `U` to unload heavy scenes if performance is affected
- Press `R` if a scene appears to have loading issues

Enjoy exploring the fascinating world of algorithm visualizations in an immersive 3D environment!

