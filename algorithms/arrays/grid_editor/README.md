# Grid Editor

An in-game 3D grid editor for VR that allows you to manipulate cubes in a miniature grid with real-time synchronization to a full-scale version.

## Integration with AdaResearch

This scene is designed to be loaded via the **MainSceneLoader** system:
- It's registered in `algorithms.json` under the "Array & Grid" category
- Gets loaded into the `AlgorithmContainer` node
- Uses the existing XR setup from the main scene (no duplicate XR origin)
- Press **'N'** in the main scene to cycle to this algorithm

## Features

- **Dual-Scale Grid System**: 
  - **Miniature Grid**: 8×8×8 resolution within a 1m³ volume (eye level).
  - **Full-Scale Grid**: Mirrored 1m³ blocks positioned 3 meters away.
  - **Real-time Sync**: Moving a miniature cube updates its full-scale twin instantly.

- **Precise VR Interactions**:
  - **Snap-to-Grid**: Cubes automatically snap to 0.125m grid points.
  - **Ghost Preview**: See exactly where the cube will land before you drop it.
  - **Haptic Feedback**: Vibration on grab and snap events.
  - **Relative Positioning**: System works anywhere in your map hierarchy (local coordinates).

- **Architecture**:
  - **Resolution**: 8×8×8 (512 total possible positions)
  - **Cell Size**: 0.125m (Miniature), 1.0m (Full-Scale)
  - **Initial State**: 3×3 cubes on the floor plane (XZ)

## Files

- `GridEditorCube.gd` - Cube script with snap-to-grid logic and synchronization
- `GridEditorCube.tscn` - Cube scene with VR pickable setup
- `GridEditorManager.gd` - Manager for dual-grid system and cube pairing
- `grid_editor_main.gd` - Main scene script
- `grid_editor_main.tscn` - Complete VR scene with environment

## Usage

### Via MainSceneLoader (Recommended)
1. Run `MainSceneLoader.tscn` (the main project scene)
2. Press **'N'** to cycle through algorithm scenes until you reach "Grid Editor Main"
3. The scene will load at position (0, 0, -5) relative to the player
4. Use your VR controllers to interact with the miniature grid cubes

### Standalone Testing
1. Open `grid_editor_main.tscn` directly in Godot
2. Run the scene
3. Note: You'll need to add XR setup manually for VR testing

## Controls

- **VR Controllers**: Grab and move cubes in the miniature grid
- **G Key** (desktop): Toggle grid line visualization

## Technical Details

### Grid Coordinate System
- **Resolution**: 8×8×8 grid
- **Miniature Unit**: 0.125m per step
- **Full-Scale Unit**: 1.0m per step
- **Coordinates**: Local relative to parent container

### Cube Pairing & Sync
Each cube in the miniature grid has a paired cube in the full-scale grid. When moved:
1. Cube snaps to local grid position (e.g., `Vector3i(2, 0, 5)`)
2. Local `position` is updated relative to `MiniatureGrid` container
3. Paired cube receives new grid coordinates
4. Paired cube updates its local `position` relative to `FullScaleGrid` container

### Future Extensibility

To add new object types:
```gdscript
# In GridEditorManager
grid_manager.add_object("sphere", Vector3i(2, 3, 1))
```

Add new object types by:
1. Creating a new scene extending `GridEditorCube` (or similar base class)
2. Registering the type in `GridEditorManager.add_object()`
3. Implementing type-specific behavior while maintaining grid snapping

## Initial Layout

The scene starts with a 3×3×3 cube arrangement in the bottom corner of the grid (positions 0-2 on each axis).
