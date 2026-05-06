# Grid Editor - Technical Documentation

## System Overview
The Grid Editor is a dual-scale VR tool that allows users to edit a 3D grid layout using a miniature interface (1m³) while seeing the result mirrored in a full-scale version.

## 1. Grid Configuration

| Property | Miniature Grid | Full-Scale Grid |
|----------|---------------|-----------------|
| **Total Size** | 1m × 1m × 1m | 1m × 1m × 1m (Scalable) |
| **Grid Resolution** | **8 × 8 × 8** | **8 × 8 × 8** |
| **Cell Size** | 0.125m (0.125m³) | 1.0m (1m³) |
| **Initial Layout** | 3×3 cubes on floor | 3×3 cubes on floor |
| **Coordinate Space** | Local (Relative) | Local (Relative) |

### Positioning
The system uses **Local Coordinates** relative to the `GridEditorMain` scene root. This ensures the editor can be placed anywhere in the map (e.g., inside `Point_Line` map at specific coordinates) and retain its internal layout.

- **Miniature Origin**: `(0, 1.0, 0)` (Local) - Floating at eye level.
- **Full-Scale Offset**: `(0, 0, 3)` (Local) - 3 meters forward in Z from the miniature grid.

## 2. Component Architecture

### GridEditorManager.gd
The central controller that:
- Instantiates the grid containers.
- Manages the lifecycle of paired cubes.
- Handles relative offsets.
- **Key Fix**: Uses `grid_to_local` logic to ensure cubes stay inside their parent containers.

### GridEditorCube.gd
The interactive cube object.
- Extends: `XRToolsPickable`
- **Snap Logic**:
  - Uses `position` (local) instead of `global_position` to respect parent transforms.
  - Snaps to the nearest 0.125m grid point when released.
  - Forces snap animation even if dropped in the same cell (to center it).
- **Synchronization**:
  - Updates its paired cube only when grid coordinates change.
  - Dynamic scaling: Mesh and collision scale based on `cell_size`.
- **Interaction**:
  - Collision Layer: 3 (Pickable Objects)
  - Visuals: Hover (Cyan), Grab (Gold), Ghost Preview.

## 3. How to Use in Maps

To add the editor to a new map:
1. Add `grid_editor_main.tscn` to the `interactables` layer in your map JSON.
2. Specify coordinates (e.g., "1, 2").
3. The **Miniature** editor will appear at that location + (0, 1, 0) height.
4. The **Full-Scale** cubes will appear at that location + (0, 0, 3) offset.

## 4. Troubleshooting

**Cube Positioning**:
If cubes appear offset or overlapping, ensure `GridEditorCube.gd` uses `position` (local) and NOT `global_position`.

**Grabbing**:
Ensure `GridEditorCube.tscn` uses `collision_layer = 4` (Layer 3: Pickable Objects) and `collision_mask = 3` (Static + Dynamic World).
