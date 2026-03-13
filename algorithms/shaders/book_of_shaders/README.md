# Book of Shaders -- Interactive Shader Gallery

A 12-chapter interactive gallery that teaches **GPU shader programming** concepts from the ground up, based on the Book of Shaders curriculum. Each chapter builds a row of shader display panels with VR-interactive sliders that drive shader uniforms in real time, letting the learner manipulate mathematical functions and see the visual result immediately.

## How It Works

Every chapter follows the same architectural pattern:
1. A `shader_defs` array lists each display panel's shader path, title, code snippet, slider definitions, and uniform name mappings.
2. In `_ready()`, the script instantiates a row of `BoxMesh` display surfaces with `ShaderMaterial` overrides, `Label3D` titles, and `ShaderRackPanel` control panels with horizontal sliders.
3. In `_process()`, each panel's slider values are read and piped into the corresponding shader's uniform parameters every frame.

### Chapter Progression

| # | Script | Topic | Displays |
|---|--------|-------|----------|
| 01 | shader_01_shaping.gd | Shaping Functions | step(), smoothstep(), sin(), pow(), Combined |
| 02 | shader_02_colors.gd | Colors | Gradient, HSB Space, mix(), Rainbow |
| 03 | shader_03_shapes.gd | Shapes (SDF) | Circle, Rectangle, Boolean Ops, Polygon |
| 04 | shader_04_matrices.gd | Matrices | Translate, Rotate, Scale, Combined |
| 05 | shader_05_patterns.gd | Patterns | Tiling, Truchet, Offset Rows, Brick |
| 06 | shader_06_random.gd | GPU Random | fract(sin(dot())), Random Grid, TV Static |
| 07 | shader_07_noise.gd | Noise | Value, Gradient, Simplex, Domain Warp |
| 08 | shader_08_cellularnoise.gd | Cellular Noise | Voronoi, Worley (F1), Crackle (F2-F1) |
| 09 | shader_09_fbm.gd | FBM | Basic FBM, Ridged, Turbulence, Domain Warp |
| 10 | shader_10_reactiondiffusion.gd | Reaction-Diffusion | Reaction-Diffusion (existing shader), DLA Growth |
| 11 | shader_11_queerrubber.gd | Queer Materials | Leather, Oil Slick Latex, Pop Plastic, Fur Velvet, Sad Metal |
| 12 | shader_12_pinkextravaganza.gd | Pink Extravaganza | Melted Candy, Crushed Pearl, Oil Slick, Queer Water, Drag Extravaganza |

Chapters 01--09 use flat 2D display panels with interactive sliders. Chapters 10--12 shift to 3D objects (spheres, tori, capsules, cylinders, planes) with dramatic lighting and rotation animation, presenting shader materials as theatrical installations.

## Features

- 12 progressive chapters covering the full shader programming curriculum
- Interactive VR sliders mapped to shader uniforms in real time
- Code snippet labels showing the key GLSL operation for each display
- Chapters 11--12 use 3D objects in dramatic arc layouts with colored OmniLight3D lighting
- Gentle rotation and bobbing animations for 3D material showcases
- Consistent gallery architecture across all chapters via ShaderRackPanel

## Files

- `shader_01_shaping.gd` -- Shaping functions (step, smoothstep, sin, pow)
- `shader_02_colors.gd` -- Color mixing and HSB/RGB conversion
- `shader_03_shapes.gd` -- Signed distance field shapes and boolean operations
- `shader_04_matrices.gd` -- UV transformation matrices
- `shader_05_patterns.gd` -- Tiling, truchet, brick patterns
- `shader_06_random.gd` -- GPU pseudorandom generation
- `shader_07_noise.gd` -- Value, gradient, simplex noise and domain warping
- `shader_08_cellularnoise.gd` -- Voronoi, Worley, and crackle noise
- `shader_09_fbm.gd` -- Fractional Brownian motion and turbulence
- `shader_10_reactiondiffusion.gd` -- Reaction-diffusion and DLA growth
- `shader_11_queerrubber.gd` -- Queer material shaders on 3D objects
- `shader_12_pinkextravaganza.gd` -- Theatrical drag shader finale
- Multiple `.gdshader` files (one per display panel per chapter)
