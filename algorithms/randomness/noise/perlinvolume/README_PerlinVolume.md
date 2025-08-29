# VR Perlin Volume Scene (Three.js Port)

## ☁️ Installation Complete!

This folder contains a Godot 4 scene that replicates the **WebGPU Volume Perlin** example from Three.js. It renders animated 3D noise within a cube to create a volumetric cloud/smoke effect.

### Files Created:
- `PerlinVolumeVR.gd`: A simple script to rotate the volume cube.
- `PerlinVolume.gdshader`: The complex shader that performs all the volumetric rendering.
- `PerlinVolumeVR.tscn`: The Godot scene file containing the mesh and material setup.
- `README_PerlinVolume.md`: This instruction file.

### How it Works:
The entire effect is achieved using a technique called **Ray Marching** inside the `PerlinVolume.gdshader`. For each pixel on the screen that covers the cube, a virtual ray is cast. The shader then "marches" along this ray step-by-step through the volume, sampling a 3D Simplex noise value at each point. These samples are accumulated to build the final color and transparency of that pixel, creating the illusion of a dense, animated cloud.

### How to Use:

1.  **Copy Files**: Copy all three generated files (`.gd`, `.gdshader`, `.tscn`) into your Godot project.
2.  **Add to Your VR World**: Open your main VR scene and drag `PerlinVolumeVR.tscn` from the FileSystem dock into your scene tree.
3.  **Position and Run**: Place the node where you want the effect to appear. The effect is best viewed when you are outside or slightly intersecting the volume.

### Customization:

You can customize the effect by selecting the `VolumeBox` node inside the `PerlinVolumeVR.tscn` and editing its **Shader Parameters** in the Inspector:

-   `Time Scale`: Controls the speed of the noise animation.
-   `Noise Scale`: Changes the "zoom" of the noise pattern. Higher values mean smaller details.
-   `Density`: Controls how thick or transparent the cloud appears.
-   `March Steps`: The number of samples taken along each ray. Higher values improve quality but decrease performance.
-   `Color1/2/3`: Defines the color gradient that the noise is mapped to.
