# VR Cubes Scene (Three.js Example Port)

## 🧊 Installation Complete!

This folder contains a complete Godot 4 scene that replicates the **VR Cubes** example from Three.js. This scene is designed purely as a visual spectacle and contains no player or UI elements.

### Files Created:
- `VRCubes.gd`: The GDScript that procedurally generates and animates all the cubes.
- `VRCubes.tscn`: The Godot scene file. You can drag this into any other scene.
- `README_VRCubes.md`: This instruction file.

### Scene Features:
- **High Performance**: Uses a `MultiMeshInstance3D` to render hundreds of cubes in a single draw call, ensuring smooth performance in VR.
- **Procedural Generation**: All cubes are positioned and colored randomly at runtime.
- **Dynamic Animation**: Each cube rotates independently on a random axis.
- **Customizable**: Easily change the number of cubes and their spread directly in the Godot editor.

### How to Use:

1.  **Copy Files**: Copy `VRCubes.gd` and `VRCubes.tscn` into your Godot project's file system.
2.  **Add to Your VR World**: Open your main VR scene (the one with your `XROrigin3D` player rig) and drag `VRCubes.tscn` from the FileSystem dock into your scene tree.
3.  **Position and Run**: Place the `VRCubes` node wherever you want the effect to appear in your world. Run the scene and you will be surrounded by rotating cubes.

### Customization in the Inspector:

Select the `VRCubes` node in your scene to adjust these properties:

-   `Cube Count`: The total number of cubes to generate (default: 500).
-   `Spread Radius`: The radius of the sphere in which the cubes are scattered (default: 10).
-   `Animation Speed`: A multiplier for the rotation speed of all cubes (default: 0.5).

This scene is a perfect starting point for creating beautiful, abstract VR environments or for stress-testing your project's rendering performance.
