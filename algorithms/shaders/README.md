# Shaders

GPU programs that define how surfaces look. Parallel computation for visual effects.

## QFEP Connection

Shaders run in **parallel** — millions of pixels computed simultaneously, each following the same rules (F) but with different inputs (E). The result is emergence: simple per-pixel logic creates complex visual patterns. Queer materials challenge "normal" material assumptions.

## Contents

| Folder | Description |
|--------|-------------|
| `queer_materials/` | Non-normative material properties |
| `queer_ecology/` | Ecological/organic shader effects |
| `queer_collection_2/` | Experimental queer visual effects |
| `degrading_shader/` | Materials that degrade over time |
| `materialtransmission/` | Light transmission and subsurface |
| `dynamicubemap/` | Dynamic environment mapping |
| `buffer/` | Frame buffer techniques |
| `tilesexplained/` | Tiled/repeating patterns |

## Key Concepts

1. **Vertex shader** — Transform vertices (position, normal)
2. **Fragment shader** — Calculate pixel color
3. **Uniforms** — Parameters passed from CPU
4. **Varyings** — Data passed from vertex to fragment
5. **Textures** — 2D data sampled in shader
6. **Render pipeline** — Vertex → Rasterize → Fragment → Output

## Shader Types in Godot

```gdshader
shader_type spatial;   // 3D materials
shader_type canvas_item;  // 2D sprites
shader_type particles;    // GPU particles
shader_type sky;          // Skybox
```

## Basic Fragment Shader

```gdshader
shader_type spatial;

void fragment() {
    // ALBEDO = base color
    ALBEDO = vec3(1.0, 0.0, 0.0);  // Red
    
    // METALLIC, ROUGHNESS = PBR properties
    METALLIC = 0.5;
    ROUGHNESS = 0.3;
}
```

## VR Experience

- See shader effects on 3D objects
- Interact with dynamic materials
- Experience queer visual aesthetics
- Watch degradation over time

## Files

- 5 GDScript files
- 7 scene files
- 3 documentation files
