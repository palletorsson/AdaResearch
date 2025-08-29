# VR Volumetric Cloud Scene (Three.js Example Port)

## ☁️ Installation Complete!

This folder contains a complete Godot 4 scene that replicates the **WebGPU Volume Cloud** example from Three.js.

### Files Created:
- `CloudVolumeVR.gd`: A simple script to rotate the cloud and update the shader.
- `CloudVolume.gdshader`: The complex ray marching shader that renders the cloud.
- `CloudVolumeVR.tscn`: The Godot scene file. Drag this into your main world.
- `README_CloudVolume.md`: This instruction file.

### What This Scene Creates:
- **A Volumetric Cloud**: A realistic, animated 3D cloud contained within a cube.
- **Ray Marching Shader**: The entire effect is generated on the GPU by marching rays through a 3D noise field.
- **Dynamic Lighting**: The cloud is realistically lit by a `DirectionalLight3D` in the scene, creating soft shadows and highlights.
- **Simple Controls**: The included script handles basic rotation and passes necessary camera/light info to the shader.

### How to Use:

1.  **Copy Files**: Copy all three generated files (`.gd`, `.gdshader`, `.tscn`) into your Godot project.
2.  **Instance in Your World**: Drag `CloudVolumeVR.tscn` from the FileSystem dock into your main VR scene.
3.  **Position and Scale**: Position the `CloudVolumeVR` node where you want the cloud to appear. You can scale the `VolumeBox` node inside it to change the cloud's size.
4.  **Run**: Put on your VR headset. You should see a large, softly lit cloud rotating in front of you.

### Customizing the Cloud:

Select the `VolumeBox` node, go to its **Material Override** in the Inspector, and expand the **Shader Parameters**. You can tweak these values to dramatically change the cloud's appearance:

-   `Cloud Cover`: Controls the overall density. Lower values create wispy clouds; higher values create dense storm clouds.
-   `Noise Scale`: Changes the size of the noise pattern. Smaller values make larger, softer puffs.
-   `Absorption`: How much light is absorbed as it passes through the cloud. Higher values make the cloud darker and more imposing.
-   `Base Color` / `Shadow Color`: Tweak these to create fantasy clouds (e.g., a nebula or poison gas).

### Technical Features:
- **Volumetric Rendering**: Uses a ray marching algorithm to simulate a true 3D volume.
- **Fractional Brownian Motion (FBM)**: Combines multiple layers of Simplex noise to create detailed and natural cloud shapes.
- **Simulated Light Scattering**: A simplified lighting model calculates how much light penetrates the cloud at each point, creating realistic depth and shading.
